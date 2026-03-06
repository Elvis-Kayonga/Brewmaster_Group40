import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';

/// Provider for managing authentication state.
class AuthProvider extends ChangeNotifier {
  final AuthService _authService;

  AuthProvider({AuthService? authService})
    : _authService = authService ?? AuthService();

  // State
  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  /// Stream of auth state changes.
  Stream<User?> get authStateChanges => _authService.authStateChanges;

  /// Initialize by checking current auth state.
  void init() {
    _currentUser = _authService.currentUser;
    _authService.authStateChanges.listen((user) {
      _currentUser = user;
      notifyListeners();
    });
    // perform an initial reload to ensure the local user is still valid
    // particularly useful when the user record may have been removed from
    // Firebase console while the app is running (e.g. during debugging).
    _refreshCurrentUser();
  }

  /// Reloads the underlying Firebase user and updates state accordingly.
  ///
  /// If the user has been deleted on the server the reload call will throw
  /// and we treat that as a sign-out (currentUser becomes null).
  Future<void> _refreshCurrentUser() async {
    try {
      final u = _authService.currentUser;
      if (u != null) {
        await u.reload();
        _currentUser = _authService.currentUser;
        notifyListeners();
      }
    } catch (e) {
      // Only clear state if the error indicates the user was deleted on the
      // server.  Other failures (network glitches, etc.) should not log the
      // user out immediately; we simply ignore them and leave the current
      // user intact.
      if (e is FirebaseAuthException && e.code == 'user-not-found') {
        _currentUser = null;
        notifyListeners();
      } else {
        // non-fatal reload error; just log for debugging
        // ignore: avoid_print
        print('AuthProvider.refresh: reload error (ignored): $e');
      }
    }
  }

  /// Public wrapper which can be called by external widgets to refresh the
  /// authentication state (e.g. before routing decisions).
  Future<void> refresh() => _refreshCurrentUser();

  /// Sign up with email and password.
  Future<bool> signUp(String email, String password) async {
    _setLoading(true);
    _clearError();
    try {
      _currentUser = await _authService.signUpWithEmail(email, password);
      notifyListeners();
      return _currentUser != null;
    } on FirebaseAuthException catch (e) {
      _setError(_mapFirebaseError(e));
      return false;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Sign in with email and password.
  Future<bool> signIn(String email, String password) async {
    _setLoading(true);
    _clearError();
    try {
      _currentUser = await _authService.signInWithEmail(email, password);
      notifyListeners();
      return _currentUser != null;
    } on FirebaseAuthException catch (e) {
      _setError(_mapFirebaseError(e));
      return false;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Sign in with Google.
  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _clearError();
    try {
      _currentUser = await _authService.signInWithGoogle();
      notifyListeners();
      return _currentUser != null;
    } on FirebaseAuthException catch (e) {
      _setError(_mapFirebaseError(e));
      return false;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Sign out.
  Future<void> signOut() async {
    _setLoading(true);
    _clearError();
    try {
      await _authService.signOut();
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  /// Send password reset email.
  Future<bool> sendPasswordResetEmail(String email) async {
    _setLoading(true);
    _clearError();
    try {
      await _authService.sendPasswordResetEmail(email);
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_mapFirebaseError(e));
      return false;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Send an email verification to the currently signed-in user.
  Future<bool> sendEmailVerification() async {
    _setLoading(true);
    _clearError();
    try {
      final sent = await _authService.sendEmailVerification();
      if (!sent) {
        // either there was no user or the email was already verified
        _setError(
          'No verification email sent (already verified or not signed in)',
        );
      }
      return sent;
    } on FirebaseAuthException catch (e) {
      _setError(_mapFirebaseError(e));
      return false;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Check if the current user's email is verified (reloads user state).
  Future<bool> checkEmailVerified() async {
    _setLoading(true);
    _clearError();
    try {
      final verified = await _authService.isEmailVerified();
      await _refreshCurrentUser();
      return verified;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Check an email action code to get the associated email.
  Future<String?> checkEmailActionCode(String code) async {
    _setLoading(true);
    _clearError();
    try {
      return await _authService.checkActionCode(code);
    } on FirebaseAuthException catch (e) {
      _setError(_mapFirebaseError(e));
      return null;
    } catch (e) {
      _setError(e.toString());
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Apply an email action code (for example an oobCode from an email link).
  Future<bool> applyEmailActionCode(String code) async {
    _setLoading(true);
    _clearError();
    try {
      await _authService.applyActionCode(code);
      await _refreshCurrentUser();
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_mapFirebaseError(e));
      return false;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Clear error message.
  void clearError() {
    _clearError();
    notifyListeners();
  }

  // Helpers
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  String _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'invalid-action-code':
        return 'Verification link is invalid or malformed.';
      case 'expired-action-code':
        return 'Verification link has expired. Request a new email.';
      default:
        return e.message ?? 'An authentication error occurred.';
    }
  }
}
