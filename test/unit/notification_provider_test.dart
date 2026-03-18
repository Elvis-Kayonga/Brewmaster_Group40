import 'package:flutter_test/flutter_test.dart';
import 'package:brewmaster/data/providers/notification_provider.dart';

void main() {
  group('NotificationProvider Unit Tests', () {
    late NotificationProvider provider;

    setUp(() {
      provider = NotificationProvider();
    });

    test('initial state is correct', () {
      expect(provider.notificationsInitialized, isFalse);
      expect(provider.preferences, isNotEmpty);
      expect(provider.preferences['messagesEnabled'], isTrue);
      expect(provider.preferences['listingsEnabled'], isTrue);
      expect(provider.preferences['paymentsEnabled'], isTrue);
      expect(provider.preferences['promotionsEnabled'], isTrue);
      expect(provider.isLoading, isFalse);
      expect(provider.error, isNull);
      expect(provider.fcmToken, isNull);
    });

    test('clearError clears error state', () {
      provider.clearError();
      expect(provider.error, isNull);
    });

    test('preferences contain all required keys', () {
      expect(provider.preferences.containsKey('messagesEnabled'), isTrue);
      expect(provider.preferences.containsKey('listingsEnabled'), isTrue);
      expect(provider.preferences.containsKey('paymentsEnabled'), isTrue);
      expect(provider.preferences.containsKey('promotionsEnabled'), isTrue);
    });

    test('all preferences are boolean values', () {
      provider.preferences.forEach((key, value) {
        expect(value, isA<bool>(), reason: '$key should be boolean');
      });
    });
  });

  group('NotificationProvider State Management', () {
    late NotificationProvider provider;

    setUp(() {
      provider = NotificationProvider();
    });

    test('provider notifies listeners on state change', () {
      int notifyCount = 0;
      provider.addListener(() => notifyCount++);

      provider.clearError();
      expect(notifyCount, greaterThan(0));
    });

    test('error state can be cleared', () {
      provider.clearError();
      expect(provider.error, isNull);
    });
  });

  group('NotificationProvider Preferences', () {
    late NotificationProvider provider;

    setUp(() {
      provider = NotificationProvider();
    });

    test('default preferences are all enabled', () {
      expect(provider.preferences['messagesEnabled'], isTrue);
      expect(provider.preferences['listingsEnabled'], isTrue);
      expect(provider.preferences['paymentsEnabled'], isTrue);
      expect(provider.preferences['promotionsEnabled'], isTrue);
    });

    test('preferences map is not null', () {
      expect(provider.preferences, isNotNull);
    });

    test('preferences map has correct size', () {
      expect(provider.preferences.length, equals(4));
    });
  });

  group('NotificationProvider Initialization', () {
    late NotificationProvider provider;

    setUp(() {
      provider = NotificationProvider();
    });

    test('initial notification state is false', () {
      expect(provider.notificationsInitialized, isFalse);
    });

    test('initial loading state is false', () {
      expect(provider.isLoading, isFalse);
    });

    test('initial error is null', () {
      expect(provider.error, isNull);
    });

    test('initial fcm token is null', () {
      expect(provider.fcmToken, isNull);
    });
  });
}
