part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Fired internally when Firebase auth state changes.
class _AuthUserChanged extends AuthEvent {
  final User? user;
  const _AuthUserChanged(this.user);

  @override
  List<Object?> get props => [user];
}

/// Check current auth state (e.g. after email verification polling confirms verified).
class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

/// Sign in with email + password.
class AuthSignInRequested extends AuthEvent {
  final String email;
  final String password;
  const AuthSignInRequested({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

/// Register a new account with email + password.
class AuthRegisterRequested extends AuthEvent {
  final String email;
  final String password;
  final String displayName;
  const AuthRegisterRequested({
    required this.email,
    required this.password,
    required this.displayName,
  });

  @override
  List<Object?> get props => [email, password, displayName];
}

/// Sign in with Google.
class AuthGoogleSignInRequested extends AuthEvent {
  const AuthGoogleSignInRequested();
}

/// Send an email verification link to the current user.
class AuthVerificationEmailRequested extends AuthEvent {
  const AuthVerificationEmailRequested();
}

/// Sign out.
class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}

/// Send a password reset email.
class AuthPasswordResetRequested extends AuthEvent {
  final String email;
  const AuthPasswordResetRequested(this.email);

  @override
  List<Object?> get props => [email];
}
