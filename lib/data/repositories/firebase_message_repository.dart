import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/models/conversation.dart';
import '../../domain/models/message.dart';
import '../../domain/models/paginated_result.dart';
import '../../domain/repositories/message_repository.dart';

/// Firebase implementation of [MessageRepository].
///
/// All Firestore access is contained here — never in BLoCs or UI.
/// Requirements: 5.2, 5.3, 5.5, 5.6
/// Developer: Developer 3
class FirebaseMessageRepository implements MessageRepository {
  FirebaseMessageRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

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

    final batch = _firestore.batch();

    batch.set(
      _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .doc(messageId),
      message.toJson(),
    );

    batch.update(
      _firestore.collection('conversations').doc(conversationId),
      {
        'lastMessage': message.toJson(),
        'updatedAt': Timestamp.fromDate(now),
      },
    );

    await batch.commit();
    return message;
  }

  @override
  Stream<List<Conversation>> watchConversations() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection('conversations')
        .where('participantIds', arrayContains: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Conversation.fromJson(d.data())).toList());
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

    final conversationId = _firestore.collection('conversations').doc().id;
    final now = DateTime.now();
    final convo = Conversation(
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
