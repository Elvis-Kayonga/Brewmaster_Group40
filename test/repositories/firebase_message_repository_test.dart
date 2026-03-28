// Tests for FirebaseMessageRepository.
// Uses FakeFirebaseFirestore and a manual FirebaseAuth stub.
// sendMessage requires an authenticated user, so we stub FirebaseAuth.currentUser.
// The NotificationRepository dependency is satisfied with a no-op stub.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:brewmaster/data/repositories/firebase_message_repository.dart';
import 'package:brewmaster/domain/models/conversation.dart';
import 'package:brewmaster/domain/models/message.dart';
import 'package:brewmaster/domain/models/notification.dart';
import 'package:brewmaster/domain/repositories/notification_repository.dart';

// ---------------------------------------------------------------------------
// Stubs
// ---------------------------------------------------------------------------

class FakeUser extends Fake implements User {
  @override
  final String uid;
  @override
  final String? displayName;
  @override
  String? get photoURL => null;

  FakeUser({required this.uid, this.displayName});
}

class FakeFirebaseAuth extends Fake implements FirebaseAuth {
  User? _user;

  void setUser(User? user) => _user = user;

  @override
  User? get currentUser => _user;
}

/// No-op notification repository — message tests don't assert on notifications.
class NoOpNotificationRepository implements NotificationRepository {
  @override
  Future<void> saveNotification(AppNotification notification) async {}

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<String?> getToken() async => null;

  @override
  Stream<Map<String, dynamic>> watchNotifications() => const Stream.empty();

  @override
  Future<void> updatePreferences(Map<String, bool> preferences) async {}

  @override
  Future<Map<String, bool>> getPreferences() async => {};

  @override
  Stream<List<AppNotification>> watchUserNotifications(String userId) =>
      Stream.value([]);

  @override
  Future<void> markAsRead(String notificationId, String userId) async {}

  @override
  Future<void> markAllAsRead(String userId) async {}

  @override
  Future<int> getUnreadCount(String userId) async => 0;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    setupFirebaseCoreMocks();
    await Firebase.initializeApp();
  });

  group('FirebaseMessageRepository', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FakeFirebaseAuth fakeAuth;
    late FirebaseMessageRepository repo;

    const currentUserId = 'user-sender';
    const currentUserName = 'Alice';
    const receiverId = 'user-receiver';

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      fakeAuth = FakeFirebaseAuth();
      fakeAuth.setUser(
        FakeUser(uid: currentUserId, displayName: currentUserName),
      );
      repo = FirebaseMessageRepository(
        firestore: fakeFirestore,
        auth: fakeAuth,
        notificationRepository: NoOpNotificationRepository(),
      );
    });

    // -------------------------------------------------------------------------
    // sendMessage
    // -------------------------------------------------------------------------

    group('sendMessage', () {
      test('returns a Message with correct fields', () async {
        const convId = 'conv-1';
        final message = await repo.sendMessage(
          conversationId: convId,
          receiverId: receiverId,
          content: 'Hello!',
        );

        expect(message.senderId, equals(currentUserId));
        expect(message.receiverId, equals(receiverId));
        expect(message.content, equals('Hello!'));
        expect(message.conversationId, equals(convId));
        expect(message.isRead, isFalse);
        expect(message.messageType, equals(MessageType.text));
      });

      test('writes message to Firestore subcollection', () async {
        const convId = 'conv-write';
        final message = await repo.sendMessage(
          conversationId: convId,
          receiverId: receiverId,
          content: 'Written to Firestore',
        );

        final doc = await fakeFirestore
            .collection('conversations')
            .doc(convId)
            .collection('messages')
            .doc(message.messageId)
            .get();

        expect(doc.exists, isTrue);
        expect(doc.data()!['content'], equals('Written to Firestore'));
        expect(doc.data()!['senderId'], equals(currentUserId));
      });

      test('updates conversation document with lastMessage', () async {
        const convId = 'conv-last';
        await repo.sendMessage(
          conversationId: convId,
          receiverId: receiverId,
          content: 'Last message content',
        );

        final convoDoc = await fakeFirestore
            .collection('conversations')
            .doc(convId)
            .get();

        expect(convoDoc.exists, isTrue);
        expect(
          convoDoc.data()!['lastMessageContent'],
          equals('Last message content'),
        );
      });

      test('increments unreadCount on conversation', () async {
        const convId = 'conv-unread';
        // Send two messages so we can verify FieldValue.increment was applied.
        await repo.sendMessage(
          conversationId: convId,
          receiverId: receiverId,
          content: 'msg 1',
        );
        await repo.sendMessage(
          conversationId: convId,
          receiverId: receiverId,
          content: 'msg 2',
        );

        final convoDoc = await fakeFirestore
            .collection('conversations')
            .doc(convId)
            .get();
        expect((convoDoc.data()!['unreadCount'] as num).toInt(), equals(2));
      });

      test('sends message with listingId when provided', () async {
        const convId = 'conv-listing';
        final message = await repo.sendMessage(
          conversationId: convId,
          receiverId: receiverId,
          content: 'Check this listing',
          listingId: 'listing-abc',
        );

        expect(message.listingId, equals('listing-abc'));
      });

      test('throws when no user is authenticated', () async {
        fakeAuth.setUser(null);

        expect(
          () => repo.sendMessage(
            conversationId: 'conv-x',
            receiverId: receiverId,
            content: 'Should throw',
          ),
          throwsA(isA<Exception>()),
        );
      });
    });

    // -------------------------------------------------------------------------
    // watchMessages
    // -------------------------------------------------------------------------

    group('watchMessages', () {
      test('emits messages from the conversation subcollection', () async {
        const convId = 'conv-watch-msgs';
        final now = Timestamp.fromDate(DateTime(2024, 6, 1));

        await fakeFirestore
            .collection('conversations')
            .doc(convId)
            .collection('messages')
            .doc('msg-w1')
            .set({
          'messageId': 'msg-w1',
          'conversationId': convId,
          'senderId': currentUserId,
          'receiverId': receiverId,
          'content': 'Watch me',
          'type': 'text',
          'isRead': false,
          'createdAt': now,
        });

        final msgs = await repo.watchMessages(convId).first;
        expect(msgs.length, equals(1));
        expect(msgs.first.content, equals('Watch me'));
      });

      test('emits empty list when conversation has no messages', () async {
        final msgs = await repo.watchMessages('conv-empty').first;
        expect(msgs, isEmpty);
      });

      test('emits Message objects', () async {
        const convId = 'conv-type';
        final now = Timestamp.fromDate(DateTime(2024));
        await fakeFirestore
            .collection('conversations')
            .doc(convId)
            .collection('messages')
            .doc('msg-t1')
            .set({
          'messageId': 'msg-t1',
          'conversationId': convId,
          'senderId': currentUserId,
          'receiverId': receiverId,
          'content': 'Typed',
          'type': 'text',
          'isRead': false,
          'createdAt': now,
        });

        final msgs = await repo.watchMessages(convId).first;
        expect(msgs.first, isA<Message>());
      });
    });

    // -------------------------------------------------------------------------
    // watchConversations
    // -------------------------------------------------------------------------

    group('watchConversations', () {
      test('emits conversations the current user participates in', () async {
        final now = Timestamp.fromDate(DateTime(2024, 6, 1));
        await fakeFirestore.collection('conversations').doc('cv-1').set({
          'conversationId': 'cv-1',
          'participantIds': [currentUserId, receiverId],
          'participantNames': {currentUserId: 'Alice', receiverId: 'Bob'},
          'unreadCount': 0,
          'createdAt': now,
          'updatedAt': now,
        });
        await fakeFirestore.collection('conversations').doc('cv-2').set({
          'conversationId': 'cv-2',
          'participantIds': ['other-a', 'other-b'],
          'participantNames': {},
          'unreadCount': 0,
          'createdAt': now,
          'updatedAt': now,
        });

        final convos = await repo.watchConversations().first;
        expect(convos.length, equals(1));
        expect(convos.first.conversationId, equals('cv-1'));
      });

      test('emits empty list when user has no conversations', () async {
        final convos = await repo.watchConversations().first;
        expect(convos, isEmpty);
      });

      test('emits Conversation objects', () async {
        final now = Timestamp.fromDate(DateTime(2024));
        await fakeFirestore.collection('conversations').doc('cv-obj').set({
          'conversationId': 'cv-obj',
          'participantIds': [currentUserId, 'someone'],
          'participantNames': {},
          'unreadCount': 0,
          'createdAt': now,
          'updatedAt': now,
        });

        final convos = await repo.watchConversations().first;
        expect(convos.first, isA<Conversation>());
      });
    });

    // -------------------------------------------------------------------------
    // getOrCreateConversation
    // -------------------------------------------------------------------------

    group('getOrCreateConversation', () {
      test('creates a new conversation when none exists', () async {
        final convo =
            await repo.getOrCreateConversation(receiverId);

        expect(convo.participantIds, containsAll([currentUserId, receiverId]));
        expect(convo.unreadCount, equals(0));

        // Verify it was written to Firestore.
        final doc = await fakeFirestore
            .collection('conversations')
            .doc(convo.conversationId)
            .get();
        expect(doc.exists, isTrue);
      });

      test('returns existing conversation when one already exists', () async {
        final convo1 = await repo.getOrCreateConversation(receiverId);
        final convo2 = await repo.getOrCreateConversation(receiverId);

        expect(convo1.conversationId, equals(convo2.conversationId));
      });
    });

    // -------------------------------------------------------------------------
    // markConversationAsRead
    // -------------------------------------------------------------------------

    group('markConversationAsRead', () {
      test('sets unreadCount to 0 on conversation document', () async {
        const convId = 'conv-read';
        final now = Timestamp.fromDate(DateTime(2024));

        await fakeFirestore.collection('conversations').doc(convId).set({
          'conversationId': convId,
          'participantIds': [currentUserId, receiverId],
          'unreadCount': 3,
          'createdAt': now,
          'updatedAt': now,
        });

        await repo.markConversationAsRead(convId);

        final doc = await fakeFirestore
            .collection('conversations')
            .doc(convId)
            .get();
        expect(doc.data()!['unreadCount'], equals(0));
      });

      test('marks unread messages for current user as read', () async {
        const convId = 'conv-msgs-read';
        final now = Timestamp.fromDate(DateTime(2024));

        await fakeFirestore
            .collection('conversations')
            .doc(convId)
            .collection('messages')
            .doc('mr-1')
            .set({
          'messageId': 'mr-1',
          'conversationId': convId,
          'senderId': receiverId,
          'receiverId': currentUserId,
          'content': 'Hi',
          'type': 'text',
          'isRead': false,
          'createdAt': now,
        });

        await fakeFirestore
            .collection('conversations')
            .doc(convId)
            .set({'unreadCount': 1, 'createdAt': now, 'updatedAt': now});

        await repo.markConversationAsRead(convId);

        final msgDoc = await fakeFirestore
            .collection('conversations')
            .doc(convId)
            .collection('messages')
            .doc('mr-1')
            .get();
        expect(msgDoc.data()!['isRead'], isTrue);
      });
    });

    // -------------------------------------------------------------------------
    // getTotalUnreadCount
    // -------------------------------------------------------------------------

    group('getTotalUnreadCount', () {
      test('sums unreadCount across all conversations for current user',
          () async {
        final now = Timestamp.fromDate(DateTime(2024));
        await fakeFirestore.collection('conversations').doc('tuc-1').set({
          'conversationId': 'tuc-1',
          'participantIds': [currentUserId, 'b1'],
          'unreadCount': 3,
          'createdAt': now,
          'updatedAt': now,
        });
        await fakeFirestore.collection('conversations').doc('tuc-2').set({
          'conversationId': 'tuc-2',
          'participantIds': [currentUserId, 'b2'],
          'unreadCount': 5,
          'createdAt': now,
          'updatedAt': now,
        });

        final total = await repo.getTotalUnreadCount();
        expect(total, equals(8));
      });

      test('returns 0 when user has no conversations', () async {
        final total = await repo.getTotalUnreadCount();
        expect(total, equals(0));
      });

      test('returns 0 when no authenticated user', () async {
        fakeAuth.setUser(null);
        final total = await repo.getTotalUnreadCount();
        expect(total, equals(0));
      });
    });

    // -------------------------------------------------------------------------
    // getMessagePage
    // -------------------------------------------------------------------------

    group('getMessagePage', () {
      test('returns first page of messages', () async {
        const convId = 'conv-page';
        final now = DateTime(2024, 6, 1);

        for (var i = 0; i < 5; i++) {
          final ts = Timestamp.fromDate(now.add(Duration(minutes: i)));
          await fakeFirestore
              .collection('conversations')
              .doc(convId)
              .collection('messages')
              .doc('page-msg-$i')
              .set({
            'messageId': 'page-msg-$i',
            'conversationId': convId,
            'senderId': currentUserId,
            'receiverId': receiverId,
            'content': 'Message $i',
            'type': 'text',
            'isRead': false,
            'createdAt': ts,
          });
        }

        final page = await repo.getMessagePage(
          conversationId: convId,
          pageSize: 3,
        );

        expect(page.items.length, equals(3));
        expect(page.hasMore, isTrue);
        expect(page.cursor, isNotNull);
      });

      test('hasMore is false when results fit within pageSize', () async {
        const convId = 'conv-page-small';
        final ts = Timestamp.fromDate(DateTime(2024));

        for (var i = 0; i < 2; i++) {
          await fakeFirestore
              .collection('conversations')
              .doc(convId)
              .collection('messages')
              .doc('sm-$i')
              .set({
            'messageId': 'sm-$i',
            'conversationId': convId,
            'senderId': currentUserId,
            'receiverId': receiverId,
            'content': 'Msg $i',
            'type': 'text',
            'isRead': false,
            'createdAt': ts,
          });
        }

        final page = await repo.getMessagePage(
          conversationId: convId,
          pageSize: 10,
        );

        expect(page.hasMore, isFalse);
        expect(page.items.length, equals(2));
      });

      test('returns empty page when conversation has no messages', () async {
        final page = await repo.getMessagePage(
          conversationId: 'conv-no-msgs',
          pageSize: 20,
        );
        expect(page.items, isEmpty);
        expect(page.hasMore, isFalse);
        expect(page.cursor, isNull);
      });
    });
  });
}
