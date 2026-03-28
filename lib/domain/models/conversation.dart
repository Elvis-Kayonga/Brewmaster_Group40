import 'package:cloud_firestore/cloud_firestore.dart';

import 'message.dart';

/// Conversation model representing a chat between users
/// Requirements: 5.2, 5.5, 16.1 (Clean Architecture)
/// Developer: Developer 3
class Conversation {
  /// Unique identifier for the conversation
  final String conversationId;

  /// List of user IDs participating in the conversation
  final List<String> participantIds;

  /// Map of userId → displayName for quick rendering (ERD: participantNames).
  final Map<String, String> participantNames;

  /// Map of userId → photoUrl for avatar rendering. May be absent for older conversations.
  final Map<String, String> participantPhotoUrls;

  /// Related listing, if the conversation was started from a listing (ERD: listingId).
  final String? listingId;

  /// The most recent message in the conversation
  final Message? lastMessage;

  /// Number of unread messages for the current user
  final int unreadCount;

  /// Timestamp when the conversation was created
  final DateTime createdAt;

  /// Timestamp when the conversation was last updated
  final DateTime updatedAt;

  /// Constructor for Conversation
  Conversation({
    required this.conversationId,
    required this.participantIds,
    this.participantNames = const {},
    this.participantPhotoUrls = const {},
    this.listingId,
    this.lastMessage,
    required this.unreadCount,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create Conversation from Firestore JSON
  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      conversationId: json['conversationId'] as String,
      participantIds: List<String>.from(json['participantIds'] as List),
      participantNames: Map<String, dynamic>.from(
              json['participantNames'] as Map? ?? {})
          .map((k, v) => MapEntry(k, v as String)),
      participantPhotoUrls: Map<String, dynamic>.from(
              json['participantPhotoUrls'] as Map? ?? {})
          .map((k, v) => MapEntry(k, v as String)),
      listingId: json['listingId'] as String?,
      lastMessage: json['lastMessage'] != null
          ? Message.fromJson(Map<String, dynamic>.from(json['lastMessage']))
          : null,
      unreadCount: json['unreadCount'] as int? ?? 0,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Convert Conversation to JSON — includes ERD fields for cross-platform compat.
  Map<String, dynamic> toJson() {
    return {
      'conversationId': conversationId,
      'participantIds': participantIds,
      'participantNames': participantNames,
      'participantPhotoUrls': participantPhotoUrls,
      'listingId': listingId,
      'lastMessage': lastMessage?.toJson(),
      // ERD also stores these as flat fields for quick reads
      'lastMessageContent': lastMessage?.content,
      'lastMessageAt': lastMessage != null
          ? Timestamp.fromDate(lastMessage!.createdAt)
          : null,
      'unreadCount': unreadCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Create a copy of the conversation with updated fields
  Conversation copyWith({
    Map<String, String>? participantNames,
    Map<String, String>? participantPhotoUrls,
    String? listingId,
    Message? lastMessage,
    int? unreadCount,
    DateTime? updatedAt,
  }) {
    return Conversation(
      conversationId: conversationId,
      participantIds: participantIds,
      participantNames: participantNames ?? this.participantNames,
      participantPhotoUrls: participantPhotoUrls ?? this.participantPhotoUrls,
      listingId: listingId ?? this.listingId,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Conversation(conversationId: $conversationId, participantIds: $participantIds, unreadCount: $unreadCount, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Conversation &&
        other.conversationId == conversationId &&
        other.participantIds.length == participantIds.length &&
        other.unreadCount == unreadCount;
  }

  @override
  int get hashCode {
    return conversationId.hashCode ^
        participantIds.hashCode ^
        unreadCount.hashCode;
  }
}
