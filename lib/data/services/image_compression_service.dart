// Feature: brewmaster-offline-sync
// Service for compressing images before upload and managing a retry queue
// for failed uploads.
//
// Requirements: 24.1, 24.2
// Developer: Developer 3 (Ryan)

import 'dart:io';
import 'dart:typed_data';

class ImageCompressionService {
  static const int _targetMaxBytes = 1024 * 1024; // 1 MB
  static const int _maxRetries = 3;

  final List<_FailedUpload> _uploadQueue = [];

  int get pendingCount => _uploadQueue.length;

  /// Compress a single [File] to be at most [_targetMaxBytes].
  /// Returns the compressed file (or original if already small enough).
  Future<File> compress(File file) async {
    final bytes = await file.readAsBytes();
    if (bytes.length <= _targetMaxBytes) return file;

    final compressed = _compressBytes(bytes, file.path);
    final outPath = '${file.path}.compressed.jpg';
    final outFile = File(outPath);
    await outFile.writeAsBytes(compressed);
    return outFile;
  }

  /// Compress all files in [files] and return the compressed list.
  Future<List<File>> compressAll(List<File> files) async {
    final results = <File>[];
    for (final f in files) {
      results.add(await compress(f));
    }
    return results;
  }

  /// Add a file path to the failed-upload retry queue.
  void enqueueFailedUpload(String filePath) {
    final existing = _uploadQueue.where((u) => u.filePath == filePath);
    if (existing.isNotEmpty) {
      final idx = _uploadQueue.indexOf(existing.first);
      _uploadQueue[idx] = existing.first.incrementRetry();
    } else {
      _uploadQueue.add(_FailedUpload(filePath: filePath));
    }
  }

  /// Process the retry queue by calling [uploadFn] for each pending file.
  /// Files that exceed [_maxRetries] are dropped.
  Future<void> processQueue(
    Future<void> Function(File file) uploadFn,
  ) async {
    final toProcess = List<_FailedUpload>.from(_uploadQueue);
    for (final entry in toProcess) {
      if (entry.retryCount >= _maxRetries) {
        _uploadQueue.remove(entry);
        continue;
      }
      try {
        await uploadFn(File(entry.filePath));
        _uploadQueue.remove(entry);
      } catch (_) {
        final idx = _uploadQueue.indexOf(entry);
        if (idx >= 0) {
          _uploadQueue[idx] = entry.incrementRetry();
        }
      }
    }
  }

  /// Clear the retry queue.
  void clearQueue() => _uploadQueue.clear();

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Simple byte-level compression: reduce quality by truncating redundant
  /// pixel data. This is a pure-Dart stub that scales bytes proportionally.
  /// In production, swap for flutter_image_compress or similar.
  Uint8List _compressBytes(Uint8List bytes, String path) {
    // Proportional reduction to stay under target
    final ratio = _targetMaxBytes / bytes.length;
    final targetLength = (bytes.length * ratio).round();
    // Return the first targetLength bytes as a simplified stub
    return Uint8List.fromList(bytes.take(targetLength).toList());
  }
}

class _FailedUpload {
  final String filePath;
  final int retryCount;

  const _FailedUpload({required this.filePath, this.retryCount = 0});

  _FailedUpload incrementRetry() =>
      _FailedUpload(filePath: filePath, retryCount: retryCount + 1);
}
