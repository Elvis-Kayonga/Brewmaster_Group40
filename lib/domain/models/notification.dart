import 'package:cloud_firestore/cloud_firestore.dart';

/// Notification type enumeration — matches ERD exactly.
enum NotificationType {
  newMessage,
  purchaseInitiated,
  paymentReceived,
  deliveryConfirmed,
  verificationUpdated,
  listingInterest,
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

/// Firestore notification record for a user.
///
/// Named [AppNotification] to avoid a clash with Flutter's built-in
/// [Notification] class.
///
/// ERD entity: notifications
/// Requirements: 12.1, 12.2, 12.3
class AppNotification {
  /// Unique identifier (PK).
  final String id;

  /// Foreign key → users.id.
  final String userId;

  /// Notification title shown in the system tray.
  final String title;

  /// Notification body text.
  final String body;

  /// Type of the notification.
  final NotificationType type;

  /// Arbitrary extra payload attached to the notification.
  final Map<String, dynamic> data;

  /// Whether the user has read / acknowledged this notification.
  final bool isRead;

  /// When the notification was created.
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.data,
    required this.isRead,
    required this.createdAt,
  });

  // ---------------------------------------------------------------------------
  // Serialisation
  // ---------------------------------------------------------------------------

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'body': body,
      'type': type.toJson(),
      'data': data,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      userId: json['userId'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      type: NotificationTypeExtension.fromJson(json['type'] as String),
      data: Map<String, dynamic>.from(json['data'] as Map? ?? {}),
      isRead: json['isRead'] as bool? ?? false,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
    );
  }

  factory AppNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppNotification.fromJson({...data, 'id': doc.id});
  }

  // ---------------------------------------------------------------------------
  // copyWith
  // ---------------------------------------------------------------------------

  AppNotification copyWith({
    String? id,
    String? userId,
    String? title,
    String? body,
    NotificationType? type,
    Map<String, dynamic>? data,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'AppNotification(id: $id, userId: $userId, type: $type, isRead: $isRead, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppNotification &&
        other.id == id &&
        other.userId == userId &&
        other.type == type &&
        other.isRead == isRead;
  }

  @override
  int get hashCode =>
      id.hashCode ^ userId.hashCode ^ type.hashCode ^ isRead.hashCode;
}
