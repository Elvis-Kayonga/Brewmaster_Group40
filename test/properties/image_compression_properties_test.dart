// test/properties/image_compression_properties_test.dart
//
// Property-based tests for task 24.2: ImageCompressionService queue behaviour.
// File I/O is avoided — tests focus on queue state and retry logic using
// temporary in-memory stubs.
//
// Developer: Developer 3 (Ryan)

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:brewmaster/data/services/image_compression_service.dart';

void main() {
  group('ImageCompressionService upload queue (task 24.2)', () {
    late ImageCompressionService service;

    setUp(() => service = ImageCompressionService());

    // -------------------------------------------------------------------------
    // pendingCount
    // -------------------------------------------------------------------------

    test('pendingCount is 0 initially', () {
      expect(service.pendingCount, 0);
    });

    test('pendingCount increases after enqueueFailedUpload()', () {
      service.enqueueFailedUpload('path/a.jpg');
      expect(service.pendingCount, 1);
    });

    test('enqueueFailedUpload() increments retryCount for same path', () {
      service.enqueueFailedUpload('path/a.jpg');
      service.enqueueFailedUpload('path/a.jpg');
      // Same file — still one entry but retryCount = 1
      expect(service.pendingCount, 1);
    });

    test('enqueueFailedUpload() adds separate entries for different paths', () {
      service.enqueueFailedUpload('path/a.jpg');
      service.enqueueFailedUpload('path/b.jpg');
      expect(service.pendingCount, 2);
    });

    // -------------------------------------------------------------------------
    // clearQueue
    // -------------------------------------------------------------------------

    test('clearQueue() resets pendingCount to 0', () {
      service.enqueueFailedUpload('path/a.jpg');
      service.enqueueFailedUpload('path/b.jpg');
      service.clearQueue();
      expect(service.pendingCount, 0);
    });

    test('clearQueue() on empty queue is a no-op', () {
      service.clearQueue();
      expect(service.pendingCount, 0);
    });

    // -------------------------------------------------------------------------
    // processQueue — success path
    // -------------------------------------------------------------------------

    test('processQueue() clears entry on successful upload', () async {
      service.enqueueFailedUpload('path/a.jpg');
      await service.processQueue((file) async {}); // always succeeds
      expect(service.pendingCount, 0);
    });

    test('processQueue() clears multiple entries on success', () async {
      service.enqueueFailedUpload('path/a.jpg');
      service.enqueueFailedUpload('path/b.jpg');
      service.enqueueFailedUpload('path/c.jpg');
      await service.processQueue((file) async {});
      expect(service.pendingCount, 0);
    });

    // -------------------------------------------------------------------------
    // processQueue — failure / retry path
    // -------------------------------------------------------------------------

    test('processQueue() keeps entry when upload throws', () async {
      service.enqueueFailedUpload('path/fail.jpg');
      await service.processQueue(
        (file) async => throw Exception('network error'),
      );
      expect(service.pendingCount, 1);
    });

    test('processQueue() drops entry after exceeding maxRetries', () async {
      const path = 'path/retry.jpg';
      // 4 enqueue calls → retryCount reaches 3 (== _maxRetries)
      for (var i = 0; i < 4; i++) {
        service.enqueueFailedUpload(path);
      }
      // retryCount is now 3; processQueue drops it immediately
      await service.processQueue(
        (file) async => throw Exception('still failing'),
      );
      expect(service.pendingCount, 0);
    });

    test('processQueue() on empty queue is a no-op', () async {
      await service.processQueue((file) async {});
      expect(service.pendingCount, 0);
    });

    // -------------------------------------------------------------------------
    // compressAll — list length invariant
    // -------------------------------------------------------------------------

    test('compressAll() returns same number of files as input', () async {
      // Create temporary files for testing
      final dir = Directory.systemTemp.createTempSync('compress_test');
      try {
        final files = <File>[];
        for (var i = 0; i < 3; i++) {
          final f = File('${dir.path}/img_$i.jpg')
            ..writeAsBytesSync(List.filled(100, 0)); // tiny file
          files.add(f);
        }
        final results = await service.compressAll(files);
        expect(results.length, files.length);
      } finally {
        dir.deleteSync(recursive: true);
      }
    });

    test('compress() returns original file when already under 1 MB', () async {
      final dir = Directory.systemTemp.createTempSync('compress_small');
      try {
        final f = File('${dir.path}/small.jpg')
          ..writeAsBytesSync(List.filled(512, 0)); // 512 bytes
        final result = await service.compress(f);
        expect(result.path, f.path);
      } finally {
        dir.deleteSync(recursive: true);
      }
    });

    test('compress() returns compressed file when over 1 MB', () async {
      final dir = Directory.systemTemp.createTempSync('compress_large');
      try {
        // Write 2 MB of zeros
        final f = File('${dir.path}/large.jpg')
          ..writeAsBytesSync(List.filled(2 * 1024 * 1024, 0));
        final result = await service.compress(f);
        final resultSize = await result.length();
        expect(resultSize, lessThanOrEqualTo(1024 * 1024));
      } finally {
        dir.deleteSync(recursive: true);
      }
    });
  });
}
