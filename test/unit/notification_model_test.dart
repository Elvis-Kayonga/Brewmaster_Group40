import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brewmaster/domain/models/notification.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

AppNotification _makeNotification({
  String id = 'notif-1',
  String userId = 'user-1',
  String title = 'Test Title',
  String body = 'Test body',
  NotificationType type = NotificationType.newMessage,
  bool isRead = false,
  DateTime? createdAt,
}) {
  return AppNotification(
    id: id,
    userId: userId,
    title: title,
    body: body,
    type: type,
    data: const {},
    isRead: isRead,
    createdAt: createdAt ?? DateTime(2024, 1, 1),
  );
}

void main() {
  group('NotificationType', () {
    test('toJson returns name', () {
      expect(NotificationType.newMessage.toJson(), equals('newMessage'));
      expect(NotificationType.paymentReceived.toJson(), equals('paymentReceived'));
      expect(NotificationType.deliveryConfirmed.toJson(), equals('deliveryConfirmed'));
    });

    test('fromJson parses all valid types', () {
      expect(NotificationTypeExtension.fromJson('newMessage'),
          equals(NotificationType.newMessage));
      expect(NotificationTypeExtension.fromJson('purchaseInitiated'),
          equals(NotificationType.purchaseInitiated));
      expect(NotificationTypeExtension.fromJson('paymentReceived'),
          equals(NotificationType.paymentReceived));
      expect(NotificationTypeExtension.fromJson('deliveryConfirmed'),
          equals(NotificationType.deliveryConfirmed));
      expect(NotificationTypeExtension.fromJson('verificationUpdated'),
          equals(NotificationType.verificationUpdated));
      expect(NotificationTypeExtension.fromJson('listingInterest'),
          equals(NotificationType.listingInterest));
    });

    test('fromJson defaults to newMessage for unknown value', () {
      expect(NotificationTypeExtension.fromJson('unknown'),
          equals(NotificationType.newMessage));
    });
  });

  group('AppNotification', () {
    test('constructor creates correct instance', () {
      final n = _makeNotification();
      expect(n.id, equals('notif-1'));
      expect(n.userId, equals('user-1'));
      expect(n.title, equals('Test Title'));
      expect(n.body, equals('Test body'));
      expect(n.type, equals(NotificationType.newMessage));
      expect(n.isRead, isFalse);
    });

    test('toJson serializes correctly', () {
      final n = _makeNotification(type: NotificationType.paymentReceived);
      final json = n.toJson();
      expect(json['id'], equals('notif-1'));
      expect(json['userId'], equals('user-1'));
      expect(json['title'], equals('Test Title'));
      expect(json['body'], equals('Test body'));
      expect(json['type'], equals('paymentReceived'));
      expect(json['isRead'], isFalse);
      expect(json['createdAt'], isA<Timestamp>());
    });

    test('fromJson deserializes correctly', () {
      final now = DateTime(2024, 6, 1, 10, 30);
      final json = {
        'id': 'n1',
        'userId': 'u1',
        'title': 'Hello',
        'body': 'World',
        'type': 'listingInterest',
        'data': {'listingId': 'l1'},
        'isRead': true,
        'createdAt': Timestamp.fromDate(now),
      };
      final n = AppNotification.fromJson(json);
      expect(n.id, equals('n1'));
      expect(n.userId, equals('u1'));
      expect(n.title, equals('Hello'));
      expect(n.body, equals('World'));
      expect(n.type, equals(NotificationType.listingInterest));
      expect(n.data['listingId'], equals('l1'));
      expect(n.isRead, isTrue);
      expect(n.createdAt, equals(now));
    });

    test('fromJson defaults isRead to false when absent', () {
      final json = {
        'id': 'n1',
        'userId': 'u1',
        'title': 'T',
        'body': 'B',
        'type': 'newMessage',
        'data': {},
        'createdAt': Timestamp.fromDate(DateTime(2024)),
      };
      final n = AppNotification.fromJson(json);
      expect(n.isRead, isFalse);
    });

    test('fromJson handles missing data field', () {
      final json = {
        'id': 'n1',
        'userId': 'u1',
        'title': 'T',
        'body': 'B',
        'type': 'newMessage',
        'createdAt': Timestamp.fromDate(DateTime(2024)),
      };
      final n = AppNotification.fromJson(json);
      expect(n.data, isEmpty);
    });

    test('copyWith overrides specific fields', () {
      final n = _makeNotification();
      final updated = n.copyWith(isRead: true, title: 'Updated');
      expect(updated.isRead, isTrue);
      expect(updated.title, equals('Updated'));
      expect(updated.id, equals(n.id));
    });

    test('equality compares id, userId, type, and isRead', () {
      final a = _makeNotification(id: 'n1', isRead: false);
      final b = _makeNotification(id: 'n1', isRead: false);
      expect(a, equals(b));
    });

    test('inequality when id differs', () {
      final a = _makeNotification(id: 'n1');
      final b = _makeNotification(id: 'n2');
      expect(a == b, isFalse);
    });

    test('hashCode is consistent', () {
      final a = _makeNotification(id: 'n1');
      final b = _makeNotification(id: 'n1');
      expect(a.hashCode, equals(b.hashCode));
    });

    test('toString includes id and type', () {
      final n = _makeNotification(id: 'n1', type: NotificationType.paymentReceived);
      final str = n.toString();
      expect(str, contains('n1'));
      expect(str, contains('paymentReceived'));
    });

    test('fromFirestore uses document id', () async {
      final firestore = FakeFirebaseFirestore();
      final docRef = firestore.collection('notifications').doc('doc-id');
      await docRef.set({
        'userId': 'u1',
        'title': 'T',
        'body': 'B',
        'type': 'newMessage',
        'data': {},
        'isRead': false,
        'createdAt': Timestamp.fromDate(DateTime(2024)),
      });
      final doc = await docRef.get();
      final n = AppNotification.fromFirestore(doc);
      expect(n.id, equals('doc-id'));
    });
  });
}
