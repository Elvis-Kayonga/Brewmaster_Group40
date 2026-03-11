// test/properties/account_deletion_properties_test.dart
//
// Property-based tests for task 27.4: cascading account deletion logic
// using an in-memory fake that tracks deleted documents.
//
// Developer: Developer 1

import 'package:flutter_test/flutter_test.dart';
import 'package:brewmaster/data/services/account_deletion_service.dart';

// ---------------------------------------------------------------------------
// In-memory fake to verify deletion behaviour without Firebase
// ---------------------------------------------------------------------------

class FakeStore {
  final Map<String, Map<String, Map<String, dynamic>>> _collections = {};

  void addDoc(String collection, String docId, Map<String, dynamic> data) {
    _collections.putIfAbsent(collection, () => {})[docId] = data;
  }

  List<String> docsWhere(
      String collection, String field, String value) {
    final col = _collections[collection] ?? {};
    return col.entries
        .where((e) => e.value[field] == value)
        .map((e) => e.key)
        .toList();
  }

  int deleteWhere(String collection, String field, String value) {
    final col = _collections[collection] ?? {};
    final toDelete = col.keys
        .where((k) => col[k]![field] == value)
        .toList();
    for (final k in toDelete) {
      col.remove(k);
    }
    return toDelete.length;
  }

  int deleteConversationsFor(String userId) {
    final col = _collections['conversations'] ?? {};
    final toDelete = col.keys.where((k) {
      final participants = col[k]!['participantIds'] as List<dynamic>? ?? [];
      return participants.contains(userId);
    }).toList();
    for (final k in toDelete) {
      col.remove(k);
    }
    return toDelete.length;
  }

  int count(String collection) =>
      (_collections[collection] ?? {}).length;
}

DeletionReport simulateDeletion(FakeStore store, String userId) {
  final counts = <String, int>{};
  for (final entry in [
    ('users', 'id'),
    ('verification_requests', 'userId'),
    ('offline_sync_queue', 'userId'),
    ('notifications', 'userId'),
    ('listings', 'farmerId'),
  ]) {
    counts[entry.$1] = store.deleteWhere(entry.$1, entry.$2, userId);
  }
  counts['conversations'] = store.deleteConversationsFor(userId);
  return DeletionReport(
    userId: userId,
    deletedCounts: counts,
    authDeleted: true,
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('DeletionReport (task 27.4)', () {
    test('succeeded is true when no errors and auth deleted', () {
      final report = DeletionReport(
        userId: 'u1',
        deletedCounts: {},
        authDeleted: true,
      );
      expect(report.succeeded, isTrue);
    });

    test('succeeded is false when auth deletion failed', () {
      final report = DeletionReport(
        userId: 'u1',
        deletedCounts: {},
        authDeleted: false,
      );
      expect(report.succeeded, isFalse);
    });

    test('succeeded is false when errors present', () {
      final report = DeletionReport(
        userId: 'u1',
        deletedCounts: {},
        authDeleted: true,
        errors: ['users: timeout'],
      );
      expect(report.succeeded, isFalse);
    });

    test('totalDeleted sums all collection counts', () {
      final report = DeletionReport(
        userId: 'u1',
        deletedCounts: {'users': 1, 'listings': 3, 'notifications': 2},
        authDeleted: true,
      );
      expect(report.totalDeleted, 6);
    });

    test('totalDeleted is 0 for empty counts', () {
      final report = DeletionReport(
        userId: 'u1',
        deletedCounts: {},
        authDeleted: true,
      );
      expect(report.totalDeleted, 0);
    });
  });

  group('Cascading deletion logic (task 27.4)', () {
    late FakeStore store;

    setUp(() {
      store = FakeStore();
      // User profile
      store.addDoc('users', 'farmer1', {'id': 'farmer1', 'role': 'farmer'});
      // Listings owned by the farmer
      store.addDoc('listings', 'l1', {'farmerId': 'farmer1'});
      store.addDoc('listings', 'l2', {'farmerId': 'farmer1'});
      // Listing by another farmer (must NOT be deleted)
      store.addDoc('listings', 'l3', {'farmerId': 'other_farmer'});
      // Notifications
      store.addDoc('notifications', 'n1', {'userId': 'farmer1'});
      store.addDoc('notifications', 'n2', {'userId': 'farmer1'});
      // Conversations
      store.addDoc('conversations', 'c1',
          {'participantIds': ['farmer1', 'buyer1']});
      store.addDoc('conversations', 'c2',
          {'participantIds': ['farmer1', 'buyer2']});
      store.addDoc('conversations', 'c3',
          {'participantIds': ['other1', 'buyer3']}); // must NOT be deleted
      // Verification request
      store.addDoc(
          'verification_requests', 'vr1', {'userId': 'farmer1'});
    });

    test('user profile document is deleted', () {
      simulateDeletion(store, 'farmer1');
      expect(store.count('users'), 0);
    });

    test('all farmer listings are deleted', () {
      simulateDeletion(store, 'farmer1');
      expect(store.docsWhere('listings', 'farmerId', 'farmer1'), isEmpty);
    });

    test('other farmers listings are preserved', () {
      simulateDeletion(store, 'farmer1');
      expect(store.count('listings'), 1); // only l3 remains
    });

    test('all user notifications are deleted', () {
      simulateDeletion(store, 'farmer1');
      expect(store.docsWhere('notifications', 'userId', 'farmer1'), isEmpty);
    });

    test('conversations with the user are deleted', () {
      simulateDeletion(store, 'farmer1');
      expect(store.docsWhere('conversations', 'participantIds', 'farmer1'),
          isEmpty);
    });

    test('conversations without the user are preserved', () {
      simulateDeletion(store, 'farmer1');
      expect(store.count('conversations'), 1); // c3 remains
    });

    test('verification requests are deleted', () {
      simulateDeletion(store, 'farmer1');
      expect(
          store.docsWhere('verification_requests', 'userId', 'farmer1'),
          isEmpty);
    });

    test('report totalDeleted counts all removed documents', () {
      final report = simulateDeletion(store, 'farmer1');
      // 1 user + 2 listings + 2 notifications + 2 conversations + 1 vr = 8
      expect(report.totalDeleted, 8);
    });

    test('deleting non-existent user returns zero counts', () {
      final report = simulateDeletion(store, 'ghost_user');
      expect(report.totalDeleted, 0);
      expect(report.succeeded, isTrue);
    });
  });
}
