// Feature: brewmaster-offline-sync
// Abstract repository for offline operation queuing and connectivity monitoring.
//
// Requirements: 22.1, 22.2, 22.3
// Developer: Developer 3 (Ryan)

import '../models/offline_sync_operation.dart';

abstract class OfflineSyncRepository {
  /// Queue an operation to be replayed when connectivity returns.
  Future<void> enqueueOperation(OfflineSyncOperation operation);

  /// Process all pending operations in FIFO order.
  /// Returns the number of operations successfully processed.
  Future<int> processPendingQueue();

  /// Remove all pending operations from the queue.
  Future<void> clearQueue();

  /// Stream that emits true when the device is online, false when offline.
  Stream<bool> watchConnectivity();

  /// Returns all pending operations ordered by timestamp ascending.
  Future<List<OfflineSyncOperation>> getPendingOperations();
}
