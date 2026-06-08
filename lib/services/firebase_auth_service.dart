import 'dart:io' show Platform;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../models/app_user.dart';
import 'auth_service.dart';
import 'local_store.dart';

/// Firebase-backed authentication: email/password, Google and Apple, with the
/// user profile mirrored to a `users/{uid}` Firestore document.
class FirebaseAuthService implements AuthService {
  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  AppUser _map(fb.User u) => AppUser(
        id: u.uid,
        email: u.email ?? '',
        name: u.displayName ?? '',
        photoUrl: u.photoURL,
        emailVerified: u.emailVerified,
        createdAt: u.metadata.creationTime,
      );

  Future<AppUser> _persist(fb.User u, {String? name}) async {
    final user = name != null ? _map(u).copyWith(name: name) : _map(u);
    await LocalStore.instance.saveSession(user.toJson());
    try {
      await _db.collection('users').doc(u.uid).set(user.toJson(), SetOptions(merge: true));
    } catch (_) {/* best-effort */}
    return user;
  }

  @override
  Future<AppUser?> currentUser() async {
    final u = _auth.currentUser;
    if (u == null) return null;
    return _persist(u);
  }

  @override
  Future<AppUser> signIn({required String email, required String password}) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
      return _persist(cred.user!);
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException('auth_failed', e.code);
    }
  }

  @override
  Future<AppUser> signUp({required String name, required String email, required String password}) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(email: email.trim(), password: password);
      await cred.user!.updateDisplayName(name.trim());
      await cred.user!.sendEmailVerification();
      return _persist(cred.user!, name: name.trim());
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException('auth_failed', e.code);
    }
  }

  @override
  Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await _auth.signOut();
    await LocalStore.instance.clearSession();
  }

  @override
  Future<void> sendPasswordReset(String email) => _auth.sendPasswordResetEmail(email: email.trim());

  @override
  Future<void> sendEmailVerification() async => _auth.currentUser?.sendEmailVerification();

  @override
  Future<bool> refreshEmailVerified() async {
    await _auth.currentUser?.reload();
    final u = _auth.currentUser;
    if (u != null && u.emailVerified) {
      await _persist(u);
      return true;
    }
    return false;
  }

  @override
  Future<AppUser> signInWithGoogle() async {
    try {
      final account = await GoogleSignIn().signIn();
      if (account == null) throw AuthException('auth_failed', 'cancelled');
      final googleAuth = await account.authentication;
      final credential = fb.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final cred = await _auth.signInWithCredential(credential);
      return _persist(cred.user!);
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException('auth_failed', e.code);
    }
  }

  @override
  Future<AppUser> signInWithApple() async {
    if (!(Platform.isIOS || Platform.isMacOS)) {
      throw AuthException('auth_failed', 'apple-unsupported');
    }
    try {
      final apple = await SignInWithApple.getAppleIDCredential(
        scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
      );
      final oauth = fb.OAuthProvider('apple.com').credential(
        idToken: apple.identityToken,
        accessToken: apple.authorizationCode,
      );
      final cred = await _auth.signInWithCredential(oauth);
      final name = [apple.givenName, apple.familyName].whereType<String>().join(' ').trim();
      return _persist(cred.user!, name: name.isEmpty ? null : name);
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException('auth_failed', e.code);
    }
  }

  @override
  Future<void> deleteAccount() async {
    final u = _auth.currentUser;
    if (u != null) {
      try {
        await _db.collection('users').doc(u.uid).delete();
      } catch (_) {}
      await u.delete();
    }
    await LocalStore.instance.clearSession();
    await LocalStore.instance.clearAllData();
  }
}
