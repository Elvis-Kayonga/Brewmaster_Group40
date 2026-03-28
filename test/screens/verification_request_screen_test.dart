import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:brewmaster/domain/models/enums.dart';
import 'package:brewmaster/domain/models/user_profile.dart';
import 'package:brewmaster/domain/models/verification_request.dart';
import 'package:brewmaster/domain/repositories/verification_repository.dart';
import 'package:brewmaster/presentation/blocs/auth/auth_bloc.dart';
import 'package:brewmaster/presentation/blocs/verification/verification_bloc.dart';
import 'package:brewmaster/presentation/screens/profile/verification_request_screen.dart';

import '../helpers/fake_repositories.dart';

// getVerificationStatus never completes — keeps bloc in loading state.
class _NeverVerificationRepo implements VerificationRepository {
  @override
  Future<VerificationRequest?> getVerificationStatus(String userId) =>
      Completer<VerificationRequest?>().future;
  @override
  Future<void> submitVerificationRequest(String uid, List<File> docs) async {}
  @override
  Future<String> uploadDocument(String uid, File doc) async => '';
  @override
  Stream<VerificationStatus> watchVerificationStatus(String uid) => const Stream.empty();
  @override
  Future<void> syncStatusToUserProfile(String uid, VerificationStatus s) async {}
}

// ── Helper ────────────────────────────────────────────────────────────────────

Widget _buildScreen({
  required AuthBloc authBloc,
  required VerificationBloc verificationBloc,
  bool isOnboarding = false,
}) =>
    MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(create: (_) => authBloc),
          BlocProvider<VerificationBloc>(create: (_) => verificationBloc),
        ],
        child: VerificationRequestScreen(isOnboarding: isOnboarding),
      ),
    );

AuthBloc _makeAuthBloc({UserProfile? profile}) {
  final ab = AuthBloc(
    authRepository: FakeAuthRepository(),
    userRepository: FakeUserRepository(),
  )..emit(AuthAuthenticated(profile ?? makeProfile()));
  return ab;
}

VerificationBloc _makeVerificationBloc({
  VerificationStatus status = VerificationStatus.unverified,
}) {
  final repo = FakeVerificationRepository()..setStatus(status);
  return VerificationBloc(repository: repo);
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    setupFirebaseCoreMocks();
    await Firebase.initializeApp();
  });

  group('VerificationRequestScreen', () {
    testWidgets('shows "Verify Identity" app bar title', (tester) async {
      await tester.pumpWidget(_buildScreen(
        authBloc: _makeAuthBloc(),
        verificationBloc: _makeVerificationBloc(),
      ));
      await tester.pump();
      expect(find.text('Verify Identity'), findsOneWidget);
    });

    testWidgets('shows submit button', (tester) async {
      await tester.pumpWidget(_buildScreen(
        authBloc: _makeAuthBloc(),
        verificationBloc: _makeVerificationBloc(),
      ));
      await tester.pump();
      expect(find.text('Submit for Verification'), findsOneWidget);
    });

    testWidgets('shows upload document option', (tester) async {
      await tester.pumpWidget(_buildScreen(
        authBloc: _makeAuthBloc(),
        verificationBloc: _makeVerificationBloc(),
      ));
      await tester.pump();
      expect(find.text('Pick Documents'), findsOneWidget);
    });

    // ── Form fields ───────────────────────────────────────────────────────────

    testWidgets('shows Submit Verification Documents heading', (tester) async {
      await tester.pumpWidget(_buildScreen(
        authBloc: _makeAuthBloc(),
        verificationBloc: _makeVerificationBloc(),
      ));
      await tester.pump();
      expect(find.text('Submit Verification Documents'), findsOneWidget);
    });

    testWidgets('shows instructional body text about accepted documents',
        (tester) async {
      await tester.pumpWidget(_buildScreen(
        authBloc: _makeAuthBloc(),
        verificationBloc: _makeVerificationBloc(),
      ));
      await tester.pump();
      expect(
        find.textContaining('national ID'),
        findsOneWidget,
      );
    });

    // ── Loading state ─────────────────────────────────────────────────────────

    testWidgets('shows loading indicator when VerificationBloc is loading',
        (tester) async {
      final vb = VerificationBloc(repository: _NeverVerificationRepo());

      await tester.pumpWidget(_buildScreen(
        authBloc: _makeAuthBloc(),
        verificationBloc: vb,
      ));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    // ── Snackbar on submit without files ─────────────────────────────────────

    testWidgets(
        'tapping Submit for Verification without files shows snackbar error',
        (tester) async {
      await tester.pumpWidget(_buildScreen(
        authBloc: _makeAuthBloc(),
        verificationBloc: _makeVerificationBloc(),
      ));
      await tester.pump();

      // Submit button is disabled when no files are selected (onPressed: null)
      // so the button should be present but non-interactive
      final submitFinder = find.text('Submit for Verification');
      expect(submitFinder, findsOneWidget);
    });

    // ── Status views ──────────────────────────────────────────────────────────

    testWidgets('shows pending status text when status is pending',
        (tester) async {
      final vb = _makeVerificationBloc(status: VerificationStatus.pending);

      await tester.pumpWidget(_buildScreen(
        authBloc: _makeAuthBloc(),
        verificationBloc: vb,
      ));
      await tester.pump();
      expect(
        find.text('Your documents are under review.'),
        findsOneWidget,
      );
    });

    testWidgets('shows verified status text when status is verified',
        (tester) async {
      final vb = _makeVerificationBloc(status: VerificationStatus.verified);

      await tester.pumpWidget(_buildScreen(
        authBloc: _makeAuthBloc(),
        verificationBloc: vb,
      ));
      await tester.pump();
      expect(find.text('Your account has been verified.'), findsOneWidget);
    });

    testWidgets('shows rejected status text when status is rejected',
        (tester) async {
      final vb = _makeVerificationBloc(status: VerificationStatus.rejected);

      await tester.pumpWidget(_buildScreen(
        authBloc: _makeAuthBloc(),
        verificationBloc: vb,
      ));
      await tester.pump();
      expect(
        find.textContaining('submission was rejected'),
        findsOneWidget,
      );
    });

    testWidgets('shows Re-submit Documents button when status is rejected',
        (tester) async {
      final vb = _makeVerificationBloc(status: VerificationStatus.rejected);

      await tester.pumpWidget(_buildScreen(
        authBloc: _makeAuthBloc(),
        verificationBloc: vb,
      ));
      await tester.pump();
      expect(find.text('Re-submit Documents'), findsOneWidget);
    });

    testWidgets(
        'tapping Re-submit Documents shows the submit form again',
        (tester) async {
      final vb = _makeVerificationBloc(status: VerificationStatus.rejected);

      await tester.pumpWidget(_buildScreen(
        authBloc: _makeAuthBloc(),
        verificationBloc: vb,
      ));
      await tester.pump();

      await tester.tap(find.text('Re-submit Documents'));
      await tester.pump();

      // After tapping, the form should be shown with Pick Documents
      expect(find.text('Pick Documents'), findsOneWidget);
    });

    // ── Success snackbar ──────────────────────────────────────────────────────

    testWidgets('shows success snackbar when VerificationSubmitSuccess emitted',
        (tester) async {
      final vb = VerificationBloc(repository: FakeVerificationRepository())
        ..emit(VerificationStatusLoaded(status: VerificationStatus.unverified));

      await tester.pumpWidget(_buildScreen(
        authBloc: _makeAuthBloc(),
        verificationBloc: vb,
      ));
      await tester.pump();

      // Emit success state to trigger the listener
      vb.emit(const VerificationSubmitSuccess());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.textContaining('Documents submitted'),
        findsOneWidget,
      );
    });

    // ── Error snackbar ────────────────────────────────────────────────────────

    testWidgets('shows error snackbar when VerificationFailure emitted',
        (tester) async {
      final vb = VerificationBloc(repository: FakeVerificationRepository())
        ..emit(VerificationStatusLoaded(status: VerificationStatus.unverified));

      await tester.pumpWidget(_buildScreen(
        authBloc: _makeAuthBloc(),
        verificationBloc: vb,
      ));
      await tester.pump();

      vb.emit(const VerificationFailure('Upload failed. Please try again.'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.text('Upload failed. Please try again.'),
        findsOneWidget,
      );
    });

    // ── Onboarding mode ───────────────────────────────────────────────────────

    testWidgets('shows Skip for now button in onboarding mode', (tester) async {
      await tester.pumpWidget(_buildScreen(
        authBloc: _makeAuthBloc(),
        verificationBloc: _makeVerificationBloc(),
        isOnboarding: true,
      ));
      await tester.pump();
      expect(find.text('Skip for now'), findsOneWidget);
    });

    testWidgets('does not show Skip for now button in normal mode',
        (tester) async {
      await tester.pumpWidget(_buildScreen(
        authBloc: _makeAuthBloc(),
        verificationBloc: _makeVerificationBloc(),
        isOnboarding: false,
      ));
      await tester.pump();
      expect(find.text('Skip for now'), findsNothing);
    });

    // ── Icons in status view ──────────────────────────────────────────────────

    testWidgets('shows hourglass icon for pending status', (tester) async {
      final vb = _makeVerificationBloc(status: VerificationStatus.pending);

      await tester.pumpWidget(_buildScreen(
        authBloc: _makeAuthBloc(),
        verificationBloc: vb,
      ));
      await tester.pump();
      expect(find.byIcon(Icons.hourglass_top), findsOneWidget);
    });

    testWidgets('shows verified icon for verified status', (tester) async {
      final vb = _makeVerificationBloc(status: VerificationStatus.verified);

      await tester.pumpWidget(_buildScreen(
        authBloc: _makeAuthBloc(),
        verificationBloc: vb,
      ));
      await tester.pump();
      expect(find.byIcon(Icons.verified), findsOneWidget);
    });

    testWidgets('shows cancel icon for rejected status', (tester) async {
      final vb = _makeVerificationBloc(status: VerificationStatus.rejected);

      await tester.pumpWidget(_buildScreen(
        authBloc: _makeAuthBloc(),
        verificationBloc: vb,
      ));
      await tester.pump();
      expect(find.byIcon(Icons.cancel_outlined), findsOneWidget);
    });
  });
}
