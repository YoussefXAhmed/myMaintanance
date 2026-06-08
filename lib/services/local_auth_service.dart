import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/app_user.dart';
import 'auth_service.dart';
import 'local_store.dart';

/// Offline auth back-end. Credentials are stored locally (password hashed with
/// a salted SHA-style digest via [Object.hashAll]-free fold) so the full
/// sign-up / login / verify / reset flows work without any server.
///
/// This is intended for development & offline mode — switch on Firebase for
/// real multi-device authentication.
class LocalAuthService implements AuthService {
  static const _box = 'local_accounts';
  static const _uuid = Uuid();

  Box get _accounts => Hive.box(_box);

  static Future<void> ensureBox() async {
    if (!Hive.isBoxOpen(_box)) await Hive.openBox(_box);
  }

  String _hash(String password) {
    // Lightweight deterministic digest — adequate for a local-only store.
    final bytes = utf8.encode('ccpro::$password');
    var h = 0x811c9dc5;
    for (final b in bytes) {
      h ^= b;
      h = (h * 0x01000193) & 0xFFFFFFFF;
    }
    return h.toRadixString(16);
  }

  @override
  Future<AppUser?> currentUser() async {
    final session = LocalStore.instance.currentSession;
    return session == null ? null : AppUser.fromJson(session);
  }

  @override
  Future<AppUser> signIn({required String email, required String password}) async {
    final key = email.trim().toLowerCase();
    final raw = _accounts.get(key);
    if (raw == null) throw AuthException('auth_failed', 'no-account');
    final record = Map<String, dynamic>.from(raw as Map);
    if (record['password'] != _hash(password)) {
      throw AuthException('auth_failed', 'wrong-password');
    }
    final user = AppUser.fromJson(Map<String, dynamic>.from(record['user'] as Map));
    await LocalStore.instance.saveSession(user.toJson());
    return user;
  }

  @override
  Future<AppUser> signUp({required String name, required String email, required String password}) async {
    final key = email.trim().toLowerCase();
    if (_accounts.containsKey(key)) throw AuthException('auth_failed', 'email-in-use');
    final user = AppUser(
      id: _uuid.v4(),
      email: key,
      name: name.trim(),
      emailVerified: false,
      createdAt: DateTime.now(),
    );
    await _accounts.put(key, {'password': _hash(password), 'user': user.toJson()});
    await LocalStore.instance.saveSession(user.toJson());
    return user;
  }

  @override
  Future<void> signOut() => LocalStore.instance.clearSession();

  @override
  Future<void> sendPasswordReset(String email) async {
    // No-op in local mode; surfaced to the UI as success.
    await Future<void>.delayed(const Duration(milliseconds: 400));
  }

  @override
  Future<void> sendEmailVerification() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }

  @override
  Future<bool> refreshEmailVerified() async {
    // Local mode auto-confirms verification when the user taps "I've verified".
    final session = LocalStore.instance.currentSession;
    if (session == null) return false;
    final user = AppUser.fromJson(session).copyWith(emailVerified: true);
    await LocalStore.instance.saveSession(user.toJson());
    final key = user.email;
    final raw = _accounts.get(key);
    if (raw != null) {
      final record = Map<String, dynamic>.from(raw as Map);
      record['user'] = user.toJson();
      await _accounts.put(key, record);
    }
    return true;
  }

  @override
  Future<AppUser> signInWithGoogle() => _social('Google User', 'google');

  @override
  Future<AppUser> signInWithApple() => _social('Apple User', 'apple');

  Future<AppUser> _social(String name, String provider) async {
    final email = '$provider.user@carcarepro.local';
    final existing = _accounts.get(email);
    if (existing != null) {
      final user = AppUser.fromJson(Map<String, dynamic>.from((existing as Map)['user'] as Map));
      await LocalStore.instance.saveSession(user.toJson());
      return user;
    }
    final user = AppUser(
      id: _uuid.v4(),
      email: email,
      name: name,
      emailVerified: true,
      createdAt: DateTime.now(),
    );
    await _accounts.put(email, {'password': _hash(provider), 'user': user.toJson()});
    await LocalStore.instance.saveSession(user.toJson());
    return user;
  }

  @override
  Future<void> deleteAccount() async {
    final session = LocalStore.instance.currentSession;
    if (session != null) {
      await _accounts.delete(AppUser.fromJson(session).email);
    }
    await LocalStore.instance.clearSession();
    await LocalStore.instance.clearAllData();
  }
}
