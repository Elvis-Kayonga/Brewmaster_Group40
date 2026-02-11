/// User role in the marketplace
enum UserRole { farmer, buyer }

/// Verification status for users
enum VerificationStatus { unverified, pending, verified, rejected }

/// Coffee processing methods
enum ProcessingMethod { washed, natural, honey }

/// Listing status
enum ListingStatus { draft, active, sold, expired }

/// Transaction status for escrow payments
enum TransactionStatus {
  pending,
  fundsHeld,
  delivered,
  completed,
  disputed,
  cancelled,
}

/// Payment methods
enum PaymentMethod { mpesa, mtnMobileMoney }

/// Message types
enum MessageType { text, listingReference, system }

/// Notification types
enum NotificationType {
  newMessage,
  purchaseInitiated,
  paymentReceived,
  deliveryConfirmed,
  verificationUpdated,
  listingInterest,
}

/// Quality grades for coffee
enum QualityGrade { specialty, premium, standard }

/// Sort options for search
enum SortOption {
  priceAsc,
  priceDesc,
  altitudeAsc,
  altitudeDesc,
  dateDesc,
  quantityDesc,
}

// Extension methods for enum serialization
extension UserRoleExtension on UserRole {
  String toJson() => name;

  static UserRole fromJson(String value) {
    return UserRole.values.firstWhere(
      (e) => e.name == value,
      orElse: () => UserRole.farmer,
    );
  }
}

extension VerificationStatusExtension on VerificationStatus {
  String toJson() => name;

  static VerificationStatus fromJson(String value) {
    return VerificationStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => VerificationStatus.unverified,
    );
  }
}

extension ProcessingMethodExtension on ProcessingMethod {
  String toJson() => name;

  static ProcessingMethod fromJson(String value) {
    return ProcessingMethod.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ProcessingMethod.washed,
    );
  }
}

extension ListingStatusExtension on ListingStatus {
  String toJson() => name;

  static ListingStatus fromJson(String value) {
    return ListingStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ListingStatus.draft,
    );
  }
}

extension TransactionStatusExtension on TransactionStatus {
  String toJson() => name;

  static TransactionStatus fromJson(String value) {
    return TransactionStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TransactionStatus.pending,
    );
  }
}

extension PaymentMethodExtension on PaymentMethod {
  String toJson() => name;

  static PaymentMethod fromJson(String value) {
    return PaymentMethod.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PaymentMethod.mpesa,
    );
  }
}

extension MessageTypeExtension on MessageType {
  String toJson() => name;

  static MessageType fromJson(String value) {
    return MessageType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => MessageType.text,
    );
  }
}

extension NotificationTypeExtension on NotificationType {
  String toJson() => name;

  static NotificationType fromJson(String value) {
    return NotificationType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => NotificationType.newMessage,
    );
  }
}

extension QualityGradeExtension on QualityGrade {
  String toJson() => name;

  static QualityGrade fromJson(String value) {
    return QualityGrade.values.firstWhere(
      (e) => e.name == value,
      orElse: () => QualityGrade.standard,
    );
  }
}

extension SortOptionExtension on SortOption {
  String toJson() => name;

  static SortOption fromJson(String value) {
    return SortOption.values.firstWhere(
      (e) => e.name == value,
      orElse: () => SortOption.dateDesc,
    );
  }
}
