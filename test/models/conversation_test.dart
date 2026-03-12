/// Unit tests for Conversation model
///
/// Testing patterns:
/// 1. Object creation and instantiation
/// 2. JSON serialization and deserialization
/// 3. Firestore Timestamp handling
/// 4. copyWith functionality
/// 5. Message integration
/// 6. Participant management
/// 7. Unread count tracking
///
/// Requirements: 5.2, 5.5, 16.1
/// Developer: Developer 3

import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:brewmaster/domain/models/conversation.dart';
import 'package:brewmaster/domain/models/message.dart';

void main() {
  group('Conversation Model Tests', () {
    late DateTime testDate;
    late Timestamp testTimestamp;

    setUp(() {
      testDate = DateTime(2024, 1, 15, 10, 30, 0);
      testTimestamp = Timestamp.fromDate(testDate);
    });

    group('Object Creation Tests', () {
      test('Should create conversation with all fields', () {
        final message = Message(
          messageId: 'msg-001',
          conversationId: 'conv-001',
          senderId: 'user-123',
          receiverId: 'user-456',
          content: 'Hello, interested in your coffee',
          messageType: MessageType.text,
          isRead: false,
          createdAt: testDate,
        );

        final conversation = Conversation(
          conversationId: 'conv-001',
          participantIds: ['user-123', 'user-456'],
          lastMessage: message,
          unreadCount: 3,
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(conversation.conversationId, 'conv-001');
        expect(conversation.participantIds, ['user-123', 'user-456']);
        expect(conversation.lastMessage, message);
        expect(conversation.unreadCount, 3);
        expect(conversation.createdAt, testDate);
        expect(conversation.updatedAt, testDate);
      });

      test('Should create conversation without lastMessage', () {
        final conversation = Conversation(
          conversationId: 'conv-new',
          participantIds: ['user-111', 'user-222'],
          lastMessage: null,
          unreadCount: 0,
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(conversation.conversationId, 'conv-new');
        expect(conversation.lastMessage, isNull);
        expect(conversation.unreadCount, 0);
      });

      test('Should handle multiple participants', () {
        final conversation = Conversation(
          conversationId: 'conv-group',
          participantIds: ['user-1', 'user-2', 'user-3'],
          unreadCount: 0,
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(conversation.participantIds.length, 3);
        expect(conversation.participantIds, contains('user-1'));
        expect(conversation.participantIds, contains('user-2'));
        expect(conversation.participantIds, contains('user-3'));
      });

      test('Should handle zero unread count', () {
        final conversation = Conversation(
          conversationId: 'conv-read',
          participantIds: ['user-1', 'user-2'],
          unreadCount: 0,
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(conversation.unreadCount, 0);
      });

      test('Should handle high unread count', () {
        final conversation = Conversation(
          conversationId: 'conv-unread',
          participantIds: ['user-1', 'user-2'],
          unreadCount: 99,
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(conversation.unreadCount, 99);
      });
    });

    group('JSON Serialization Tests', () {
      test('Should convert to JSON correctly with lastMessage', () {
        final message = Message(
          messageId: 'msg-001',
          conversationId: 'conv-001',
          senderId: 'user-123',
          receiverId: 'user-456',
          content: 'Test message',
          messageType: MessageType.text,
          isRead: true,
          createdAt: testDate,
        );

        final conversation = Conversation(
          conversationId: 'conv-001',
          participantIds: ['user-123', 'user-456'],
          lastMessage: message,
          unreadCount: 2,
          createdAt: testDate,
          updatedAt: testDate,
        );

        final json = conversation.toJson();

        expect(json['conversationId'], 'conv-001');
        expect(json['participantIds'], ['user-123', 'user-456']);
        expect(json['lastMessage'], isNotNull);
        expect(json['lastMessage']['messageId'], 'msg-001');
        expect(json['unreadCount'], 2);
        expect(json['createdAt'], isA<Timestamp>());
        expect(json['updatedAt'], isA<Timestamp>());
      });

      test('Should convert to JSON correctly without lastMessage', () {
        final conversation = Conversation(
          conversationId: 'conv-002',
          participantIds: ['user-111', 'user-222'],
          lastMessage: null,
          unreadCount: 0,
          createdAt: testDate,
          updatedAt: testDate,
        );

        final json = conversation.toJson();

        expect(json['conversationId'], 'conv-002');
        expect(json['participantIds'], ['user-111', 'user-222']);
        expect(json['lastMessage'], isNull);
        expect(json['unreadCount'], 0);
      });

      test('Should deserialize from JSON with lastMessage', () {
        final json = {
          'conversationId': 'conv-003',
          'participantIds': ['user-123', 'user-456'],
          'lastMessage': {
            'messageId': 'msg-100',
            'conversationId': 'conv-003',
            'senderId': 'user-123',
            'receiverId': 'user-456',
            'content': 'Latest message',
            'messageType': 'text',
            'isRead': false,
            'createdAt': testTimestamp,
          },
          'unreadCount': 5,
          'createdAt': testTimestamp,
          'updatedAt': testTimestamp,
        };

        final conversation = Conversation.fromJson(json);

        expect(conversation.conversationId, 'conv-003');
        expect(conversation.participantIds, ['user-123', 'user-456']);
        expect(conversation.lastMessage, isNotNull);
        expect(conversation.lastMessage!.messageId, 'msg-100');
        expect(conversation.lastMessage!.content, 'Latest message');
        expect(conversation.unreadCount, 5);
        expect(conversation.createdAt.year, 2024);
        expect(conversation.createdAt.month, 1);
        expect(conversation.updatedAt.year, 2024);
      });

      test('Should deserialize from JSON without lastMessage', () {
        final json = {
          'conversationId': 'conv-004',
          'participantIds': ['user-111', 'user-222'],
          'lastMessage': null,
          'unreadCount': 0,
          'createdAt': testTimestamp,
          'updatedAt': testTimestamp,
        };

        final conversation = Conversation.fromJson(json);

        expect(conversation.conversationId, 'conv-004');
        expect(conversation.participantIds, ['user-111', 'user-222']);
        expect(conversation.lastMessage, isNull);
        expect(conversation.unreadCount, 0);
      });

      test('Should roundtrip through JSON successfully', () {
        final message = Message(
          messageId: 'msg-rt',
          conversationId: 'conv-rt',
          senderId: 'user-a',
          receiverId: 'user-b',
          content: 'Roundtrip test',
          messageType: MessageType.listingReference,
          listingId: 'listing-123',
          isRead: true,
          createdAt: testDate,
        );

        final original = Conversation(
          conversationId: 'conv-rt',
          participantIds: ['user-a', 'user-b'],
          lastMessage: message,
          unreadCount: 7,
          createdAt: testDate,
          updatedAt: testDate.add(const Duration(hours: 1)),
        );

        final json = original.toJson();
        final restored = Conversation.fromJson(json);

        expect(restored.conversationId, original.conversationId);
        expect(restored.participantIds, original.participantIds);
        expect(restored.lastMessage!.messageId, original.lastMessage!.messageId);
        expect(restored.lastMessage!.content, original.lastMessage!.content);
        expect(restored.lastMessage!.listingId, original.lastMessage!.listingId);
        expect(restored.unreadCount, original.unreadCount);
        expect(restored.createdAt, original.createdAt);
        expect(restored.updatedAt, original.updatedAt);
      });
    });

    group('copyWith Tests', () {
      late Conversation baseConversation;

      setUp(() {
        baseConversation = Conversation(
          conversationId: 'conv-base',
          participantIds: ['user-1', 'user-2'],
          lastMessage: Message(
            messageId: 'msg-old',
            conversationId: 'conv-base',
            senderId: 'user-1',
            receiverId: 'user-2',
            content: 'Old message',
            messageType: MessageType.text,
            isRead: true,
            createdAt: testDate,
          ),
          unreadCount: 3,
          createdAt: testDate,
          updatedAt: testDate,
        );
      });

      test('Should copy with new lastMessage', () {
        final newMessage = Message(
          messageId: 'msg-new',
          conversationId: 'conv-base',
          senderId: 'user-2',
          receiverId: 'user-1',
          content: 'New message',
          messageType: MessageType.text,
          isRead: false,
          createdAt: testDate.add(const Duration(minutes: 30)),
        );

        final updated = baseConversation.copyWith(lastMessage: newMessage);

        expect(updated.conversationId, baseConversation.conversationId);
        expect(updated.participantIds, baseConversation.participantIds);
        expect(updated.lastMessage!.messageId, 'msg-new');
        expect(updated.lastMessage!.content, 'New message');
        expect(updated.unreadCount, baseConversation.unreadCount);
        expect(updated.createdAt, baseConversation.createdAt);
        expect(updated.updatedAt, baseConversation.updatedAt);
      });

      test('Should copy with new unreadCount', () {
        final updated = baseConversation.copyWith(unreadCount: 10);

        expect(updated.conversationId, baseConversation.conversationId);
        expect(updated.participantIds, baseConversation.participantIds);
        expect(updated.lastMessage!.messageId, baseConversation.lastMessage!.messageId);
        expect(updated.unreadCount, 10);
        expect(updated.createdAt, baseConversation.createdAt);
      });

      test('Should copy with new updatedAt', () {
        final newUpdateTime = testDate.add(const Duration(hours: 2));
        final updated = baseConversation.copyWith(updatedAt: newUpdateTime);

        expect(updated.conversationId, baseConversation.conversationId);
        expect(updated.participantIds, baseConversation.participantIds);
        expect(updated.updatedAt, newUpdateTime);
        expect(updated.createdAt, baseConversation.createdAt);
      });

      test('Should copy with multiple updates', () {
        final newMessage = Message(
          messageId: 'msg-latest',
          conversationId: 'conv-base',
          senderId: 'user-1',
          receiverId: 'user-2',
          content: 'Latest message',
          messageType: MessageType.text,
          isRead: false,
          createdAt: testDate.add(const Duration(hours: 1)),
        );

        final newUpdateTime = testDate.add(const Duration(hours: 1));

        final updated = baseConversation.copyWith(
          lastMessage: newMessage,
          unreadCount: 5,
          updatedAt: newUpdateTime,
        );

        expect(updated.lastMessage!.messageId, 'msg-latest');
        expect(updated.unreadCount, 5);
        expect(updated.updatedAt, newUpdateTime);
      });

      test('Should copy without changes when no parameters provided', () {
        final updated = baseConversation.copyWith();

        expect(updated.conversationId, baseConversation.conversationId);
        expect(updated.participantIds, baseConversation.participantIds);
        expect(updated.lastMessage!.messageId, baseConversation.lastMessage!.messageId);
        expect(updated.unreadCount, baseConversation.unreadCount);
        expect(updated.createdAt, baseConversation.createdAt);
        expect(updated.updatedAt, baseConversation.updatedAt);
      });

      test('Should reset unreadCount to zero', () {
        final updated = baseConversation.copyWith(unreadCount: 0);

        expect(updated.unreadCount, 0);
      });
    });

    group('Message Type Integration Tests', () {
      test('Should handle text message type', () {
        final message = Message(
          messageId: 'msg-text',
          conversationId: 'conv-001',
          senderId: 'user-1',
          receiverId: 'user-2',
          content: 'Plain text message',
          messageType: MessageType.text,
          isRead: false,
          createdAt: testDate,
        );

        final conversation = Conversation(
          conversationId: 'conv-001',
          participantIds: ['user-1', 'user-2'],
          lastMessage: message,
          unreadCount: 1,
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(conversation.lastMessage!.messageType, MessageType.text);
        expect(conversation.lastMessage!.listingId, isNull);
      });

      test('Should handle listing reference message type', () {
        final message = Message(
          messageId: 'msg-listing',
          conversationId: 'conv-002',
          senderId: 'user-buyer',
          receiverId: 'user-farmer',
          content: 'Interested in this listing',
          messageType: MessageType.listingReference,
          listingId: 'listing-456',
          isRead: false,
          createdAt: testDate,
        );

        final conversation = Conversation(
          conversationId: 'conv-002',
          participantIds: ['user-buyer', 'user-farmer'],
          lastMessage: message,
          unreadCount: 1,
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(conversation.lastMessage!.messageType, MessageType.listingReference);
        expect(conversation.lastMessage!.listingId, 'listing-456');
      });
    });

    group('Edge Cases and Validation Tests', () {
      test('Should handle empty participant list', () {
        final conversation = Conversation(
          conversationId: 'conv-empty',
          participantIds: [],
          unreadCount: 0,
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(conversation.participantIds, isEmpty);
      });

      test('Should handle single participant', () {
        final conversation = Conversation(
          conversationId: 'conv-solo',
          participantIds: ['user-only'],
          unreadCount: 0,
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(conversation.participantIds.length, 1);
        expect(conversation.participantIds.first, 'user-only');
      });

      test('Should handle updatedAt after createdAt', () {
        final createdTime = DateTime(2024, 1, 1, 10, 0);
        final updatedTime = DateTime(2024, 1, 1, 11, 30);

        final conversation = Conversation(
          conversationId: 'conv-time',
          participantIds: ['user-1', 'user-2'],
          unreadCount: 0,
          createdAt: createdTime,
          updatedAt: updatedTime,
        );

        expect(conversation.updatedAt.isAfter(conversation.createdAt), isTrue);
        expect(
          conversation.updatedAt.difference(conversation.createdAt),
          const Duration(hours: 1, minutes: 30),
        );
      });

      test('Should handle createdAt and updatedAt being the same', () {
        final conversation = Conversation(
          conversationId: 'conv-same-time',
          participantIds: ['user-1', 'user-2'],
          unreadCount: 0,
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(conversation.createdAt, conversation.updatedAt);
      });

      test('Should handle very long participant list', () {
        final manyParticipants = List.generate(100, (i) => 'user-$i');

        final conversation = Conversation(
          conversationId: 'conv-many',
          participantIds: manyParticipants,
          unreadCount: 0,
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(conversation.participantIds.length, 100);
        expect(conversation.participantIds.first, 'user-0');
        expect(conversation.participantIds.last, 'user-99');
      });
    });

    group('Business Logic Tests', () {
      test('Should simulate marking messages as read', () {
        final conversation = Conversation(
          conversationId: 'conv-unread',
          participantIds: ['user-1', 'user-2'],
          unreadCount: 5,
          createdAt: testDate,
          updatedAt: testDate,
        );

        // Simulate marking all as read
        final afterRead = conversation.copyWith(
          unreadCount: 0,
          updatedAt: testDate.add(const Duration(seconds: 1)),
        );

        expect(afterRead.unreadCount, 0);
        expect(afterRead.updatedAt.isAfter(conversation.updatedAt), isTrue);
      });

      test('Should simulate receiving a new message', () {
        final oldMessage = Message(
          messageId: 'msg-old',
          conversationId: 'conv-001',
          senderId: 'user-1',
          receiverId: 'user-2',
          content: 'Old message',
          messageType: MessageType.text,
          isRead: true,
          createdAt: testDate,
        );

        final conversation = Conversation(
          conversationId: 'conv-001',
          participantIds: ['user-1', 'user-2'],
          lastMessage: oldMessage,
          unreadCount: 0,
          createdAt: testDate,
          updatedAt: testDate,
        );

        // Simulate new message arrival
        final newMessage = Message(
          messageId: 'msg-new',
          conversationId: 'conv-001',
          senderId: 'user-2',
          receiverId: 'user-1',
          content: 'New message',
          messageType: MessageType.text,
          isRead: false,
          createdAt: testDate.add(const Duration(minutes: 10)),
        );

        final afterNewMessage = conversation.copyWith(
          lastMessage: newMessage,
          unreadCount: conversation.unreadCount + 1,
          updatedAt: newMessage.createdAt,
        );

        expect(afterNewMessage.lastMessage!.messageId, 'msg-new');
        expect(afterNewMessage.unreadCount, 1);
        expect(afterNewMessage.updatedAt.isAfter(conversation.updatedAt), isTrue);
      });

      test('Should simulate conversation with increasing unread count', () {
        var conversation = Conversation(
          conversationId: 'conv-increment',
          participantIds: ['user-1', 'user-2'],
          unreadCount: 0,
          createdAt: testDate,
          updatedAt: testDate,
        );

        // Receive 3 messages
        for (var i = 1; i <= 3; i++) {
          final message = Message(
            messageId: 'msg-$i',
            conversationId: 'conv-increment',
            senderId: 'user-2',
            receiverId: 'user-1',
            content: 'Message $i',
            messageType: MessageType.text,
            isRead: false,
            createdAt: testDate.add(Duration(minutes: i)),
          );

          conversation = conversation.copyWith(
            lastMessage: message,
            unreadCount: conversation.unreadCount + 1,
            updatedAt: message.createdAt,
          );
        }

        expect(conversation.unreadCount, 3);
        expect(conversation.lastMessage!.content, 'Message 3');
      });
    });
  });
}
