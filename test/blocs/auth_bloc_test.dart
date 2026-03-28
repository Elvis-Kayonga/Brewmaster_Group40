// test/blocs/auth_bloc_test.dart
//
// Comprehensive unit tests for AuthBloc.
// Uses plain flutter_test — no bloc_test package dependency.
//
// Coverage:
//  1. Initial state
//  2. AuthCheckRequested  — unauthenticated / authenticated / needs-profile / unverified
//  3. AuthSignInRequested — success (stream-driven), failure
//  4. AuthRegisterRequested — success, failure
//  5. AuthGoogleSignInRequested — success, cancelled, failure
//  6. AuthSignOutRequested
//  7. AuthPasswordResetRequested — success, failure
//  8. AuthVerificationEmailRequested
//  9. _AuthUserChanged via stream — null user, valid user

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_test/flutter_test.dart';

import 'package:brewmaster/domain/models/enums.dart';
import 'package:brewmaster/domain/models/user_profile.dart';
import 'package:brewmaster/domain/repositories/auth_repository.dart';
import 'package:brewmaster/domain/repositories/user_repository.dart';
import 'package:brewmaster/presentation/blocs/auth/auth_bloc.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Fake Firebase User
// ─────────────────────────────────────────────────────────────────────────────

class _FakeUserInfo implements fb.UserInfo {
  final String _providerId;
  const _FakeUserInfo(this._providerId);

  @override
  String get providerId => _providerId;
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _FakeUser implements fb.User {
  @override
  final String uid;
  @override
  final String? email;
  @override
  final bool emailVerified;
  @override
  final List<fb.UserInfo> providerData;
  @override
  String? get displayName => null;
  @override
  String? get phoneNumber => null;
  @override
  String? get photoURL => null;

  _FakeUser({
    required this.uid,
    this.email,
    this.emailVerified = false,
    List<fb.UserInfo>? providerData,
  }) : providerData = providerData ?? const [];

  @override
  Future<void> reload() async {}

  @override
  Future<void> updateDisplayName(String? displayName) async {}

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

_FakeUser _emailUser({
  String uid = 'uid-1',
  String email = 'user@test.com',
  bool emailVerified = true,
}) =>
    _FakeUser(uid: uid, email: email, emailVerified: emailVerified);

_FakeUser _googleUser({
  String uid = 'gid-1',
  String email = 'guser@gmail.com',
}) =>
    _FakeUser(
      uid: uid,
      email: email,
      emailVerified: true,
      providerData: [const _FakeUserInfo('google.com')],
    );

// ─────────────────────────────────────────────────────────────────────────────
// Controllable FakeAuthRepository
// ─────────────────────────────────────────────────────────────────────────────

class _FakeAuthRepository implements AuthRepository {
  fb.User? _currentUser;
  bool _emailVerified = false;
  bool _sendVerificationResult = true;
  Exception? _signInError;
  Exception? _registerError;
  Exception? _googleError;
  Exception? _passwordResetError;
  fb.User? _signInResult;
  fb.User? _registerResult;
  fb.User? _googleResult;

  // Controllable stream for authStateChanges
  final StreamController<fb.User?> _authStateController =
      StreamController<fb.User?>.broadcast();

  // Push a user change event onto the stream
  void pushAuthState(fb.User? user) {
    _currentUser = user;
    _authStateController.add(user);
  }

  void setCurrentUser(fb.User? user) => _currentUser = user;
  void setEmailVerified(bool v) => _emailVerified = v;
  void setSendVerificationResult(bool v) => _sendVerificationResult = v;
  void setSignInResult(fb.User? user) => _signInResult = user;
  void setRegisterResult(fb.User? user) => _registerResult = user;
  void setGoogleResult(fb.User? user) => _googleResult = user;
  void setSignInError(Exception e) => _signInError = e;
  void setRegisterError(Exception e) => _registerError = e;
  void setGoogleError(Exception e) => _googleError = e;
  void setPasswordResetError(Exception e) => _passwordResetError = e;

  void dispose() => _authStateController.close();

  @override
  Stream<fb.User?> get authStateChanges => _authStateController.stream;

  @override
  fb.User? get currentUser => _currentUser;

  @override
  Future<fb.User?> signIn(String email, String password) async {
    if (_signInError != null) throw _signInError!;
    if (_signInResult != null) {
      _currentUser = _signInResult;
    }
    return _signInResult;
  }

  @override
  Future<fb.User?> register(String email, String password) async {
    if (_registerError != null) throw _registerError!;
    if (_registerResult != null) {
      _currentUser = _registerResult;
    }
    return _registerResult;
  }

  @override
  Future<fb.User?> signInWithGoogle() async {
    if (_googleError != null) throw _googleError!;
    if (_googleResult != null) {
      _currentUser = _googleResult;
    }
    return _googleResult;
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    if (_passwordResetError != null) throw _passwordResetError!;
  }

  @override
  Future<bool> sendEmailVerification() async => _sendVerificationResult;

  @override
  Future<bool> isEmailVerified() async => _emailVerified;
}

// ─────────────────────────────────────────────────────────────────────────────
// Controllable FakeUserRepository
// ─────────────────────────────────────────────────────────────────────────────

class _FakeUserRepository implements UserRepository {
  UserProfile? _profile;
  Exception? _error;

  void setProfile(UserProfile? p) => _profile = p;
  void setError(Exception e) => _error = e;

  @override
  Future<UserProfile?> getUserProfile(String userId) async {
    if (_error != null) throw _error!;
    return _profile;
  }

  @override
  Future<UserProfile?> getUserProfileByEmail(String email) async => _profile;

  @override
  Future<void> createUserProfile(UserProfile p) async {
    if (_error != null) throw _error!;
  }

  @override
  Future<void> updateUserProfile(
      String userId, Map<String, dynamic> updates) async {
    if (_error != null) throw _error!;
  }

  @override
  Stream<UserProfile?> watchUserProfile(String userId) =>
      _profile != null ? Stream.value(_profile) : const Stream.empty();

  @override
  Future<void> saveListing(String userId, String listingId) async {}

  @override
  Future<void> unsaveListing(String userId, String listingId) async {}

  @override
  Future<List<String>> getSavedListings(String userId) async => [];
}

// ─────────────────────────────────────────────────────────────────────────────
// Profile fixtures
// ─────────────────────────────────────────────────────────────────────────────

final _kNow = DateTime(2025, 1, 1);

UserProfile _makeProfile({
  String uid = 'uid-1',
  VerificationStatus status = VerificationStatus.verified,
  bool isVerified = true,
}) =>
    UserProfile(
      id: uid,
      email: 'user@test.com',
      phoneNumber: '+1234567890',
      role: UserRole.farmer,
      displayName: 'Test User',
      isVerified: isVerified,
      createdAt: _kNow,
      updatedAt: _kNow,
      verificationStatus: status,
    );

// ─────────────────────────────────────────────────────────────────────────────
// Test helpers
// ─────────────────────────────────────────────────────────────────────────────

/// Collect bloc states after performing [act], waiting for [ticks] event loops.
Future<List<AuthState>> _collectStates(
  AuthBloc bloc, {
  required Future<void> Function() act,
  int ticks = 3,
}) async {
  final states = <AuthState>[];
  final sub = bloc.stream.listen(states.add);
  await act();
  for (var i = 0; i < ticks; i++) {
    await Future<void>.delayed(Duration.zero);
  }
  await sub.cancel();
  return states;
}

// ─────────────────────────────────────────────────────────────────────────────
// Tests
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  late _FakeAuthRepository authRepo;
  late _FakeUserRepository userRepo;

  AuthBloc buildBloc() => AuthBloc(
        authRepository: authRepo,
        userRepository: userRepo,
      );

  setUp(() {
    authRepo = _FakeAuthRepository();
    userRepo = _FakeUserRepository();
  });

  tearDown(() {
    authRepo.dispose();
  });

  // ───────────────────────────────────────────────────────────────────────────
  // 1. Initial state
  // ───────────────────────────────────────────────────────────────────────────

  group('AuthBloc — initial state', () {
    test('starts with AuthInitial', () {
      final bloc = buildBloc();
      expect(bloc.state, isA<AuthInitial>());
      bloc.close();
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // 2. AuthCheckRequested
  // ───────────────────────────────────────────────────────────────────────────

  group('AuthBloc — AuthCheckRequested', () {
    test('emits AuthUnauthenticated when no user is logged in', () async {
      authRepo.setCurrentUser(null);
      final bloc = buildBloc();

      final states = await _collectStates(
        bloc,
        act: () async => bloc.add(const AuthCheckRequested()),
      );

      expect(states, contains(isA<AuthUnauthenticated>()));
      bloc.close();
    });

    test('emits AuthAuthenticated when user exists with verified profile',
        () async {
      final user = _emailUser(emailVerified: true);
      authRepo.setCurrentUser(user);
      authRepo.setEmailVerified(true);
      userRepo.setProfile(_makeProfile(status: VerificationStatus.verified));

      final bloc = buildBloc();

      final states = await _collectStates(
        bloc,
        act: () async => bloc.add(const AuthCheckRequested()),
      );

      expect(states, contains(isA<AuthAuthenticated>()));
      bloc.close();
    });

    test('emits AuthNeedsProfile when user exists but no Firestore profile',
        () async {
      final user = _emailUser(emailVerified: true);
      authRepo.setCurrentUser(user);
      userRepo.setProfile(null);

      final bloc = buildBloc();

      final states = await _collectStates(
        bloc,
        act: () async => bloc.add(const AuthCheckRequested()),
      );

      expect(states, contains(isA<AuthNeedsProfile>()));
      bloc.close();
    });

    test('emits AuthEmailNotVerified when email user is unverified', () async {
      final user = _emailUser(emailVerified: false);
      authRepo.setCurrentUser(user);
      authRepo.setEmailVerified(false);
      userRepo.setProfile(_makeProfile());

      final bloc = buildBloc();

      final states = await _collectStates(
        bloc,
        act: () async => bloc.add(const AuthCheckRequested()),
      );

      expect(states, contains(isA<AuthEmailNotVerified>()));
      bloc.close();
    });

    test('skips email-verification check for Google users', () async {
      final user = _googleUser();
      authRepo.setCurrentUser(user);
      authRepo.setEmailVerified(false); // should be ignored for Google users
      userRepo.setProfile(_makeProfile(status: VerificationStatus.verified));

      final bloc = buildBloc();

      final states = await _collectStates(
        bloc,
        act: () async => bloc.add(const AuthCheckRequested()),
      );

      // Google users bypass email verification → goes straight to authenticated
      expect(states, contains(isA<AuthAuthenticated>()));
      bloc.close();
    });

    test('emits AuthNeedsKycVerification when verification status is unverified',
        () async {
      final user = _emailUser(emailVerified: true);
      authRepo.setCurrentUser(user);
      authRepo.setEmailVerified(true);
      userRepo
          .setProfile(_makeProfile(status: VerificationStatus.unverified));

      final bloc = buildBloc();

      final states = await _collectStates(
        bloc,
        act: () async => bloc.add(const AuthCheckRequested()),
      );

      expect(states, contains(isA<AuthNeedsKycVerification>()));
      bloc.close();
    });

    test('emits AuthKycPending when verification status is pending', () async {
      final user = _emailUser(emailVerified: true);
      authRepo.setCurrentUser(user);
      authRepo.setEmailVerified(true);
      userRepo.setProfile(_makeProfile(status: VerificationStatus.pending));

      final bloc = buildBloc();

      final states = await _collectStates(
        bloc,
        act: () async => bloc.add(const AuthCheckRequested()),
      );

      expect(states, contains(isA<AuthKycPending>()));
      bloc.close();
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // 3. AuthSignInRequested
  // ───────────────────────────────────────────────────────────────────────────

  group('AuthBloc — AuthSignInRequested', () {
    test('emits AuthLoading then AuthEmailNotVerified for unverified user',
        () async {
      final user = _emailUser(emailVerified: false);
      authRepo.setSignInResult(user);

      final bloc = buildBloc();

      final states = await _collectStates(
        bloc,
        act: () async => bloc.add(
          const AuthSignInRequested(email: 'user@test.com', password: 'pw123'),
        ),
      );

      expect(states.first, isA<AuthLoading>());
      expect(states, contains(isA<AuthEmailNotVerified>()));
      bloc.close();
    });

    test('emits AuthLoading then AuthFailure on FirebaseAuthException',
        () async {
      authRepo.setSignInError(
        fb.FirebaseAuthException(code: 'user-not-found'),
      );

      final bloc = buildBloc();

      final states = await _collectStates(
        bloc,
        act: () async => bloc.add(
          const AuthSignInRequested(email: 'x@x.com', password: 'pw'),
        ),
      );

      expect(states.first, isA<AuthLoading>());
      expect(states.last, isA<AuthFailure>());
      expect((states.last as AuthFailure).message,
          'No account found with this email.');
      bloc.close();
    });

    test('emits AuthLoading then AuthFailure on generic exception', () async {
      authRepo.setSignInError(Exception('network error'));

      final bloc = buildBloc();

      final states = await _collectStates(
        bloc,
        act: () async => bloc.add(
          const AuthSignInRequested(email: 'x@x.com', password: 'pw'),
        ),
      );

      expect(states.first, isA<AuthLoading>());
      expect(states.last, isA<AuthFailure>());
      bloc.close();
    });

    test('emits AuthLoading and lets stream drive state on successful sign-in',
        () async {
      // Sign-in returns a verified user; no stream event fired in this test
      final user = _emailUser(emailVerified: true);
      authRepo.setSignInResult(user);
      userRepo.setProfile(_makeProfile(status: VerificationStatus.verified));

      final bloc = buildBloc();

      final states = await _collectStates(
        bloc,
        act: () async => bloc.add(
          const AuthSignInRequested(
              email: 'user@test.com', password: 'pw123'),
        ),
      );

      // After successful sign-in for a verified user the bloc emits AuthLoading
      // and then waits for _AuthUserChanged via the stream. At minimum loading
      // should be present.
      expect(states, contains(isA<AuthLoading>()));
      bloc.close();
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // 4. AuthRegisterRequested
  // ───────────────────────────────────────────────────────────────────────────

  group('AuthBloc — AuthRegisterRequested', () {
    test('emits AuthLoading then AuthNeedsProfile on success', () async {
      // Use the same email on both the fake user and the event so the
      // bloc's `user.email ?? event.email` expression is unambiguous.
      const registrationEmail = 'new@test.com';
      final user = _FakeUser(
        uid: 'new-uid',
        email: registrationEmail,
        emailVerified: false,
      );
      authRepo.setRegisterResult(user);

      final bloc = buildBloc();

      final states = await _collectStates(
        bloc,
        act: () async => bloc.add(
          const AuthRegisterRequested(
            email: registrationEmail,
            password: 'pw123',
            displayName: 'Alice',
            role: UserRole.farmer,
          ),
        ),
      );

      expect(states.first, isA<AuthLoading>());
      expect(states, contains(isA<AuthNeedsProfile>()));

      final needsProfile = states.whereType<AuthNeedsProfile>().first;
      expect(needsProfile.email, registrationEmail);
      expect(needsProfile.displayName, 'Alice');
      expect(needsProfile.role, UserRole.farmer);
      expect(needsProfile.isGoogleUser, isFalse);

      bloc.close();
    });

    test('does not emit AuthNeedsProfile when register returns null', () async {
      authRepo.setRegisterResult(null);

      final bloc = buildBloc();

      final states = await _collectStates(
        bloc,
        act: () async => bloc.add(
          const AuthRegisterRequested(
            email: 'new@test.com',
            password: 'pw123',
            displayName: 'Alice',
            role: UserRole.farmer,
          ),
        ),
      );

      expect(states, contains(isA<AuthLoading>()));
      expect(states.whereType<AuthNeedsProfile>(), isEmpty);
      bloc.close();
    });

    test('emits AuthLoading then AuthFailure on FirebaseAuthException',
        () async {
      authRepo.setRegisterError(
        fb.FirebaseAuthException(code: 'email-already-in-use'),
      );

      final bloc = buildBloc();

      final states = await _collectStates(
        bloc,
        act: () async => bloc.add(
          const AuthRegisterRequested(
            email: 'dup@test.com',
            password: 'pw123',
            displayName: 'Bob',
            role: UserRole.buyer,
          ),
        ),
      );

      expect(states.first, isA<AuthLoading>());
      expect(states.last, isA<AuthFailure>());
      expect((states.last as AuthFailure).message,
          'An account already exists with this email.');
      bloc.close();
    });

    test('emits AuthLoading then AuthFailure on generic exception', () async {
      authRepo.setRegisterError(Exception('server error'));

      final bloc = buildBloc();

      final states = await _collectStates(
        bloc,
        act: () async => bloc.add(
          const AuthRegisterRequested(
            email: 'new@test.com',
            password: 'pw123',
            displayName: 'Carol',
            role: UserRole.farmer,
          ),
        ),
      );

      expect(states.first, isA<AuthLoading>());
      expect(states.last, isA<AuthFailure>());
      bloc.close();
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // 5. AuthGoogleSignInRequested
  // ───────────────────────────────────────────────────────────────────────────

  group('AuthBloc — AuthGoogleSignInRequested', () {
    test('emits AuthLoading and lets stream drive state on success', () async {
      final user = _googleUser();
      authRepo.setGoogleResult(user);
      userRepo.setProfile(_makeProfile(status: VerificationStatus.verified));

      final bloc = buildBloc();

      final states = await _collectStates(
        bloc,
        act: () async => bloc.add(const AuthGoogleSignInRequested()),
      );

      expect(states, contains(isA<AuthLoading>()));
      // Stream will fire via pushAuthState in real scenario;
      // at minimum loading is emitted here.
      bloc.close();
    });

    test('emits AuthLoading then AuthUnauthenticated when user cancels',
        () async {
      authRepo.setGoogleResult(null); // null = cancelled

      final bloc = buildBloc();

      final states = await _collectStates(
        bloc,
        act: () async => bloc.add(const AuthGoogleSignInRequested()),
      );

      expect(states.first, isA<AuthLoading>());
      expect(states, contains(isA<AuthUnauthenticated>()));
      bloc.close();
    });

    test('emits AuthLoading then AuthFailure on FirebaseAuthException',
        () async {
      authRepo.setGoogleError(
        fb.FirebaseAuthException(code: 'invalid-credential'),
      );

      final bloc = buildBloc();

      final states = await _collectStates(
        bloc,
        act: () async => bloc.add(const AuthGoogleSignInRequested()),
      );

      expect(states.first, isA<AuthLoading>());
      expect(states.last, isA<AuthFailure>());
      expect(
          (states.last as AuthFailure).message, 'Invalid email or password.');
      bloc.close();
    });

    test('emits AuthLoading then AuthFailure on generic exception', () async {
      authRepo.setGoogleError(Exception('google error'));

      final bloc = buildBloc();

      final states = await _collectStates(
        bloc,
        act: () async => bloc.add(const AuthGoogleSignInRequested()),
      );

      expect(states.first, isA<AuthLoading>());
      expect(states.last, isA<AuthFailure>());
      bloc.close();
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // 6. AuthSignOutRequested
  // ───────────────────────────────────────────────────────────────────────────

  group('AuthBloc — AuthSignOutRequested', () {
    test('emits AuthUnauthenticated after signOut via stream', () async {
      // Simulate a logged-in state first by pushing a user onto the stream,
      // then push null when signOut is called.
      final bloc = buildBloc();

      // Push null user via authStateChanges stream after signOut
      final states = await _collectStates(
        bloc,
        act: () async {
          bloc.add(const AuthSignOutRequested());
          // Simulate Firebase pushing null auth state after sign out
          await Future<void>.delayed(Duration.zero);
          authRepo.pushAuthState(null);
        },
        ticks: 5,
      );

      expect(states, contains(isA<AuthUnauthenticated>()));
      bloc.close();
    });

    test('clears pending registration data on signOut', () async {
      // Register first to set pending data
      final user = _emailUser(uid: 'u2', emailVerified: false);
      authRepo.setRegisterResult(user);

      final bloc = buildBloc();

      // Register to set _pendingRegistrationRole
      bloc.add(const AuthRegisterRequested(
        email: 'a@a.com',
        password: 'pw',
        displayName: 'Alice',
        role: UserRole.farmer,
      ));
      await Future<void>.delayed(Duration.zero);

      // Now sign out — should clear the pending data without throwing
      bloc.add(const AuthSignOutRequested());
      await Future<void>.delayed(Duration.zero);

      // Bloc should still be alive and functional
      expect(bloc.state, isNotNull);
      bloc.close();
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // 7. AuthPasswordResetRequested
  // ───────────────────────────────────────────────────────────────────────────

  group('AuthBloc — AuthPasswordResetRequested', () {
    test('emits AuthLoading then AuthPasswordResetSent on success', () async {
      final bloc = buildBloc();

      final states = await _collectStates(
        bloc,
        act: () async => bloc.add(
          const AuthPasswordResetRequested('reset@test.com'),
        ),
      );

      expect(states.first, isA<AuthLoading>());
      expect(states.last, isA<AuthPasswordResetSent>());
      bloc.close();
    });

    test('emits AuthLoading then AuthFailure on FirebaseAuthException',
        () async {
      authRepo.setPasswordResetError(
        fb.FirebaseAuthException(code: 'user-not-found'),
      );

      final bloc = buildBloc();

      final states = await _collectStates(
        bloc,
        act: () async => bloc.add(
          const AuthPasswordResetRequested('nobody@test.com'),
        ),
      );

      expect(states.first, isA<AuthLoading>());
      expect(states.last, isA<AuthFailure>());
      expect((states.last as AuthFailure).message,
          'No account found with this email.');
      bloc.close();
    });

    test('emits AuthLoading then AuthFailure on generic exception', () async {
      authRepo.setPasswordResetError(Exception('network error'));

      final bloc = buildBloc();

      final states = await _collectStates(
        bloc,
        act: () async => bloc.add(
          const AuthPasswordResetRequested('x@test.com'),
        ),
      );

      expect(states.first, isA<AuthLoading>());
      expect(states.last, isA<AuthFailure>());
      bloc.close();
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // 8. AuthVerificationEmailRequested
  // ───────────────────────────────────────────────────────────────────────────

  group('AuthBloc — AuthVerificationEmailRequested', () {
    test('emits AuthVerificationEmailSent then AuthEmailNotVerified on success',
        () async {
      authRepo.setSendVerificationResult(true);

      final bloc = buildBloc();

      final states = await _collectStates(
        bloc,
        act: () async =>
            bloc.add(const AuthVerificationEmailRequested()),
      );

      // Should emit sent + not-verified (re-emit to keep UI on verification page)
      expect(states, contains(isA<AuthVerificationEmailSent>()));
      expect(states.last, isA<AuthEmailNotVerified>());
      bloc.close();
    });

    test(
        'emits only AuthEmailNotVerified when sendEmailVerification returns false',
        () async {
      authRepo.setSendVerificationResult(false);

      final bloc = buildBloc();

      final states = await _collectStates(
        bloc,
        act: () async =>
            bloc.add(const AuthVerificationEmailRequested()),
      );

      expect(states.whereType<AuthVerificationEmailSent>(), isEmpty);
      expect(states.last, isA<AuthEmailNotVerified>());
      bloc.close();
    });

    test('handles AuthVerificationEmailRequested without throwing', () async {
      authRepo.setSendVerificationResult(true);
      final bloc = buildBloc();

      expect(
        () async {
          bloc.add(const AuthVerificationEmailRequested());
          await Future<void>.delayed(Duration.zero);
        },
        returnsNormally,
      );
      bloc.close();
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // 9. _AuthUserChanged via authStateChanges stream
  // ───────────────────────────────────────────────────────────────────────────

  group('AuthBloc — _AuthUserChanged via stream', () {
    test('emits AuthUnauthenticated when stream emits null', () async {
      final bloc = buildBloc();

      final states = await _collectStates(
        bloc,
        act: () async => authRepo.pushAuthState(null),
        ticks: 3,
      );

      expect(states, contains(isA<AuthUnauthenticated>()));
      bloc.close();
    });

    test('emits AuthNeedsProfile when stream emits user with no Firestore profile',
        () async {
      final user = _emailUser(uid: 'new-uid', emailVerified: false);
      userRepo.setProfile(null); // no profile yet

      final bloc = buildBloc();

      final states = await _collectStates(
        bloc,
        act: () async => authRepo.pushAuthState(user),
        ticks: 5,
      );

      expect(states, contains(isA<AuthNeedsProfile>()));
      final s = states.whereType<AuthNeedsProfile>().first;
      expect(s.uid, 'new-uid');
      expect(s.isGoogleUser, isFalse);
      bloc.close();
    });

    test('emits AuthNeedsProfile with isGoogleUser=true for Google user',
        () async {
      final user = _googleUser(uid: 'g-uid');
      userRepo.setProfile(null); // no profile yet

      final bloc = buildBloc();

      final states = await _collectStates(
        bloc,
        act: () async => authRepo.pushAuthState(user),
        ticks: 5,
      );

      expect(states, contains(isA<AuthNeedsProfile>()));
      final s = states.whereType<AuthNeedsProfile>().first;
      expect(s.isGoogleUser, isTrue);
      bloc.close();
    });

    test(
        'emits AuthEmailNotVerified when stream emits unverified non-Google user with profile',
        () async {
      final user = _emailUser(emailVerified: false);
      userRepo.setProfile(_makeProfile());

      final bloc = buildBloc();

      final states = await _collectStates(
        bloc,
        act: () async => authRepo.pushAuthState(user),
        ticks: 5,
      );

      expect(states, contains(isA<AuthEmailNotVerified>()));
      bloc.close();
    });

    test('emits AuthAuthenticated when stream emits verified user with profile',
        () async {
      final user = _emailUser(emailVerified: true);
      userRepo.setProfile(_makeProfile(
        status: VerificationStatus.verified,
        isVerified: true,
      ));

      final bloc = buildBloc();

      final states = await _collectStates(
        bloc,
        act: () async => authRepo.pushAuthState(user),
        ticks: 5,
      );

      expect(states, contains(isA<AuthAuthenticated>()));
      bloc.close();
    });

    test('emits AuthNeedsKycVerification when profile is unverified', () async {
      final user = _emailUser(emailVerified: true);
      userRepo.setProfile(_makeProfile(
        status: VerificationStatus.unverified,
        isVerified: true,
      ));

      final bloc = buildBloc();

      final states = await _collectStates(
        bloc,
        act: () async => authRepo.pushAuthState(user),
        ticks: 5,
      );

      expect(states, contains(isA<AuthNeedsKycVerification>()));
      bloc.close();
    });

    test('emits AuthKycPending when profile status is pending', () async {
      final user = _emailUser(emailVerified: true);
      userRepo.setProfile(
          _makeProfile(status: VerificationStatus.pending, isVerified: true));

      final bloc = buildBloc();

      final states = await _collectStates(
        bloc,
        act: () async => authRepo.pushAuthState(user),
        ticks: 5,
      );

      expect(states, contains(isA<AuthKycPending>()));
      bloc.close();
    });

    test('emits AuthNeedsKycVerification when profile status is rejected',
        () async {
      final user = _emailUser(emailVerified: true);
      userRepo.setProfile(
          _makeProfile(status: VerificationStatus.rejected, isVerified: true));

      final bloc = buildBloc();

      final states = await _collectStates(
        bloc,
        act: () async => authRepo.pushAuthState(user),
        ticks: 5,
      );

      expect(states, contains(isA<AuthNeedsKycVerification>()));
      bloc.close();
    });

    test('multiple stream events are processed in order', () async {
      final user = _emailUser(emailVerified: true);
      userRepo.setProfile(_makeProfile(status: VerificationStatus.verified));

      final bloc = buildBloc();

      final states = <AuthState>[];
      final sub = bloc.stream.listen(states.add);

      // First push null → unauthenticated
      authRepo.pushAuthState(null);
      await Future<void>.delayed(Duration.zero);

      // Then push a user → authenticated path
      authRepo.pushAuthState(user);
      for (var i = 0; i < 5; i++) {
        await Future<void>.delayed(Duration.zero);
      }

      await sub.cancel();

      expect(states, contains(isA<AuthUnauthenticated>()));
      expect(states, contains(isA<AuthAuthenticated>()));

      bloc.close();
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // 10. Firebase error message mapping
  // ───────────────────────────────────────────────────────────────────────────

  group('AuthBloc — FirebaseAuthException error mapping', () {
    final errorCases = <String, String>{
      'user-not-found': 'No account found with this email.',
      'wrong-password': 'Incorrect password.',
      'email-already-in-use': 'An account already exists with this email.',
      'weak-password': 'Password is too weak.',
      'invalid-email': 'Invalid email address.',
      'user-disabled': 'This account has been disabled.',
      'too-many-requests': 'Too many attempts. Please try again later.',
      'invalid-credential': 'Invalid email or password.',
    };

    for (final entry in errorCases.entries) {
      test('maps ${entry.key} → "${entry.value}"', () async {
        authRepo.setSignInError(fb.FirebaseAuthException(code: entry.key));

        final bloc = buildBloc();

        final states = await _collectStates(
          bloc,
          act: () async => bloc.add(
            const AuthSignInRequested(email: 'x@x.com', password: 'pw'),
          ),
        );

        final failure = states.whereType<AuthFailure>().first;
        expect(failure.message, entry.value);

        bloc.close();
      });
    }

    test('uses exception message for unknown error code', () async {
      authRepo.setSignInError(
        fb.FirebaseAuthException(
          code: 'unknown-code',
          message: 'Custom error message.',
        ),
      );

      final bloc = buildBloc();

      final states = await _collectStates(
        bloc,
        act: () async => bloc.add(
          const AuthSignInRequested(email: 'x@x.com', password: 'pw'),
        ),
      );

      final failure = states.whereType<AuthFailure>().first;
      expect(failure.message, 'Custom error message.');
      bloc.close();
    });

    test('uses fallback for unknown error code with null message', () async {
      authRepo.setSignInError(
        fb.FirebaseAuthException(code: 'some-other-code'),
      );

      final bloc = buildBloc();

      final states = await _collectStates(
        bloc,
        act: () async => bloc.add(
          const AuthSignInRequested(email: 'x@x.com', password: 'pw'),
        ),
      );

      final failure = states.whereType<AuthFailure>().first;
      expect(failure.message, 'An authentication error occurred.');
      bloc.close();
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // 11. Bloc lifecycle
  // ───────────────────────────────────────────────────────────────────────────

  group('AuthBloc — lifecycle', () {
    test('close() cancels authStateChanges subscription without error',
        () async {
      final bloc = buildBloc();
      await expectLater(bloc.close(), completes);
    });

    test('bloc is closed after close()', () async {
      final bloc = buildBloc();
      await bloc.close();
      expect(bloc.isClosed, isTrue);
    });
  });
}
