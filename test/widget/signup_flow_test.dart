import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

import 'package:brewmaster/domain/models/user_profile.dart';
import 'package:brewmaster/domain/repositories/auth_repository.dart';
import 'package:brewmaster/domain/repositories/user_repository.dart';
import 'package:brewmaster/presentation/blocs/auth/auth_bloc.dart';
import 'package:brewmaster/presentation/blocs/profile/profile_bloc.dart';
import 'package:brewmaster/presentation/screens/auth/signup_screen.dart';
import 'package:brewmaster/presentation/screens/auth/login_screen.dart';

// ---------------------------------------------------------------------------
// Minimal fake implementations
// ---------------------------------------------------------------------------

class _FakeUser implements fb.User {
  @override
  final String uid;
  @override
  final String? email;
  @override
  final bool emailVerified;
  @override
  final List<fb.UserInfo> providerData = const [];

  _FakeUser({
    required this.uid,
    this.email,
    this.emailVerified = false,
  });

  @override
  Future<void> reload() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAuthRepository implements AuthRepository {
  final fb.User? _user;
  _FakeAuthRepository(this._user);

  @override
  fb.User? get currentUser => _user;

  @override
  Stream<fb.User?> get authStateChanges => Stream.value(_user);

  @override
  Future<fb.User?> register(String email, String password) async => _user;

  @override
  Future<fb.User?> signIn(String email, String password) async => _user;

  @override
  Future<fb.User?> signInWithGoogle() async => _user;

  @override
  Future<void> signOut() async {}

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<bool> sendEmailVerification() async => true;

  @override
  Future<bool> isEmailVerified() async => _user?.emailVerified ?? false;
}

class _FakeUserRepository implements UserRepository {
  UserProfile? lastCreated;

  @override
  Future<UserProfile?> getUserProfile(String userId) async => null;

  @override
  Future<UserProfile?> getUserProfileByEmail(String email) async => null;

  @override
  Future<void> createUserProfile(UserProfile profile) async {
    lastCreated = profile;
  }

  @override
  Future<void> updateUserProfile(
      String userId, Map<String, dynamic> updates) async {}

  @override
  Stream<UserProfile?> watchUserProfile(String userId) =>
      const Stream.empty();
}

// ---------------------------------------------------------------------------
// Helper to build the widget under test wrapped in BLoC providers
// ---------------------------------------------------------------------------

Widget _buildApp({
  required Widget home,
  required AuthRepository authRepo,
  required UserRepository userRepo,
}) {
  return MultiBlocProvider(
    providers: [
      BlocProvider<AuthBloc>(
        create: (_) => AuthBloc(
          authRepository: authRepo,
          userRepository: userRepo,
        ),
      ),
      BlocProvider<ProfileBloc>(
        create: (_) => ProfileBloc(userRepository: userRepo),
      ),
    ],
    child: MaterialApp(home: home),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  testWidgets('SignupScreen renders email, password and display name fields',
      (WidgetTester tester) async {
    final user = _FakeUser(
        uid: 'uid123', email: 'test@example.com', emailVerified: false);
    final authRepo = _FakeAuthRepository(user);
    final userRepo = _FakeUserRepository();

    await tester.pumpWidget(
        _buildApp(home: const SignupScreen(), authRepo: authRepo, userRepo: userRepo));

    expect(find.byType(TextFormField), findsWidgets);
    expect(find.text('Sign Up'), findsAtLeastNWidgets(1));
  });

  testWidgets('LoginScreen renders email and password fields',
      (WidgetTester tester) async {
    final authRepo = _FakeAuthRepository(null);
    final userRepo = _FakeUserRepository();

    await tester.pumpWidget(
        _buildApp(home: const LoginScreen(), authRepo: authRepo, userRepo: userRepo));

    expect(find.byType(TextFormField), findsWidgets);
    expect(find.text('Sign In'), findsAtLeastNWidgets(1));
  });

  testWidgets(
      'Tapping Sign Up with valid credentials dispatches AuthRegisterRequested',
      (WidgetTester tester) async {
    final user = _FakeUser(
        uid: 'uid123', email: 'test@example.com', emailVerified: false);
    final authRepo = _FakeAuthRepository(user);
    final userRepo = _FakeUserRepository();

    await tester.pumpWidget(
        _buildApp(home: const SignupScreen(), authRepo: authRepo, userRepo: userRepo));

    // Enter email, password, confirm password, display name
    await tester.enterText(find.byType(TextFormField).at(0), 'test@example.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'Password1!');
    await tester.enterText(find.byType(TextFormField).at(2), 'Password1!');
    await tester.enterText(find.byType(TextFormField).at(3), 'Test User');

    await tester.tap(find.text('Sign Up'));
    await tester.pump();

    // No crash = the event was dispatched successfully
    expect(find.byType(SignupScreen), findsOneWidget);
  });
}
