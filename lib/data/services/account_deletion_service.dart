// Feature: brewmaster-security
// Service for cascading account deletion — removes all user-owned data across
// every Firestore collection before deleting the Firebase Auth account.
//
// Requirements: 13.3, 13.5
// Developer: Developer 1

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Summary returned after a deletion attempt.
class DeletionReport {
  final String userId;
  final Map<String, int> deletedCounts; // collection → number of docs deleted
  final bool authDeleted;
  final List<String> errors;

  const DeletionReport({
    required this.userId,
    required this.deletedCounts,
    required this.authDeleted,
    this.errors = const [],
  });

  bool get succeeded => errors.isEmpty && authDeleted;

  int get totalDeleted =>
      deletedCounts.values.fold(0, (acc, n) => acc + n);
}

class AccountDeletionService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  AccountDeletionService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  /// Delete all data for [userId] and remove the Firebase Auth account.
  Future<DeletionReport> deleteAccount(String userId) async {
    final counts = <String, int>{};
    final errors = <String>[];

    // Collections with direct userId ownership
    final ownedCollections = [
      ('users', 'id'),
      ('verification_requests', 'userId'),
      ('offline_sync_queue', 'userId'),
      ('notifications', 'userId'),
    ];

    for (final (collection, field) in ownedCollections) {
      try {
        counts[collection] =
            await _deleteWhere(collection, field, userId);
      } catch (e) {
        errors.add('$collection: $e');
      }
    }

    // Listings owned by farmer
    try {
      counts['listings'] =
          await _deleteWhere('listings', 'farmerId', userId);
    } catch (e) {
      errors.add('listings: $e');
    }

    // Conversations where user is a participant (delete whole conv + messages)
    try {
      counts['conversations'] =
          await _deleteConversations(userId);
    } catch (e) {
      errors.add('conversations: $e');
    }

    // Delete Firebase Auth account
    bool authDeleted = false;
    try {
      final user = _auth.currentUser;
      if (user != null && user.uid == userId) {
        await user.delete();
        authDeleted = true;
      }
    } catch (e) {
      errors.add('auth: $e');
    }

    return DeletionReport(
      userId: userId,
      deletedCounts: counts,
      authDeleted: authDeleted,
      errors: errors,
    );
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  Future<int> _deleteWhere(
      String collection, String field, String value) async {
    int count = 0;
    QuerySnapshot snapshot;
    do {
      snapshot = await _firestore
          .collection(collection)
          .where(field, isEqualTo: value)
          .limit(500)
          .get();
      if (snapshot.docs.isEmpty) break;
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      count += snapshot.docs.length;
    } while (snapshot.docs.length == 500);
    return count;
  }

  Future<int> _deleteConversations(String userId) async {
    int count = 0;
    final snapshot = await _firestore
        .collection('conversations')
        .where('participantIds', arrayContains: userId)
        .get();

    for (final conv in snapshot.docs) {
      // Delete all messages in the conversation first
      await _deleteSubcollection(conv.reference, 'messages');
      await conv.reference.delete();
      count++;
    }
    return count;
  }

  Future<void> _deleteSubcollection(
      DocumentReference parent, String subcollection) async {
    QuerySnapshot snapshot;
    do {
      snapshot =
          await parent.collection(subcollection).limit(500).get();
      if (snapshot.docs.isEmpty) break;
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } while (snapshot.docs.length == 500);
  }
}
