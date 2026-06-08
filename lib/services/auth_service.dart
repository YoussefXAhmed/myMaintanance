import '../core/app_config.dart';
import '../models/app_user.dart';
import 'firebase_service.dart';
import 'local_auth_service.dart';
import 'firebase_auth_service.dart';

/// Thrown by auth implementations; [messageKey] is a localization key.
class AuthException implements Exception {
  AuthException(this.messageKey, [this.detail]);
  final String messageKey;
  final String? detail;
  @override
  String toString() => 'AuthException($messageKey)';
}

/// Common contract for the local and Firebase auth back-ends, so the rest of
/// the app never branches on which one is active.
abstract class AuthService {
  Future<AppUser?> currentUser();

  Future<AppUser> signIn({required String email, required String password});

  Future<AppUser> signUp({required String name, required String email, required String password});

  Future<void> signOut();

  Future<void> sendPasswordReset(String email);

  Future<void> sendEmailVerification();

  /// Reloads the user and returns whether the email is now verified.
  Future<bool> refreshEmailVerified();

  Future<AppUser> signInWithGoogle();

  Future<AppUser> signInWithApple();

  Future<void> deleteAccount();

  /// Selects the back-end: Firebase when enabled and initialised, else local.
  factory AuthService.resolve() {
    if (AppConfig.enableFirebase && FirebaseService.isAvailable) {
      return FirebaseAuthService();
    }
    return LocalAuthService();
  }
}
