// Feature: brewmaster-verification
// Model representing a user's verification record (1:1 with users per ERD).
//
// Requirements: 7.1, 7.2
// Developer: Developer 1

import 'enums.dart';

class VerificationRequest {
  /// The user's ID — also the Firestore document ID in the verifications collection.
  final String userId;
  final VerificationStatus state;
  final List<String> documentUrls;
  final String? rejectionReason;
  final DateTime? verifiedAt;
  final DateTime updatedAt;

  const VerificationRequest({
    required this.userId,
    required this.state,
    required this.documentUrls,
    this.rejectionReason,
    this.verifiedAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'state': state.toJson(),
        'documentUrls': documentUrls,
        'rejectionReason': rejectionReason,
        'verifiedAt': verifiedAt?.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory VerificationRequest.fromJson(Map<String, dynamic> json) =>
      VerificationRequest(
        userId: json['userId'] as String,
        state: VerificationStatusExtension.fromJson(
          json['state'] as String? ?? 'unverified',
        ),
        documentUrls: (json['documentUrls'] as List<dynamic>? ?? [])
            .map((e) => e as String)
            .toList(),
        rejectionReason: json['rejectionReason'] as String?,
        verifiedAt: json['verifiedAt'] != null
            ? DateTime.parse(json['verifiedAt'] as String)
            : null,
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );

  VerificationRequest copyWith({
    String? userId,
    VerificationStatus? state,
    List<String>? documentUrls,
    String? rejectionReason,
    DateTime? verifiedAt,
    DateTime? updatedAt,
  }) =>
      VerificationRequest(
        userId: userId ?? this.userId,
        state: state ?? this.state,
        documentUrls: documentUrls ?? this.documentUrls,
        rejectionReason: rejectionReason ?? this.rejectionReason,
        verifiedAt: verifiedAt ?? this.verifiedAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
