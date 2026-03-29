// Smoke test: verifies the app's unauthenticated entry point renders correctly.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:brewmaster/config/localization/app_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

import 'package:brewmaster/domain/repositories/auth_repository.dart';
import 'package:brewmaster/domain/repositories/user_repository.dart';
import 'package:brewmaster/presentation/blocs/auth/auth_bloc.dart';
import 'package:brewmaster/presentation/blocs/profile/profile_bloc.dart';
import 'package:brewmaster/presentation/screens/auth/auth_gate.dart';
import 'package:brewmaster/presentation/screens/auth/login_screen.dart';

class _FakeAuthRepository implements AuthRepository {
  @override
  fb.User? get currentUser => null;
  @override
  Stream<fb.User?> get authStateChanges => Stream.value(null);
  @override
  Future<fb.User?> register(String e, String p) async => null;
  @override
  Future<fb.User?> signIn(String e, String p) async => null;
  @override
  Future<fb.User?> signInWithGoogle() async => null;
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
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);

  @override
  Future<void> saveListing(String userId, String listingId) async {}

  @override
  Future<void> unsaveListing(String userId, String listingId) async {}

  @override
  Future<List<String>> getSavedListings(String userId) async => [];
}

void main() {
  testWidgets('Smoke test: unauthenticated app shows AuthGate and LoginScreen',
      (WidgetTester tester) async {
    final authRepo = _FakeAuthRepository();
    final userRepo = _FakeUserRepository();

    await tester.pumpWidget(
      MultiBlocProvider(
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
        child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: AuthGate()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AuthGate), findsOneWidget);
    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
