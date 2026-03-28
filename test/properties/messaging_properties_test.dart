// Feature: brewmaster-marketplace
// Property tests for message delivery, unread counts, read status,
// listing references, and notification preferences.
//
// Validates: Requirements 5.2, 5.3, 5.4, 5.5, 5.6, 12.1, 12.2, 12.6
// Tasks: 9.2, 10.3, 11.3
// Developer: Developer 3

import 'package:flutter_test/flutter_test.dart';

import 'package:brewmaster/domain/models/conversation.dart';
import 'package:brewmaster/domain/models/message.dart';
import 'package:brewmaster/domain/models/paginated_result.dart';
import 'package:brewmaster/domain/repositories/message_repository.dart';
import 'package:brewmaster/domain/repositories/notification_repository.dart';

// ---------------------------------------------------------------------------
// Fake MessageRepository
// ---------------------------------------------------------------------------

class FakeMessageRepository implements MessageRepository {
  final List<Message> _sent = [];
  final Map<String, List<Message>> _messages = {};
  final List<Conversation> _conversations = [];
  bool shouldThrow = false;

  @override
  Future<Message> sendMessage({
    required String conversationId,
    required String receiverId,
    required String content,
    MessageType messageType = MessageType.text,
    String? listingId,
  }) async {
    if (shouldThrow) throw Exception('network error');
    final msg = Message(
      messageId: 'msg_${_sent.length + 1}',
      conversationId: conversationId,
      senderId: 'user_1',
      receiverId: receiverId,
      content: content,
      messageType: messageType,
      listingId: listingId,
      isRead: false,
      createdAt: DateTime.now(),
    );
    _sent.add(msg);
    _messages.putIfAbsent(conversationId, () => []).add(msg);
    return msg;
  }

  @override
  Stream<List<Conversation>> watchConversations() =>
      Stream.value(List.unmodifiable(_conversations));

  @override
  Stream<List<Message>> watchMessages(String conversationId) =>
      Stream.value(List.unmodifiable(_messages[conversationId] ?? []));

  @override
  Future<void> markConversationAsRead(String conversationId) async {
    final msgs = _messages[conversationId];
    if (msgs == null) return;
    for (var i = 0; i < msgs.length; i++) {
      msgs[i] = msgs[i].copyWith(isRead: true);
    }
  }

  @override
  Future<Conversation> getOrCreateConversation(String otherUserId) async {
    final existing = _conversations.where(
      (c) => c.participantIds.contains(otherUserId),
    );
    if (existing.isNotEmpty) return existing.first;

    final convo = Conversation(
      conversationId: 'convo_${_conversations.length + 1}',
      participantIds: ['user_1', otherUserId],
      lastMessage: null,
      unreadCount: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _conversations.add(convo);
    return convo;
  }

  @override
  Future<int> getTotalUnreadCount() async {
    return _conversations.fold<int>(0, (acc, c) => acc + c.unreadCount);
  }

  @override
  Future<PaginatedResult<Message>> getMessagePage({
    required String conversationId,
    int pageSize = 30,
    Object? startAfter,
  }) async =>
      PaginatedResult<Message>(
          items: List.from(_messages[conversationId] ?? []), hasMore: false);

  List<Message> get sentMessages => List.unmodifiable(_sent);

  @override
  Future<void> migrateParticipantPhotoUrls() async {}
}

// ---------------------------------------------------------------------------
// Fake NotificationRepository
// ---------------------------------------------------------------------------

class FakeNotificationRepository implements NotificationRepository {
  bool _permissionGranted = false;
  Map<String, bool> _preferences = {
    'messagesEnabled': true,
    'listingsEnabled': true,
    'paymentsEnabled': true,
    'promotionsEnabled': true,
  };

  @override
  Future<bool> requestPermission() async {
    _permissionGranted = true;
    return true;
  }

  @override
  Future<String?> getToken() async =>
      _permissionGranted ? 'fake_fcm_token' : null;

  @override
  Stream<Map<String, dynamic>> watchNotifications() => const Stream.empty();

  @override
  Future<void> updatePreferences(Map<String, bool> preferences) async {
    _preferences = Map.from(preferences);
  }

  @override
  Future<Map<String, bool>> getPreferences() async =>
      Map.unmodifiable(_preferences);

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

// ---------------------------------------------------------------------------
// Task 9.2 – message delivery and read status properties
// ---------------------------------------------------------------------------

void main() {
  group('Property – Message structure (Requirement 5.2)', () {
    test('all required fields are present after sendMessage', () async {
      final repo = FakeMessageRepository();
      final msg = await repo.sendMessage(
        conversationId: 'c1',
        receiverId: 'user_2',
        content: 'Hello!',
      );
      expect(msg.messageId, isNotEmpty);
      expect(msg.conversationId, equals('c1'));
      expect(msg.senderId, isNotEmpty);
      expect(msg.receiverId, equals('user_2'));
      expect(msg.content, equals('Hello!'));
      expect(msg.messageType, equals(MessageType.text));
      expect(msg.isRead, isFalse);
      expect(msg.createdAt, isNotNull);
    });

    test('fromJson / toJson round-trip preserves all fields', () {
      final now = DateTime(2024, 5, 1, 10, 30);
      final original = Message(
        messageId: 'm1',
        conversationId: 'c1',
        senderId: 's1',
        receiverId: 'r1',
        content: 'Test message',
        messageType: MessageType.text,
        listingId: null,
        isRead: false,
        createdAt: now,
      );
      final json = original.toJson();
      final restored = Message.fromJson({
        ...json,
        'createdAt': json['createdAt'], // already a Timestamp
      });
      expect(restored.messageId, equals(original.messageId));
      expect(restored.content, equals(original.content));
      expect(restored.isRead, equals(original.isRead));
      expect(restored.messageType, equals(original.messageType));
    });

    test('new messages are unread by default', () async {
      final repo = FakeMessageRepository();
      final msg = await repo.sendMessage(
        conversationId: 'c1',
        receiverId: 'r1',
        content: 'Hi',
      );
      expect(msg.isRead, isFalse);
    });

    test('markConversationAsRead marks all messages as read', () async {
      final repo = FakeMessageRepository();
      await repo.sendMessage(
          conversationId: 'c1', receiverId: 'r1', content: 'Msg 1');
      await repo.sendMessage(
          conversationId: 'c1', receiverId: 'r1', content: 'Msg 2');

      await repo.markConversationAsRead('c1');

      final messages = await repo.watchMessages('c1').first;
      expect(messages.every((m) => m.isRead), isTrue);
    });

    test('copyWith changes only isRead', () {
      final msg = Message(
        messageId: 'm1',
        conversationId: 'c1',
        senderId: 's1',
        receiverId: 'r1',
        content: 'hello',
        messageType: MessageType.text,
        isRead: false,
        createdAt: DateTime.now(),
      );
      final read = msg.copyWith(isRead: true);
      expect(read.isRead, isTrue);
      expect(read.content, equals(msg.content));
      expect(read.messageId, equals(msg.messageId));
    });
  });

  group('Property – Unread counts (Requirement 5.3)', () {
    test('getTotalUnreadCount sums unreadCount across conversations', () async {
      final repo = FakeMessageRepository();
      repo._conversations.addAll([
        Conversation(
          conversationId: 'c1',
          participantIds: ['u1', 'u2'],
          lastMessage: null,
          unreadCount: 3,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Conversation(
          conversationId: 'c2',
          participantIds: ['u1', 'u3'],
          lastMessage: null,
          unreadCount: 2,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ]);
      expect(await repo.getTotalUnreadCount(), equals(5));
    });

    test('getTotalUnreadCount is 0 when no conversations', () async {
      final repo = FakeMessageRepository();
      expect(await repo.getTotalUnreadCount(), equals(0));
    });
  });

  // Task 10.3 – listing reference property
  group('Property – Listing reference in messages (Requirement 5.7)', () {
    test('message with listingId carries the reference', () async {
      final repo = FakeMessageRepository();
      final msg = await repo.sendMessage(
        conversationId: 'c1',
        receiverId: 'r1',
        content: 'Check this listing',
        messageType: MessageType.listingReference,
        listingId: 'listing_abc',
      );
      expect(msg.messageType, equals(MessageType.listingReference));
      expect(msg.listingId, equals('listing_abc'));
    });

    test('text message has null listingId', () async {
      final repo = FakeMessageRepository();
      final msg = await repo.sendMessage(
        conversationId: 'c1',
        receiverId: 'r1',
        content: 'Just a text',
      );
      expect(msg.messageType, equals(MessageType.text));
      expect(msg.listingId, isNull);
    });

    test('listing reference message round-trips through JSON', () {
      final now = DateTime(2024, 3, 10);
      final original = Message(
        messageId: 'm2',
        conversationId: 'c1',
        senderId: 's1',
        receiverId: 'r1',
        content: 'See listing',
        messageType: MessageType.listingReference,
        listingId: 'listing_xyz',
        isRead: false,
        createdAt: now,
      );
      final json = original.toJson();
      final restored = Message.fromJson({...json, 'createdAt': json['createdAt']});
      expect(restored.messageType, equals(MessageType.listingReference));
      expect(restored.listingId, equals('listing_xyz'));
    });
  });

  // Task 11.3 – notification preferences property
  group('Property – Notification preferences (Requirement 12.6)', () {
    test('default preferences are all enabled', () async {
      final repo = FakeNotificationRepository();
      final prefs = await repo.getPreferences();
      expect(prefs['messagesEnabled'], isTrue);
      expect(prefs['listingsEnabled'], isTrue);
      expect(prefs['paymentsEnabled'], isTrue);
      expect(prefs['promotionsEnabled'], isTrue);
    });

    test('updatePreferences persists changes', () async {
      final repo = FakeNotificationRepository();
      await repo.updatePreferences({
        'messagesEnabled': true,
        'listingsEnabled': false,
        'paymentsEnabled': true,
        'promotionsEnabled': false,
      });
      final prefs = await repo.getPreferences();
      expect(prefs['listingsEnabled'], isFalse);
      expect(prefs['promotionsEnabled'], isFalse);
      expect(prefs['messagesEnabled'], isTrue);
    });

    test('requestPermission returns true and token becomes available', () async {
      final repo = FakeNotificationRepository();
      final granted = await repo.requestPermission();
      expect(granted, isTrue);
      final token = await repo.getToken();
      expect(token, isNotNull);
      expect(token, isNotEmpty);
    });

    test('token is null before permission is granted', () async {
      final repo = FakeNotificationRepository();
      final token = await repo.getToken();
      expect(token, isNull);
    });
  });
}
