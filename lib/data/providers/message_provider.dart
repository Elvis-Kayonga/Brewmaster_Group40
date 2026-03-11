import 'package:flutter/material.dart';
import '../../domain/models/message.dart';
import '../../domain/models/conversation.dart';
import '../services/message_service.dart';

/// Provider for managing messaging state
/// Handles conversations, messages, and real-time updates
class MessageProvider extends ChangeNotifier {
  final MessageService _messageService = MessageService();

  List<Conversation> _conversations = [];
  List<Message> _currentConversationMessages = [];
  String? _currentConversationId;
  bool _isLoading = false;
  String? _error;
  int _totalUnreadCount = 0;

  // Getters
  List<Conversation> get conversations => _conversations;
  List<Message> get currentConversationMessages => _currentConversationMessages;
  String? get currentConversationId => _currentConversationId;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get totalUnreadCount => _totalUnreadCount;

  /// Initialize conversation listener
  void initConversationListener() {
    _messageService.watchConversations().listen((conversations) {
      _conversations = conversations;
      notifyListeners();
      // Update total unread count
      _updateTotalUnreadCount();
    });
  }

  /// Load messages for a specific conversation
  void loadConversationMessages(String conversationId) {
    _currentConversationId = conversationId;
    _messageService.watchConversationMessages(conversationId).listen((
      messages,
    ) {
      _currentConversationMessages = messages;
      notifyListeners();
      // Mark conversation as read
      _messageService.markConversationAsRead(conversationId);
    });
  }

  /// Send a message
  Future<void> sendMessage({
    required String conversationId,
    required String receiverId,
    required String content,
    MessageType messageType = MessageType.text,
    String? listingId,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _messageService.sendMessage(
        conversationId: conversationId,
        receiverId: receiverId,
        content: content,
        messageType: messageType,
        listingId: listingId,
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Get or create a conversation
  Future<Conversation?> getOrCreateConversation(String otherUserId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final conversation = await _messageService.getOrCreateConversation(
        otherUserId,
      );

      _isLoading = false;
      notifyListeners();

      return conversation;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Mark a message as read
  Future<void> markMessageAsRead(
    String conversationId,
    String messageId,
  ) async {
    try {
      await _messageService.markMessageAsRead(conversationId, messageId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Delete a message
  Future<void> deleteMessage(String conversationId, String messageId) async {
    try {
      await _messageService.deleteMessage(conversationId, messageId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Get unread count for a conversation
  Future<int> getUnreadCount(String conversationId) async {
    try {
      return await _messageService.getUnreadCount(conversationId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return 0;
    }
  }

  /// Get offline queue
  List<Map<String, dynamic>> getOfflineQueue() {
    return _messageService.getOfflineQueue();
  }

  /// Sync offline messages
  Future<void> syncOfflineMessages() async {
    try {
      _isLoading = true;
      notifyListeners();

      await _messageService.syncOfflineMessages();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Update total unread count
  Future<void> _updateTotalUnreadCount() async {
    try {
      _totalUnreadCount = await _messageService.getTotalUnreadCount();
      notifyListeners();
    } catch (e) {
      // Silent fail for background update
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Search conversations by participant name
  List<Conversation> searchConversations(String query) {
    if (query.isEmpty) return _conversations;
    // This would require storing participant names in conversation
    // For now, return all conversations
    return _conversations;
  }
}
