// Feature: brewmaster-verification
// Abstract repository for farmer/buyer identity verification.
//
// Requirements: 7.1, 7.2, 7.3
// Developer: Developer 1

import 'dart:io';
import '../models/enums.dart';
import '../models/verification_request.dart';

abstract class VerificationRepository {
  /// Submit a new verification request for [userId], uploading [documents].
  Future<void> submitVerificationRequest(
    String userId,
    List<File> documents,
  );

  /// Upload a single document for [userId] and return the download URL.
  Future<String> uploadDocument(String userId, File document);

  /// Fetch the latest verification request for [userId], or null if none.
  Future<VerificationRequest?> getVerificationStatus(String userId);

  /// Stream that emits the latest [VerificationStatus] for [userId] in
  /// real time (useful for showing pending → verified transitions).
  Stream<VerificationStatus> watchVerificationStatus(String userId);

  /// Mirrors the verification status onto the user profile document so that
  /// [AuthBloc] can read the correct status without querying this collection.
  Future<void> syncStatusToUserProfile(String userId, VerificationStatus status);
}
