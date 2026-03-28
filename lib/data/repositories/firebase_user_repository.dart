// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:brewmaster/domain/models/user_profile.dart';
import 'package:brewmaster/domain/repositories/user_repository.dart';

/// Firebase/Firestore implementation of [UserRepository].
class FirebaseUserRepository implements UserRepository {
  final FirebaseFirestore _firestore;

  FirebaseUserRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  @override
  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final doc = await _users.doc(userId).get();
      if (!doc.exists || doc.data() == null) return null;
      return UserProfile.fromJson(doc.data()!);
    } catch (e) {
      throw Exception('Failed to get user profile: $e');
    }
  }

  @override
  Future<UserProfile?> getUserProfileByEmail(String email) async {
    try {
      print('[USER_REPO] Looking up profile by email: $email');
      var query = await _users.where('email', isEqualTo: email).limit(1).get();
      print('[USER_REPO] Exact match returned ${query.docs.length} doc(s)');

      if (query.docs.isNotEmpty) {
        return UserProfile.fromJson(query.docs.first.data());
      }

      // Case-insensitive fallback
      print('[USER_REPO] Trying case-insensitive fallback...');
      final all = await _users.get();
      final emailLower = email.toLowerCase();
      for (final doc in all.docs) {
        final profile = UserProfile.fromJson(doc.data());
        if (profile.email.toLowerCase() == emailLower) {
          print('[USER_REPO] ✅ Found via case-insensitive match: ${doc.id}');
          return profile;
        }
      }

      print('[USER_REPO] ❌ No profile found for email: $email');
      return null;
    } catch (e) {
      print('[USER_REPO] ❌ Error: $e');
      throw Exception('Failed to get user profile by email: $e');
    }
  }

  @override
  Future<void> createUserProfile(UserProfile profile) async {
    try {
      await _users.doc(profile.id).set(profile.toJson());
    } catch (e) {
      throw Exception('Failed to create user profile: $e');
    }
  }

  @override
  Future<void> updateUserProfile(
    String userId,
    Map<String, dynamic> updates,
  ) async {
    try {
      print('[USER_REPO] Updating $userId with: $updates');
      await _users.doc(userId).update(updates);
      print('[USER_REPO] ✅ Updated successfully');
    } catch (e) {
      print('[USER_REPO] ❌ Error: $e');
      throw Exception('Failed to update user profile: $e');
    }
  }

  @override
  Stream<UserProfile?> watchUserProfile(String userId) {
    return _users.doc(userId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return UserProfile.fromJson(doc.data()!);
    });
  }

  @override
  Future<void> saveListing(String userId, String listingId) async {
    try {
      await _users.doc(userId).update({
        'savedListings': FieldValue.arrayUnion([listingId]),
      });
    } catch (e) {
      throw Exception('Failed to save listing: $e');
    }
  }

  @override
  Future<void> unsaveListing(String userId, String listingId) async {
    try {
      await _users.doc(userId).update({
        'savedListings': FieldValue.arrayRemove([listingId]),
      });
    } catch (e) {
      throw Exception('Failed to unsave listing: $e');
    }
  }

  @override
  Future<List<String>> getSavedListings(String userId) async {
    try {
      final doc = await _users.doc(userId).get();
      if (!doc.exists || doc.data() == null) return [];
      return List<String>.from(doc.data()!['savedListings'] as List? ?? []);
    } catch (e) {
      return [];
    }
  }

}
