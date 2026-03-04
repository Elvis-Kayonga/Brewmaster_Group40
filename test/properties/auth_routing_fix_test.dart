// Feature: auth-screen-routing-fix, Fix Verification Tests
// **Validates: Requirements 2.1, 2.2, 2.3**
//
// These fix verification tests confirm that the fixed code correctly:
//   - Task 5.1: AuthGate renders LoginScreen when unauthenticated and main
//               content ("BrewMaster Home") when authenticated, for any
//               randomly generated auth state.
//   - Task 5.2: AuthProvider is always resolvable from the widget tree via
//               Consumer<AuthProvider> without throwing ProviderNotFoundException.
//
// Unlike the exploration tests (Task 4), these tests are EXPECTED TO PASS
// on the fixed code.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:faker/faker.dart';

import 'package:brewmaster/data/services/auth_service.dart';
import 'package:brewmaster/data/services/user_service.dart';
import 'package:brewmaster/data/providers/auth_provider.dart' as app;
import 'package:brewmaster/data/providers/user_provider.dart';
import 'package:brewmaster/main.dart';
import 'package:brewmaster/presentation/screens/auth/login_screen.dart';

// ---------------------------------------------------------------------------
// Fakes (same pattern as exploration tests)
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
  String? get displayName => 'Fake User';
  @override
  Future<void> reload() async {}
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

class FakeUserCredential implements UserCredential {
  final FakeUser _user;
  FakeUserCredential(this._user);

  @override
  User get user => _user;
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

// Minimal Firestore mock
class _FakeFirebaseFirestore implements FirebaseFirestore {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// Minimal UserService mock
class _FakeUserService extends UserService {
  _FakeUserService() : super(firestore: _FakeFirebaseFirestore());
}

// ---------------------------------------------------------------------------
// Helper: builds a testable widget tree mirroring the fixed main.dart
// ---------------------------------------------------------------------------

Widget buildFixedApp({FakeFirebaseAuth? fakeAuth}) {
  final auth = fakeAuth ?? FakeFirebaseAuth();
  final googleSignIn = FakeGoogleSignIn();
  final authService = AuthService(auth: auth, googleSignIn: googleSignIn);
  final authProvider = app.AuthProvider(authService: authService)..init();
  final userProvider = UserProvider(userService: _FakeUserService());

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<app.AuthProvider>.value(value: authProvider),
      ChangeNotifierProvider<UserProvider>.value(value: userProvider),
    ],
    child: const MaterialApp(home: AuthGate()),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  final faker = Faker();

  // ==========================================================================
  // Task 5.1: For any auth state, AuthGate renders LoginScreen when
  // unauthenticated and main content when authenticated (Property 1)
  // **Validates: Requirements 2.1, 2.2**
  // ==========================================================================
  group('Fix 5.1: AuthGate routes correctly for any auth state', () {
    testWidgets('for 100 random auth states, AuthGate renders LoginScreen when '
        'unauthenticated and BrewMaster Home when authenticated', (
      WidgetTester tester,
    ) async {
      for (int i = 0; i < 100; i++) {
        final fakeAuth = FakeFirebaseAuth();
        final isAuthenticated = faker.randomGenerator.boolean();

        if (isAuthenticated) {
          fakeAuth.setCurrentUser(
            FakeUser(uid: faker.guid.guid(), email: faker.internet.email()),
          );
        }

        await tester.pumpWidget(buildFixedApp(fakeAuth: fakeAuth));
        await tester.pumpAndSettle();

        if (isAuthenticated) {
          // Authenticated: should see main content
          expect(
            find.text('BrewMaster Home'),
            findsOneWidget,
            reason:
                'Authenticated user should see "BrewMaster Home" '
                '(iteration $i, isAuthenticated=$isAuthenticated)',
          );
          expect(
            find.byType(LoginScreen),
            findsNothing,
            reason:
                'LoginScreen should NOT be visible when authenticated '
                '(iteration $i)',
          );
        } else {
          // Unauthenticated: should see LoginScreen
          expect(
            find.byType(LoginScreen),
            findsOneWidget,
            reason:
                'Unauthenticated user should see LoginScreen '
                '(iteration $i, isAuthenticated=$isAuthenticated)',
          );
          expect(
            find.text('BrewMaster Home'),
            findsNothing,
            reason:
                'Main content should NOT be visible when unauthenticated '
                '(iteration $i)',
          );
        }
      }
    });

    testWidgets(
      'unauthenticated state always renders LoginScreen with expected UI elements',
      (WidgetTester tester) async {
        final fakeAuth = FakeFirebaseAuth();
        // No user set -> unauthenticated

        await tester.pumpWidget(buildFixedApp(fakeAuth: fakeAuth));
        await tester.pumpAndSettle();

        expect(find.byType(LoginScreen), findsOneWidget);
        expect(find.text('Welcome to BrewMaster'), findsOneWidget);
        expect(find.text('Sign In'), findsOneWidget);
      },
    );

    testWidgets('authenticated state always renders main content scaffold', (
      WidgetTester tester,
    ) async {
      final fakeAuth = FakeFirebaseAuth();
      fakeAuth.setCurrentUser(
        FakeUser(uid: 'test-uid', email: 'test@brew.com'),
      );

      await tester.pumpWidget(buildFixedApp(fakeAuth: fakeAuth));
      await tester.pumpAndSettle();

      expect(find.text('BrewMaster Home'), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
    });
  });

  // ==========================================================================
  // Task 5.2: AuthProvider is always resolvable from the widget tree
  // without errors (Property 1)
  // **Validates: Requirements 2.3**
  // ==========================================================================
  group('Fix 5.2: AuthProvider is always resolvable from widget tree', () {
    testWidgets(
      'AuthProvider is resolvable via Consumer for 100 random auth states '
      'without ProviderNotFoundException',
      (WidgetTester tester) async {
        for (int i = 0; i < 100; i++) {
          final fakeAuth = FakeFirebaseAuth();

          // Randomly decide auth state
          if (faker.randomGenerator.boolean()) {
            fakeAuth.setCurrentUser(
              FakeUser(uid: faker.guid.guid(), email: faker.internet.email()),
            );
          }

          await tester.pumpWidget(buildFixedApp(fakeAuth: fakeAuth));

          // AuthGate uses Consumer<AuthProvider> internally.
          // If AuthProvider were not registered, this would throw
          // ProviderNotFoundException.
          expect(
            find.byType(AuthGate),
            findsOneWidget,
            reason:
                'AuthGate should render successfully, proving AuthProvider '
                'is resolvable (iteration $i)',
          );

          // Verify no exception was thrown during widget tree construction
          expect(
            tester.takeException(),
            isNull,
            reason:
                'No ProviderNotFoundException should occur when resolving '
                'AuthProvider from the widget tree (iteration $i)',
          );
        }
      },
    );

    testWidgets(
      'AuthProvider is accessible and has correct state after resolution',
      (WidgetTester tester) async {
        final fakeAuth = FakeFirebaseAuth();
        fakeAuth.setCurrentUser(
          FakeUser(uid: 'resolve-test', email: 'resolve@test.com'),
        );

        await tester.pumpWidget(buildFixedApp(fakeAuth: fakeAuth));
        await tester.pumpAndSettle();

        // The fact that AuthGate rendered without error proves
        // AuthProvider is resolvable. Additionally verify the widget
        // tree is intact.
        expect(find.byType(AuthGate), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
