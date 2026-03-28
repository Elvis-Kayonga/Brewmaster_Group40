// Widget tests for ProfileSetupScreen
// Coverage: role selection screen, role cards, form screens (farmer/buyer),
//           country dropdown, ProfileFailure error banner + snackbar,
//           ProfileCreateSuccess listener, Save Profile button.

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:brewmaster/domain/models/enums.dart';
import 'package:brewmaster/presentation/blocs/auth/auth_bloc.dart';
import 'package:brewmaster/presentation/blocs/profile/profile_bloc.dart';
import 'package:brewmaster/presentation/screens/auth/profile_setup_screen.dart';
import 'package:brewmaster/presentation/widgets/common/error_state_widget.dart';

import '../helpers/fake_repositories.dart';

// ── Helper ────────────────────────────────────────────────────────────────────

Widget _wrap({UserRole? role}) {
  return MaterialApp(
    home: MultiBlocProvider(
      providers: [
        BlocProvider<ProfileBloc>(
          create: (_) =>
              ProfileBloc(userRepository: FakeUserRepository()),
        ),
        BlocProvider<AuthBloc>(
          create: (_) => AuthBloc(
            authRepository: FakeAuthRepository(),
            userRepository: FakeUserRepository(),
          ),
        ),
      ],
      child: ProfileSetupScreen(
        userId: 'user-1',
        email: 'test@test.com',
        displayName: 'Test User',
        role: role,
      ),
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

  group('ProfileSetupScreen — role selection', () {
    testWidgets('shows "Select Your Role" app bar when role is null',
        (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      expect(find.text('Select Your Role'), findsOneWidget);
    });

    testWidgets('shows "I\'m a Farmer" role card', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      expect(find.text("I'm a Farmer"), findsOneWidget);
    });

    testWidgets('shows "I\'m a Buyer" role card', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      expect(find.text("I'm a Buyer"), findsOneWidget);
    });

    testWidgets('shows agriculture icon on farmer card', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      expect(find.byIcon(Icons.agriculture), findsOneWidget);
    });

    testWidgets('shows shopping cart icon on buyer card', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      expect(find.byIcon(Icons.shopping_cart), findsOneWidget);
    });

    testWidgets('tapping farmer card transitions to farm details form',
        (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();

      await tester.tap(find.text("I'm a Farmer"));
      await tester.pump();

      expect(find.text('Farm Details'), findsOneWidget);
    });

    testWidgets('tapping buyer card transitions to business details form',
        (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();

      await tester.tap(find.text("I'm a Buyer"));
      await tester.pump();

      expect(find.text('Business Details'), findsOneWidget);
    });

    testWidgets('shows role description text on cards', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      expect(find.text('Grow and sell coffee beans'), findsOneWidget);
      expect(find.text('Purchase and trade coffee'), findsOneWidget);
    });
  });

  group('ProfileSetupScreen — farmer form', () {
    testWidgets('shows "Complete Your Profile" app bar', (tester) async {
      await tester.pumpWidget(_wrap(role: UserRole.farmer));
      await tester.pump();
      expect(find.text('Complete Your Profile'), findsOneWidget);
    });

    testWidgets('shows Farm Details heading for farmer', (tester) async {
      await tester.pumpWidget(_wrap(role: UserRole.farmer));
      await tester.pump();
      expect(find.text('Farm Details'), findsOneWidget);
    });

    testWidgets('shows farm-specific fields for farmer role', (tester) async {
      await tester.pumpWidget(_wrap(role: UserRole.farmer));
      await tester.pump();
      expect(find.text('Farm Size (hectares)'), findsOneWidget);
      expect(find.text('Farm Location'), findsOneWidget);
      expect(find.text('Coffee Varieties'), findsOneWidget);
    });

    testWidgets('shows country dropdown hint "Select your country"',
        (tester) async {
      await tester.pumpWidget(_wrap(role: UserRole.farmer));
      await tester.pump();
      expect(find.text('Select your country'), findsOneWidget);
    });

    testWidgets('shows "Save Profile" button', (tester) async {
      await tester.pumpWidget(_wrap(role: UserRole.farmer));
      await tester.pump();
      expect(find.text('Save Profile'), findsOneWidget);
    });

    testWidgets('shows flag icon in country dropdown', (tester) async {
      await tester.pumpWidget(_wrap(role: UserRole.farmer));
      await tester.pump();
      expect(find.byIcon(Icons.flag_outlined), findsOneWidget);
    });

    testWidgets('ProfileFailure shows ErrorBanner in builder', (tester) async {
      await tester.pumpWidget(_wrap(role: UserRole.farmer));
      await tester.pump();

      final bloc =
          tester.element(find.byType(Scaffold)).read<ProfileBloc>();
      bloc.emit(const ProfileFailure('Save failed'));
      await tester.pump();
      await tester.pump();

      expect(find.byType(ErrorBanner), findsOneWidget);
    });

    testWidgets('ProfileFailure shows snackbar from listener', (tester) async {
      await tester.pumpWidget(_wrap(role: UserRole.farmer));
      await tester.pump();

      final bloc =
          tester.element(find.byType(Scaffold)).read<ProfileBloc>();
      bloc.emit(const ProfileFailure('Network error'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Network error'), findsWidgets);
    });

    testWidgets('tapping "Save Profile" without filling form still submits',
        (tester) async {
      await tester.pumpWidget(_wrap(role: UserRole.farmer));
      await tester.pump();

      await tester.tap(find.text('Save Profile'));
      await tester.pump();

      // No crash — the form validates (all optional fields for farmer)
      expect(find.byType(ProfileSetupScreen), findsOneWidget);
    });
  });

  group('ProfileSetupScreen — buyer form', () {
    testWidgets('shows Business Details heading for buyer', (tester) async {
      await tester.pumpWidget(_wrap(role: UserRole.buyer));
      await tester.pump();
      expect(find.text('Business Details'), findsOneWidget);
    });

    testWidgets('shows buyer-specific fields', (tester) async {
      await tester.pumpWidget(_wrap(role: UserRole.buyer));
      await tester.pump();
      expect(find.text('Business Name'), findsOneWidget);
      expect(find.text('Business Type'), findsOneWidget);
      expect(find.text('Monthly Volume (kg)'), findsOneWidget);
    });

    testWidgets('does not show farm fields for buyer role', (tester) async {
      await tester.pumpWidget(_wrap(role: UserRole.buyer));
      await tester.pump();
      expect(find.text('Farm Size (hectares)'), findsNothing);
      expect(find.text('Coffee Varieties'), findsNothing);
    });

    testWidgets('shows country dropdown for buyer form', (tester) async {
      await tester.pumpWidget(_wrap(role: UserRole.buyer));
      await tester.pump();
      expect(find.text('Select your country'), findsOneWidget);
    });

    testWidgets('ProfileLoading shows loading indicator in Save button',
        (tester) async {
      await tester.pumpWidget(_wrap(role: UserRole.buyer));
      await tester.pump();

      final bloc =
          tester.element(find.byType(Scaffold)).read<ProfileBloc>();
      bloc.emit(ProfileLoading());
      await tester.pump();
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });
  });
}
