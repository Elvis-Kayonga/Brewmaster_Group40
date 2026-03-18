// Feature: brewmaster-verification
// Firebase implementation of VerificationRepository.
// Stores one verification record per user (1:1 per ERD) in the
// 'verifications' collection, keyed by userId.
// Documents are uploaded to Cloudinary (consistent with the rest of the app).
//
// Requirements: 7.1, 7.2, 7.3
// Developer: Developer 1

import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../../config/cloudinary_config.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/verification_request.dart';
import '../../domain/repositories/verification_repository.dart';

class FirebaseVerificationRepository implements VerificationRepository {
  final FirebaseFirestore _firestore;

  // ERD collection name — one document per user, keyed by userId.
  static const _collection = 'verifications';

  FirebaseVerificationRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<void> submitVerificationRequest(
    String userId,
    List<File> documents,
  ) async {
    final urls = <String>[];
    for (final doc in documents) {
      urls.add(await uploadDocument(userId, doc));
    }

    final now = DateTime.now();
    final record = VerificationRequest(
      userId: userId,
      state: VerificationStatus.pending,
      documentUrls: urls,
      updatedAt: now,
    );

    // Upsert: userId is the document ID — maintains 1:1 relationship per ERD.
    await _firestore
        .collection(_collection)
        .doc(userId)
        .set(record.toJson());

    // Mirror status on user profile for quick reads across the app.
    await _firestore.collection('users').doc(userId).update({
      'verificationStatus': VerificationStatus.pending.toJson(),
    });
  }

  @override
  Future<String> uploadDocument(String userId, File document) async {
    final uri = Uri.parse(CloudinaryConfig.uploadUrl);
    final fileName = document.path.split('/').last;

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = CloudinaryConfig.uploadPreset
      ..fields['public_id'] = 'verification/$userId/${DateTime.now().millisecondsSinceEpoch}_$fileName'
      ..files.add(await http.MultipartFile.fromPath('file', document.path));

    final response = await request.send();
    final body = await response.stream.bytesToString();

    if (response.statusCode != 200) {
      throw Exception('Document upload failed: ${response.statusCode} $body');
    }

    final data = jsonDecode(body) as Map<String, dynamic>;
    return data['secure_url'] as String;
  }

  @override
  Future<VerificationRequest?> getVerificationStatus(String userId) async {
    // Direct lookup by userId — no query or index needed.
    final doc = await _firestore
        .collection(_collection)
        .doc(userId)
        .get();

    if (!doc.exists || doc.data() == null) return null;
    return VerificationRequest.fromJson(doc.data()!);
  }

  @override
  Stream<VerificationStatus> watchVerificationStatus(String userId) {
    // Watch the verifications document directly — this is what admin tools
    // update. Watching users/{userId} would miss changes made here.
    return _firestore
        .collection(_collection)
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (!doc.exists || doc.data() == null) {
        return VerificationStatus.unverified;
      }
      return VerificationStatusExtension.fromJson(
        doc.data()!['state'] as String? ?? 'unverified',
      );
    });
  }

  @override
  Future<void> syncStatusToUserProfile(
      String userId, VerificationStatus status) async {
    // Keep users/{userId}.verificationStatus in sync so AuthBloc reads the
    // correct value without querying the verifications collection.
    await _firestore.collection('users').doc(userId).update({
      'verificationStatus': status.toJson(),
    });
  }
}
