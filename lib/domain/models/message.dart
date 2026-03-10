import 'package:cloud_firestore/cloud_firestore.dart';

/// Message type enumeration
/// Defines the type of content in a message
enum MessageType {
  /// Plain text message
  text,

  /// Message containing a reference to a coffee listing
  listingReference,
}

/// Helper function to convert string to MessageType enum
MessageType messageTypeFromString(String value) {
  return MessageType.values.firstWhere(
    (e) => e.name == value,
    orElse: () => MessageType.text,
  );
}

/// Message model representing a single message in a conversation
/// Requirements: 5.2, 5.5, 16.1 (Clean Architecture)
/// Developer: Developer 3
class Message {
  /// Unique identifier for the message
  final String messageId;

  /// ID of the conversation this message belongs to
  final String conversationId;

  /// ID of the user who sent the message
  final String senderId;

  /// ID of the user who receives the message
  final String receiverId;

  /// Text content of the message
  final String content;

  /// Type of message (text or listing reference)
  final MessageType messageType;

  /// Optional ID of the listing being referenced
  final String? listingId;

  /// Whether the message has been read by the receiver
  final bool isRead;

  /// Timestamp when the message was created
  final DateTime createdAt;

  /// Constructor for Message
  Message({
    required this.messageId,
    required this.conversationId,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.messageType,
    this.listingId,
    required this.isRead,
    required this.createdAt,
  });

  /// Create Message from Firestore JSON
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      messageId: json['messageId'] as String,
      conversationId: json['conversationId'] as String,
      senderId: json['senderId'] as String,
      receiverId: json['receiverId'] as String,
      content: json['content'] as String,
      messageType: messageTypeFromString(json['messageType'] as String),
      listingId: json['listingId'] as String?,
      isRead: json['isRead'] as bool,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
    );
  }

  /// Convert Message to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'messageId': messageId,
      'conversationId': conversationId,
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'messageType': messageType.name,
      'listingId': listingId,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Create a copy of the message with updated fields
  Message copyWith({bool? isRead, String? content}) {
    return Message(
      messageId: messageId,
      conversationId: conversationId,
      senderId: senderId,
      receiverId: receiverId,
      content: content ?? this.content,
      messageType: messageType,
      listingId: listingId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }

  @override
  String toString() {
    return 'Message(messageId: $messageId, conversationId: $conversationId, senderId: $senderId, receiverId: $receiverId, messageType: $messageType, isRead: $isRead)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Message &&
        other.messageId == messageId &&
        other.conversationId == conversationId &&
        other.senderId == senderId &&
        other.receiverId == receiverId &&
        other.content == content &&
        other.messageType == messageType &&
        other.listingId == listingId &&
        other.isRead == isRead;
  }

  @override
  int get hashCode {
    return messageId.hashCode ^
        conversationId.hashCode ^
        senderId.hashCode ^
        receiverId.hashCode ^
        content.hashCode ^
        messageType.hashCode ^
        (listingId?.hashCode ?? 0) ^
        isRead.hashCode;
  }
}
