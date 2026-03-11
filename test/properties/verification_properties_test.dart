// test/properties/verification_properties_test.dart
//
// Property-based tests for task 25.2: VerificationRequest model and
// VerificationRepository behaviour using an in-memory fake.
//
// Developer: Developer 1

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:brewmaster/domain/models/enums.dart';
import 'package:brewmaster/domain/models/verification_request.dart';
import 'package:brewmaster/domain/repositories/verification_repository.dart';

// ---------------------------------------------------------------------------
// In-memory fake repository
// ---------------------------------------------------------------------------

class _InMemoryVerificationRepository implements VerificationRepository {
  final Map<String, VerificationRequest> _store = {};
  final Map<String, VerificationStatus> _statusOverrides = {};

  @override
  Future<void> submitVerificationRequest(
    String userId,
    List<File> documents,
  ) async {
    final now = DateTime.now();
    final req = VerificationRequest(
      id: 'req_$userId',
      userId: userId,
      status: VerificationStatus.pending,
      documentUrls: documents.map((f) => 'https://fake/${f.path}').toList(),
      submittedAt: now,
      updatedAt: now,
    );
    _store[userId] = req;
    _statusOverrides[userId] = VerificationStatus.pending;
  }

  @override
  Future<String> uploadDocument(String userId, File document) async =>
      'https://fake/$userId/${document.path}';

  @override
  Future<VerificationRequest?> getVerificationStatus(String userId) async =>
      _store[userId];

  @override
  Stream<VerificationStatus> watchVerificationStatus(String userId) =>
      Stream.value(
        _statusOverrides[userId] ?? VerificationStatus.unverified,
      );

  /// Test helper: set a user's status directly.
  void setStatus(String userId, VerificationStatus status) {
    _statusOverrides[userId] = status;
    final existing = _store[userId];
    if (existing != null) {
      _store[userId] = existing.copyWith(status: status);
    }
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

VerificationRequest _makeRequest({
  String id = 'req1',
  String userId = 'user1',
  VerificationStatus status = VerificationStatus.pending,
  List<String>? documentUrls,
  String? rejectionReason,
  DateTime? submittedAt,
  DateTime? updatedAt,
}) =>
    VerificationRequest(
      id: id,
      userId: userId,
      status: status,
      documentUrls: documentUrls ?? ['https://example.com/doc.pdf'],
      rejectionReason: rejectionReason,
      submittedAt: submittedAt ?? DateTime(2024, 1, 1),
      updatedAt: updatedAt ?? DateTime(2024, 1, 2),
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('VerificationRequest serialization (task 25.2)', () {
    test('toJson()/fromJson() round-trips for pending status', () {
      final req = _makeRequest(status: VerificationStatus.pending);
      final restored = VerificationRequest.fromJson(req.toJson());
      expect(restored.id, req.id);
      expect(restored.userId, req.userId);
      expect(restored.status, VerificationStatus.pending);
    });

    test('toJson()/fromJson() round-trips for verified status', () {
      final req = _makeRequest(status: VerificationStatus.verified);
      final restored = VerificationRequest.fromJson(req.toJson());
      expect(restored.status, VerificationStatus.verified);
    });

    test('toJson()/fromJson() round-trips for rejected status', () {
      final req = _makeRequest(
        status: VerificationStatus.rejected,
        rejectionReason: 'Documents unclear',
      );
      final restored = VerificationRequest.fromJson(req.toJson());
      expect(restored.status, VerificationStatus.rejected);
      expect(restored.rejectionReason, 'Documents unclear');
    });

    test('toJson()/fromJson() round-trips for unverified status', () {
      final req = _makeRequest(status: VerificationStatus.unverified);
      final restored = VerificationRequest.fromJson(req.toJson());
      expect(restored.status, VerificationStatus.unverified);
    });

    test('timestamps preserved as ISO-8601 through serialization', () {
      final submitted = DateTime(2024, 3, 15, 9, 0, 0);
      final updated = DateTime(2024, 3, 16, 10, 30, 0);
      final req = _makeRequest(submittedAt: submitted, updatedAt: updated);
      final restored = VerificationRequest.fromJson(req.toJson());
      expect(restored.submittedAt.toIso8601String(), submitted.toIso8601String());
      expect(restored.updatedAt.toIso8601String(), updated.toIso8601String());
    });

    test('documentUrls list is preserved through serialization', () {
      final urls = ['https://a.com/1.pdf', 'https://b.com/2.jpg'];
      final req = _makeRequest(documentUrls: urls);
      final restored = VerificationRequest.fromJson(req.toJson());
      expect(restored.documentUrls, urls);
    });

    test('empty documentUrls round-trips correctly', () {
      final req = _makeRequest(documentUrls: []);
      final restored = VerificationRequest.fromJson(req.toJson());
      expect(restored.documentUrls, isEmpty);
    });

    test('null rejectionReason round-trips as null', () {
      final req = _makeRequest(rejectionReason: null);
      final restored = VerificationRequest.fromJson(req.toJson());
      expect(restored.rejectionReason, isNull);
    });

    test('copyWith() updates status without mutating original', () {
      final original = _makeRequest(status: VerificationStatus.pending);
      final updated = original.copyWith(status: VerificationStatus.verified);
      expect(updated.status, VerificationStatus.verified);
      expect(original.status, VerificationStatus.pending);
    });

    test('copyWith() preserves all unchanged fields', () {
      final original = _makeRequest(
        id: 'r1',
        userId: 'u1',
        documentUrls: ['doc.pdf'],
      );
      final updated = original.copyWith(status: VerificationStatus.rejected);
      expect(updated.id, 'r1');
      expect(updated.userId, 'u1');
      expect(updated.documentUrls, ['doc.pdf']);
    });
  });

  group('VerificationRepository document collection (task 25.2)', () {
    late _InMemoryVerificationRepository repo;

    setUp(() => repo = _InMemoryVerificationRepository());

    test('getVerificationStatus() returns null before any submission', () async {
      final result = await repo.getVerificationStatus('user_new');
      expect(result, isNull);
    });

    test('submitVerificationRequest() creates a pending request', () async {
      await repo.submitVerificationRequest('user1', []);
      final result = await repo.getVerificationStatus('user1');
      expect(result, isNotNull);
      expect(result!.status, VerificationStatus.pending);
      expect(result.userId, 'user1');
    });

    test('submitVerificationRequest() stores document URLs', () async {
      final dir = Directory.systemTemp.createTempSync('verify_test');
      try {
        final file = File('${dir.path}/id.pdf')..writeAsStringSync('fake');
        await repo.submitVerificationRequest('user2', [file]);
        final result = await repo.getVerificationStatus('user2');
        expect(result!.documentUrls, isNotEmpty);
      } finally {
        dir.deleteSync(recursive: true);
      }
    });

    test('uploadDocument() returns a non-empty URL', () async {
      final dir = Directory.systemTemp.createTempSync('upload_test');
      try {
        final file = File('${dir.path}/doc.jpg')..writeAsStringSync('data');
        final url = await repo.uploadDocument('user3', file);
        expect(url, isNotEmpty);
      } finally {
        dir.deleteSync(recursive: true);
      }
    });

    test('watchVerificationStatus() emits unverified for unknown user', () async {
      final status = await repo.watchVerificationStatus('nobody').first;
      expect(status, VerificationStatus.unverified);
    });

    test('watchVerificationStatus() emits pending after submission', () async {
      await repo.submitVerificationRequest('user4', []);
      final status = await repo.watchVerificationStatus('user4').first;
      expect(status, VerificationStatus.pending);
    });

    test('status transitions from pending to verified', () async {
      await repo.submitVerificationRequest('user5', []);
      repo.setStatus('user5', VerificationStatus.verified);
      final result = await repo.getVerificationStatus('user5');
      expect(result!.status, VerificationStatus.verified);
    });

    test('status transitions from pending to rejected', () async {
      await repo.submitVerificationRequest('user6', []);
      repo.setStatus('user6', VerificationStatus.rejected);
      final result = await repo.getVerificationStatus('user6');
      expect(result!.status, VerificationStatus.rejected);
    });

    test('multiple users have independent verification states', () async {
      await repo.submitVerificationRequest('farmer1', []);
      await repo.submitVerificationRequest('buyer1', []);
      repo.setStatus('farmer1', VerificationStatus.verified);

      final farmerStatus = await repo.getVerificationStatus('farmer1');
      final buyerStatus = await repo.getVerificationStatus('buyer1');

      expect(farmerStatus!.status, VerificationStatus.verified);
      expect(buyerStatus!.status, VerificationStatus.pending);
    });

    test('all VerificationStatus values serialize and restore correctly', () {
      for (final status in VerificationStatus.values) {
        final req = _makeRequest(status: status);
        final restored = VerificationRequest.fromJson(req.toJson());
        expect(restored.status, status,
            reason: 'Failed for status: ${status.name}');
      }
    });
  });
}
