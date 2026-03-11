import '../models/conversation.dart';
import '../models/message.dart';

/// Abstract interface for messaging operations.
///
/// Requirements: 5.2, 5.3, 5.5, 5.6
/// Developer: Developer 3
abstract class MessageRepository {
  /// Send a message in [conversationId] to [receiverId].
  Future<Message> sendMessage({
    required String conversationId,
    required String receiverId,
    required String content,
    MessageType messageType = MessageType.text,
    String? listingId,
  });

  /// Real-time stream of all conversations for the current user.
  Stream<List<Conversation>> watchConversations();

  /// Real-time stream of messages in [conversationId].
  Stream<List<Message>> watchMessages(String conversationId);

  /// Mark all unread messages in [conversationId] as read.
  Future<void> markConversationAsRead(String conversationId);

  /// Get or create a direct conversation with [otherUserId].
  Future<Conversation> getOrCreateConversation(String otherUserId);

  /// Total unread message count across all conversations.
  Future<int> getTotalUnreadCount();
}
