import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';

import 'package:brewmaster/data/providers/auth_provider.dart' as app;
import 'package:brewmaster/data/providers/user_provider.dart';
import 'package:brewmaster/data/services/auth_service.dart';
import 'package:brewmaster/data/services/user_service.dart';
import 'package:brewmaster/domain/models/user_profile.dart';
import 'package:brewmaster/presentation/screens/auth/signup_screen.dart';
import 'package:brewmaster/presentation/screens/auth/profile_setup_screen.dart';

// same supporting test classes as profile test
class TestUser implements fb.User {
  @override
  final String uid;
  @override
  final String? email;
  @override
  final bool emailVerified;
  @override
  final List<fb.UserInfo> providerData;

  TestUser({
    required this.uid,
    this.email,
    this.emailVerified = false,
    this.providerData = const [],
  });

  @override
  Future<void> reload() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeFirebaseAuth implements fb.FirebaseAuth {
  final fb.User? _user;
  _FakeFirebaseAuth(this._user);

  @override
  fb.User? get currentUser => _user;

  @override
  Stream<fb.User?> authStateChanges() => Stream.value(_user);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeGoogleSignIn implements GoogleSignIn {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAuthService extends AuthService {
  final fb.User? fakeUser;
  FakeAuthService({this.fakeUser})
    : super(
        auth: _FakeFirebaseAuth(fakeUser),
        googleSignIn: _FakeGoogleSignIn(),
      );

  @override
  fb.User? get currentUser => fakeUser;

  @override
  Stream<fb.User?> get authStateChanges => Stream.value(fakeUser);

  @override
  Future<fb.User?> signUpWithEmail(String email, String password) async {
    // immediately return the fake user so provider.signUp succeeds
    return fakeUser;
  }
}

class _FakeFirebaseFirestore implements FirebaseFirestore {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class CapturingUserService extends UserService {
  UserProfile? lastCreated;

  CapturingUserService() : super(firestore: _FakeFirebaseFirestore());

  @override
  Future<void> createUserProfile(UserProfile profile) async {
    lastCreated = profile;
    // don't call super
  }
}

void main() {
  testWidgets(
    'Email signup jumps to profile setup with provided display name',
    (WidgetTester tester) async {
      final fakeUser = TestUser(uid: 'uid123', email: 'test@example.com');

      final authProvider = app.AuthProvider(
        authService: FakeAuthService(fakeUser: fakeUser),
      )..init();
      final fakeService = CapturingUserService();
      final userProvider = UserProvider(userService: fakeService);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<app.AuthProvider>.value(value: authProvider),
            ChangeNotifierProvider<UserProvider>.value(value: userProvider),
          ],
          child: const MaterialApp(home: SignupScreen()),
        ),
      );

      // fill signup form
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'test@example.com',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'password');
      await tester.enterText(find.byType(TextFormField).at(2), 'password');
      await tester.enterText(find.byType(TextFormField).at(3), 'My Name');

      // tap sign up and wait for navigation
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      // should now be on ProfileSetupScreen (save button present)
      expect(find.byType(ProfileSetupScreen), findsOneWidget);

      // choose role by tapping the buyer card
      await tester.tap(find.text("I'm a Buyer"));
      await tester.pumpAndSettle();

      // fill buyer fields so form valid
      await tester.enterText(find.byType(TextFormField).at(0), 'Acme Coffee');
      await tester.enterText(find.byType(TextFormField).at(1), 'Roaster');
      await tester.enterText(find.byType(TextFormField).at(2), '100');

      await tester.tap(find.text('Save Profile'));
      await tester.pumpAndSettle();

      expect(fakeService.lastCreated, isNotNull);
      expect(fakeService.lastCreated!.displayName, equals('My Name'));
    },
  );
}
