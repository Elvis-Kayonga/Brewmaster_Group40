import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:brewmaster/domain/models/user_profile.dart';
import '../services/user_service.dart';

/// Provider for managing user profile state.
class UserProvider extends ChangeNotifier {
  final UserService _userService;

  UserProvider({UserService? userService})
    : _userService = userService ?? UserService();

  // State
  UserProfile? _userProfile;
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription? _profileSubscription;

  // Getters
  UserProfile? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Load a user profile by ID.
  Future<void> loadProfile(String userId) async {
    _setLoading(true);
    _clearError();
    try {
      _userProfile = await _userService.getUserProfile(userId);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load profile: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Create a new user profile.
  Future<bool> createProfile(UserProfile profile) async {
    _setLoading(true);
    _clearError();
    try {
      await _userService.createUserProfile(profile);
      _userProfile = profile;
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to create profile: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Update an existing user profile.
  Future<bool> updateProfile(
    String userId,
    Map<String, dynamic> updates,
  ) async {
    _setLoading(true);
    _clearError();
    try {
      await _userService.updateUserProfile(userId, updates);
      // Reload profile to get updated data
      _userProfile = await _userService.getUserProfile(userId);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to update profile: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Watch a user profile for real-time updates.
  void watchProfile(String userId) {
    _profileSubscription?.cancel();
    _profileSubscription = _userService
        .watchUserProfile(userId)
        .listen(
          (profile) {
            _userProfile = profile;
            notifyListeners();
          },
          onError: (e) {
            _setError('Failed to watch profile: $e');
          },
        );
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

  @override
  void dispose() {
    _profileSubscription?.cancel();
    super.dispose();
  }
}
