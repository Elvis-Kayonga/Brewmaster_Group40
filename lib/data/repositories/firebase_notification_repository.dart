import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/notification.dart';
import '../../domain/repositories/notification_repository.dart';

/// Firebase / FCM implementation of [NotificationRepository].
///
/// All FCM and Firestore calls are contained here — never in BLoCs or UI.
/// Requirements: 5.4, 12.1, 12.2, 12.3, 12.6, 12.7
/// Developer: Developer 3
class FirebaseNotificationRepository implements NotificationRepository {
  FirebaseNotificationRepository({
    FirebaseMessaging? messaging,
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _messaging = messaging ?? FirebaseMessaging.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseMessaging _messaging;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  static const _prefKeys = {
    'messagesEnabled': 'notifications_messages',
    'listingsEnabled': 'notifications_listings',
    'paymentsEnabled': 'notifications_payments',
    'promotionsEnabled': 'notifications_promotions',
  };

  @override
  Future<bool> requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    final granted =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
            settings.authorizationStatus == AuthorizationStatus.provisional;

    if (granted) {
      final token = await _messaging.getToken();
      if (token != null) await _saveToken(token);
      _messaging.onTokenRefresh.listen(_saveToken);
    }

    return granted;
  }

  @override
  Future<String?> getToken() => _messaging.getToken();

  @override
  Stream<Map<String, dynamic>> watchNotifications() {
    final controller = StreamController<Map<String, dynamic>>.broadcast();
    FirebaseMessaging.onMessage.listen((msg) {
      controller.add({
        'type': msg.data['type'] ?? 'unknown',
        'title': msg.notification?.title ?? '',
        'body': msg.notification?.body ?? '',
        'data': msg.data,
      });
    });
    return controller.stream;
  }

  @override
  Future<void> updatePreferences(Map<String, bool> preferences) async {
    // 1. SharedPreferences — primary local store, always succeeds.
    final prefs = await SharedPreferences.getInstance();
    for (final entry in preferences.entries) {
      final key = _prefKeys[entry.key];
      if (key != null) await prefs.setBool(key, entry.value);
    }

    // 2. Firestore — best-effort cross-device sync; never blocks the UI.
    final userId = _auth.currentUser?.uid;
    if (userId != null) {
      _firestore
          .collection('users')
          .doc(userId)
          .collection('preferences')
          .doc('notifications')
          .set({
        ...preferences,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true))
          .catchError((_) {});
    }
  }

  @override
  Future<Map<String, bool>> getPreferences() async {
    final userId = _auth.currentUser?.uid;

    // Try Firestore first when authenticated
    if (userId != null) {
      try {
        final doc = await _firestore
            .collection('users')
            .doc(userId)
            .collection('preferences')
            .doc('notifications')
            .get();

        if (doc.exists && doc.data() != null) {
          final d = doc.data()!;
          return {
            'messagesEnabled': d['messagesEnabled'] as bool? ?? true,
            'listingsEnabled': d['listingsEnabled'] as bool? ?? true,
            'paymentsEnabled': d['paymentsEnabled'] as bool? ?? true,
            'promotionsEnabled': d['promotionsEnabled'] as bool? ?? true,
          };
        }
      } catch (_) {
        // Fall through to SharedPreferences cache
      }
    }

    // Fallback: read from SharedPreferences (persisted on last successful save)
    final prefs = await SharedPreferences.getInstance();
    final hasAnySaved = _prefKeys.values.any((k) => prefs.containsKey(k));
    if (hasAnySaved) {
      return {
        for (final entry in _prefKeys.entries)
          entry.key: prefs.getBool(entry.value) ?? true,
      };
    }

    return _defaults();
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  Future<void> _saveToken(String token) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;
    await _firestore.collection('users').doc(userId).update({
      'fcmToken': token,
      'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fcmToken', token);
  }

  Map<String, bool> _defaults() => {
        'messagesEnabled': true,
        'listingsEnabled': true,
        'paymentsEnabled': true,
        'promotionsEnabled': true,
      };

  // ---------------------------------------------------------------------------
  // Firestore notification persistence (ERD: notifications collection)
  // ---------------------------------------------------------------------------

  @override
  Future<void> saveNotification(AppNotification notification) async {
    await _firestore
        .collection('notifications')
        .doc(notification.id)
        .set(notification.toJson());
  }

  @override
  Stream<List<AppNotification>> watchUserNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => AppNotification.fromFirestore(d)).toList());
  }

  @override
  Future<void> markAsRead(String notificationId, String userId) async {
    await _firestore
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    final unread = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (final doc in unread.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  @override
  Future<int> getUnreadCount(String userId) async {
    final snap = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();
    return snap.size;
  }
}
