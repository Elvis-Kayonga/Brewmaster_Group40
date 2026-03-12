// test/properties/batch_write_properties_test.dart
//
// Property-based tests for task 31.4: BatchWriteService.chunk() and
// batch-size invariants using the static helper (no Firebase needed).
//
// Developer: Developer 6

import 'package:flutter_test/flutter_test.dart';
import 'package:brewmaster/data/services/batch_write_service.dart';

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('BatchWriteService.chunk — size invariants (task 31.4)', () {
    test('empty list produces no chunks', () {
      expect(BatchWriteService.chunk<int>([]), isEmpty);
    });

    test('list smaller than maxBatchSize produces one chunk', () {
      final chunks = BatchWriteService.chunk(List.generate(10, (i) => i));
      expect(chunks, hasLength(1));
      expect(chunks.first, hasLength(10));
    });

    test('list exactly maxBatchSize produces one chunk', () {
      final chunks =
          BatchWriteService.chunk(List.generate(500, (i) => i));
      expect(chunks, hasLength(1));
      expect(chunks.first, hasLength(500));
    });

    test('list of 501 produces two chunks', () {
      final chunks =
          BatchWriteService.chunk(List.generate(501, (i) => i));
      expect(chunks, hasLength(2));
      expect(chunks.first, hasLength(500));
      expect(chunks.last, hasLength(1));
    });

    test('no chunk exceeds maxBatchSize', () {
      final items = List.generate(1234, (i) => i);
      for (final chunk in BatchWriteService.chunk(items)) {
        expect(chunk.length, lessThanOrEqualTo(BatchWriteService.maxBatchSize));
      }
    });

    test('all items are preserved across chunks', () {
      final items = List.generate(750, (i) => i);
      final flat =
          BatchWriteService.chunk(items).expand((c) => c).toList();
      expect(flat, items);
    });

    test('item order is preserved across chunks', () {
      final items = List.generate(600, (i) => i * 2);
      final flat =
          BatchWriteService.chunk(items).expand((c) => c).toList();
      expect(flat, items);
    });

    test('custom chunk size is respected', () {
      final chunks = BatchWriteService.chunk(List.generate(25, (i) => i), 10);
      expect(chunks, hasLength(3));
      expect(chunks[0], hasLength(10));
      expect(chunks[1], hasLength(10));
      expect(chunks[2], hasLength(5));
    });

    test('chunk size of 1 gives one item per chunk', () {
      final items = [1, 2, 3];
      final chunks = BatchWriteService.chunk(items, 1);
      expect(chunks, hasLength(3));
      for (final c in chunks) {
        expect(c, hasLength(1));
      }
    });
  });

  group('BatchWriteService constants (task 31.4)', () {
    test('maxBatchSize is 500', () {
      expect(BatchWriteService.maxBatchSize, 500);
    });
  });

  group('BatchWriteService.chunk — type safety (task 31.4)', () {
    test('works with String items', () {
      final chunks = BatchWriteService.chunk(['a', 'b', 'c'], 2);
      expect(chunks, hasLength(2));
      expect(chunks.first, ['a', 'b']);
      expect(chunks.last, ['c']);
    });

    test('works with Map items', () {
      final docs = List.generate(
          5, (i) => <String, dynamic>{'id': i, 'value': 'v$i'});
      final chunks = BatchWriteService.chunk(docs, 3);
      expect(chunks.expand((c) => c).toList(), docs);
    });
  });
}
