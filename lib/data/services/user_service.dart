// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:brewmaster/domain/models/user_profile.dart';

/// Service for managing user profiles in Firestore.
class UserService {
  final FirebaseFirestore _firestore;

  UserService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  /// Get a user profile by email (case-insensitive).
  Future<UserProfile?> getUserProfileByEmail(String email) async {
    try {
      print('[USER_SERVICE] Looking up profile by email: $email');
      // Try exact match first
      var query = await _usersCollection.where('email', isEqualTo: email).limit(1).get();
      print('[USER_SERVICE] Exact match query returned ${query.docs.length} document(s)');
      
      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        print('[USER_SERVICE] ✅ Found profile (exact match) - Doc ID: ${doc.id}');
        return UserProfile.fromJson(doc.data());
      }

      // Try case-insensitive match by querying all and filtering
      print('[USER_SERVICE] Exact match not found, trying case-insensitive...');
      query = await _usersCollection.get();
      print('[USER_SERVICE] Total users in collection: ${query.docs.length}');
      
      final emailLower = email.toLowerCase();
      for (final doc in query.docs) {
        final profile = UserProfile.fromJson(doc.data());
        if (profile.email.toLowerCase() == emailLower) {
          print('[USER_SERVICE] ✅ Found profile (case-insensitive) - Doc ID: ${doc.id}, Stored email: ${profile.email}');
          return profile;
        }
      }
      
      print('[USER_SERVICE] ❌ No profile found for email: $email (tried both exact and case-insensitive)');
      return null;
    } catch (e) {
      print('[USER_SERVICE] ❌ Error getting profile by email: $e');
      throw Exception('Failed to get user profile by email: $e');
    }
  }

  /// Get a user profile by ID.
  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final doc = await _usersCollection.doc(userId).get();
      if (!doc.exists || doc.data() == null) return null;
      return UserProfile.fromJson(doc.data()!);
    } catch (e) {
      throw Exception('Failed to get user profile: $e');
    }
  }

  /// Create a new user profile.
  Future<void> createUserProfile(UserProfile profile) async {
    try {
      await _usersCollection.doc(profile.id).set(profile.toJson());
    } catch (e) {
      throw Exception('Failed to create user profile: $e');
    }
  }

  /// Update an existing user profile.
  Future<void> updateUserProfile(
    String userId,
    Map<String, dynamic> updates,
  ) async {
    try {
      print('[USER_SERVICE] Updating profile $userId with: $updates');
      await _usersCollection.doc(userId).update(updates);
      print('[USER_SERVICE] ✅ Profile updated successfully for $userId');
    } catch (e) {
      print('[USER_SERVICE] ❌ Error updating profile: $e');
      throw Exception('Failed to update user profile: $e');
    }
  }

  /// Watch a user profile for real-time updates.
  Stream<UserProfile?> watchUserProfile(String userId) {
    return _usersCollection.doc(userId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return UserProfile.fromJson(doc.data()!);
    });
  }
}
