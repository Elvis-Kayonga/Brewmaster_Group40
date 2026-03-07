import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Notification payload model
class NotificationPayload {
  final String type;
  final String title;
  final String body;
  final Map<String, dynamic> data;

  NotificationPayload({
    required this.type,
    required this.title,
    required this.body,
    required this.data,
  });

  factory NotificationPayload.fromMessage(RemoteMessage message) {
    return NotificationPayload(
      type: message.data['type'] ?? 'unknown',
      title: message.notification?.title ?? '',
      body: message.notification?.body ?? '',
      data: message.data,
    );
  }
}

/// Service for managing Firebase Cloud Messaging notifications
class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  /// Initialize FCM
  Future<void> initialize() async {
    try {
      // Request user permission for iOS
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('User granted notification permission');
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        print('User granted provisional permission');
      } else {
        print('User declined or has not yet granted permission');
      }

      // Get FCM token
      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        await _saveFCMToken(token);
      }

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        _saveFCMToken(newToken);
      });

      // Set up foreground notification handler
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _handleForegroundMessage(message);
      });

      // Set up background notification handler
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _handleBackgroundMessageOpened(message);
      });

      // Get initial message if app was launched from notification
      final initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        _handleBackgroundMessageOpened(initialMessage);
      }
    } catch (e) {
      print('Error initializing Firebase Messaging: $e');
      rethrow;
    }
  }

  /// Handle foreground message
  void _handleForegroundMessage(RemoteMessage message) {
    final payload = NotificationPayload.fromMessage(message);
    print('Foreground message: ${payload.title} - ${payload.body}');
    // Implement foreground notification display here
    // You can use local_notifications package to handle this
  }

  /// Handle background message opened
  void _handleBackgroundMessageOpened(RemoteMessage message) {
    final payload = NotificationPayload.fromMessage(message);
    print('Background message opened: ${payload.type}');
    // Navigate to appropriate screen based on notification type
    // This would be handled by named routes in main.dart
  }

  /// Save FCM token to Firestore
  Future<void> _saveFCMToken(String token) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      await _firestore.collection('users').doc(userId).update({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      });

      // Also save to SharedPreferences for offline access
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcmToken', token);
    } catch (e) {
      print('Error saving FCM token: $e');
    }
  }

  /// Send a test notification
  Future<void> sendTestNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // This would typically be called from a Firebase Cloud Function
      // For local testing, you might call a local endpoint or use emulator
      print('Test notification: $title - $body');
    } catch (e) {
      print('Error sending test notification: $e');
      rethrow;
    }
  }

  /// Update notification preferences
  Future<void> updateNotificationPreferences({
    required bool messagesEnabled,
    required bool listingsEnabled,
    required bool paymentsEnabled,
    required bool promotionsEnabled,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('preferences')
          .doc('notifications')
          .set({
            'messagesEnabled': messagesEnabled,
            'listingsEnabled': listingsEnabled,
            'paymentsEnabled': paymentsEnabled,
            'promotionsEnabled': promotionsEnabled,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      // Save locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notifications_messages', messagesEnabled);
      await prefs.setBool('notifications_listings', listingsEnabled);
      await prefs.setBool('notifications_payments', paymentsEnabled);
      await prefs.setBool('notifications_promotions', promotionsEnabled);
    } catch (e) {
      print('Error updating notification preferences: $e');
      rethrow;
    }
  }

  /// Get notification preferences
  Future<Map<String, bool>> getNotificationPreferences() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return {};

      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('preferences')
          .doc('notifications')
          .get();

      if (doc.exists) {
        return {
          'messagesEnabled': doc.data()?['messagesEnabled'] ?? true,
          'listingsEnabled': doc.data()?['listingsEnabled'] ?? true,
          'paymentsEnabled': doc.data()?['paymentsEnabled'] ?? true,
          'promotionsEnabled': doc.data()?['promotionsEnabled'] ?? true,
        };
      }

      // Return defaults
      return {
        'messagesEnabled': true,
        'listingsEnabled': true,
        'paymentsEnabled': true,
        'promotionsEnabled': true,
      };
    } catch (e) {
      print('Error getting notification preferences: $e');
      return {};
    }
  }

  /// Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
    } catch (e) {
      print('Error subscribing to topic: $e');
      rethrow;
    }
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
    } catch (e) {
      print('Error unsubscribing from topic: $e');
      rethrow;
    }
  }

  /// Enable notifications by requesting permission
  Future<void> enableNotifications() async {
    try {
      await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
    } catch (e) {
      print('Error enabling notifications: $e');
      rethrow;
    }
  }

  /// Disable notifications
  Future<void> disableNotifications() async {
    try {
      // Firebase Messaging doesn't have a built-in disable method
      // Users would need to disable through system settings or app settings
      print('Notifications disabled via app settings');
    } catch (e) {
      print('Error disabling notifications: $e');
      rethrow;
    }
  }

  /// Get FCM token
  Future<String?> getFCMToken() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (e) {
      print('Error getting FCM token: $e');
      return null;
    }
  }
}
