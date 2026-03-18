import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/models/conversation.dart';
import '../../domain/models/message.dart';
import '../../domain/models/notification.dart';
import '../../domain/models/paginated_result.dart';
import '../../domain/repositories/message_repository.dart';
import '../../domain/repositories/notification_repository.dart';

/// Firebase implementation of [MessageRepository].
///
/// All Firestore access is contained here — never in BLoCs or UI.
/// Requirements: 5.2, 5.3, 5.5, 5.6
/// Developer: Developer 3
class FirebaseMessageRepository implements MessageRepository {
  FirebaseMessageRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    required NotificationRepository notificationRepository,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _notifications = notificationRepository;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final NotificationRepository _notifications;

  String get _currentUserId {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('User not authenticated');
    return uid;
  }

  @override
  Future<Message> sendMessage({
    required String conversationId,
    required String receiverId,
    required String content,
    MessageType messageType = MessageType.text,
    String? listingId,
  }) async {
    final userId = _currentUserId;
    final senderName = _auth.currentUser?.displayName ?? '';
    final messageId = _firestore.collection('messages').doc().id;
    final now = DateTime.now();

    final message = Message(
      messageId: messageId,
      conversationId: conversationId,
      senderId: userId,
      senderName: senderName.isNotEmpty ? senderName : null,
      receiverId: receiverId,
      content: content,
      messageType: messageType,
      listingId: listingId,
      isRead: false,
      createdAt: now,
    );

    final batch = _firestore.batch();

    // Write the message to the subcollection.
    batch.set(
      _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .doc(messageId),
      message.toJson(),
    );

    // Update conversation with last message + increment unread count.
    // Use set+merge so this never throws if the conversation doc is missing.
    batch.set(
      _firestore.collection('conversations').doc(conversationId),
      {
        'lastMessage': message.toJson(),
        'lastMessageContent': content,
        'lastMessageAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
        'unreadCount': FieldValue.increment(1),
      },
      SetOptions(merge: true),
    );

    await batch.commit();

    final notifId = _firestore.collection('notifications').doc().id;
    _notifications.saveNotification(AppNotification(
      id: notifId,
      userId: receiverId,
      title: senderName.isNotEmpty ? senderName : 'New Message',
      body: content.length > 80 ? '${content.substring(0, 80)}…' : content,
      type: NotificationType.newMessage,
      data: {'conversationId': conversationId},
      isRead: false,
      createdAt: now,
    ));

    return message;
  }

  @override
  Stream<List<Conversation>> watchConversations() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection('conversations')
        .where('participantIds', arrayContains: userId)
        .snapshots()
        .map((snap) {
      final list =
          snap.docs.map((d) => Conversation.fromJson(d.data())).toList();
      list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return list;
    });
  }

  @override
  Stream<List<Message>> watchMessages(String conversationId) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Message.fromJson(d.data())).toList());
  }

  @override
  Future<void> markConversationAsRead(String conversationId) async {
    final userId = _currentUserId;
    final batch = _firestore.batch();

    final unread = await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .where('receiverId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    for (final doc in unread.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    batch.update(
      _firestore.collection('conversations').doc(conversationId),
      {'unreadCount': 0},
    );

    await batch.commit();
  }

  @override
  Future<Conversation> getOrCreateConversation(String otherUserId) async {
    final userId = _currentUserId;

    final existing = await _firestore
        .collection('conversations')
        .where('participantIds', arrayContains: userId)
        .get();

    for (final doc in existing.docs) {
      final convo = Conversation.fromJson(doc.data());
      if (convo.participantIds.contains(otherUserId)) return convo;
    }

    // Fetch both display names so the conversation tile can show real names.
    final currentUserName = _auth.currentUser?.displayName ?? '';
    String otherUserName = '';
    try {
      final otherDoc =
          await _firestore.collection('users').doc(otherUserId).get();
      otherUserName = otherDoc.data()?['displayName'] as String? ?? '';
    } catch (_) {}

    final conversationId = _firestore.collection('conversations').doc().id;
    final now = DateTime.now();
    final convo = Conversation(
      conversationId: conversationId,
      participantIds: [userId, otherUserId],
      participantNames: {
        userId: currentUserName,
        otherUserId: otherUserName,
      },
      lastMessage: null,
      unreadCount: 0,
      createdAt: now,
      updatedAt: now,
    );

    await _firestore
        .collection('conversations')
        .doc(conversationId)
        .set(convo.toJson());

    return convo;
  }

  @override
  Future<PaginatedResult<Message>> getMessagePage({
    required String conversationId,
    int pageSize = 30,
    Object? startAfter,
  }) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(pageSize + 1);

    if (startAfter is DocumentSnapshot) {
      query = query.startAfterDocument(startAfter);
    }

    final snapshot = await query.get();
    final hasMore = snapshot.docs.length > pageSize;
    final docs = hasMore ? snapshot.docs.sublist(0, pageSize) : snapshot.docs;

    return PaginatedResult<Message>(
      items: docs.map((d) => Message.fromJson(d.data())).toList(),
      hasMore: hasMore,
      cursor: docs.isNotEmpty ? docs.last : null,
    );
  }

  @override
  Future<int> getTotalUnreadCount() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return 0;

    final snap = await _firestore
        .collection('conversations')
        .where('participantIds', arrayContains: userId)
        .get();

    return snap.docs.fold<int>(
      0,
      (acc, d) => acc + ((d.data()['unreadCount'] as num?)?.toInt() ?? 0),
    );
  }
}
