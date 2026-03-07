import 'package:flutter/material.dart';
import '../services/notification_service.dart';

/// Provider for managing notification state
class NotificationProvider extends ChangeNotifier {
  final NotificationService _notificationService = NotificationService();

  bool _notificationsInitialized = false;
  Map<String, bool> _preferences = {
    'messagesEnabled': true,
    'listingsEnabled': true,
    'paymentsEnabled': true,
    'promotionsEnabled': true,
  };
  bool _isLoading = false;
  String? _error;
  String? _fcmToken;

  // Getters
  bool get notificationsInitialized => _notificationsInitialized;
  Map<String, bool> get preferences => _preferences;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get fcmToken => _fcmToken;

  /// Initialize notifications
  Future<void> initializeNotifications() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Initialize Firebase Messaging
      await _notificationService.initialize();

      // Load preferences
      await loadPreferences();

      // Get FCM token
      _fcmToken = await _notificationService.getFCMToken();

      _notificationsInitialized = true;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load notification preferences from Firestore
  Future<void> loadPreferences() async {
    try {
      _isLoading = true;
      notifyListeners();

      _preferences = await _notificationService.getNotificationPreferences();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update preference for messages
  Future<void> setMessagesEnabled(bool enabled) async {
    try {
      _preferences['messagesEnabled'] = enabled;
      notifyListeners();

      await _notificationService.updateNotificationPreferences(
        messagesEnabled: enabled,
        listingsEnabled: _preferences['listingsEnabled'] ?? true,
        paymentsEnabled: _preferences['paymentsEnabled'] ?? true,
        promotionsEnabled: _preferences['promotionsEnabled'] ?? true,
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Update preference for listings
  Future<void> setListingsEnabled(bool enabled) async {
    try {
      _preferences['listingsEnabled'] = enabled;
      notifyListeners();

      await _notificationService.updateNotificationPreferences(
        messagesEnabled: _preferences['messagesEnabled'] ?? true,
        listingsEnabled: enabled,
        paymentsEnabled: _preferences['paymentsEnabled'] ?? true,
        promotionsEnabled: _preferences['promotionsEnabled'] ?? true,
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Update preference for payments
  Future<void> setPaymentsEnabled(bool enabled) async {
    try {
      _preferences['paymentsEnabled'] = enabled;
      notifyListeners();

      await _notificationService.updateNotificationPreferences(
        messagesEnabled: _preferences['messagesEnabled'] ?? true,
        listingsEnabled: _preferences['listingsEnabled'] ?? true,
        paymentsEnabled: enabled,
        promotionsEnabled: _preferences['promotionsEnabled'] ?? true,
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Update preference for promotions
  Future<void> setPromotionsEnabled(bool enabled) async {
    try {
      _preferences['promotionsEnabled'] = enabled;
      notifyListeners();

      await _notificationService.updateNotificationPreferences(
        messagesEnabled: _preferences['messagesEnabled'] ?? true,
        listingsEnabled: _preferences['listingsEnabled'] ?? true,
        paymentsEnabled: _preferences['paymentsEnabled'] ?? true,
        promotionsEnabled: enabled,
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Subscribe to a topic
  Future<void> subscribeTo(String topic) async {
    try {
      await _notificationService.subscribeToTopic(topic);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFrom(String topic) async {
    try {
      await _notificationService.unsubscribeFromTopic(topic);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Enable all notifications
  Future<void> enableAllNotifications() async {
    try {
      await _notificationService.enableNotifications();
      _preferences['messagesEnabled'] = true;
      _preferences['listingsEnabled'] = true;
      _preferences['paymentsEnabled'] = true;
      _preferences['promotionsEnabled'] = true;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Disable all notifications
  Future<void> disableAllNotifications() async {
    try {
      await _notificationService.disableNotifications();
      _preferences['messagesEnabled'] = false;
      _preferences['listingsEnabled'] = false;
      _preferences['paymentsEnabled'] = false;
      _preferences['promotionsEnabled'] = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
