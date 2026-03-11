// Feature: brewmaster-verification
// Firebase implementation of VerificationRepository.
// Uploads documents to Firebase Storage and stores requests in Firestore.
//
// Requirements: 7.1, 7.2, 7.3
// Developer: Developer 1

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/verification_request.dart';
import '../../domain/repositories/verification_repository.dart';

class FirebaseVerificationRepository implements VerificationRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  static const _collection = 'verification_requests';

  FirebaseVerificationRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

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
    final ref = _firestore.collection(_collection).doc();
    final request = VerificationRequest(
      id: ref.id,
      userId: userId,
      status: VerificationStatus.pending,
      documentUrls: urls,
      submittedAt: now,
      updatedAt: now,
    );

    await ref.set(request.toJson());

    // Mark the user profile as pending
    await _firestore.collection('users').doc(userId).update({
      'verificationStatus': VerificationStatus.pending.toJson(),
    });
  }

  @override
  Future<String> uploadDocument(String userId, File document) async {
    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${document.path.split('/').last}';
    final ref = _storage.ref('verification/$userId/$fileName');
    await ref.putFile(document);
    return ref.getDownloadURL();
  }

  @override
  Future<VerificationRequest?> getVerificationStatus(String userId) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .orderBy('submittedAt', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return VerificationRequest.fromJson(snapshot.docs.first.data());
  }

  @override
  Stream<VerificationStatus> watchVerificationStatus(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (!doc.exists || doc.data() == null) {
        return VerificationStatus.unverified;
      }
      return VerificationStatusExtension.fromJson(
        doc.data()!['verificationStatus'] as String? ?? 'unverified',
      );
    });
  }
}
