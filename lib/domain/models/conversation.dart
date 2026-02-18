import 'package:cloud_firestore/cloud_firestore.dart';

import 'message.dart';

// Conversation model representing a chat between users

class Conversation {
  final String conversationId;
  final List<String> participantIds;
  final Message? lastMessage;
  final int unreadCount;
  final DateTime createdAt;
  final DateTime updatedAt;
// Constructor for Conversation
  Conversation({
    required this.conversationId,
    required this.participantIds,
    this.lastMessage,
    required this.unreadCount,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convert Firestore/JSON to Conversation object
  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      conversationId: json['conversationId'] as String,
      participantIds: List<String>.from(
        json['participantIds'] as List,
      ),
      lastMessage: json['lastMessage'] != null
          ? Message.fromJson(
              Map<String, dynamic>.from(json['lastMessage']),
            )
          : null,
      unreadCount: json['unreadCount'] as int,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
    );
  }

  // Convert Conversation object to Firestore/JSON
  Map<String, dynamic> toJson() {
    return {
      'conversationId': conversationId,
      'participantIds': participantIds,
      'lastMessage': lastMessage?.toJson(),
      'unreadCount': unreadCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Create a copy of the conversation with updated fields
  Conversation copyWith({
    Message? lastMessage,
    int? unreadCount,
    DateTime? updatedAt,
  }) {
    return Conversation(
      conversationId: conversationId,
      participantIds: participantIds,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
