// Integration tests for auth-screen-routing-fix
// Task 7.1: Full unauthenticated launch → LoginScreen flow
// Task 7.2: Full authenticated launch → main content flow
//
// These are integration-style widget tests that verify the complete launch
// flow through ChangeNotifierProvider → MyApp → AuthGate → correct screen.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';

import 'package:brewmaster/data/services/auth_service.dart';
import 'package:brewmaster/data/providers/auth_provider.dart' as app;
import 'package:brewmaster/main.dart';
import 'package:brewmaster/presentation/screens/auth/login_screen.dart';

// ---------------------------------------------------------------------------
// Fakes (reused pattern from existing property tests)
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

// ---------------------------------------------------------------------------
// Helper: builds the full app tree (Provider → MyApp → AuthGate)
// ---------------------------------------------------------------------------

Widget buildFullApp({FakeFirebaseAuth? fakeAuth}) {
  final auth = fakeAuth ?? FakeFirebaseAuth();
  final googleSignIn = FakeGoogleSignIn();
  final authService = AuthService(auth: auth, googleSignIn: googleSignIn);
  final authProvider = app.AuthProvider(authService: authService)..init();

  return ChangeNotifierProvider<app.AuthProvider>.value(
    value: authProvider,
    child: const MyApp(),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // ==========================================================================
  // Task 7.1: Unauthenticated launch → LoginScreen flow
  // ==========================================================================
  group('Integration 7.1: Unauthenticated launch shows LoginScreen', () {
    testWidgets('full app launch with no user displays LoginScreen', (
      WidgetTester tester,
    ) async {
      // No user set → unauthenticated
      await tester.pumpWidget(buildFullApp());
      await tester.pumpAndSettle();

      // LoginScreen is rendered
      expect(find.byType(LoginScreen), findsOneWidget);

      // Main content is NOT rendered
      expect(find.text('BrewMaster Home'), findsNothing);
    });

    testWidgets('LoginScreen shows Welcome text and Sign In button', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildFullApp());
      await tester.pumpAndSettle();

      expect(find.text('Welcome to BrewMaster'), findsOneWidget);
      expect(find.text('Sign in to continue'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
    });

    testWidgets('LoginScreen shows Google sign-in and Sign Up options', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildFullApp());
      await tester.pumpAndSettle();

      expect(find.text('Sign in with Google'), findsOneWidget);
      expect(find.text('Sign Up'), findsOneWidget);
      expect(find.text("Don't have an account? "), findsOneWidget);
    });

    testWidgets('LoginScreen shows coffee icon', (WidgetTester tester) async {
      await tester.pumpWidget(buildFullApp());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.coffee), findsOneWidget);
    });

    testWidgets(
      'AuthGate is present in widget tree for unauthenticated launch',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildFullApp());
        await tester.pumpAndSettle();

        expect(find.byType(AuthGate), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });

  // ==========================================================================
  // Task 7.2: Authenticated launch → main content flow
  // ==========================================================================
  group('Integration 7.2: Authenticated launch shows main content', () {
    testWidgets(
      'full app launch with authenticated user displays BrewMaster Home',
      (WidgetTester tester) async {
        final fakeAuth = FakeFirebaseAuth();
        fakeAuth.setCurrentUser(
          FakeUser(uid: 'user-123', email: 'brewer@test.com'),
        );

        await tester.pumpWidget(buildFullApp(fakeAuth: fakeAuth));
        await tester.pumpAndSettle();

        // Main content is rendered
        expect(find.text('BrewMaster Home'), findsOneWidget);

        // LoginScreen is NOT rendered
        expect(find.byType(LoginScreen), findsNothing);
      },
    );

    testWidgets('authenticated launch does not show login UI elements', (
      WidgetTester tester,
    ) async {
      final fakeAuth = FakeFirebaseAuth();
      fakeAuth.setCurrentUser(
        FakeUser(uid: 'user-456', email: 'coffee@test.com'),
      );

      await tester.pumpWidget(buildFullApp(fakeAuth: fakeAuth));
      await tester.pumpAndSettle();

      expect(find.text('Welcome to BrewMaster'), findsNothing);
      expect(find.text('Sign in to continue'), findsNothing);
      expect(find.text('Sign in with Google'), findsNothing);
    });

    testWidgets('AuthGate is present in widget tree for authenticated launch', (
      WidgetTester tester,
    ) async {
      final fakeAuth = FakeFirebaseAuth();
      fakeAuth.setCurrentUser(
        FakeUser(uid: 'user-789', email: 'auth@test.com'),
      );

      await tester.pumpWidget(buildFullApp(fakeAuth: fakeAuth));
      await tester.pumpAndSettle();

      expect(find.byType(AuthGate), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('authenticated launch renders a Scaffold with main content', (
      WidgetTester tester,
    ) async {
      final fakeAuth = FakeFirebaseAuth();
      fakeAuth.setCurrentUser(
        FakeUser(uid: 'user-scaffold', email: 'scaffold@test.com'),
      );

      await tester.pumpWidget(buildFullApp(fakeAuth: fakeAuth));
      await tester.pumpAndSettle();

      // The main content is wrapped in a Scaffold
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.text('BrewMaster Home'), findsOneWidget);
    });
  });
}
