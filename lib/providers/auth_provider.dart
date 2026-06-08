import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/cloud_sync_service.dart';
import '../services/local_store.dart';

final authServiceProvider = Provider<AuthService>((_) => AuthService.resolve());

class AuthState {
  const AuthState({this.user, this.loading = false, this.errorKey});
  final AppUser? user;
  final bool loading;
  final String? errorKey;

  bool get isAuthenticated => user != null;

  AuthState copyWith({AppUser? user, bool? loading, String? errorKey, bool clearError = false, bool clearUser = false}) =>
      AuthState(
        user: clearUser ? null : (user ?? this.user),
        loading: loading ?? this.loading,
        errorKey: clearError ? null : (errorKey ?? this.errorKey),
      );
}

class AuthController extends Notifier<AuthState> {
  AuthService get _service => ref.read(authServiceProvider);

  @override
  AuthState build() {
    final session = LocalStore.instance.currentSession;
    return AuthState(user: session == null ? null : AppUser.fromJson(session));
  }

  Future<bool> _run(Future<AppUser> Function() action) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final user = await action();
      state = AuthState(user: user);
      // Seed local store from cloud on a fresh device (best-effort).
      await CloudSync.instance.pullAll();
      return true;
    } on AuthException catch (e) {
      state = AuthState(user: state.user, errorKey: e.messageKey);
      return false;
    } catch (_) {
      state = AuthState(user: state.user, errorKey: 'auth_failed');
      return false;
    }
  }

  Future<bool> signIn(String email, String password) =>
      _run(() => _service.signIn(email: email, password: password));

  Future<bool> signUp(String name, String email, String password) =>
      _run(() => _service.signUp(name: name, email: email, password: password));

  Future<bool> signInWithGoogle() => _run(() => _service.signInWithGoogle());

  Future<bool> signInWithApple() => _run(() => _service.signInWithApple());

  Future<void> sendPasswordReset(String email) => _service.sendPasswordReset(email);

  Future<void> resendVerification() => _service.sendEmailVerification();

  Future<bool> refreshVerification() async {
    final verified = await _service.refreshEmailVerified();
    if (verified && state.user != null) {
      state = state.copyWith(user: state.user!.copyWith(emailVerified: true));
    }
    return verified;
  }

  Future<void> signOut() async {
    await _service.signOut();
    state = const AuthState();
  }

  Future<void> deleteAccount() async {
    await _service.deleteAccount();
    state = const AuthState();
  }

  void clearError() => state = state.copyWith(clearError: true);
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(AuthController.new);
