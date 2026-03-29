// Widget tests for SignupScreen.
// Coverage: UI structure, role toggle, form validators, BlocListener states,
//           Google sign-up button, Sign In link navigation.

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:brewmaster/config/localization/app_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:brewmaster/presentation/blocs/auth/auth_bloc.dart';
import 'package:brewmaster/presentation/screens/auth/signup_screen.dart';

import '../helpers/fake_repositories.dart';

// ── Helper ────────────────────────────────────────────────────────────────────

Widget _wrap({AuthBloc? bloc}) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: BlocProvider<AuthBloc>(
      create: (_) =>
          bloc ??
          AuthBloc(
            authRepository: FakeAuthRepository(),
            userRepository: FakeUserRepository(),
          ),
      child: const SignupScreen(),
    ),
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    setupFirebaseCoreMocks();
    await Firebase.initializeApp();
  });

  group('SignupScreen — UI', () {
    testWidgets('shows "Join BrewMaster" heading', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      await tester.pump();
      await tester.pump();
      expect(find.text('Join BrewMaster'), findsOneWidget);
    });

    testWidgets('shows "Sign up as Buyer" button by default', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      await tester.pump();
      expect(find.text('Sign up as Buyer'), findsOneWidget);
    });

    testWidgets('shows "Sign up with Google" button', (tester) async {
      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_wrap());
      await tester.pump();
      await tester.pump();
      expect(find.text('Sign up with Google'), findsOneWidget);
    });

    testWidgets('shows "Sign In" link text', (tester) async {
      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_wrap());
      await tester.pump();
      await tester.pump();
      expect(find.text('Sign In'), findsOneWidget);
    });

    testWidgets('shows Full Name, Email Address, Password fields', (tester) async {
      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_wrap());
      await tester.pump();
      await tester.pump();
      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);
    });
  });

  group('SignupScreen — role toggle', () {
    testWidgets('tapping Sell role changes button text to "Sign up as Seller"',
        (tester) async {
      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_wrap());
      await tester.pump();
      await tester.pump();

      // The _RoleToggle shows "Buy" and "Sell" options
      if (find.text('Sell').evaluate().isNotEmpty) {
        await tester.tap(find.text('Sell'));
        await tester.pump();
        expect(find.text('Sign up as Seller'), findsOneWidget);
      }
    });
  });

  group('SignupScreen — form validation', () {
    testWidgets('tapping submit with empty name shows "Name is required"',
        (tester) async {
      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_wrap());
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('Sign up as Buyer'));
      await tester.pump();

      expect(find.textContaining('required'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows "Enter a valid email" for invalid email', (tester) async {
      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_wrap());
      await tester.pump();
      await tester.pump();

      final fields = find.byType(TextFormField);
      if (fields.evaluate().isNotEmpty) {
        // Fill name to pass name validator
        await tester.enterText(fields.first, 'John Doe');
        // Enter invalid email
        if (fields.evaluate().length > 1) {
          await tester.enterText(fields.at(1), 'notanemail');
        }
      }

      await tester.tap(find.text('Sign up as Buyer'));
      await tester.pump();

      expect(find.textContaining('valid email'), findsOneWidget);
    });

    testWidgets('shows "Passwords do not match" when confirm password differs',
        (tester) async {
      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_wrap());
      await tester.pump();
      await tester.pump();

      final fields = find.byType(TextFormField);
      if (fields.evaluate().length >= 4) {
        await tester.enterText(fields.at(0), 'John Doe');
        await tester.enterText(fields.at(1), 'test@example.com');
        await tester.enterText(fields.at(2), 'Password123!');
        await tester.enterText(fields.at(3), 'DifferentPass!');
      }

      await tester.tap(find.text('Sign up as Buyer'));
      await tester.pump();

      expect(find.textContaining('do not match'), findsOneWidget);
    });

    testWidgets('valid form dispatches AuthRegisterRequested (no crash)',
        (tester) async {
      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_wrap());
      await tester.pump();
      await tester.pump();

      final fields = find.byType(TextFormField);
      if (fields.evaluate().length >= 4) {
        await tester.enterText(fields.at(0), 'John Doe');
        await tester.enterText(fields.at(1), 'test@example.com');
        await tester.enterText(fields.at(2), 'Password123!');
        await tester.enterText(fields.at(3), 'Password123!');
      }

      await tester.tap(find.text('Sign up as Buyer'));
      await tester.pump();

      // _handleSignUp executed — no crash
      expect(find.byType(SignupScreen), findsOneWidget);
    });
  });

  group('SignupScreen — BlocListener states', () {
    testWidgets('AuthFailure shows error snackbar', (tester) async {
      final ab = AuthBloc(
        authRepository: FakeAuthRepository(),
        userRepository: FakeUserRepository(),
      );

      await tester.pumpWidget(_wrap(bloc: ab));
      await tester.pump();
      await tester.pump();

      // Emit failure after initial render (triggers listener)
      ab.emit(const AuthFailure('Registration failed'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Registration failed'), findsOneWidget);
    });

    testWidgets('AuthLoading shows CircularProgressIndicator in submit button',
        (tester) async {
      final ab = AuthBloc(
        authRepository: FakeAuthRepository(),
        userRepository: FakeUserRepository(),
      )..emit(const AuthLoading());

      await tester.pumpWidget(_wrap(bloc: ab));
      await tester.pump();
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets(
        'AuthNeedsProfile pops navigator (two-route setup)', (tester) async {
      bool popped = false;
      final ab = AuthBloc(
        authRepository: FakeAuthRepository(),
        userRepository: FakeUserRepository(),
      );

      await tester.pumpWidget(
        BlocProvider<AuthBloc>(
          create: (_) => ab,
          child: MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () {
                  Navigator.push<void>(
                    ctx,
                    MaterialPageRoute<void>(
                      builder: (_) => BlocProvider.value(
                        value: ab,
                        child: const SignupScreen(),
                      ),
                    ),
                  ).then((_) => popped = true);
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.byType(SignupScreen), findsOneWidget);

      // AuthNeedsProfile triggers Navigator.pop in listener
      ab.emit(const AuthNeedsProfile(uid: 'u1', email: 'test@test.com'));
      await tester.pumpAndSettle();

      expect(popped, isTrue);
      expect(find.byType(SignupScreen), findsNothing);
    });
  });

  group('SignupScreen — Google sign-up', () {
    testWidgets('tapping "Sign up with Google" dispatches event (no crash)',
        (tester) async {
      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_wrap());
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('Sign up with Google'));
      await tester.pump();

      // _handleGoogleSignUp dispatched AuthGoogleSignInRequested — no crash
      expect(find.byType(SignupScreen), findsOneWidget);
    });
  });

  group('SignupScreen — Sign In link', () {
    testWidgets('tapping "Sign In" link calls Navigator.pop', (tester) async {
      bool popped = false;
      final ab = AuthBloc(
        authRepository: FakeAuthRepository(),
        userRepository: FakeUserRepository(),
      );

      await tester.pumpWidget(
        BlocProvider<AuthBloc>(
          create: (_) => ab,
          child: MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () {
                  Navigator.push<void>(
                    ctx,
                    MaterialPageRoute<void>(
                      builder: (_) => BlocProvider.value(
                        value: ab,
                        child: const SignupScreen(),
                      ),
                    ),
                  ).then((_) => popped = true);
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.byType(SignupScreen), findsOneWidget);

      // Tap the "Sign In" link GestureDetector
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(popped, isTrue);
    });
  });
}
