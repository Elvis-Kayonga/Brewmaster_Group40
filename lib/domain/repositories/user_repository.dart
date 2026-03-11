import 'package:brewmaster/domain/models/user_profile.dart';

/// Abstract interface for user profile operations.
abstract class UserRepository {
  /// Get a user profile by Firestore document ID (uid).
  Future<UserProfile?> getUserProfile(String userId);

  /// Lookup a user profile by email address (case-insensitive).
  Future<UserProfile?> getUserProfileByEmail(String email);

  /// Create a new user profile document.
  Future<void> createUserProfile(UserProfile profile);

  /// Partially update a user profile with the given fields.
  Future<void> updateUserProfile(String userId, Map<String, dynamic> updates);

  /// Real-time stream of a user's profile document.
  Stream<UserProfile?> watchUserProfile(String userId);

}
