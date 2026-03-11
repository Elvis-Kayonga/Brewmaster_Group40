// ignore_for_file: avoid_print

import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:brewmaster/domain/models/user_profile.dart';
import 'package:brewmaster/domain/repositories/auth_repository.dart';
import 'package:brewmaster/domain/repositories/user_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  final UserRepository _userRepository;
  late final StreamSubscription<User?> _authSubscription;

  AuthBloc({
    required AuthRepository authRepository,
    required UserRepository userRepository,
  })  : _authRepository = authRepository,
        _userRepository = userRepository,
        super(const AuthInitial()) {
    on<_AuthUserChanged>(_onAuthUserChanged);
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthSignInRequested>(_onSignIn);
    on<AuthRegisterRequested>(_onRegister);
    on<AuthGoogleSignInRequested>(_onGoogleSignIn);
    on<AuthVerificationEmailRequested>(_onSendVerificationEmail);
    on<AuthSignOutRequested>(_onSignOut);
    on<AuthPasswordResetRequested>(_onPasswordReset);

    // Listen to Firebase auth state changes and dispatch internally
    _authSubscription = _authRepository.authStateChanges.listen(
      (user) => add(_AuthUserChanged(user)),
    );
  }

  // ---------------------------------------------------------------------------
  // Handlers
  // ---------------------------------------------------------------------------

  Future<void> _onAuthUserChanged(
    _AuthUserChanged event,
    Emitter<AuthState> emit,
  ) async {
    final user = event.user;
    if (user == null) {
      emit(const AuthUnauthenticated());
      return;
    }

    // Reload so emailVerified is fresh
    try {
      await user.reload();
    } catch (_) {}

    final fresh = _authRepository.currentUser;
    if (fresh == null) {
      emit(const AuthUnauthenticated());
      return;
    }

    // Check if a Firestore profile exists
    final profile = await _userRepository.getUserProfile(fresh.uid);

    if (profile == null) {
      // New user — needs to complete profile setup
      final isGoogle = fresh.providerData
          .any((p) => p.providerId == 'google.com');
      emit(AuthNeedsProfile(
        uid: fresh.uid,
        email: fresh.email,
        displayName: fresh.displayName,
        isGoogleUser: isGoogle,
      ));
      return;
    }

    if (!fresh.emailVerified && !_isGoogleUser(fresh)) {
      emit(const AuthEmailNotVerified());
      return;
    }

    emit(AuthAuthenticated(await _syncVerifiedFlag(fresh, profile)));
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    final user = _authRepository.currentUser;
    if (user == null) {
      emit(const AuthUnauthenticated());
      return;
    }

    final profile = await _userRepository.getUserProfile(user.uid);
    if (profile == null) {
      final isGoogle = _isGoogleUser(user);
      emit(AuthNeedsProfile(
        uid: user.uid,
        email: user.email,
        displayName: user.displayName,
        isGoogleUser: isGoogle,
      ));
      return;
    }

    // Use isEmailVerified() which does reload + force-token-refresh internally,
    // ensuring the cached emailVerified flag is always up-to-date on Android.
    if (!_isGoogleUser(user) && !await _authRepository.isEmailVerified()) {
      emit(const AuthEmailNotVerified());
      return;
    }

    final fresh = _authRepository.currentUser ?? user;
    emit(AuthAuthenticated(await _syncVerifiedFlag(fresh, profile)));
  }

  Future<void> _onSignIn(
    AuthSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await _authRepository.signIn(event.email, event.password);
      // Explicitly block unverified email users from signing in
      final firebaseUser = _authRepository.currentUser;
      if (firebaseUser != null &&
          !firebaseUser.emailVerified &&
          !_isGoogleUser(firebaseUser)) {
        emit(const AuthEmailNotVerified());
        return;
      }
      // _AuthUserChanged will fire automatically via stream for the full state resolution
    } on FirebaseAuthException catch (e) {
      emit(AuthFailure(_mapFirebaseError(e)));
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _onRegister(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final user = await _authRepository.register(event.email, event.password);
      if (user != null) {
        // Best-effort: persist to Firebase Auth so other surfaces can read it
        if (event.displayName.isNotEmpty) {
          try {
            await user.updateDisplayName(event.displayName);
          } catch (_) {}
        }
        // Emit directly using event.displayName — avoids the reload() race condition
        // that overwrites displayName with null before updateDisplayName propagates,
        // and guarantees navigation to ProfileSetupScreen even when authStateChanges()
        // doesn't fire due to the Pigeon bug on some Android devices.
        emit(AuthNeedsProfile(
          uid: user.uid,
          email: user.email ?? event.email,
          displayName: event.displayName,
          isGoogleUser: false,
        ));
      }
    } on FirebaseAuthException catch (e) {
      emit(AuthFailure(_mapFirebaseError(e)));
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _onGoogleSignIn(
    AuthGoogleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final user = await _authRepository.signInWithGoogle();
      if (user == null) {
        // User cancelled the Google picker
        emit(const AuthUnauthenticated());
      }
      // Otherwise _AuthUserChanged fires automatically
    } on FirebaseAuthException catch (e) {
      emit(AuthFailure(_mapFirebaseError(e)));
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _onSendVerificationEmail(
    AuthVerificationEmailRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final sent = await _authRepository.sendEmailVerification();
      if (sent) emit(const AuthVerificationEmailSent());
    } on FirebaseAuthException catch (e) {
      emit(AuthFailure(_mapFirebaseError(e)));
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
    // Re-emit not-verified so the screen stays on the verification page
    emit(const AuthEmailNotVerified());
  }

  Future<void> _onSignOut(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await _authRepository.signOut();
      // _AuthUserChanged(null) fires automatically
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _onPasswordReset(
    AuthPasswordResetRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await _authRepository.sendPasswordResetEmail(event.email);
      emit(const AuthPasswordResetSent());
    } on FirebaseAuthException catch (e) {
      emit(AuthFailure(_mapFirebaseError(e)));
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// If the Firebase user's email is now verified but the Firestore profile
  /// still has [isVerified] == false, update it and return the fresh profile.
  Future<UserProfile> _syncVerifiedFlag(User user, UserProfile profile) async {
    if (!profile.isVerified) {
      try {
        await _userRepository.updateUserProfile(
            user.uid, {'isVerified': true});
        final refreshed = await _userRepository.getUserProfile(user.uid);
        if (refreshed != null) return refreshed;
      } catch (_) {}
    }
    return profile;
  }

  bool _isGoogleUser(User user) =>
      user.providerData.any((p) => p.providerId == 'google.com');

  String _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      default:
        return e.message ?? 'An authentication error occurred.';
    }
  }

  @override
  Future<void> close() {
    _authSubscription.cancel();
    return super.close();
  }
}
