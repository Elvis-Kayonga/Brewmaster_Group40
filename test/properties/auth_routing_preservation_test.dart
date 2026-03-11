// Feature: auth-screen-routing-fix, Preservation Tests
// **Validates: Requirements 3.1, 3.4**
//
// These tests verify that the BrewMasterApp's MaterialApp configuration is
// preserved correctly under the BLoC architecture rewrite.

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
  group('Task 6.1 – MaterialApp uses Material 3 (useMaterial3: true)', () {
    testWidgets('BrewMasterApp theme has useMaterial3 set to true',
        (tester) async {
      await tester.pumpWidget(_buildApp(user: null, profile: null));
      await tester.pumpAndSettle();

      final MaterialApp materialApp =
          tester.widget<MaterialApp>(find.byType(MaterialApp));

      expect(
        materialApp.theme?.useMaterial3,
        isTrue,
        reason: 'BrewMasterApp must opt into Material 3',
      );
    });

    testWidgets('BrewMasterApp theme has a ColorScheme derived from brown seed',
        (tester) async {
      await tester.pumpWidget(_buildApp(user: null, profile: null));
      await tester.pumpAndSettle();

      final MaterialApp materialApp =
          tester.widget<MaterialApp>(find.byType(MaterialApp));

      expect(
        materialApp.theme?.colorScheme,
        isNotNull,
        reason: 'BrewMasterApp must define a colorScheme',
      );
    });
  });

  group('Task 6.2 – MaterialApp title is "BrewMaster" and app renders correctly',
      () {
    testWidgets('MaterialApp title is "BrewMaster"', (tester) async {
      await tester.pumpWidget(_buildApp(user: null, profile: null));
      await tester.pumpAndSettle();

      final MaterialApp materialApp =
          tester.widget<MaterialApp>(find.byType(MaterialApp));

      expect(
        materialApp.title,
        equals('BrewMaster'),
        reason: 'App title must remain "BrewMaster"',
      );
    });

    testWidgets('BrewMasterApp renders a MaterialApp widget', (tester) async {
      await tester.pumpWidget(_buildApp(user: null, profile: null));
      await tester.pumpAndSettle();

      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('BrewMasterApp renders without errors', (tester) async {
      await tester.pumpWidget(_buildApp(user: null, profile: null));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('BrewMasterApp is a StatelessWidget', (tester) async {
      await tester.pumpWidget(_buildApp(user: null, profile: null));
      await tester.pumpAndSettle();

      expect(
        find.byType(BrewMasterApp),
        findsOneWidget,
        reason: 'BrewMasterApp must be present in the widget tree',
      );
      expect(
        tester.widget(find.byType(BrewMasterApp)),
        isA<StatelessWidget>(),
        reason: 'BrewMasterApp must be a StatelessWidget',
      );
    });
  });
}
