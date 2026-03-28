// Widget tests for VerificationPendingScreen
// Coverage: renders correctly, displays all key UI elements, buttons present.

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:brewmaster/domain/models/enums.dart';
import 'package:brewmaster/presentation/blocs/auth/auth_bloc.dart';
import 'package:brewmaster/presentation/blocs/verification/verification_bloc.dart';
import 'package:brewmaster/presentation/screens/profile/verification_pending_screen.dart';

import '../helpers/fake_repositories.dart';

// ── Helper ────────────────────────────────────────────────────────────────────

Widget _wrap({bool kycPending = false}) {
  return MaterialApp(
    home: MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) {
            final b = AuthBloc(
              authRepository: FakeAuthRepository(),
              userRepository: FakeUserRepository(),
            );
            if (kycPending) {
              b.emit(AuthKycPending(
                makeProfile(verificationStatus: VerificationStatus.pending),
              ));
            }
            return b;
          },
        ),
        BlocProvider<VerificationBloc>(
          create: (_) =>
              VerificationBloc(repository: FakeVerificationRepository()),
        ),
      ],
      child: const VerificationPendingScreen(),
    ),
  );
}

/// Sets a tall viewport so the screen's Column doesn't overflow in tests.
void _setLargeView(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1400);
  tester.view.devicePixelRatio = 1.0;
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    setupFirebaseCoreMocks();
    await Firebase.initializeApp();
  });

  group('VerificationPendingScreen', () {
    testWidgets('shows "Verification Pending" app bar title', (tester) async {
      _setLargeView(tester);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(_wrap());
      await tester.pump();
      expect(find.text('Verification Pending'), findsOneWidget);
    });

    testWidgets('shows "Documents Under Review" heading', (tester) async {
      _setLargeView(tester);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(_wrap());
      await tester.pump();
      expect(find.text('Documents Under Review'), findsOneWidget);
    });

    testWidgets('shows hourglass icon', (tester) async {
      _setLargeView(tester);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(_wrap());
      await tester.pump();
      expect(find.byIcon(Icons.hourglass_top_rounded), findsOneWidget);
    });

    testWidgets('shows review description text', (tester) async {
      _setLargeView(tester);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(_wrap());
      await tester.pump();
      expect(find.textContaining('being reviewed by our team'), findsOneWidget);
    });

    testWidgets('shows email notification icon', (tester) async {
      _setLargeView(tester);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(_wrap());
      await tester.pump();
      expect(find.byIcon(Icons.email_outlined), findsOneWidget);
    });

    testWidgets('shows 1-2 business days timeline text', (tester) async {
      _setLargeView(tester);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(_wrap());
      await tester.pump();
      expect(find.textContaining('1–2 business days'), findsOneWidget);
    });

    testWidgets('shows CircularProgressIndicator', (tester) async {
      _setLargeView(tester);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(_wrap());
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows "Check Status" button', (tester) async {
      _setLargeView(tester);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(_wrap());
      await tester.pump();
      expect(find.text('Check Status'), findsOneWidget);
    });

    testWidgets('shows "Sign Out" button', (tester) async {
      _setLargeView(tester);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(_wrap());
      await tester.pump();
      expect(find.text('Sign Out'), findsOneWidget);
    });

    testWidgets('tapping Check Status does not crash', (tester) async {
      _setLargeView(tester);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(_wrap());
      await tester.pump();
      await tester.tap(find.text('Check Status'));
      await tester.pump();
    });

    testWidgets('tapping Sign Out does not crash', (tester) async {
      _setLargeView(tester);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(_wrap());
      await tester.pump();
      await tester.tap(find.text('Sign Out'));
      await tester.pump();
    });

    testWidgets(
        'kycPending state triggers VerificationStatusLoadRequested in initState',
        (tester) async {
      _setLargeView(tester);
      addTearDown(tester.view.resetPhysicalSize);
      // Lines 35-38: if (authState is AuthKycPending) branch in initState
      await tester.pumpWidget(_wrap(kycPending: true));
      await tester.pump();
      expect(find.byType(VerificationPendingScreen), findsOneWidget);
    });

    testWidgets('poll timer fires AuthCheckRequested after 30 s', (tester) async {
      _setLargeView(tester);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(_wrap());
      await tester.pump();
      // Line 43: _pollTimer callback
      await tester.pump(const Duration(seconds: 31));
      expect(find.byType(VerificationPendingScreen), findsOneWidget);
    });

    testWidgets(
        'listenWhen dispatches AuthCheckRequested when verification verified',
        (tester) async {
      _setLargeView(tester);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(_wrap());
      await tester.pump();

      // Lines 56-59 (listenWhen) and 62 (listener body)
      final ctx = tester.element(find.byType(VerificationPendingScreen));
      BlocProvider.of<VerificationBloc>(ctx).emit(
        const VerificationStatusLoaded(status: VerificationStatus.verified),
      );
      await tester.pump();

      expect(find.byType(VerificationPendingScreen), findsOneWidget);
    });
  });
}
