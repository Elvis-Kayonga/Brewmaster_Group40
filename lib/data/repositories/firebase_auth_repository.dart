// ignore_for_file: avoid_print

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:brewmaster/domain/repositories/auth_repository.dart';

/// Firebase implementation of [AuthRepository].
class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  FirebaseAuthRepository({FirebaseAuth? auth, GoogleSignIn? googleSignIn})
      : _auth = auth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  @override
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  @override
  User? get currentUser => _auth.currentUser;

  @override
  Future<User?> register(String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } on FirebaseAuthException catch (e, st) {
      print('⚠️ register FirebaseAuthException: code=${e.code}, message=${e.message}');
      print(st);
      rethrow;
    } catch (e, st) {
      print('⚠️ register caught non-Firebase exception: $e');
      print(st);
      // Pigeon cast bug: auth may have succeeded despite the error
      if (e.toString().contains('PigeonUserDetails') ||
          e.toString().contains('List<Object?>')) {
        print('⚠️ Pigeon cast bug caught during register - checking currentUser fallback');
        final user = _auth.currentUser;
        if (user != null) {
          print('✅ Registered via fallback: ${user.email}');
          return user;
        }
      }
      throw Exception('Sign up failed: $e');
    }
  }

  @override
  Future<User?> signIn(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } on FirebaseAuthException catch (e, st) {
      print('⚠️ signIn FirebaseAuthException: code=${e.code}, message=${e.message}');
      print(st);
      rethrow;
    } catch (e, st) {
      print('⚠️ signIn caught non-Firebase exception: $e');
      print(st);
      final err = e.toString();
      if (err.contains('PigeonUserDetails') || err.contains('List<Object?>')) {
        final user = _auth.currentUser;
        if (user != null) return user;
      }
      throw Exception('Sign in failed: $e');
    }
  }

  @override
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      print('✅ Google sign-in: ${userCredential.user?.email}');
      return userCredential.user;
    } on FirebaseAuthException catch (e, st) {
      print('⚠️ signInWithGoogle FirebaseAuthException: code=${e.code}, message=${e.message}');
      print(st);
      rethrow;
    } catch (e, st) {
      print('⚠️ signInWithGoogle caught non-Firebase exception: $e');
      print(st);
      if (e.toString().contains('PigeonUserDetails') ||
          e.toString().contains('List<Object?>')) {
        print('⚠️ Pigeon cast bug caught - checking currentUser fallback');
        final user = _auth.currentUser;
        if (user != null) {
          print('✅ Google sign-in via fallback: ${user.email}');
          return user;
        }
      }
      throw Exception('Google sign-in failed: $e');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await Future.wait([_auth.signOut(), _googleSignIn.signOut()]);
    } catch (e) {
      throw Exception('Sign out failed: $e');
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw Exception('Password reset failed: $e');
    }
  }

  @override
  Future<bool> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('⚠️ sendEmailVerification: no current user');
        return false;
      }
      if (user.emailVerified) {
        print('⚠️ sendEmailVerification: user already verified');
        return false;
      }
      await user.sendEmailVerification();
      print('📧 Verification email sent to ${user.email}');
      return true;
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw Exception('Send email verification failed: $e');
    }
  }

  @override
  Future<bool> isEmailVerified() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    // Step 1: reload fetches fresh user data from Firebase servers
    try {
      await user.reload();
    } catch (_) {}
    // Step 2: force-refresh the ID token — on Android this is the reliable
    // way to flush the cached emailVerified flag after reload
    try {
      await _auth.currentUser?.getIdToken(true);
    } catch (_) {}
    return _auth.currentUser?.emailVerified ?? false;
  }
}
