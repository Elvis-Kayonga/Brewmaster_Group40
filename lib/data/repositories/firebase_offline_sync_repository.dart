// Feature: brewmaster-offline-sync
// Firebase implementation of OfflineSyncRepository.
// Uses Firestore as the persistent queue and connectivity_plus for network state.
//
// Requirements: 22.1, 22.2, 22.3
// Developer: Developer 3 (Ryan)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../domain/models/offline_sync_operation.dart';
import '../../domain/repositories/offline_sync_repository.dart';

class FirebaseOfflineSyncRepository implements OfflineSyncRepository {
  final FirebaseFirestore _firestore;
  final Connectivity _connectivity;

  static const _queueCollection = 'offline_sync_queue';
  static const _maxRetries = 3;

  FirebaseOfflineSyncRepository({
    FirebaseFirestore? firestore,
    Connectivity? connectivity,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _connectivity = connectivity ?? Connectivity();

  @override
  Future<void> enqueueOperation(OfflineSyncOperation operation) async {
    await _firestore
        .collection(_queueCollection)
        .doc(operation.id)
        .set(operation.toJson());
  }

  @override
  Future<List<OfflineSyncOperation>> getPendingOperations() async {
    final snapshot = await _firestore
        .collection(_queueCollection)
        .orderBy('timestamp')
        .get();
    return snapshot.docs
        .map((d) => OfflineSyncOperation.fromJson(d.data()))
        .toList();
  }

  @override
  Future<int> processPendingQueue() async {
    final operations = await getPendingOperations();
    int successCount = 0;

    for (final op in operations) {
      if (op.retryCount >= _maxRetries) {
        // Drop permanently failed operations
        await _firestore.collection(_queueCollection).doc(op.id).delete();
        continue;
      }

      try {
        await _applyOperation(op);
        await _firestore.collection(_queueCollection).doc(op.id).delete();
        successCount++;
      } catch (_) {
        // Increment retry count and persist
        await _firestore.collection(_queueCollection).doc(op.id).update({
          'retryCount': op.retryCount + 1,
        });
      }
    }

    return successCount;
  }

  @override
  Future<void> clearQueue() async {
    final snapshot =
        await _firestore.collection(_queueCollection).get();
    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  @override
  Stream<bool> watchConnectivity() {
    return _connectivity.onConnectivityChanged.map(
      (result) =>
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.ethernet,
    );
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  Future<void> _applyOperation(OfflineSyncOperation op) async {
    final ref = _firestore.collection(op.collection).doc(op.documentId);
    switch (op.type) {
      case OfflineSyncOperationType.create:
        await ref.set(op.data);
      case OfflineSyncOperationType.update:
        await ref.update(op.data);
      case OfflineSyncOperationType.delete:
        await ref.delete();
    }
  }
}
