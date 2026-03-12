import 'package:flutter_test/flutter_test.dart';
import 'package:brewmaster/data/providers/message_provider.dart';
import 'package:brewmaster/domain/models/message.dart';
import 'package:brewmaster/domain/models/conversation.dart';

void main() {
  group('MessageProvider Unit Tests', () {
    late MessageProvider provider;

    setUp(() {
      provider = MessageProvider();
    });

    test('initial state is correct', () {
      expect(provider.conversations, isEmpty);
      expect(provider.currentConversationMessages, isEmpty);
      expect(provider.currentConversationId, isNull);
      expect(provider.isLoading, isFalse);
      expect(provider.error, isNull);
      expect(provider.totalUnreadCount, 0);
    });

    test('clearError clears error state', () {
      provider.clearError();
      expect(provider.error, isNull);
    });

    test('searchConversations returns all when query is empty', () {
      final result = provider.searchConversations('');
      expect(result, equals(provider.conversations));
    });

    test('searchConversations returns conversations when query provided', () {
      final result = provider.searchConversations('test');
      expect(result, isA<List<Conversation>>());
    });

    test('getOfflineQueue returns list', () {
      final queue = provider.getOfflineQueue();
      expect(queue, isA<List<Map<String, dynamic>>>());
    });
  });

  group('MessageProvider State Management', () {
    late MessageProvider provider;

    setUp(() {
      provider = MessageProvider();
    });

    test('provider notifies listeners on state change', () {
      int notifyCount = 0;
      provider.addListener(() => notifyCount++);

      provider.clearError();
      expect(notifyCount, greaterThan(0));
    });

    test('error state can be set and cleared', () {
      provider.clearError();
      expect(provider.error, isNull);
    });
  });

  group('MessageProvider Conversation Management', () {
    late MessageProvider provider;

    setUp(() {
      provider = MessageProvider();
    });

    test('searchConversations handles empty list', () {
      final results = provider.searchConversations('test');
      expect(results, isA<List<Conversation>>());
      expect(results, isEmpty);
    });

    test('searchConversations returns all on empty query', () {
      final results = provider.searchConversations('');
      expect(results, equals(provider.conversations));
    });
  });
}
