// Widget tests for EmailVerificationScreen
// Coverage: renders UI elements, resend button cooldown, sign-out button.

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:brewmaster/presentation/blocs/auth/auth_bloc.dart';
import 'package:brewmaster/presentation/screens/auth/email_verification_screen.dart';

import '../helpers/fake_repositories.dart';

// ── Helper ─────────────────────────────────────────────────────────────────

Widget _wrap() {
  return MaterialApp(
    home: BlocProvider<AuthBloc>(
      create: (_) => AuthBloc(
        authRepository: FakeAuthRepository(),
        userRepository: FakeUserRepository(),
      ),
      child: const EmailVerificationScreen(),
    ),
  );
}

// ── Tests ──────────────────────────────────────────────────────────────────

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    setupFirebaseCoreMocks();
    await Firebase.initializeApp();
  });

  group('EmailVerificationScreen', () {
    testWidgets('shows "Verify Your Email" app bar title', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      expect(find.text('Verify Your Email'), findsOneWidget);
    });

    testWidgets('shows email icon', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      expect(find.byIcon(Icons.mark_email_unread_outlined), findsOneWidget);
    });

    testWidgets('shows "Check your inbox" heading', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      expect(find.text('Check your inbox'), findsOneWidget);
    });

    testWidgets('shows instructional body text', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      expect(find.textContaining('verification link'), findsOneWidget);
    });

    testWidgets('shows CircularProgressIndicator (polling indicator)',
        (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows disabled resend button during cooldown', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      // The button is disabled while cooldown > 0; label contains "Resend in"
      expect(find.textContaining('Resend in'), findsOneWidget);
      final btn = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
      expect(btn.onPressed, isNull);
    });

    testWidgets('shows "Sign Out" text button', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      expect(find.text('Sign Out'), findsOneWidget);
    });

    testWidgets('tapping Sign Out does not crash', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      await tester.tap(find.text('Sign Out'));
      await tester.pump();
    });
  });
}
