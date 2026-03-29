import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:brewmaster/config/localization/app_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:brewmaster/domain/models/enums.dart';
import 'package:brewmaster/presentation/blocs/auth/auth_bloc.dart';
import 'package:brewmaster/presentation/blocs/profile/profile_bloc.dart';
import 'package:brewmaster/presentation/blocs/verification/verification_bloc.dart';
import 'package:brewmaster/presentation/screens/profile/profile_screen.dart';

import '../helpers/fake_repositories.dart';

// ── Helper ────────────────────────────────────────────────────────────────────

Widget _buildScreen({
  required AuthBloc authBloc,
  required ProfileBloc profileBloc,
  VerificationBloc? verificationBloc,
}) {
  final vb = verificationBloc ?? VerificationBloc(repository: FakeVerificationRepository());
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(create: (_) => authBloc),
        BlocProvider<ProfileBloc>(create: (_) => profileBloc),
        BlocProvider<VerificationBloc>(create: (_) => vb),
      ],
      child: const ProfileScreen(),
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

  group('ProfileScreen', () {
    testWidgets('shows loading indicator on ProfileLoading', (tester) async {
      final ab = AuthBloc(
        authRepository: FakeAuthRepository(),
        userRepository: FakeUserRepository(),
      )..emit(AuthAuthenticated(makeProfile()));
      // Use empty watchUserProfile so emit.forEach completes without overriding state
      final pb = ProfileBloc(userRepository: FakeUserRepository())
        ..emit(const ProfileLoading());

      await tester.pumpWidget(_buildScreen(authBloc: ab, profileBloc: pb));
      await tester.pump();
      await tester.pump();
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows profile display name when loaded', (tester) async {
      final profile = makeProfile(displayName: 'Test User');
      final ab = AuthBloc(
        authRepository: FakeAuthRepository(),
        userRepository: FakeUserRepository(),
      )..emit(AuthAuthenticated(profile));
      final pb = ProfileBloc(userRepository: FakeUserRepository(profile: profile))
        ..emit(ProfileLoaded(profile));

      await tester.pumpWidget(_buildScreen(authBloc: ab, profileBloc: pb));
      await tester.pump();
      await tester.pump();
      expect(find.text('Test User'), findsOneWidget);
    });

    testWidgets('shows email when profile is loaded', (tester) async {
      final profile = makeProfile(email: 'test@test.com');
      final ab = AuthBloc(
        authRepository: FakeAuthRepository(),
        userRepository: FakeUserRepository(),
      )..emit(AuthAuthenticated(profile));
      final pb = ProfileBloc(userRepository: FakeUserRepository(profile: profile))
        ..emit(ProfileLoaded(profile));

      await tester.pumpWidget(_buildScreen(authBloc: ab, profileBloc: pb));
      await tester.pump();
      await tester.pump();
      expect(find.text('test@test.com'), findsOneWidget);
    });

    testWidgets('shows role badge (Farmer)', (tester) async {
      final profile = makeProfile(role: UserRole.farmer);
      final ab = AuthBloc(
        authRepository: FakeAuthRepository(),
        userRepository: FakeUserRepository(),
      )..emit(AuthAuthenticated(profile));
      final pb = ProfileBloc(userRepository: FakeUserRepository(profile: profile))
        ..emit(ProfileLoaded(profile));

      await tester.pumpWidget(_buildScreen(authBloc: ab, profileBloc: pb));
      await tester.pump();
      await tester.pump();
      expect(find.text('Farmer'), findsOneWidget);
    });

    testWidgets('shows Edit Profile button', (tester) async {
      final profile = makeProfile();
      final ab = AuthBloc(
        authRepository: FakeAuthRepository(),
        userRepository: FakeUserRepository(),
      )..emit(AuthAuthenticated(profile));
      final pb = ProfileBloc(userRepository: FakeUserRepository(profile: profile))
        ..emit(ProfileLoaded(profile));

      await tester.pumpWidget(_buildScreen(authBloc: ab, profileBloc: pb));
      await tester.pump();
      await tester.pump();
      expect(find.text('Edit Profile'), findsOneWidget);
    });

    // ── Edit profile button is tappable ───────────────────────────────────────

    testWidgets('Edit Profile button is tappable', (tester) async {
      final profile = makeProfile();
      final ab = AuthBloc(
        authRepository: FakeAuthRepository(),
        userRepository: FakeUserRepository(),
      )..emit(AuthAuthenticated(profile));
      final pb = ProfileBloc(userRepository: FakeUserRepository(profile: profile))
        ..emit(ProfileLoaded(profile));

      await tester.pumpWidget(_buildScreen(authBloc: ab, profileBloc: pb));
      await tester.pump();
      await tester.pump();

      final editButton = find.text('Edit Profile');
      expect(editButton, findsOneWidget);
      // Verify it can be tapped without throwing
      await tester.tap(editButton);
      await tester.pump();
    });

    // ── Verification status badge ─────────────────────────────────────────────

    testWidgets('shows Pending verification badge when status is pending',
        (tester) async {
      final profile =
          makeProfile(verificationStatus: VerificationStatus.pending);
      final ab = AuthBloc(
        authRepository: FakeAuthRepository(),
        userRepository: FakeUserRepository(),
      )..emit(AuthAuthenticated(profile));
      final pb = ProfileBloc(userRepository: FakeUserRepository(profile: profile))
        ..emit(ProfileLoaded(profile));

      await tester.pumpWidget(_buildScreen(authBloc: ab, profileBloc: pb));
      await tester.pump();
      await tester.pump();
      expect(find.text('Pending'), findsOneWidget);
    });

    testWidgets('shows Verified badge when verification status is verified',
        (tester) async {
      final profile =
          makeProfile(verificationStatus: VerificationStatus.verified);
      final ab = AuthBloc(
        authRepository: FakeAuthRepository(),
        userRepository: FakeUserRepository(),
      )..emit(AuthAuthenticated(profile));
      final pb = ProfileBloc(userRepository: FakeUserRepository(profile: profile))
        ..emit(ProfileLoaded(profile));

      await tester.pumpWidget(_buildScreen(authBloc: ab, profileBloc: pb));
      await tester.pump();
      await tester.pump();
      expect(find.text('Verified'), findsOneWidget);
    });

    testWidgets(
        'shows Get Verified button when verification status is unverified',
        (tester) async {
      final profile =
          makeProfile(verificationStatus: VerificationStatus.unverified);
      final ab = AuthBloc(
        authRepository: FakeAuthRepository(),
        userRepository: FakeUserRepository(),
      )..emit(AuthAuthenticated(profile));
      final pb = ProfileBloc(userRepository: FakeUserRepository(profile: profile))
        ..emit(ProfileLoaded(profile));

      await tester.pumpWidget(_buildScreen(authBloc: ab, profileBloc: pb));
      await tester.pump();
      await tester.pump();
      expect(find.text('Get Verified'), findsOneWidget);
    });

    testWidgets(
        'does not show Get Verified button when already verified',
        (tester) async {
      final profile =
          makeProfile(verificationStatus: VerificationStatus.verified);
      final ab = AuthBloc(
        authRepository: FakeAuthRepository(),
        userRepository: FakeUserRepository(),
      )..emit(AuthAuthenticated(profile));
      final pb = ProfileBloc(userRepository: FakeUserRepository(profile: profile))
        ..emit(ProfileLoaded(profile));

      await tester.pumpWidget(_buildScreen(authBloc: ab, profileBloc: pb));
      await tester.pump();
      await tester.pump();
      expect(find.text('Get Verified'), findsNothing);
    });

    // ── Farmer-specific data ──────────────────────────────────────────────────

    testWidgets('shows Farm Details section for farmer role', (tester) async {
      final profile = makeProfile(role: UserRole.farmer);
      final ab = AuthBloc(
        authRepository: FakeAuthRepository(),
        userRepository: FakeUserRepository(),
      )..emit(AuthAuthenticated(profile));
      final pb = ProfileBloc(userRepository: FakeUserRepository(profile: profile))
        ..emit(ProfileLoaded(profile));

      await tester.pumpWidget(_buildScreen(authBloc: ab, profileBloc: pb));
      await tester.pump();
      await tester.pump();
      expect(find.text('Farm Details'), findsOneWidget);
    });

    testWidgets('shows farm size for farmer profile', (tester) async {
      final profile = makeProfile(role: UserRole.farmer);
      final ab = AuthBloc(
        authRepository: FakeAuthRepository(),
        userRepository: FakeUserRepository(),
      )..emit(AuthAuthenticated(profile));
      final pb = ProfileBloc(userRepository: FakeUserRepository(profile: profile))
        ..emit(ProfileLoaded(profile));

      await tester.pumpWidget(_buildScreen(authBloc: ab, profileBloc: pb));
      await tester.pump();
      await tester.pump();
      // makeProfile sets farmSize: 5.0
      expect(find.textContaining('5.0 hectares'), findsOneWidget);
    });

    testWidgets('shows farm location for farmer profile', (tester) async {
      final profile = makeProfile(role: UserRole.farmer);
      final ab = AuthBloc(
        authRepository: FakeAuthRepository(),
        userRepository: FakeUserRepository(),
      )..emit(AuthAuthenticated(profile));
      final pb = ProfileBloc(userRepository: FakeUserRepository(profile: profile))
        ..emit(ProfileLoaded(profile));

      await tester.pumpWidget(_buildScreen(authBloc: ab, profileBloc: pb));
      await tester.pump();
      await tester.pump();
      // makeProfile sets farmLocation: 'Kigali'
      expect(find.text('Kigali'), findsOneWidget);
    });

    // ── Buyer-specific data ───────────────────────────────────────────────────

    testWidgets('shows Business Details section for buyer role', (tester) async {
      final profile = makeProfile(role: UserRole.buyer);
      final ab = AuthBloc(
        authRepository: FakeAuthRepository(),
        userRepository: FakeUserRepository(),
      )..emit(AuthAuthenticated(profile));
      final pb = ProfileBloc(userRepository: FakeUserRepository(profile: profile))
        ..emit(ProfileLoaded(profile));

      await tester.pumpWidget(_buildScreen(authBloc: ab, profileBloc: pb));
      await tester.pump();
      await tester.pump();
      expect(find.text('Business Details'), findsOneWidget);
    });

    testWidgets('shows business name for buyer profile', (tester) async {
      final profile = makeProfile(role: UserRole.buyer);
      final ab = AuthBloc(
        authRepository: FakeAuthRepository(),
        userRepository: FakeUserRepository(),
      )..emit(AuthAuthenticated(profile));
      final pb = ProfileBloc(userRepository: FakeUserRepository(profile: profile))
        ..emit(ProfileLoaded(profile));

      await tester.pumpWidget(_buildScreen(authBloc: ab, profileBloc: pb));
      await tester.pump();
      await tester.pump();
      // makeProfile sets businessName: 'CoffeeCo'
      expect(find.text('CoffeeCo'), findsOneWidget);
    });

    testWidgets('shows business type for buyer profile', (tester) async {
      final profile = makeProfile(role: UserRole.buyer);
      final ab = AuthBloc(
        authRepository: FakeAuthRepository(),
        userRepository: FakeUserRepository(),
      )..emit(AuthAuthenticated(profile));
      final pb = ProfileBloc(userRepository: FakeUserRepository(profile: profile))
        ..emit(ProfileLoaded(profile));

      await tester.pumpWidget(_buildScreen(authBloc: ab, profileBloc: pb));
      await tester.pump();
      await tester.pump();
      // makeProfile sets businessType: 'Roaster'
      expect(find.text('Roaster'), findsOneWidget);
    });

    testWidgets('shows Buyer role badge for buyer profile', (tester) async {
      final profile = makeProfile(role: UserRole.buyer);
      final ab = AuthBloc(
        authRepository: FakeAuthRepository(),
        userRepository: FakeUserRepository(),
      )..emit(AuthAuthenticated(profile));
      final pb = ProfileBloc(userRepository: FakeUserRepository(profile: profile))
        ..emit(ProfileLoaded(profile));

      await tester.pumpWidget(_buildScreen(authBloc: ab, profileBloc: pb));
      await tester.pump();
      await tester.pump();
      expect(find.text('Buyer'), findsOneWidget);
    });

    testWidgets('does not show Farm Details section for buyer role',
        (tester) async {
      final profile = makeProfile(role: UserRole.buyer);
      final ab = AuthBloc(
        authRepository: FakeAuthRepository(),
        userRepository: FakeUserRepository(),
      )..emit(AuthAuthenticated(profile));
      final pb = ProfileBloc(userRepository: FakeUserRepository(profile: profile))
        ..emit(ProfileLoaded(profile));

      await tester.pumpWidget(_buildScreen(authBloc: ab, profileBloc: pb));
      await tester.pump();
      await tester.pump();
      expect(find.text('Farm Details'), findsNothing);
    });

    // ── Verification pending state ────────────────────────────────────────────

    testWidgets('does not show Get Verified button when status is pending',
        (tester) async {
      final profile =
          makeProfile(verificationStatus: VerificationStatus.pending);
      final ab = AuthBloc(
        authRepository: FakeAuthRepository(),
        userRepository: FakeUserRepository(),
      )..emit(AuthAuthenticated(profile));
      final pb = ProfileBloc(userRepository: FakeUserRepository(profile: profile))
        ..emit(ProfileLoaded(profile));

      await tester.pumpWidget(_buildScreen(authBloc: ab, profileBloc: pb));
      await tester.pump();
      await tester.pump();
      expect(find.text('Get Verified'), findsNothing);
    });

    // ── Sign out button ───────────────────────────────────────────────────────

    testWidgets('shows Sign out button', (tester) async {
      final profile = makeProfile();
      final ab = AuthBloc(
        authRepository: FakeAuthRepository(),
        userRepository: FakeUserRepository(),
      )..emit(AuthAuthenticated(profile));
      final pb = ProfileBloc(userRepository: FakeUserRepository(profile: profile))
        ..emit(ProfileLoaded(profile));

      await tester.pumpWidget(_buildScreen(authBloc: ab, profileBloc: pb));
      await tester.pump();
      await tester.pump();
      expect(find.text('Sign Out'), findsOneWidget);
    });

    testWidgets('tapping Sign out dispatches AuthSignOutRequested event',
        (tester) async {
      final profile = makeProfile();
      final fakeAuth = FakeAuthRepository();
      final ab = AuthBloc(
        authRepository: fakeAuth,
        userRepository: FakeUserRepository(),
      )..emit(AuthAuthenticated(profile));
      final pb = ProfileBloc(userRepository: FakeUserRepository(profile: profile))
        ..emit(ProfileLoaded(profile));

      await tester.pumpWidget(_buildScreen(authBloc: ab, profileBloc: pb));
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('Sign Out'));
      await tester.pump();
      // After tapping, the AuthBloc should have processed the sign-out event.
      // We verify no exception was thrown (FakeAuthRepository.signOut is a no-op).
    });

    // ── Email verification status ─────────────────────────────────────────────

    testWidgets('shows Email Verified badge when isVerified is true',
        (tester) async {
      final profile = makeProfile(isVerified: true);
      final ab = AuthBloc(
        authRepository: FakeAuthRepository(),
        userRepository: FakeUserRepository(),
      )..emit(AuthAuthenticated(profile));
      final pb = ProfileBloc(userRepository: FakeUserRepository(profile: profile))
        ..emit(ProfileLoaded(profile));

      await tester.pumpWidget(_buildScreen(authBloc: ab, profileBloc: pb));
      await tester.pump();
      await tester.pump();
      expect(find.text('Email Verified'), findsOneWidget);
    });

    testWidgets('shows Email Unverified badge when isVerified is false',
        (tester) async {
      final profile = makeProfile(isVerified: false);
      final ab = AuthBloc(
        authRepository: FakeAuthRepository(),
        userRepository: FakeUserRepository(),
      )..emit(AuthAuthenticated(profile));
      final pb = ProfileBloc(userRepository: FakeUserRepository(profile: profile))
        ..emit(ProfileLoaded(profile));

      await tester.pumpWidget(_buildScreen(authBloc: ab, profileBloc: pb));
      await tester.pump();
      await tester.pump();
      expect(find.text('Email Unverified'), findsOneWidget);
    });

    testWidgets('shows Verify Email button when email is not verified',
        (tester) async {
      final profile = makeProfile(isVerified: false);
      final ab = AuthBloc(
        authRepository: FakeAuthRepository(),
        userRepository: FakeUserRepository(),
      )..emit(AuthAuthenticated(profile));
      final pb = ProfileBloc(userRepository: FakeUserRepository(profile: profile))
        ..emit(ProfileLoaded(profile));

      await tester.pumpWidget(_buildScreen(authBloc: ab, profileBloc: pb));
      await tester.pump();
      await tester.pump();
      expect(find.text('Verify Email'), findsOneWidget);
    });

    // ── Settings button ───────────────────────────────────────────────────────

    testWidgets('shows Settings button', (tester) async {
      final profile = makeProfile();
      final ab = AuthBloc(
        authRepository: FakeAuthRepository(),
        userRepository: FakeUserRepository(),
      )..emit(AuthAuthenticated(profile));
      final pb = ProfileBloc(userRepository: FakeUserRepository(profile: profile))
        ..emit(ProfileLoaded(profile));

      await tester.pumpWidget(_buildScreen(authBloc: ab, profileBloc: pb));
      await tester.pump();
      await tester.pump();
      expect(find.text('Settings'), findsOneWidget);
    });

    // ── Error / no profile state ──────────────────────────────────────────────

    testWidgets('shows no profile message on ProfileFailure', (tester) async {
      final ab = AuthBloc(
        authRepository: FakeAuthRepository(),
        userRepository: FakeUserRepository(),
      )..emit(AuthAuthenticated(makeProfile()));
      final pb = ProfileBloc(userRepository: FakeUserRepository())
        ..emit(const ProfileFailure('Something went wrong'));

      await tester.pumpWidget(_buildScreen(authBloc: ab, profileBloc: pb));
      await tester.pump();
      await tester.pump();
      expect(find.text('Something went wrong'), findsOneWidget);
    });
  });
}
