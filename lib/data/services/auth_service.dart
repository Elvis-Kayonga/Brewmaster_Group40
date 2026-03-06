// ignore_for_file: avoid_print

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Service for handling Firebase authentication operations.
class AuthService {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  AuthService({FirebaseAuth? auth, GoogleSignIn? googleSignIn})
    : _auth = auth ?? FirebaseAuth.instance,
      _googleSignIn = googleSignIn ?? GoogleSignIn();

  /// Stream of auth state changes.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Currently signed-in user, or null.
  User? get currentUser => _auth.currentUser;

  /// Sign up with email and password.
  Future<User?> signUpWithEmail(String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } on FirebaseAuthException catch (e, st) {
      // Log FirebaseAuthException details for debugging
      print('⚠️ signInWithEmail FirebaseAuthException: code=${e.code}, message=${e.message}');
      print(st);
      rethrow;
    } catch (e, st) {
      // Log full exception & stack for debugging unexpected cast/errors
      // so we can see actual Firebase codes returned on device.
      print('⚠️ signInWithEmail caught non-Firebase exception: $e');
      print(st);
      // Rare platform channel casts (Pigeon) can occur even when auth
      // operation actually succeeded (observed in some plugin versions).
      // If that happens, check the current Firebase user as a fallback.
      if (e.toString().contains('PigeonUserDetails') ||
          e.toString().contains('List<Object?>')) {
        print(
          '⚠️ Pigeon cast bug caught during signUp - checking currentUser fallback',
        );
        final user = _auth.currentUser;
        if (user != null) {
          print('✅ Signed up via fallback: ${user.email}');
          return user;
        }
      }
      throw Exception('Sign up failed: $e');
    }
  }

  /// Sign in with email and password.
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } on FirebaseAuthException catch (e, st) {
      // Log FirebaseAuthException details for debugging
      print('⚠️ signInWithEmail FirebaseAuthException: code=${e.code}, message=${e.message}');
      print(st);
      rethrow;
    } catch (e, st) {
      // Log details for debugging
      print('⚠️ signInWithEmail caught non-Firebase exception: $e');
      print(st);
      // Some platform/channel versions occasionally throw Pigeon casting
      // errors where the plugin's platform code returns an unexpected
      // value (e.g. a List<Object?>) which results in a cast error. In
      // that case the auth operation may have actually succeeded — check
      // the current Firebase user as a fallback before failing.
      final err = e.toString();
      if (err.contains('PigeonUserDetails') || err.contains('List<Object?>')) {
        final user = _auth.currentUser;
        if (user != null) return user;
      }
      throw Exception('Sign in failed: $e');
    }
  }

  /// Sign in with Google.
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // User cancelled

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      print('✅ Signed in: ${userCredential.user?.email}');
      return userCredential.user;
    } on FirebaseAuthException catch (e, st) {
      // Log FirebaseAuthException for debugging
      print('⚠️ signInWithGoogle FirebaseAuthException: code=${e.code}, message=${e.message}');
      print(st);
      rethrow;
    } catch (e, st) {
      // Log other exceptions too
      print('⚠️ signInWithGoogle caught non-Firebase exception: $e');
      print(st);
      // Known google_sign_in Pigeon bug - auth succeeds but return cast fails
      // Firebase auth already completed so check currentUser directly
      if (e.toString().contains('PigeonUserDetails') ||
          e.toString().contains('List<Object?>')) {
        print('⚠️ Pigeon cast bug caught - checking currentUser fallback');
        final user = _auth.currentUser;
        if (user != null) {
          print('✅ Signed in via fallback: ${user.email}');
          return user; // auth succeeded, return current user
        }
      }
      throw Exception('Google sign-in failed: $e');
    }
  }
  /// Sign out from all providers.
  Future<void> signOut() async {
    try {
      await Future.wait([_auth.signOut(), _googleSignIn.signOut()]);
    } catch (e) {
      throw Exception('Sign out failed: $e');
    }
  }

  /// Send password reset email.
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw Exception('Password reset failed: $e');
    }
  }

  /// Send an email verification link to the currently signed-in user.
  /// Send an email verification link to the currently signed-in user.
  ///
  /// Returns `true` if a network request was made to Firebase to send a
  /// verification email.  If there is no signed-in user or if the user's
  /// email is already marked verified, nothing is sent and the method returns
  /// `false` (no exception is thrown in those cases).
  Future<bool> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        // nothing to do
        print('⚠️ sendEmailVerification called with no current user');
        return false;
      }
      if (user.emailVerified) {
        // already verified, Firebase will not send another link
        print('⚠️ sendEmailVerification: user already verified');
        return false;
      }
      await user.sendEmailVerification();
      print('📧 Verification email requested for ${user.email}');
      return true;
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw Exception('Send email verification failed: $e');
    }
  }

  /// Reload the current user and return whether their email is verified.
  Future<bool> isEmailVerified() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;
      await user.reload();
      return _auth.currentUser?.emailVerified ?? false;
    } catch (e) {
      throw Exception('Check email verification failed: $e');
    }
  }

  /// Check an email action code to get information about it.
  Future<String?> checkActionCode(String code) async {
    try {
      print('[AUTH_SERVICE] Checking action code...');
      final info = await _auth.checkActionCode(code);
      print('[AUTH_SERVICE] Action code operation: ${info.operation}');
      print('[AUTH_SERVICE] Action code data keys: ${info.data.keys}');
      // Only handle email verification actions
      if (info.operation == ActionCodeInfoOperation.verifyEmail) {
        final email = info.data['email'] as String?;
        print('[AUTH_SERVICE] ✅ Email from action code: $email');
        return email;
      }
      print('[AUTH_SERVICE] ❌ Not a verification action, operation: ${info.operation}');
      return null;
    } on FirebaseAuthException catch (e) {
      print('[AUTH_SERVICE] ❌ FirebaseAuthException checking action code: code=${e.code}, message=${e.message}');
      rethrow;
    } catch (e) {
      print('[AUTH_SERVICE] ❌ Exception checking action code: $e');
      throw Exception('Check action code failed: $e');
    }
  }

  /// Apply an email action code (e.g. an email verification oobCode).
  Future<void> applyActionCode(String code) async {
    try {
      print('[AUTH_SERVICE] Applying action code...');
      await _auth.applyActionCode(code);
      print('[AUTH_SERVICE] ✅ Action code applied successfully');
    } on FirebaseAuthException catch (e) {
      print('[AUTH_SERVICE] ❌ FirebaseAuthException applying action code: code=${e.code}, message=${e.message}');
      rethrow;
    } catch (e) {
      print('[AUTH_SERVICE] ❌ Exception applying action code: $e');
      throw Exception('Apply action code failed: $e');
    }
  }
}
