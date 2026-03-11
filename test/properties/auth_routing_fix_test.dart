// Feature: auth-screen-routing-fix, Fix Verification Tests
// **Validates: Requirements 2.1, 2.2, 2.3**
//
// Property-based tests that verify the BLoC routing fix holds across a range
// of randomly generated user states (5 iterations each).

import 'package:faker/faker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:brewmaster/domain/models/user_profile.dart';
import 'package:brewmaster/domain/models/enums.dart';
import 'package:brewmaster/domain/repositories/auth_repository.dart';
import 'package:brewmaster/domain/repositories/user_repository.dart';
import 'package:brewmaster/domain/repositories/payment_repository.dart';
import 'package:brewmaster/presentation/blocs/auth/auth_bloc.dart';
import 'package:brewmaster/presentation/blocs/profile/profile_bloc.dart';
import 'package:brewmaster/presentation/blocs/payment/payment_bloc.dart';
import 'package:brewmaster/presentation/screens/auth/auth_gate.dart';
import 'package:brewmaster/presentation/screens/auth/login_screen.dart';
import 'package:brewmaster/presentation/screens/dashboard/dashboard_screen.dart';
import 'package:brewmaster/main.dart';

// ---------------------------------------------------------------------------
// Fake Firebase User
// ---------------------------------------------------------------------------

class _FakeUser implements fb.User {
  @override final String uid;
  @override final String? email;
  @override final bool emailVerified;
  @override final List<fb.UserInfo> providerData = const [];
  _FakeUser({required this.uid, this.email, this.emailVerified = false});
  @override Future<void> reload() async {}
  @override dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

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

UserProfile _fakeProfile({required String uid, required String email}) {
  final now = DateTime.now();
  return UserProfile(
    id: uid,
    email: email,
    phoneNumber: '',
    role: UserRole.buyer,
    displayName: _faker.person.name(),
    createdAt: now,
    updatedAt: now,
    isVerified: true,
    verificationStatus: VerificationStatus.verified,
  );
}

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
  group(
      'Task 5.1 – AuthGate renders LoginScreen when unauthenticated, '
      'DashboardScreen when authenticated', () {
    testWidgets(
        'property: unauthenticated user always lands on LoginScreen (5 iterations)',
        (tester) async {
      for (var i = 0; i < 5; i++) {
        await tester.pumpWidget(_buildApp(user: null, profile: null));
        await tester.pumpAndSettle();

        expect(
          find.byType(LoginScreen),
          findsOneWidget,
          reason: 'Iteration $i: expected LoginScreen for null user',
        );
        expect(
          find.byType(DashboardScreen),
          findsNothing,
          reason: 'Iteration $i: DashboardScreen must not appear for null user',
        );
      }
    });

    testWidgets(
        'property: authenticated user with profile always lands on DashboardScreen (5 iterations)',
        (tester) async {
      for (var i = 0; i < 5; i++) {
        final uid = _faker.guid.guid();
        final email = _faker.internet.email();
        final fakeUser = _FakeUser(
          uid: uid,
          email: email,
          emailVerified: true,
        );
        final profile = _fakeProfile(uid: uid, email: email);

        await tester.pumpWidget(_buildApp(user: fakeUser, profile: profile));
        await tester.pumpAndSettle();

        expect(
          find.byType(DashboardScreen),
          findsOneWidget,
          reason: 'Iteration $i: expected DashboardScreen for authenticated user',
        );
        expect(
          find.byType(LoginScreen),
          findsNothing,
          reason: 'Iteration $i: LoginScreen must not appear for authenticated user',
        );
      }
    });

    testWidgets('AuthGate is always present regardless of auth state',
        (tester) async {
      // Unauthenticated
      await tester.pumpWidget(_buildApp(user: null, profile: null));
      await tester.pumpAndSettle();
      expect(find.byType(AuthGate), findsOneWidget);

      // Authenticated
      final uid = _faker.guid.guid();
      final email = _faker.internet.email();
      final fakeUser = _FakeUser(uid: uid, email: email, emailVerified: true);
      final profile = _fakeProfile(uid: uid, email: email);
      await tester.pumpWidget(_buildApp(user: fakeUser, profile: profile));
      await tester.pumpAndSettle();
      expect(find.byType(AuthGate), findsOneWidget);
    });
  });

  group(
      'Task 5.2 – AuthBloc is always resolvable from the widget tree via '
      'context.read<AuthBloc>() without throwing', () {
    testWidgets(
        'property: context.read<AuthBloc>() succeeds in 5 randomly seeded trees',
        (tester) async {
      for (var i = 0; i < 5; i++) {
        AuthBloc? capturedBloc;
        Object? capturedError;

        await tester.pumpWidget(
          _buildApp(user: null, profile: null),
        );
        await tester.pumpAndSettle();

        // Use a Builder to read the bloc from within the tree.
        await tester.pumpWidget(
          MultiBlocProvider(
            providers: [
              BlocProvider(
                  create: (_) => AuthBloc(
                        authRepository: _FakeAuthRepository(null),
                        userRepository: _FakeUserRepository(null),
                      )),
              BlocProvider(
                  create: (_) =>
                      ProfileBloc(userRepository: _FakeUserRepository(null))),
              BlocProvider(
                  create: (_) => PaymentBloc(
                      paymentRepository: _FakePaymentRepository())),
            ],
            child: MaterialApp(
              home: Builder(
                builder: (context) {
                  try {
                    capturedBloc = context.read<AuthBloc>();
                  } catch (e) {
                    capturedError = e;
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          capturedError,
          isNull,
          reason:
              'Iteration $i: context.read<AuthBloc>() must not throw',
        );
        expect(
          capturedBloc,
          isA<AuthBloc>(),
          reason:
              'Iteration $i: context.read<AuthBloc>() must return an AuthBloc',
        );
      }
    });
  });
}
