// test/properties/offline_sync_properties_test.dart
//
// Property-based tests for tasks 22.2: OfflineSyncOperation model and
// OfflineSyncRepository queue behaviour using an in-memory fake.
//
// Developer: Developer 3 (Ryan)

import 'package:flutter_test/flutter_test.dart';
import 'package:brewmaster/domain/models/offline_sync_operation.dart';
import 'package:brewmaster/domain/repositories/offline_sync_repository.dart';

// ---------------------------------------------------------------------------
// In-memory fake repository
// ---------------------------------------------------------------------------

class _InMemoryOfflineSyncRepository implements OfflineSyncRepository {
  final List<OfflineSyncOperation> _queue = [];
  bool _isOnline = true;

  void setOnline(bool value) => _isOnline = value;

  @override
  Future<void> enqueueOperation(OfflineSyncOperation operation) async {
    _queue.add(operation);
  }

  @override
  Future<List<OfflineSyncOperation>> getPendingOperations() async {
    final sorted = List<OfflineSyncOperation>.from(_queue)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return sorted;
  }

  @override
  Future<int> processPendingQueue() async {
    if (!_isOnline) return 0;
    final count = _queue.length;
    _queue.clear();
    return count;
  }

  @override
  Future<void> clearQueue() async => _queue.clear();

  @override
  Stream<bool> watchConnectivity() => Stream.value(_isOnline);
}

// ---------------------------------------------------------------------------
// Helper factories
// ---------------------------------------------------------------------------

OfflineSyncOperation _makeOp({
  String id = 'op1',
  OfflineSyncOperationType type = OfflineSyncOperationType.create,
  String collection = 'listings',
  String documentId = 'doc1',
  Map<String, dynamic>? data,
  DateTime? timestamp,
  int retryCount = 0,
}) =>
    OfflineSyncOperation(
      id: id,
      type: type,
      collection: collection,
      documentId: documentId,
      data: data ?? {'field': 'value'},
      timestamp: timestamp ?? DateTime(2024, 1, 1),
      retryCount: retryCount,
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('OfflineSyncOperation serialization (task 22.2)', () {
    test('toJson() round-trips through fromJson() for create', () {
      final op = _makeOp(type: OfflineSyncOperationType.create);
      final json = op.toJson();
      final restored = OfflineSyncOperation.fromJson(json);
      expect(restored.id, op.id);
      expect(restored.type, OfflineSyncOperationType.create);
      expect(restored.collection, op.collection);
      expect(restored.documentId, op.documentId);
      expect(restored.retryCount, op.retryCount);
    });

    test('toJson() round-trips through fromJson() for update', () {
      final op = _makeOp(type: OfflineSyncOperationType.update, id: 'op2');
      final restored = OfflineSyncOperation.fromJson(op.toJson());
      expect(restored.type, OfflineSyncOperationType.update);
    });

    test('toJson() round-trips through fromJson() for delete', () {
      final op = _makeOp(type: OfflineSyncOperationType.delete, id: 'op3');
      final restored = OfflineSyncOperation.fromJson(op.toJson());
      expect(restored.type, OfflineSyncOperationType.delete);
    });

    test('timestamp is preserved as ISO-8601 through serialization', () {
      final ts = DateTime(2024, 6, 15, 10, 30, 0);
      final op = _makeOp(timestamp: ts);
      final restored = OfflineSyncOperation.fromJson(op.toJson());
      expect(restored.timestamp.toIso8601String(), ts.toIso8601String());
    });

    test('retryCount is preserved through serialization', () {
      final op = _makeOp(retryCount: 2);
      final restored = OfflineSyncOperation.fromJson(op.toJson());
      expect(restored.retryCount, 2);
    });

    test('data map is preserved through serialization', () {
      final op = _makeOp(data: {'variety': 'Bourbon', 'quantity': 100.0});
      final restored = OfflineSyncOperation.fromJson(op.toJson());
      expect(restored.data['variety'], 'Bourbon');
      expect(restored.data['quantity'], 100.0);
    });

    test('copyWith() creates new instance with updated retryCount', () {
      final op = _makeOp(retryCount: 0);
      final incremented = op.copyWith(retryCount: 1);
      expect(incremented.retryCount, 1);
      expect(incremented.id, op.id);
      expect(incremented.type, op.type);
    });

    test('copyWith() does not mutate original', () {
      final op = _makeOp(retryCount: 0);
      op.copyWith(retryCount: 3);
      expect(op.retryCount, 0);
    });
  });

  group('OfflineSyncRepository queue behaviour (task 22.2)', () {
    late _InMemoryOfflineSyncRepository repo;

    setUp(() => repo = _InMemoryOfflineSyncRepository());

    test('enqueueOperation() adds operation to queue', () async {
      await repo.enqueueOperation(_makeOp());
      final ops = await repo.getPendingOperations();
      expect(ops.length, 1);
    });

    test('getPendingOperations() returns operations in timestamp order', () async {
      final op1 = _makeOp(id: 'a', timestamp: DateTime(2024, 1, 3));
      final op2 = _makeOp(id: 'b', timestamp: DateTime(2024, 1, 1));
      final op3 = _makeOp(id: 'c', timestamp: DateTime(2024, 1, 2));
      await repo.enqueueOperation(op1);
      await repo.enqueueOperation(op2);
      await repo.enqueueOperation(op3);
      final ops = await repo.getPendingOperations();
      expect(ops.map((o) => o.id).toList(), ['b', 'c', 'a']);
    });

    test('processPendingQueue() clears all operations when online', () async {
      await repo.enqueueOperation(_makeOp(id: 'x'));
      await repo.enqueueOperation(_makeOp(id: 'y'));
      repo.setOnline(true);
      final count = await repo.processPendingQueue();
      expect(count, 2);
      final remaining = await repo.getPendingOperations();
      expect(remaining, isEmpty);
    });

    test('processPendingQueue() returns 0 when offline', () async {
      await repo.enqueueOperation(_makeOp());
      repo.setOnline(false);
      final count = await repo.processPendingQueue();
      expect(count, 0);
    });

    test('clearQueue() removes all pending operations', () async {
      await repo.enqueueOperation(_makeOp(id: 'p'));
      await repo.enqueueOperation(_makeOp(id: 'q'));
      await repo.clearQueue();
      final ops = await repo.getPendingOperations();
      expect(ops, isEmpty);
    });

    test('watchConnectivity() emits current online status', () async {
      repo.setOnline(true);
      final isOnline = await repo.watchConnectivity().first;
      expect(isOnline, true);
    });

    test('watchConnectivity() emits false when offline', () async {
      repo.setOnline(false);
      final isOnline = await repo.watchConnectivity().first;
      expect(isOnline, false);
    });

    test('multiple enqueue then process leaves queue empty', () async {
      for (var i = 0; i < 5; i++) {
        await repo.enqueueOperation(_makeOp(id: 'op$i'));
      }
      repo.setOnline(true);
      await repo.processPendingQueue();
      expect(await repo.getPendingOperations(), isEmpty);
    });

    test('enqueue after clear adds to fresh queue', () async {
      await repo.enqueueOperation(_makeOp(id: 'first'));
      await repo.clearQueue();
      await repo.enqueueOperation(_makeOp(id: 'second'));
      final ops = await repo.getPendingOperations();
      expect(ops.length, 1);
      expect(ops.first.id, 'second');
    });
  });

  group('OfflineSyncOperationType enum coverage', () {
    test('all types are distinct', () {
      final types = OfflineSyncOperationType.values;
      expect(types.toSet().length, types.length);
    });

    test('each type serializes to its name', () {
      for (final t in OfflineSyncOperationType.values) {
        final op = _makeOp(type: t);
        expect(op.toJson()['type'], t.name);
      }
    });

    test('fromJson restores all type variants', () {
      for (final t in OfflineSyncOperationType.values) {
        final op = _makeOp(type: t);
        final restored = OfflineSyncOperation.fromJson(op.toJson());
        expect(restored.type, t);
      }
    });
  });
}
