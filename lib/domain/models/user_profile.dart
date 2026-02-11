import 'package:cloud_firestore/cloud_firestore.dart';
import 'enums.dart';

/// User profile model for both farmers and buyers
class UserProfile {
  final String id;
  final String email;
  final String phoneNumber;
  final UserRole role;
  final String displayName;
  final String? photoUrl;
  final bool isVerified;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Farmer-specific fields
  final double? farmSize;
  final String? farmLocation;
  final List<String>? coffeeVarieties;
  final String? farmRegistrationNumber;

  // Buyer-specific fields
  final String? businessName;
  final String? businessType;
  final double? monthlyVolume;

  // FCM token for notifications
  final String? fcmToken;

  // Verification status
  final VerificationStatus verificationStatus;

  UserProfile({
    required this.id,
    required this.email,
    required this.phoneNumber,
    required this.role,
    required this.displayName,
    this.photoUrl,
    this.isVerified = false,
    required this.createdAt,
    required this.updatedAt,
    this.farmSize,
    this.farmLocation,
    this.coffeeVarieties,
    this.farmRegistrationNumber,
    this.businessName,
    this.businessType,
    this.monthlyVolume,
    this.fcmToken,
    this.verificationStatus = VerificationStatus.unverified,
  });

  /// Convert UserProfile to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'phoneNumber': phoneNumber,
      'role': role.toJson(),
      'displayName': displayName,
      'photoUrl': photoUrl,
      'isVerified': isVerified,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'farmSize': farmSize,
      'farmLocation': farmLocation,
      'coffeeVarieties': coffeeVarieties,
      'farmRegistrationNumber': farmRegistrationNumber,
      'businessName': businessName,
      'businessType': businessType,
      'monthlyVolume': monthlyVolume,
      'fcmToken': fcmToken,
      'verificationStatus': verificationStatus.toJson(),
    };
  }

  /// Create UserProfile from Firestore JSON
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      phoneNumber: json['phoneNumber'] as String,
      role: UserRoleExtension.fromJson(json['role'] as String),
      displayName: json['displayName'] as String,
      photoUrl: json['photoUrl'] as String?,
      isVerified: json['isVerified'] as bool? ?? false,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
      farmSize: json['farmSize'] as double?,
      farmLocation: json['farmLocation'] as String?,
      coffeeVarieties: (json['coffeeVarieties'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      farmRegistrationNumber: json['farmRegistrationNumber'] as String?,
      businessName: json['businessName'] as String?,
      businessType: json['businessType'] as String?,
      monthlyVolume: json['monthlyVolume'] as double?,
      fcmToken: json['fcmToken'] as String?,
      verificationStatus: VerificationStatusExtension.fromJson(
        json['verificationStatus'] as String? ?? 'unverified',
      ),
    );
  }

  /// Create a copy of UserProfile with updated fields
  UserProfile copyWith({
    String? id,
    String? email,
    String? phoneNumber,
    UserRole? role,
    String? displayName,
    String? photoUrl,
    bool? isVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? farmSize,
    String? farmLocation,
    List<String>? coffeeVarieties,
    String? farmRegistrationNumber,
    String? businessName,
    String? businessType,
    double? monthlyVolume,
    String? fcmToken,
    VerificationStatus? verificationStatus,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      farmSize: farmSize ?? this.farmSize,
      farmLocation: farmLocation ?? this.farmLocation,
      coffeeVarieties: coffeeVarieties ?? this.coffeeVarieties,
      farmRegistrationNumber:
          farmRegistrationNumber ?? this.farmRegistrationNumber,
      businessName: businessName ?? this.businessName,
      businessType: businessType ?? this.businessType,
      monthlyVolume: monthlyVolume ?? this.monthlyVolume,
      fcmToken: fcmToken ?? this.fcmToken,
      verificationStatus: verificationStatus ?? this.verificationStatus,
    );
  }

  @override
  String toString() {
    return 'UserProfile(id: $id, email: $email, role: $role, displayName: $displayName, isVerified: $isVerified)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UserProfile &&
        other.id == id &&
        other.email == email &&
        other.phoneNumber == phoneNumber &&
        other.role == role &&
        other.displayName == displayName &&
        other.photoUrl == photoUrl &&
        other.isVerified == isVerified &&
        other.farmSize == farmSize &&
        other.farmLocation == farmLocation &&
        other.businessName == businessName &&
        other.businessType == businessType &&
        other.monthlyVolume == monthlyVolume &&
        other.verificationStatus == verificationStatus;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        email.hashCode ^
        phoneNumber.hashCode ^
        role.hashCode ^
        displayName.hashCode ^
        (photoUrl?.hashCode ?? 0) ^
        isVerified.hashCode ^
        (farmSize?.hashCode ?? 0) ^
        (farmLocation?.hashCode ?? 0) ^
        (businessName?.hashCode ?? 0) ^
        (businessType?.hashCode ?? 0) ^
        (monthlyVolume?.hashCode ?? 0) ^
        verificationStatus.hashCode;
  }
}
