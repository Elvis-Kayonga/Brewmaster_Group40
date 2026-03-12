/// Abstract interface for push notification operations.
///
/// Requirements: 5.4, 12.1, 12.2, 12.3, 12.6, 12.7
/// Developer: Developer 3
abstract class NotificationRepository {
  /// Request push notification permission from the OS.
  Future<bool> requestPermission();

  /// Returns the current FCM device token, or null if unavailable.
  Future<String?> getToken();

  /// Stream of incoming notification payloads while the app is foregrounded.
  Stream<Map<String, dynamic>> watchNotifications();

  /// Persist notification preference toggles for the current user.
  Future<void> updatePreferences(Map<String, bool> preferences);

  /// Retrieve the current notification preferences for the current user.
  Future<Map<String, bool>> getPreferences();
}
