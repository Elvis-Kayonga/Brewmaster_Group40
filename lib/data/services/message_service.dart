import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/models/message.dart';
import '../../domain/models/conversation.dart';

/// Service for managing messages and conversations
/// Handles message creation, reading, offline queue management, and real-time updates
class MessageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Offline queue for messages that couldn't be sent
  final List<Map<String, dynamic>> _offlineQueue = [];

  /// Send a new message
  Future<Message> sendMessage({
    required String conversationId,
    required String receiverId,
    required String content,
    MessageType messageType = MessageType.text,
    String? listingId,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      final messageId = _firestore.collection('messages').doc().id;
      final now = DateTime.now();

      final message = Message(
        messageId: messageId,
        conversationId: conversationId,
        senderId: userId,
        receiverId: receiverId,
        content: content,
        messageType: messageType,
        listingId: listingId,
        isRead: false,
        createdAt: now,
      );

      // Add to Firestore
      await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .doc(messageId)
          .set(message.toJson());

      // Update conversation's last message and timestamp
      await _firestore.collection('conversations').doc(conversationId).update({
        'lastMessage': message.toJson(),
        'updatedAt': Timestamp.fromDate(now),
      });

      return message;
    } catch (e) {
      // Add to offline queue if sending fails
      _addToOfflineQueue({
        'conversationId': conversationId,
        'receiverId': receiverId,
        'content': content,
        'messageType': messageType.name,
        'listingId': listingId,
        'timestamp': DateTime.now().toIso8601String(),
      });
      rethrow;
    }
  }

  /// Get all conversations for the current user
  Stream<List<Conversation>> watchConversations() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection('conversations')
        .where('participantIds', arrayContains: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Conversation.fromJson(doc.data()))
              .toList();
        });
  }

  /// Get messages for a specific conversation
  Stream<List<Message>> watchConversationMessages(String conversationId) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Message.fromJson(doc.data()))
              .toList();
        });
  }

  /// Mark a message as read
  Future<void> markMessageAsRead(
    String conversationId,
    String messageId,
  ) async {
    try {
      await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .doc(messageId)
          .update({'isRead': true});
    } catch (e) {
      rethrow;
    }
  }

  /// Mark all messages in a conversation as read
  Future<void> markConversationAsRead(String conversationId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      final batch = _firestore.batch();

      final messagesQuery = await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .where('receiverId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (final doc in messagesQuery.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      // Update unread count in conversation
      await _firestore.collection('conversations').doc(conversationId).update({
        'unreadCount': 0,
      });

      await batch.commit();
    } catch (e) {
      rethrow;
    }
  }

  /// Get or create a conversation between two users
  Future<Conversation> getOrCreateConversation(String otherUserId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      // Query for existing conversation
      final query = await _firestore
          .collection('conversations')
          .where('participantIds', arrayContains: userId)
          .get();

      for (final doc in query.docs) {
        final conversation = Conversation.fromJson(doc.data());
        if (conversation.participantIds.contains(otherUserId)) {
          return conversation;
        }
      }

      // Create new conversation if none exists
      final conversationId = _firestore.collection('conversations').doc().id;
      final now = DateTime.now();

      final conversation = Conversation(
        conversationId: conversationId,
        participantIds: [userId, otherUserId],
        lastMessage: null,
        unreadCount: 0,
        createdAt: now,
        updatedAt: now,
      );

      await _firestore
          .collection('conversations')
          .doc(conversationId)
          .set(conversation.toJson());

      return conversation;
    } catch (e) {
      rethrow;
    }
  }

  /// Get unread message count for a conversation
  Future<int> getUnreadCount(String conversationId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      final query = await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .where('receiverId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      return query.docs.length;
    } catch (e) {
      rethrow;
    }
  }

  /// Delete a message
  Future<void> deleteMessage(String conversationId, String messageId) async {
    try {
      await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .doc(messageId)
          .delete();
    } catch (e) {
      rethrow;
    }
  }

  /// Add a message to the offline queue
  void _addToOfflineQueue(Map<String, dynamic> messageData) {
    _offlineQueue.add(messageData);
  }

  /// Get offline queue
  List<Map<String, dynamic>> getOfflineQueue() {
    return List.from(_offlineQueue);
  }

  /// Clear offline queue
  void clearOfflineQueue() {
    _offlineQueue.clear();
  }

  /// Sync offline messages when back online
  Future<void> syncOfflineMessages() async {
    try {
      final queue = List.from(_offlineQueue);
      for (final messageData in queue) {
        await sendMessage(
          conversationId: messageData['conversationId'],
          receiverId: messageData['receiverId'],
          content: messageData['content'],
          messageType: MessageType.text,
          listingId: messageData['listingId'],
        );
        _offlineQueue.removeWhere(
          (msg) =>
              msg['timestamp'] == messageData['timestamp'] &&
              msg['content'] == messageData['content'],
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get total unread count across all conversations
  Future<int> getTotalUnreadCount() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      final conversations = await _firestore
          .collection('conversations')
          .where('participantIds', arrayContains: userId)
          .get();

      int totalUnread = 0;
      for (final doc in conversations.docs) {
        final unreadCount = doc.data()['unreadCount'] as int? ?? 0;
        totalUnread += unreadCount;
      }

      return totalUnread;
    } catch (e) {
      rethrow;
    }
  }
}
