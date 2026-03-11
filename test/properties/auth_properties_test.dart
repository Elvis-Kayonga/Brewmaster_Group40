// Feature: brewmaster-marketplace, Property 1: Authentication Method Support
// **Validates: Requirements 1.2**
//
// Property: For any user registration attempt, the system should successfully
// create an account using either email/password or Google sign-in authentication methods.

import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:faker/faker.dart';

import 'package:brewmaster/data/repositories/firebase_auth_repository.dart';

// --- Manual mock implementations for Firebase Auth (platform-dependent) ---

/// Tracks calls made to FirebaseAuth methods for verification.
class AuthCallLog {
  final List<Map<String, String>> signUpCalls = [];
  final List<Map<String, String>> signInCalls = [];
  int signInWithCredentialCalls = 0;
  int signOutCalls = 0;
}

/// A fake User that returns a predictable uid and email.
class FakeUser implements User {
  final String _uid;
  final String? _email;

  FakeUser({required String uid, String? email})
      : _uid = uid,
        _email = email;

  @override
  String get uid => _uid;

  @override
  String? get email => _email;

  @override
  Future<void> reload() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A fake UserCredential that wraps a FakeUser.
class FakeUserCredential implements UserCredential {
  final FakeUser _user;

  FakeUserCredential(this._user);

  @override
  User get user => _user;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A fake FirebaseAuth that records calls and returns predictable results.
class FakeFirebaseAuth implements FirebaseAuth {
  final AuthCallLog callLog = AuthCallLog();
  FakeUser? _currentUser;
  bool shouldFail = false;

  @override
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    callLog.signUpCalls.add({'email': email, 'password': password});
    if (shouldFail) {
      throw FirebaseAuthException(
        code: 'email-already-in-use',
        message: 'Test error',
      );
    }
    _currentUser = FakeUser(
      uid: 'uid_${callLog.signUpCalls.length}',
      email: email,
    );
    return FakeUserCredential(_currentUser!);
  }

  @override
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    callLog.signInCalls.add({'email': email, 'password': password});
    if (shouldFail) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'Test error',
      );
    }
    _currentUser = FakeUser(
      uid: 'uid_signin_${callLog.signInCalls.length}',
      email: email,
    );
    return FakeUserCredential(_currentUser!);
  }

  @override
  Future<UserCredential> signInWithCredential(
      AuthCredential credential) async {
    callLog.signInWithCredentialCalls++;
    if (shouldFail) {
      throw FirebaseAuthException(
        code: 'invalid-credential',
        message: 'Test error',
      );
    }
    _currentUser = FakeUser(
      uid: 'uid_google_${callLog.signInWithCredentialCalls}',
      email: 'google@test.com',
    );
    return FakeUserCredential(_currentUser!);
  }

  @override
  Future<void> signOut() async {
    callLog.signOutCalls++;
    _currentUser = null;
  }

  @override
  User? get currentUser => _currentUser;

  @override
  Stream<User?> authStateChanges() => Stream.value(_currentUser);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Fake GoogleSignInAuthentication with token values.
class FakeGoogleSignInAuthentication implements GoogleSignInAuthentication {
  @override
  String? get accessToken => 'fake_access_token';

  @override
  String? get idToken => 'fake_id_token';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Fake GoogleSignInAccount that returns fake authentication.
class FakeGoogleSignInAccount implements GoogleSignInAccount {
  @override
  Future<GoogleSignInAuthentication> get authentication async =>
      FakeGoogleSignInAuthentication();

  @override
  String get email => 'google_user@gmail.com';

  @override
  String get id => 'google_id_123';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Fake GoogleSignIn that can simulate success or cancellation.
class FakeGoogleSignIn implements GoogleSignIn {
  bool simulateCancel = false;
  int signInCalls = 0;
  int signOutCalls = 0;

  @override
  Future<GoogleSignInAccount?> signIn() async {
    signInCalls++;
    if (simulateCancel) return null;
    return FakeGoogleSignInAccount();
  }

  @override
  Future<GoogleSignInAccount?> signOut() async {
    signOutCalls++;
    return null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// --- Property Tests ---

void main() {
  final faker = Faker();

  group('Property 1: Authentication Method Support', () {
    late FakeFirebaseAuth fakeAuth;
    late FakeGoogleSignIn fakeGoogleSignIn;
    late FirebaseAuthRepository authRepo;

    setUp(() {
      fakeAuth = FakeFirebaseAuth();
      fakeGoogleSignIn = FakeGoogleSignIn();
      authRepo = FirebaseAuthRepository(
          auth: fakeAuth, googleSignIn: fakeGoogleSignIn);
    });

    // Property 1a: Email/password sign-up returns a non-null user for any valid input
    test(
      'email/password sign-up succeeds for any valid email and password (100 iterations)',
      () async {
        for (int i = 0; i < 100; i++) {
          final email = faker.internet.email();
          final password = faker.internet.password(
            length: 8 + faker.randomGenerator.integer(20),
          );

          final user = await authRepo.register(email, password);

          expect(
            user,
            isNotNull,
            reason:
                'Sign-up should return a user for email=$email (iteration $i)',
          );
          expect(
            user!.email,
            equals(email),
            reason:
                'Returned user email should match the registration email',
          );
        }

        expect(
          fakeAuth.callLog.signUpCalls.length,
          equals(100),
          reason:
              'createUserWithEmailAndPassword should be called exactly 100 times',
        );
      },
    );

    // Property 1b: Email/password sign-in returns a non-null user for any valid input
    test(
      'email/password sign-in succeeds for any valid email and password (100 iterations)',
      () async {
        for (int i = 0; i < 100; i++) {
          final email = faker.internet.email();
          final password = faker.internet.password(
            length: 8 + faker.randomGenerator.integer(20),
          );

          final user = await authRepo.signIn(email, password);

          expect(
            user,
            isNotNull,
            reason:
                'Sign-in should return a user for email=$email (iteration $i)',
          );
          expect(
            user!.email,
            equals(email),
            reason: 'Returned user email should match the sign-in email',
          );
        }

        expect(
          fakeAuth.callLog.signInCalls.length,
          equals(100),
          reason:
              'signInWithEmailAndPassword should be called exactly 100 times',
        );
      },
    );

    // Property 1c: Google sign-in returns a non-null user when not cancelled
    test(
      'Google sign-in succeeds and returns a user (100 iterations)',
      () async {
        for (int i = 0; i < 100; i++) {
          final user = await authRepo.signInWithGoogle();

          expect(
            user,
            isNotNull,
            reason: 'Google sign-in should return a user (iteration $i)',
          );
        }

        expect(
          fakeGoogleSignIn.signInCalls,
          equals(100),
          reason:
              'GoogleSignIn.signIn() should be called exactly 100 times',
        );
        expect(
          fakeAuth.callLog.signInWithCredentialCalls,
          equals(100),
          reason:
              'signInWithCredential should be called exactly 100 times',
        );
      },
    );

    // Property 1d: Both auth methods produce a user with a non-empty uid
    test(
      'all auth methods produce a user with a non-empty uid (100 iterations)',
      () async {
        for (int i = 0; i < 100; i++) {
          final email = faker.internet.email();
          final password = faker.internet.password(length: 10);

          // Alternate between the three auth methods
          final User? user;
          switch (i % 3) {
            case 0:
              user = await authRepo.register(email, password);
              break;
            case 1:
              user = await authRepo.signIn(email, password);
              break;
            default:
              user = await authRepo.signInWithGoogle();
              break;
          }

          expect(
            user,
            isNotNull,
            reason: 'Auth method should return a user (iteration $i)',
          );
          expect(
            user!.uid,
            isNotEmpty,
            reason: 'User uid should be non-empty (iteration $i)',
          );
        }
      },
    );

    // Property 1e: Google sign-in gracefully returns null when user cancels
    test('Google sign-in returns null when user cancels (100 iterations)',
        () async {
      fakeGoogleSignIn.simulateCancel = true;

      for (int i = 0; i < 100; i++) {
        final user = await authRepo.signInWithGoogle();

        expect(
          user,
          isNull,
          reason:
              'Google sign-in should return null when cancelled (iteration $i)',
        );
      }

      // Firebase signInWithCredential should never be called when Google sign-in is cancelled
      expect(
        fakeAuth.callLog.signInWithCredentialCalls,
        equals(0),
        reason:
            'signInWithCredential should not be called when Google sign-in is cancelled',
      );
    });
  });
}
