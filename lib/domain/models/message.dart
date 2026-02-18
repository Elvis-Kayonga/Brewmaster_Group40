import 'package:cloud_firestore/cloud_firestore.dart';

// Message model representing a single message in a conversation
enum MessageType {
  text,
  listingReference,
}

// Helper function to convert string to MessageType enum
MessageType messageTypeFromString(String value) {
  return MessageType.values.firstWhere(
    (e) => e.name == value,
    orElse: () => MessageType.text,
  );
}

// Message model representing a single message in a conversation
class Message {
  final String messageId;
  final String conversationId;
  final String senderId;
  final String receiverId;
  final String content;
  final MessageType messageType;
  final String? listingId;
  final bool isRead;
  final DateTime createdAt;

// Constructor for Message
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

  // Convert Firestore/JSON to Message object
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      messageId: json['messageId'] as String,
      conversationId: json['conversationId'] as String,
      senderId: json['senderId'] as String,
      receiverId: json['receiverId'] as String,
      content: json['content'] as String,
      messageType: messageTypeFromString(
        json['messageType'] as String,
      ),
      listingId: json['listingId'],
      isRead: json['isRead'] as bool,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
    );
  }

  // Convert Message object to Firestore/JSON
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

  // Create a copy of the message with updated fields
  Message copyWith({
    bool? isRead,
    String? content,
  }) {
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
}
