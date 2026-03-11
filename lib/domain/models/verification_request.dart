// Feature: brewmaster-verification
// Model representing a user's verification request with submitted documents.
//
// Requirements: 7.1, 7.2
// Developer: Developer 1

import 'enums.dart';

class VerificationRequest {
  final String id;
  final String userId;
  final VerificationStatus status;
  final List<String> documentUrls;
  final String? rejectionReason;
  final DateTime submittedAt;
  final DateTime updatedAt;

  const VerificationRequest({
    required this.id,
    required this.userId,
    required this.status,
    required this.documentUrls,
    this.rejectionReason,
    required this.submittedAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'status': status.toJson(),
        'documentUrls': documentUrls,
        'rejectionReason': rejectionReason,
        'submittedAt': submittedAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory VerificationRequest.fromJson(Map<String, dynamic> json) =>
      VerificationRequest(
        id: json['id'] as String,
        userId: json['userId'] as String,
        status: VerificationStatusExtension.fromJson(
          json['status'] as String? ?? 'unverified',
        ),
        documentUrls: (json['documentUrls'] as List<dynamic>? ?? [])
            .map((e) => e as String)
            .toList(),
        rejectionReason: json['rejectionReason'] as String?,
        submittedAt: DateTime.parse(json['submittedAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );

  VerificationRequest copyWith({
    String? id,
    String? userId,
    VerificationStatus? status,
    List<String>? documentUrls,
    String? rejectionReason,
    DateTime? submittedAt,
    DateTime? updatedAt,
  }) =>
      VerificationRequest(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        status: status ?? this.status,
        documentUrls: documentUrls ?? this.documentUrls,
        rejectionReason: rejectionReason ?? this.rejectionReason,
        submittedAt: submittedAt ?? this.submittedAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
