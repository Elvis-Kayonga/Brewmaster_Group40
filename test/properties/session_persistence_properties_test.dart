// Feature: brewmaster-marketplace, Property 3: Session State Persistence
// **Validates: Requirements 1.7**
//
// Property: For any authenticated user, logging in then restarting the app
// should maintain the authentication session without requiring re-login.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:faker/faker.dart';

import 'package:brewmaster/data/repositories/firebase_auth_repository.dart';

// --- Manual fake implementations ---

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

/// A fake FirebaseAuth that simulates session persistence.
/// After sign-in, currentUser remains set (simulating Firebase's native
/// session persistence). A new FirebaseAuthRepository using the same
/// FakeFirebaseAuth instance will see the persisted session.
class FakeFirebaseAuth implements FirebaseAuth {
  FakeUser? _currentUser;
  final StreamController<User?> _authStateController =
      StreamController<User?>.broadcast();

  @override
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    _currentUser =
        FakeUser(uid: 'uid_signup_${email.hashCode}', email: email);
    _authStateController.add(_currentUser);
    return FakeUserCredential(_currentUser!);
  }

  @override
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    _currentUser =
        FakeUser(uid: 'uid_signin_${email.hashCode}', email: email);
    _authStateController.add(_currentUser);
    return FakeUserCredential(_currentUser!);
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    _authStateController.add(null);
  }

  @override
  User? get currentUser => _currentUser;

  @override
  Stream<User?> authStateChanges() => _authStateController.stream;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  void dispose() {
    _authStateController.close();
  }
}

// --- Property Tests ---

void main() {
  final faker = Faker();

  group('Property 3: Session State Persistence', () {
    late FakeFirebaseAuth fakeAuth;

    setUp(() {
      fakeAuth = FakeFirebaseAuth();
    });

    tearDown(() {
      fakeAuth.dispose();
    });

    // Property 3a: After sign-in, currentUser is non-null on the repository
    test(
      'after sign-in, currentUser persists on FirebaseAuthRepository (100 iterations)',
      () async {
        final authRepo = FirebaseAuthRepository(auth: fakeAuth);

        for (int i = 0; i < 100; i++) {
          final email = faker.internet.email();
          final password = faker.internet.password(
            length: 8 + faker.randomGenerator.integer(20),
          );

          await authRepo.signIn(email, password);

          expect(
            authRepo.currentUser,
            isNotNull,
            reason:
                'currentUser should be non-null after sign-in (iteration $i, email=$email)',
          );
          expect(
            authRepo.currentUser!.email,
            equals(email),
            reason:
                'currentUser email should match sign-in email (iteration $i)',
          );
        }
      },
    );

    // Property 3b: A new repository using the same FirebaseAuth instance
    // restores the session (simulating app restart with persisted auth)
    test(
      'new FirebaseAuthRepository restores session from same FirebaseAuth (100 iterations)',
      () async {
        final authRepo = FirebaseAuthRepository(auth: fakeAuth);

        for (int i = 0; i < 100; i++) {
          final email = faker.internet.email();
          final password = faker.internet.password(
            length: 8 + faker.randomGenerator.integer(20),
          );

          // Sign in via the repository
          await authRepo.signIn(email, password);

          // Simulate app restart: create a new repository with the same
          // underlying FirebaseAuth (which still holds the session)
          final restartRepo = FirebaseAuthRepository(auth: fakeAuth);

          expect(
            restartRepo.currentUser,
            isNotNull,
            reason:
                'New repository should restore session (iteration $i)',
          );
          expect(
            restartRepo.currentUser!.email,
            equals(email),
            reason:
                'Restored session email should match original sign-in (iteration $i)',
          );
        }
      },
    );

    // Property 3c: authStateChanges stream emits the authenticated user
    test(
      'authStateChanges emits authenticated user after sign-in (100 iterations)',
      () async {
        final authRepo = FirebaseAuthRepository(auth: fakeAuth);

        for (int i = 0; i < 100; i++) {
          final email = faker.internet.email();
          final password = faker.internet.password(
            length: 8 + faker.randomGenerator.integer(20),
          );

          // Listen for the next auth state change before signing in
          final futureUser = authRepo.authStateChanges.first;

          await authRepo.signIn(email, password);

          final emittedUser = await futureUser;

          expect(
            emittedUser,
            isNotNull,
            reason:
                'authStateChanges should emit a user after sign-in (iteration $i)',
          );
          expect(
            emittedUser!.email,
            equals(email),
            reason:
                'Emitted user email should match sign-in email (iteration $i)',
          );
        }
      },
    );

    // Property 3d: Session persists for both sign-up and sign-in methods
    test(
      'session persists for both register and sign-in methods (100 iterations)',
      () async {
        for (int i = 0; i < 100; i++) {
          final email = faker.internet.email();
          final password = faker.internet.password(
            length: 8 + faker.randomGenerator.integer(20),
          );

          final authRepo = FirebaseAuthRepository(auth: fakeAuth);

          // Alternate between sign-up and sign-in
          if (i.isEven) {
            await authRepo.register(email, password);
          } else {
            await authRepo.signIn(email, password);
          }

          // Verify session is set on the underlying auth
          expect(
            fakeAuth.currentUser,
            isNotNull,
            reason:
                'FirebaseAuth.currentUser should persist after auth (iteration $i)',
          );

          // Simulate restart: new repository picks up the session
          final restartRepo = FirebaseAuthRepository(auth: fakeAuth);

          expect(
            restartRepo.currentUser,
            isNotNull,
            reason:
                'Session should persist across repository re-creation (iteration $i)',
          );
          expect(
            restartRepo.currentUser!.email,
            equals(email),
            reason: 'Persisted session email should match (iteration $i)',
          );
        }
      },
    );
  });
}
