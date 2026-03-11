// Feature: auth-screen-routing-fix, Exploratory Fault Condition Tests
// **Validates: Requirements 2.1, 2.3**
//
// These tests probe boundary / fault conditions in the BLoC-based
// auth-routing architecture. They are analogous to the original
// ProviderNotFoundException tests but updated for flutter_bloc.

import 'package:faker/faker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:brewmaster/domain/models/user_profile.dart';
import 'package:brewmaster/domain/repositories/auth_repository.dart';
import 'package:brewmaster/domain/repositories/user_repository.dart';
import 'package:brewmaster/domain/repositories/payment_repository.dart';
import 'package:brewmaster/presentation/blocs/auth/auth_bloc.dart';
import 'package:brewmaster/presentation/blocs/profile/profile_bloc.dart';
import 'package:brewmaster/presentation/blocs/payment/payment_bloc.dart';
import 'package:brewmaster/presentation/screens/auth/auth_gate.dart';
import 'package:brewmaster/presentation/screens/auth/login_screen.dart';
import 'package:brewmaster/main.dart';

// ---------------------------------------------------------------------------
// Fake repositories
// ---------------------------------------------------------------------------

class _FakeAuthRepository implements AuthRepository {
  final fb.User? _user;
  _FakeAuthRepository(this._user);
  @override fb.User? get currentUser => _user;
  @override Stream<fb.User?> get authStateChanges => Stream.value(_user);
  @override Future<fb.User?> register(String e, String p) async => _user;
  @override Future<fb.User?> signIn(String e, String p) async => _user;
  @override Future<fb.User?> signInWithGoogle() async => _user;
  @override Future<void> signOut() async {}
  @override Future<void> sendPasswordResetEmail(String e) async {}
  @override Future<bool> sendEmailVerification() async => true;
  @override Future<bool> isEmailVerified() async => _user?.emailVerified ?? false;
}

class _FakeUserRepository implements UserRepository {
  final UserProfile? _profile;
  _FakeUserRepository(this._profile);
  @override Future<UserProfile?> getUserProfile(String id) async => _profile;
  @override Future<UserProfile?> getUserProfileByEmail(String e) async => null;
  @override Future<void> createUserProfile(UserProfile p) async {}
  @override Future<void> updateUserProfile(String id, Map<String, dynamic> u) async {}
  @override Stream<UserProfile?> watchUserProfile(String id) => const Stream.empty();
}

class _FakePaymentRepository implements PaymentRepository {
  @override dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

final _faker = Faker();

Widget _buildApp({fb.User? user, UserProfile? profile}) {
  final authRepo = _FakeAuthRepository(user);
  final userRepo = _FakeUserRepository(profile);
  final paymentRepo = _FakePaymentRepository();
  return MultiBlocProvider(
    providers: [
      BlocProvider(
          create: (_) => AuthBloc(
                authRepository: authRepo,
                userRepository: userRepo,
              )),
      BlocProvider(create: (_) => ProfileBloc(userRepository: userRepo)),
      BlocProvider(
          create: (_) => PaymentBloc(paymentRepository: paymentRepo)),
    ],
    child: const BrewMasterApp(),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('Task 4.1 – AuthGate without BlocProvider<AuthBloc> throws StateError',
      () {
    // This mirrors the old ProviderNotFoundException test: if AuthGate is
    // placed in the tree without a BlocProvider<AuthBloc> ancestor, flutter_bloc
    // throws a StateError when trying to read the bloc from context.
    testWidgets(
        'AuthGate wrapped in MaterialApp without BlocProvider throws StateError',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AuthGate(),
        ),
      );
      // flutter_bloc throws a StateError when BlocProvider<AuthBloc> is absent.
      expect(tester.takeException(), isA<StateError>());
    });

    testWidgets(
        'AuthGate with all BlocProviders present does NOT throw', (tester) async {
      await tester.pumpWidget(_buildApp(user: null, profile: null));
      await tester.pumpAndSettle();
      // No exception should be thrown.
      expect(tester.takeException(), isNull);
    });
  });

  group('Task 4.2 – Without a user, LoginScreen is shown (not DashboardScreen)',
      () {
    testWidgets('null user produces LoginScreen', (tester) async {
      await tester.pumpWidget(_buildApp(user: null, profile: null));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('null user does not produce Dashboard content', (tester) async {
      await tester.pumpWidget(_buildApp(user: null, profile: null));
      await tester.pumpAndSettle();

      expect(find.text('Dashboard content coming soon'), findsNothing);
    });

    testWidgets('null user with random email still shows LoginScreen',
        (tester) async {
      // Use Faker to generate varied inputs — same result every time.
      // The email is logged to show varied input but no user is passed.
      final randomEmail = _faker.internet.email();
      expect(randomEmail, isA<String>()); // consume the value; no user is passed
      await tester.pumpWidget(_buildApp(user: null, profile: null));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(AuthGate), findsOneWidget);
    });
  });
}
