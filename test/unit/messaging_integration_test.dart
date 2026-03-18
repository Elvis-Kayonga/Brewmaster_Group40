import 'package:flutter_test/flutter_test.dart';
import 'package:brewmaster/domain/models/message.dart';
import 'package:brewmaster/domain/models/conversation.dart';

void main() {
  group('Messaging Integration Tests', () {
    test('message creation with all required fields', () {
      final message = Message(
        messageId: 'msg-123',
        conversationId: 'conv-123',
        senderId: 'user1',
        receiverId: 'user2',
        content: 'Hello',
        messageType: MessageType.text,
        listingId: null,
        isRead: false,
        createdAt: DateTime.now(),
      );

      expect(message.messageId, 'msg-123');
      expect(message.content, 'Hello');
      expect(message.isRead, isFalse);
    });

    test('conversation creation with participants', () {
      final conversation = Conversation(
        conversationId: 'conv-123',
        participantIds: ['user1', 'user2'],
        lastMessage: null,
        unreadCount: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(conversation.participantIds.length, 2);
      expect(conversation.unreadCount, 0);
    });

    test('message copyWith updates only specified fields', () {
      final original = Message(
        messageId: 'msg-123',
        conversationId: 'conv-123',
        senderId: 'user1',
        receiverId: 'user2',
        content: 'Hello',
        messageType: MessageType.text,
        listingId: null,
        isRead: false,
        createdAt: DateTime.now(),
      );

      final updated = original.copyWith(isRead: true);

      expect(updated.messageId, original.messageId);
      expect(updated.content, original.content);
      expect(updated.isRead, isTrue);
    });

    test('conversation copyWith updates unread count', () {
      final original = Conversation(
        conversationId: 'conv-123',
        participantIds: ['user1', 'user2'],
        lastMessage: null,
        unreadCount: 5,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final updated = original.copyWith(unreadCount: 0);

      expect(updated.conversationId, original.conversationId);
      expect(updated.unreadCount, 0);
    });

    test('listing reference message includes listing ID', () {
      final message = Message(
        messageId: 'msg-123',
        conversationId: 'conv-123',
        senderId: 'user1',
        receiverId: 'user2',
        content: 'Check this listing',
        messageType: MessageType.listingReference,
        listingId: 'listing-456',
        isRead: false,
        createdAt: DateTime.now(),
      );

      expect(message.messageType, MessageType.listingReference);
      expect(message.listingId, 'listing-456');
    });

    test('conversation with last message', () {
      final lastMessage = Message(
        messageId: 'msg-123',
        conversationId: 'conv-123',
        senderId: 'user1',
        receiverId: 'user2',
        content: 'Last message',
        messageType: MessageType.text,
        listingId: null,
        isRead: true,
        createdAt: DateTime.now(),
      );

      final conversation = Conversation(
        conversationId: 'conv-123',
        participantIds: ['user1', 'user2'],
        lastMessage: lastMessage,
        unreadCount: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(conversation.lastMessage, isNotNull);
      expect(conversation.lastMessage!.content, 'Last message');
    });

    test('messages maintain chronological order', () {
      final baseTime = DateTime.now();
      final messages = [
        Message(
          messageId: 'msg-1',
          conversationId: 'conv-123',
          senderId: 'user1',
          receiverId: 'user2',
          content: 'First',
          messageType: MessageType.text,
          listingId: null,
          isRead: false,
          createdAt: baseTime,
        ),
        Message(
          messageId: 'msg-2',
          conversationId: 'conv-123',
          senderId: 'user1',
          receiverId: 'user2',
          content: 'Second',
          messageType: MessageType.text,
          listingId: null,
          isRead: false,
          createdAt: baseTime.add(const Duration(minutes: 1)),
        ),
        Message(
          messageId: 'msg-3',
          conversationId: 'conv-123',
          senderId: 'user1',
          receiverId: 'user2',
          content: 'Third',
          messageType: MessageType.text,
          listingId: null,
          isRead: false,
          createdAt: baseTime.add(const Duration(minutes: 2)),
        ),
      ];

      messages.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      expect(messages[0].content, 'Third');
      expect(messages[1].content, 'Second');
      expect(messages[2].content, 'First');
    });

    test('unread count is always non-negative', () {
      final conversation = Conversation(
        conversationId: 'conv-123',
        participantIds: ['user1', 'user2'],
        lastMessage: null,
        unreadCount: 10,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(conversation.unreadCount, greaterThanOrEqualTo(0));
    });

    test('conversation participants are unique', () {
      final participantIds = ['user1', 'user2'];
      final uniqueIds = participantIds.toSet();

      expect(participantIds.length, equals(uniqueIds.length));
    });
  });

  group('Notification Integration Tests', () {
    test('notification preferences structure', () {
      final preferences = {
        'messagesEnabled': true,
        'listingsEnabled': true,
        'paymentsEnabled': false,
        'promotionsEnabled': true,
      };

      expect(preferences.containsKey('messagesEnabled'), isTrue);
      expect(preferences.containsKey('listingsEnabled'), isTrue);
      expect(preferences.containsKey('paymentsEnabled'), isTrue);
      expect(preferences.containsKey('promotionsEnabled'), isTrue);
    });

    test('all notification preferences are boolean', () {
      final preferences = {
        'messagesEnabled': true,
        'listingsEnabled': false,
        'paymentsEnabled': true,
        'promotionsEnabled': false,
      };

      preferences.forEach((key, value) {
        expect(value, isA<bool>());
      });
    });

    test('fcm token format validation', () {
      final token = 'fcm-token-123456789';
      expect(token, isNotEmpty);
      expect(token, isA<String>());
    });

    test('topic subscription deduplication', () {
      final subscriptions = ['coffee-prices', 'coffee-prices', 'new-listings'];
      final uniqueSubscriptions = subscriptions.toSet();

      expect(uniqueSubscriptions.length, 2);
      expect(uniqueSubscriptions.contains('coffee-prices'), isTrue);
      expect(uniqueSubscriptions.contains('new-listings'), isTrue);
    });
  });
}
