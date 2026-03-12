// lib/data/services/batch_write_service.dart
//
// Firestore batch-write service.
// Splits large write/delete/update payloads into chunks of ≤ 500 operations
// (Firestore's per-batch limit) and commits them sequentially.
//
// Requirements: 14.3, 14.4
// Developer: Developer 6

import 'package:cloud_firestore/cloud_firestore.dart';

/// Executes bulk Firestore operations in chunks of [maxBatchSize] (≤ 500).
class BatchWriteService {
  final FirebaseFirestore _firestore;

  /// Maximum operations per Firestore batch (hard limit is 500).
  static const int maxBatchSize = 500;

  BatchWriteService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Set (create or overwrite) [documents] in [collection].
  ///
  /// Optionally provide [ids] to use as document IDs; otherwise Firestore
  /// auto-generates them. Returns the total number of documents written.
  Future<int> batchSet(
    CollectionReference<Map<String, dynamic>> collection,
    List<Map<String, dynamic>> documents, {
    List<String>? ids,
  }) async {
    int written = 0;
    for (final chunk in _chunk(documents)) {
      final batch = _firestore.batch();
      for (var i = 0; i < chunk.length; i++) {
        final globalIndex = written + i;
        final ref = (ids != null && globalIndex < ids.length)
            ? collection.doc(ids[globalIndex])
            : collection.doc();
        batch.set(ref, chunk[i]);
      }
      await batch.commit();
      written += chunk.length;
    }
    return written;
  }

  /// Delete documents identified by [ids] from [collection].
  /// Returns the number of delete operations committed.
  Future<int> batchDelete(
    CollectionReference<Map<String, dynamic>> collection,
    List<String> ids,
  ) async {
    int deleted = 0;
    for (final chunk in _chunk(ids)) {
      final batch = _firestore.batch();
      for (final id in chunk) {
        batch.delete(collection.doc(id));
      }
      await batch.commit();
      deleted += chunk.length;
    }
    return deleted;
  }

  /// Update [documents] (partial merge) by their [ids] in [collection].
  /// [ids] and [documents] must have the same length.
  /// Returns the number of update operations committed.
  Future<int> batchUpdate(
    CollectionReference<Map<String, dynamic>> collection,
    List<String> ids,
    List<Map<String, dynamic>> documents,
  ) async {
    assert(ids.length == documents.length,
        'ids and documents must have the same length');
    final pairs = List.generate(ids.length, (i) => (ids[i], documents[i]));
    int updated = 0;
    for (final chunk in _chunk(pairs)) {
      final batch = _firestore.batch();
      for (final (id, data) in chunk) {
        batch.update(collection.doc(id), data);
      }
      await batch.commit();
      updated += chunk.length;
    }
    return updated;
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Split [items] into sub-lists of at most [maxBatchSize] elements.
  /// Exposed as static so tests can call it without Firebase.
  static List<List<T>> chunk<T>(List<T> items, [int size = maxBatchSize]) =>
      _chunk(items, size);

  static List<List<T>> _chunk<T>(List<T> items, [int size = maxBatchSize]) {
    if (items.isEmpty) return [];
    final chunks = <List<T>>[];
    for (var i = 0; i < items.length; i += size) {
      chunks.add(items.sublist(
          i, (i + size) < items.length ? i + size : items.length));
    }
    return chunks;
  }
}
