import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:brewmaster/presentation/screens/messaging/chat_screen.dart';
import 'package:brewmaster/data/providers/message_provider.dart';
import 'package:brewmaster/domain/models/conversation.dart';

void main() {
  group('ChatScreen Widget Tests', () {
    late MessageProvider mockProvider;
    late Conversation testConversation;

    setUp(() {
      mockProvider = MessageProvider();
      testConversation = Conversation(
        conversationId: 'test-conv-123',
        participantIds: ['user1', 'user2'],
        lastMessage: null,
        unreadCount: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });

    Widget createTestWidget() {
      return ChangeNotifierProvider<MessageProvider>.value(
        value: mockProvider,
        child: MaterialApp(
          home: ChatScreen(conversation: testConversation),
        ),
      );
    }

    testWidgets('displays app bar with conversation ID', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.textContaining('Chat #'), findsOneWidget);
    });

    testWidgets('displays message input field', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Type a message...'), findsOneWidget);
    });

    testWidgets('send button is disabled when text is empty', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final sendButton = find.byIcon(Icons.send);
      expect(sendButton, findsOneWidget);
      
      final fab = tester.widget<FloatingActionButton>(
        find.ancestor(
          of: sendButton,
          matching: find.byType(FloatingActionButton),
        ),
      );
      expect(fab.onPressed, isNull);
    });

    testWidgets('send button enables when text is entered', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Test message');
      await tester.pump();

      final sendButton = find.byIcon(Icons.send);
      final fab = tester.widget<FloatingActionButton>(
        find.ancestor(
          of: sendButton,
          matching: find.byType(FloatingActionButton),
        ),
      );
      expect(fab.onPressed, isNotNull);
    });

    testWidgets('displays attachment button', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('displays loading indicator when loading', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
