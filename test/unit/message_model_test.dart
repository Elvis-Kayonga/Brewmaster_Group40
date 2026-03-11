import 'package:flutter_test/flutter_test.dart';
import 'package:brewmaster/domain/models/message.dart';
import 'package:brewmaster/domain/models/conversation.dart';
import 'package:faker/faker.dart';

void main() {
  group('Message Model Property Tests', () {
    /// Property 1: Message Serialization Round-Trip
    /// Validates: Message toJson/fromJson works correctly
    /// Feature: brewmaster-marketplace, Property 1: Message Serialization Round-Trip
    test(
      'Property 1: Message serialization and deserialization should preserve all fields',
      () {
        final faker = Faker();

        for (int i = 0; i < 100; i++) {
          // Generate random message
          final messageId = faker.guid.guid();
          final conversationId = faker.guid.guid();
          final senderId = faker.guid.guid();
          final receiverId = faker.guid.guid();
          final content = faker.lorem.sentence();
          final messageType = MessageType.values[i % 2];
          final listingId = i % 5 == 0 ? faker.guid.guid() : null;
          final isRead = i % 2 == 0;
          final createdAt = DateTime.now().subtract(Duration(hours: i));

          final originalMessage = Message(
            messageId: messageId,
            conversationId: conversationId,
            senderId: senderId,
            receiverId: receiverId,
            content: content,
            messageType: messageType,
            listingId: listingId,
            isRead: isRead,
            createdAt: createdAt,
          );

          // Serialize and deserialize
          final json = originalMessage.toJson();
          final deserializedMessage = Message.fromJson(json);

          // Verify all fields match
          expect(
            deserializedMessage.messageId,
            equals(messageId),
            reason: 'messageId should match after round-trip',
          );
          expect(
            deserializedMessage.conversationId,
            equals(conversationId),
            reason: 'conversationId should match after round-trip',
          );
          expect(
            deserializedMessage.senderId,
            equals(senderId),
            reason: 'senderId should match after round-trip',
          );
          expect(
            deserializedMessage.receiverId,
            equals(receiverId),
            reason: 'receiverId should match after round-trip',
          );
          expect(
            deserializedMessage.content,
            equals(content),
            reason: 'content should match after round-trip',
          );
          expect(
            deserializedMessage.messageType,
            equals(messageType),
            reason: 'messageType should match after round-trip',
          );
          expect(
            deserializedMessage.listingId,
            equals(listingId),
            reason: 'listingId should match after round-trip',
          );
          expect(
            deserializedMessage.isRead,
            equals(isRead),
            reason: 'isRead should match after round-trip',
          );
        }
      },
    );

    /// Property 2: Message Read Status Update
    /// Validates: copyWith method preserves all but specified fields
    /// Feature: brewmaster-marketplace, Property 2: Message Read Status Update
    test(
      'Property 2: Message copyWith should update only specified fields',
      () {
        final faker = Faker();

        for (int i = 0; i < 100; i++) {
          final original = Message(
            messageId: faker.guid.guid(),
            conversationId: faker.guid.guid(),
            senderId: faker.guid.guid(),
            receiverId: faker.guid.guid(),
            content: faker.lorem.sentence(),
            messageType: MessageType.text,
            listingId: null,
            isRead: false,
            createdAt: DateTime.now(),
          );

          final updated = original.copyWith(isRead: true);

          // Verify unchanged fields
          expect(
            updated.messageId,
            equals(original.messageId),
            reason: 'messageId should not change with copyWith',
          );
          expect(
            updated.conversationId,
            equals(original.conversationId),
            reason: 'conversationId should not change with copyWith',
          );
          expect(
            updated.senderId,
            equals(original.senderId),
            reason: 'senderId should not change with copyWith',
          );
          expect(
            updated.receiverId,
            equals(original.receiverId),
            reason: 'receiverId should not change with copyWith',
          );
          expect(
            updated.content,
            equals(original.content),
            reason: 'content should not change with copyWith',
          );
          expect(
            updated.createdAt,
            equals(original.createdAt),
            reason: 'createdAt should not change with copyWith',
          );

          // Verify changed field
          expect(
            updated.isRead,
            equals(true),
            reason: 'isRead should be updated',
          );
        }
      },
    );

    /// Property 3: Listing Reference Messages
    /// Validates: Messages with listing references are properly handled
    /// Feature: brewmaster-marketplace, Property 3: Listing Reference Messages
    test(
      'Property 3: Messages with listing references should serialize correctly',
      () {
        final faker = Faker();

        for (int i = 0; i < 100; i++) {
          final message = Message(
            messageId: faker.guid.guid(),
            conversationId: faker.guid.guid(),
            senderId: faker.guid.guid(),
            receiverId: faker.guid.guid(),
            content: faker.lorem.sentence(),
            messageType: MessageType.listingReference,
            listingId: faker.guid.guid(),
            isRead: i % 2 == 0,
            createdAt: DateTime.now(),
          );

          final json = message.toJson();
          expect(
            json['messageType'],
            equals('listingReference'),
            reason: 'messageType should be listingReference',
          );
          expect(
            json['listingId'],
            isNotNull,
            reason:
                'listingId should not be null for listing reference messages',
          );

          final deserialized = Message.fromJson(json);
          expect(
            deserialized.messageType,
            equals(MessageType.listingReference),
            reason: 'messageType should deserialize correctly',
          );
          expect(
            deserialized.listingId,
            isNotNull,
            reason: 'listingId should be preserved',
          );
        }
      },
    );
  });

  group('Conversation Model Property Tests', () {
    /// Property 4: Conversation Serialization
    /// Validates: Conversation serialization and deserialization
    /// Feature: brewmaster-marketplace, Property 4: Conversation Serialization
    test(
      'Property 4: Conversation serialization should preserve all fields',
      () {
        final faker = Faker();

        for (int i = 0; i < 100; i++) {
          final conversationId = faker.guid.guid();
          final participantIds = [faker.guid.guid(), faker.guid.guid()];
          final unreadCount = faker.randomGenerator.integer(100);
          final createdAt = DateTime.now().subtract(Duration(days: i));
          final updatedAt = DateTime.now();

          final original = Conversation(
            conversationId: conversationId,
            participantIds: participantIds,
            lastMessage: null,
            unreadCount: unreadCount,
            createdAt: createdAt,
            updatedAt: updatedAt,
          );

          final json = original.toJson();
          final deserialized = Conversation.fromJson(json);

          expect(
            deserialized.conversationId,
            equals(conversationId),
            reason: 'conversationId should match',
          );
          expect(
            deserialized.participantIds,
            equals(participantIds),
            reason: 'participantIds should match',
          );
          expect(
            deserialized.unreadCount,
            equals(unreadCount),
            reason: 'unreadCount should match',
          );
        }
      },
    );

    /// Property 5: Conversation Unread Count Updates
    /// Validates: copyWith properly updates unread count
    /// Feature: brewmaster-marketplace, Property 5: Conversation Unread Count Updates
    test(
      'Property 5: Conversation copyWith should correctly update unread count',
      () {
        final faker = Faker();

        for (int i = 0; i < 100; i++) {
          final original = Conversation(
            conversationId: faker.guid.guid(),
            participantIds: [faker.guid.guid(), faker.guid.guid()],
            lastMessage: null,
            unreadCount: i,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          final newUnreadCount = (i + 10) % 100;
          final updated = original.copyWith(unreadCount: newUnreadCount);

          expect(
            updated.unreadCount,
            equals(newUnreadCount),
            reason: 'unreadCount should be updated',
          );
          expect(
            updated.conversationId,
            equals(original.conversationId),
            reason: 'conversationId should remain unchanged',
          );
          expect(
            updated.participantIds,
            equals(original.participantIds),
            reason: 'participantIds should remain unchanged',
          );
        }
      },
    );

    /// Property 6: Conversation with Last Message
    /// Validates: Conversations correctly include nested last message
    /// Feature: brewmaster-marketplace, Property 6: Conversation with Last Message
    test(
      'Property 6: Conversation with last message should serialize correctly',
      () {
        final faker = Faker();

        for (int i = 0; i < 100; i++) {
          final lastMessage = Message(
            messageId: faker.guid.guid(),
            conversationId: faker.guid.guid(),
            senderId: faker.guid.guid(),
            receiverId: faker.guid.guid(),
            content: faker.lorem.sentence(),
            messageType: MessageType.text,
            listingId: null,
            isRead: true,
            createdAt: DateTime.now(),
          );

          final conversation = Conversation(
            conversationId: faker.guid.guid(),
            participantIds: [faker.guid.guid(), faker.guid.guid()],
            lastMessage: lastMessage,
            unreadCount: 0,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          final json = conversation.toJson();
          expect(
            json['lastMessage'],
            isNotNull,
            reason: 'lastMessage should not be null in JSON',
          );

          final deserialized = Conversation.fromJson(json);
          expect(
            deserialized.lastMessage,
            isNotNull,
            reason: 'lastMessage should be deserialized',
          );
          expect(
            deserialized.lastMessage!.messageId,
            equals(lastMessage.messageId),
            reason: 'last message ID should match',
          );
        }
      },
    );
  });

  group('Message Delivery Property Tests', () {
    /// Property 7: Message Ordering
    /// Validates: Messages are correctly ordered by creation time
    /// Feature: brewmaster-marketplace, Property 7: Message Ordering
    test(
      'Property 7: Messages should maintain chronological order by createdAt',
      () {
        final faker = Faker();

        for (int test = 0; test < 100; test++) {
          final messages = <Message>[];
          final baseTime = DateTime.now();

          for (int i = 0; i < 10; i++) {
            messages.add(
              Message(
                messageId: faker.guid.guid(),
                conversationId: 'conv-test',
                senderId: faker.guid.guid(),
                receiverId: faker.guid.guid(),
                content: 'Message $i',
                messageType: MessageType.text,
                listingId: null,
                isRead: false,
                createdAt: baseTime.add(Duration(minutes: i)),
              ),
            );
          }

          // Shuffle and sort
          messages.shuffle();
          messages.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          // Verify order (most recent first)
          for (int i = 0; i < messages.length - 1; i++) {
            expect(
              messages[i].createdAt.isAfter(messages[i + 1].createdAt) ||
                  messages[i].createdAt.isAtSameMomentAs(
                    messages[i + 1].createdAt,
                  ),
              true,
              reason: 'Messages should be in reverse chronological order',
            );
          }
        }
      },
    );

    /// Property 8: Unread Count Consistency
    /// Validates: Unread count is always non-negative
    /// Feature: brewmaster-marketplace, Property 8: Unread Count Consistency
    test('Property 8: Unread count should never be negative', () {
      final faker = Faker();

      for (int i = 0; i < 100; i++) {
        final unreadCount = faker.randomGenerator.integer(1000);

        final conversation = Conversation(
          conversationId: faker.guid.guid(),
          participantIds: [faker.guid.guid(), faker.guid.guid()],
          lastMessage: null,
          unreadCount: unreadCount,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(
          conversation.unreadCount,
          greaterThanOrEqualTo(0),
          reason: 'Unread count should never be negative',
        );
      }
    });
  });
}
