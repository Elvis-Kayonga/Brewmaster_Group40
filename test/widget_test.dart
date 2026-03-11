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
import 'package:brewmaster/presentation/screens/auth/login_screen.dart';
import 'package:brewmaster/main.dart';

class _FakeAuthRepository implements AuthRepository {
  final fb.User? _user;
  _FakeAuthRepository(this._user);

  @override
  fb.User? get currentUser => _user;
  @override
  Stream<fb.User?> get authStateChanges => Stream.value(_user);
  @override
  Future<fb.User?> register(String e, String p) async => _user;
  @override
  Future<fb.User?> signIn(String e, String p) async => _user;
  @override
  Future<fb.User?> signInWithGoogle() async => _user;
  @override
  Future<void> signOut() async {}
  @override
  Future<void> sendPasswordResetEmail(String e) async {}
  @override
  Future<bool> sendEmailVerification() async => true;
  @override
  Future<bool> isEmailVerified() async => false;
}

class _FakeUserRepository implements UserRepository {
  @override
  Future<UserProfile?> getUserProfile(String id) async => null;
  @override
  Future<UserProfile?> getUserProfileByEmail(String e) async => null;
  @override
  Future<void> createUserProfile(UserProfile p) async {}
  @override
  Future<void> updateUserProfile(String id, Map<String, dynamic> u) async {}
  @override
  Stream<UserProfile?> watchUserProfile(String id) => const Stream.empty();
}

class _FakePaymentRepository implements PaymentRepository {
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

Widget _buildTestApp() {
  final authRepo = _FakeAuthRepository(null);
  final userRepo = _FakeUserRepository();
  final paymentRepo = _FakePaymentRepository();
  return MultiBlocProvider(
    providers: [
      BlocProvider(
          create: (_) => AuthBloc(
              authRepository: authRepo, userRepository: userRepo)),
      BlocProvider(create: (_) => ProfileBloc(userRepository: userRepo)),
      BlocProvider(
          create: (_) => PaymentBloc(paymentRepository: paymentRepo)),
    ],
    child: const BrewMasterApp(),
  );
}

void main() {
  testWidgets('App smoke test: renders without crashing (unauthenticated)',
      (WidgetTester tester) async {
    await tester.pumpWidget(_buildTestApp());
    await tester.pumpAndSettle();

    // Unauthenticated → LoginScreen is shown
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
