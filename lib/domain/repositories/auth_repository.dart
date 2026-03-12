import 'package:firebase_auth/firebase_auth.dart';

/// Abstract interface for authentication operations.
/// The UI and BLoC layer must only depend on this interface, never on Firebase directly.
abstract class AuthRepository {
  /// Stream of Firebase auth state changes (null = signed out).
  Stream<User?> get authStateChanges;

  /// The currently signed-in Firebase user, or null.
  User? get currentUser;

  /// Register a new account with email and password.
  Future<User?> register(String email, String password);

  /// Sign in with email and password.
  Future<User?> signIn(String email, String password);

  /// Sign in with Google OAuth.
  Future<User?> signInWithGoogle();

  /// Sign out from all providers.
  Future<void> signOut();

  /// Send a password reset email.
  Future<void> sendPasswordResetEmail(String email);

  /// Send an email verification link to the currently signed-in user.
  /// Returns true if an email was actually sent.
  Future<bool> sendEmailVerification();

  /// Reload the current user and return whether their email is verified.
  Future<bool> isEmailVerified();
}
