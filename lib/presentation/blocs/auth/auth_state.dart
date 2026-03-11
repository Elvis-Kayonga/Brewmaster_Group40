part of 'auth_bloc.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any auth check.
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Auth operation in progress.
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// User is fully authenticated and has a Firestore profile.
class AuthAuthenticated extends AuthState {
  final UserProfile profile;
  const AuthAuthenticated(this.profile);

  @override
  List<Object?> get props => [profile];
}

/// No user is signed in.
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// Firebase user is signed in but no Firestore profile exists yet.
/// Carries enough data for ProfileSetupScreen to pre-fill fields.
class AuthNeedsProfile extends AuthState {
  final String uid;
  final String? email;
  final String? displayName;
  final bool isGoogleUser;

  const AuthNeedsProfile({
    required this.uid,
    this.email,
    this.displayName,
    this.isGoogleUser = false,
  });

  @override
  List<Object?> get props => [uid, email, displayName, isGoogleUser];
}

/// Firebase user is signed in but email is not yet verified.
class AuthEmailNotVerified extends AuthState {
  const AuthEmailNotVerified();
}

/// A verification email was successfully sent (transient — UI shows snackbar).
class AuthVerificationEmailSent extends AuthState {
  const AuthVerificationEmailSent();
}

/// A password reset email was successfully sent.
class AuthPasswordResetSent extends AuthState {
  const AuthPasswordResetSent();
}

/// Auth operation failed.
class AuthFailure extends AuthState {
  final String message;
  const AuthFailure(this.message);

  @override
  List<Object?> get props => [message];
}
