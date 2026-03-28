// Tests for FirebaseNotificationRepository (Firestore-backed methods only).
// FirebaseMessaging and FirebaseAuth interactions are skipped — they require
// platform channels that are not available in unit tests.
// Focus: saveNotification, watchUserNotifications, markAsRead,
//         markAllAsRead, getUnreadCount, getPreferences.
//
// Manual stubs are used instead of @GenerateMocks to avoid requiring
// a build_runner invocation.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:brewmaster/data/repositories/firebase_notification_repository.dart';
import 'package:brewmaster/domain/models/notification.dart';

// ---------------------------------------------------------------------------
// Manual stubs (no build_runner needed)
// ---------------------------------------------------------------------------

class FakeFirebaseAuth extends Fake implements FirebaseAuth {
  User? _user;

  void setUser(User? user) => _user = user;

  @override
  User? get currentUser => _user;
}

class FakeFirebaseMessaging extends Fake implements FirebaseMessaging {
  @override
  Future<NotificationSettings> requestPermission({
    bool alert = true,
    bool announcement = false,
    bool badge = true,
    bool carPlay = false,
    bool criticalAlert = false,
    bool provisional = false,
    bool sound = true,
  }) async {
    throw UnimplementedError('Not tested');
  }

  @override
  Future<String?> getToken({String? vapidKey}) async => null;
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

AppNotification makeNotif({
  String id = 'n1',
  String userId = 'user-1',
  bool isRead = false,
  DateTime? createdAt,
}) {
  return AppNotification(
    id: id,
    userId: userId,
    title: 'Test',
    body: 'Body',
    type: NotificationType.newMessage,
    data: const {},
    isRead: isRead,
    createdAt: createdAt ?? DateTime(2024, 6, 1),
  );
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

  group('FirebaseNotificationRepository (Firestore methods)', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FakeFirebaseAuth fakeAuth;
    late FakeFirebaseMessaging fakeMessaging;
    late FirebaseNotificationRepository repo;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      fakeFirestore = FakeFirebaseFirestore();
      fakeAuth = FakeFirebaseAuth();
      fakeMessaging = FakeFirebaseMessaging();

      repo = FirebaseNotificationRepository(
        firestore: fakeFirestore,
        auth: fakeAuth,
        messaging: fakeMessaging,
      );
    });

    // -------------------------------------------------------------------------
    // saveNotification
    // -------------------------------------------------------------------------

    group('saveNotification', () {
      test('writes notification to Firestore under its id', () async {
        final notif = makeNotif(id: 'notif-save-1');
        await repo.saveNotification(notif);

        final doc = await fakeFirestore
            .collection('notifications')
            .doc('notif-save-1')
            .get();

        expect(doc.exists, isTrue);
        expect(doc.data()!['userId'], equals('user-1'));
        expect(doc.data()!['title'], equals('Test'));
        expect(doc.data()!['isRead'], isFalse);
      });

      test('overwrites existing notification with same id', () async {
        final notif = makeNotif(id: 'notif-overwrite');
        await repo.saveNotification(notif);

        final updated = notif.copyWith(title: 'Updated', isRead: true);
        await repo.saveNotification(updated);

        final doc = await fakeFirestore
            .collection('notifications')
            .doc('notif-overwrite')
            .get();
        expect(doc.data()!['title'], equals('Updated'));
        expect(doc.data()!['isRead'], isTrue);
      });
    });

    // -------------------------------------------------------------------------
    // watchUserNotifications
    // -------------------------------------------------------------------------

    group('watchUserNotifications', () {
      test('emits list of notifications for the given user', () async {
        const userId = 'user-watch';
        final ts = Timestamp.fromDate(DateTime(2024, 6, 1));

        await fakeFirestore.collection('notifications').doc('w1').set({
          'id': 'w1',
          'userId': userId,
          'title': 'A',
          'body': 'B',
          'type': 'newMessage',
          'data': {},
          'isRead': false,
          'createdAt': ts,
        });
        await fakeFirestore.collection('notifications').doc('w2').set({
          'id': 'w2',
          'userId': 'other-user',
          'title': 'C',
          'body': 'D',
          'type': 'newMessage',
          'data': {},
          'isRead': false,
          'createdAt': ts,
        });

        final stream = repo.watchUserNotifications(userId);
        final notifications = await stream.first;

        expect(notifications.length, equals(1));
        expect(notifications.first.userId, equals(userId));
      });

      test('emits empty list when user has no notifications', () async {
        final stream = repo.watchUserNotifications('user-none');
        final notifications = await stream.first;
        expect(notifications, isEmpty);
      });

      test('emits AppNotification objects', () async {
        const userId = 'user-type-check';
        final ts = Timestamp.fromDate(DateTime(2024));
        await fakeFirestore.collection('notifications').doc('tc1').set({
          'id': 'tc1',
          'userId': userId,
          'title': 'T',
          'body': 'B',
          'type': 'newMessage',
          'data': {},
          'isRead': false,
          'createdAt': ts,
        });

        final stream = repo.watchUserNotifications(userId);
        final notifications = await stream.first;
        expect(notifications.first, isA<AppNotification>());
      });
    });

    // -------------------------------------------------------------------------
    // markAsRead
    // -------------------------------------------------------------------------

    group('markAsRead', () {
      test('sets isRead to true for the given notification', () async {
        await fakeFirestore
            .collection('notifications')
            .doc('mark-1')
            .set({
          'id': 'mark-1',
          'userId': 'user-1',
          'title': 'T',
          'body': 'B',
          'type': 'newMessage',
          'data': {},
          'isRead': false,
          'createdAt': Timestamp.fromDate(DateTime(2024)),
        });

        await repo.markAsRead('mark-1', 'user-1');

        final doc = await fakeFirestore
            .collection('notifications')
            .doc('mark-1')
            .get();
        expect(doc.data()!['isRead'], isTrue);
      });
    });

    // -------------------------------------------------------------------------
    // markAllAsRead
    // -------------------------------------------------------------------------

    group('markAllAsRead', () {
      test('marks all unread notifications for the user as read', () async {
        const userId = 'user-mark-all';
        final ts = Timestamp.fromDate(DateTime(2024));

        for (var i = 1; i <= 3; i++) {
          await fakeFirestore
              .collection('notifications')
              .doc('ma-$i')
              .set({
            'id': 'ma-$i',
            'userId': userId,
            'title': 'N$i',
            'body': 'B',
            'type': 'newMessage',
            'data': {},
            'isRead': false,
            'createdAt': ts,
          });
        }

        await repo.markAllAsRead(userId);

        final snap = await fakeFirestore
            .collection('notifications')
            .where('userId', isEqualTo: userId)
            .get();

        expect(
          snap.docs.every((d) => d.data()['isRead'] == true),
          isTrue,
        );
      });

      test('does not affect notifications belonging to other users', () async {
        const userId = 'user-mark-all-2';
        const otherUser = 'other-mark';
        final ts = Timestamp.fromDate(DateTime(2024));

        await fakeFirestore
            .collection('notifications')
            .doc('other-notif')
            .set({
          'id': 'other-notif',
          'userId': otherUser,
          'title': 'N',
          'body': 'B',
          'type': 'newMessage',
          'data': {},
          'isRead': false,
          'createdAt': ts,
        });

        await repo.markAllAsRead(userId);

        final doc = await fakeFirestore
            .collection('notifications')
            .doc('other-notif')
            .get();
        expect(doc.data()!['isRead'], isFalse);
      });
    });

    // -------------------------------------------------------------------------
    // getUnreadCount
    // -------------------------------------------------------------------------

    group('getUnreadCount', () {
      test('returns number of unread notifications for user', () async {
        const userId = 'user-unread';
        final ts = Timestamp.fromDate(DateTime(2024));

        await fakeFirestore
            .collection('notifications')
            .doc('ur-1')
            .set({
          'id': 'ur-1',
          'userId': userId,
          'title': 'N',
          'body': 'B',
          'type': 'newMessage',
          'data': {},
          'isRead': false,
          'createdAt': ts,
        });
        await fakeFirestore
            .collection('notifications')
            .doc('ur-2')
            .set({
          'id': 'ur-2',
          'userId': userId,
          'title': 'N2',
          'body': 'B2',
          'type': 'newMessage',
          'data': {},
          'isRead': true,
          'createdAt': ts,
        });

        final count = await repo.getUnreadCount(userId);
        expect(count, equals(1));
      });

      test('returns 0 when all notifications are read', () async {
        const userId = 'user-all-read';
        final ts = Timestamp.fromDate(DateTime(2024));
        await fakeFirestore
            .collection('notifications')
            .doc('ar-1')
            .set({
          'id': 'ar-1',
          'userId': userId,
          'title': 'N',
          'body': 'B',
          'type': 'newMessage',
          'data': {},
          'isRead': true,
          'createdAt': ts,
        });

        final count = await repo.getUnreadCount(userId);
        expect(count, equals(0));
      });

      test('returns 0 when user has no notifications', () async {
        final count = await repo.getUnreadCount('user-zero');
        expect(count, equals(0));
      });
    });

    // -------------------------------------------------------------------------
    // getPreferences — returns defaults when no user is authenticated
    // -------------------------------------------------------------------------

    group('getPreferences', () {
      test('returns default preferences when no user is logged in', () async {
        // fakeAuth.currentUser is null by default
        final prefs = await repo.getPreferences();

        expect(prefs['messagesEnabled'], isTrue);
        expect(prefs['listingsEnabled'], isTrue);
        expect(prefs['paymentsEnabled'], isTrue);
        expect(prefs['promotionsEnabled'], isTrue);
      });
    });
  });
}
