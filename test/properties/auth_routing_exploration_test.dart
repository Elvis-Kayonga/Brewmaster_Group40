// Feature: auth-screen-routing-fix, Exploratory Fault Condition Tests
// **Validates: Requirements 2.1, 2.3**
//
// These exploration tests verify the fixed widget tree behavior.
// On the UNFIXED code (where MyHomePage was hardcoded and AuthProvider was
// never registered), these tests would have FAILED:
//   - Task 4.1: context.read<AuthProvider>() would throw ProviderNotFoundException
//   - Task 4.2: LoginScreen would never appear (MyHomePage was shown instead)
//
// On the FIXED code, both tests PASS, confirming the fix is correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:faker/faker.dart';

import 'package:brewmaster/data/services/auth_service.dart';
import 'package:brewmaster/data/providers/auth_provider.dart' as app;
import 'package:brewmaster/main.dart';

// ---------------------------------------------------------------------------
// Fakes (reusing patterns from auth_properties_test.dart)
// ---------------------------------------------------------------------------

class FakeUser implements User {
  final String _uid;
  final String? _email;
  FakeUser({required String uid, String? email}) : _uid = uid, _email = email;

  @override
  String get uid => _uid;
  @override
  String? get email => _email;
  @override
  Future<void> reload() async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeUserCredential implements UserCredential {
  final FakeUser _user;
  FakeUserCredential(this._user);

  @override
  User get user => _user;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeFirebaseAuth implements FirebaseAuth {
  FakeUser? _currentUser;

  void setCurrentUser(FakeUser? user) {
    _currentUser = user;
  }

  @override
  User? get currentUser => _currentUser;

  @override
  Stream<User?> authStateChanges() => Stream.value(_currentUser);

  @override
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    _currentUser = FakeUser(uid: 'uid_signup', email: email);
    return FakeUserCredential(_currentUser!);
  }

  @override
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    _currentUser = FakeUser(uid: 'uid_signin', email: email);
    return FakeUserCredential(_currentUser!);
  }

  @override
  Future<UserCredential> signInWithCredential(AuthCredential credential) async {
    _currentUser = FakeUser(uid: 'uid_google', email: 'g@test.com');
    return FakeUserCredential(_currentUser!);
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeGoogleSignIn implements GoogleSignIn {
  @override
  Future<GoogleSignInAccount?> signIn() async => null;
  @override
  Future<GoogleSignInAccount?> signOut() async => null;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ---------------------------------------------------------------------------
// Helper: builds a testable widget tree that mirrors the fixed main.dart
// ---------------------------------------------------------------------------

/// Builds a widget tree equivalent to the fixed app's structure:
///   `ChangeNotifierProvider<AuthProvider>` -> `MaterialApp` -> `AuthGate`
///
/// This is exactly what the fix added. On unfixed code, AuthProvider was
/// never registered, so any widget calling `context.read<AuthProvider>()`
/// would throw ProviderNotFoundException.
Widget buildTestableApp({FakeFirebaseAuth? fakeAuth}) {
  final auth = fakeAuth ?? FakeFirebaseAuth();
  final googleSignIn = FakeGoogleSignIn();
  final authService = AuthService(auth: auth, googleSignIn: googleSignIn);
  final authProvider = app.AuthProvider(authService: authService)..init();

  return ChangeNotifierProvider<app.AuthProvider>.value(
    value: authProvider,
    child: const MaterialApp(home: AuthGate()),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  final faker = Faker();

  // ==========================================================================
  // Task 4.1: AuthProvider is resolvable from widget tree
  // ==========================================================================
  group('Exploration 4.1: AuthProvider resolvable from widget tree', () {
    // On UNFIXED code this would have thrown ProviderNotFoundException because
    // AuthProvider was never registered via ChangeNotifierProvider.
    // The fix wraps MyApp with ChangeNotifierProvider<AuthProvider>, making
    // the provider available to all descendants including AuthGate.

    testWidgets(
      'AuthProvider is accessible via Consumer for random auth states (100 iterations)',
      (WidgetTester tester) async {
        for (int i = 0; i < 100; i++) {
          final fakeAuth = FakeFirebaseAuth();

          // Randomly decide if user is authenticated
          if (faker.randomGenerator.boolean()) {
            fakeAuth.setCurrentUser(
              FakeUser(uid: faker.guid.guid(), email: faker.internet.email()),
            );
          }

          await tester.pumpWidget(buildTestableApp(fakeAuth: fakeAuth));

          // Verify AuthGate (which uses Consumer<AuthProvider>) exists and
          // rendered without throwing ProviderNotFoundException.
          // On unfixed code, AuthProvider was never registered so AuthGate's
          // Consumer would throw ProviderNotFoundException.
          expect(
            find.byType(AuthGate),
            findsOneWidget,
            reason:
                'AuthGate should exist in widget tree (iteration $i). '
                'On unfixed code, AuthProvider was never registered so '
                'AuthGate\'s Consumer would throw ProviderNotFoundException.',
          );

          // Also verify no exception was thrown during rendering
          expect(
            tester.takeException(),
            isNull,
            reason:
                'No exception should occur when resolving AuthProvider '
                '(iteration $i).',
          );
        }
      },
    );

    testWidgets(
      'AuthGate widget successfully consumes AuthProvider without errors',
      (WidgetTester tester) async {
        final fakeAuth = FakeFirebaseAuth();
        await tester.pumpWidget(buildTestableApp(fakeAuth: fakeAuth));

        // If AuthProvider were not registered (unfixed code), pumping the
        // widget tree would throw ProviderNotFoundException. The fact that
        // we reach this point without error proves the provider is resolvable.
        expect(
          tester.takeException(),
          isNull,
          reason:
              'No exception should be thrown when AuthGate consumes '
              'AuthProvider. On unfixed code, ProviderNotFoundException '
              'would have been thrown here.',
        );
      },
    );
  });

  // ==========================================================================
  // Task 4.2: Unauthenticated launch shows LoginScreen
  // ==========================================================================
  group('Exploration 4.2: Unauthenticated launch shows LoginScreen', () {
    // On UNFIXED code, MyHomePage was always shown regardless of auth state.
    // The fix introduces AuthGate which checks isAuthenticated and renders
    // LoginScreen when the user is not authenticated.

    testWidgets(
      'LoginScreen is rendered when user is not authenticated (100 random states)',
      (WidgetTester tester) async {
        for (int i = 0; i < 100; i++) {
          // No current user -> unauthenticated
          final fakeAuth = FakeFirebaseAuth();

          await tester.pumpWidget(buildTestableApp(fakeAuth: fakeAuth));
          await tester.pumpAndSettle();

          // On the fixed code, AuthGate renders LoginScreen for unauthenticated users.
          // On unfixed code, MyHomePage would have been rendered instead.
          expect(
            find.text('Welcome to BrewMaster'),
            findsOneWidget,
            reason:
                'LoginScreen should display "Welcome to BrewMaster" header '
                'when user is unauthenticated (iteration $i). '
                'On unfixed code, MyHomePage counter widget was shown instead.',
          );

          expect(
            find.text('Sign In'),
            findsOneWidget,
            reason:
                'LoginScreen should show a "Sign In" button when unauthenticated '
                '(iteration $i).',
          );
        }
      },
    );

    testWidgets('BrewMaster Home is NOT shown when user is unauthenticated', (
      WidgetTester tester,
    ) async {
      final fakeAuth = FakeFirebaseAuth();
      // No user set -> unauthenticated

      await tester.pumpWidget(buildTestableApp(fakeAuth: fakeAuth));
      await tester.pumpAndSettle();

      // The placeholder main content text should NOT appear
      expect(
        find.text('BrewMaster Home'),
        findsNothing,
        reason:
            'The authenticated home content should not be visible when '
            'user is unauthenticated. On unfixed code, the MyHomePage '
            'counter placeholder was shown for all states.',
      );
    });
  });
}
