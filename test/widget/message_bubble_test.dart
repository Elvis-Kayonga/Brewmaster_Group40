import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brewmaster/presentation/widgets/message/message_bubble.dart';
import 'package:brewmaster/domain/models/message.dart';

void main() {
  group('MessageBubble Widget Tests', () {
    late Message testMessage;

    setUp(() {
      testMessage = Message(
        messageId: 'msg-123',
        conversationId: 'conv-123',
        senderId: 'user1',
        receiverId: 'user2',
        content: 'Test message content',
        messageType: MessageType.text,
        listingId: null,
        isRead: false,
        createdAt: DateTime.now(),
      );
    });

    Widget createTestWidget({required bool isOutgoing}) {
      return MaterialApp(
        home: Scaffold(
          body: MessageBubble(
            message: testMessage,
            isOutgoing: isOutgoing,
          ),
        ),
      );
    }

    testWidgets('displays message content', (tester) async {
      await tester.pumpWidget(createTestWidget(isOutgoing: true));
      expect(find.text('Test message content'), findsOneWidget);
    });

    testWidgets('outgoing message aligns right', (tester) async {
      await tester.pumpWidget(createTestWidget(isOutgoing: true));
      
      final align = tester.widget<Align>(find.byType(Align).first);
      expect(align.alignment, Alignment.centerRight);
    });

    testWidgets('incoming message aligns left', (tester) async {
      await tester.pumpWidget(createTestWidget(isOutgoing: false));
      
      final align = tester.widget<Align>(find.byType(Align).first);
      expect(align.alignment, Alignment.centerLeft);
    });

    testWidgets('displays timestamp', (tester) async {
      await tester.pumpWidget(createTestWidget(isOutgoing: true));
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('outgoing message shows read status icon', (tester) async {
      await tester.pumpWidget(createTestWidget(isOutgoing: true));
      expect(find.byIcon(Icons.done), findsOneWidget);
    });

    testWidgets('read message shows double check icon', (tester) async {
      testMessage = testMessage.copyWith(isRead: true);
      await tester.pumpWidget(createTestWidget(isOutgoing: true));
      expect(find.byIcon(Icons.done_all), findsOneWidget);
    });

    testWidgets('listing reference message displays listing info', (tester) async {
      final listingMessage = Message(
        messageId: 'msg-456',
        conversationId: 'conv-123',
        senderId: 'user1',
        receiverId: 'user2',
        content: 'Check this listing',
        messageType: MessageType.listingReference,
        listingId: 'listing-789',
        isRead: false,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessageBubble(
              message: listingMessage,
              isOutgoing: true,
            ),
          ),
        ),
      );

      expect(find.text('Check this listing'), findsOneWidget);
      expect(find.byIcon(Icons.local_offer), findsOneWidget);
    });

    testWidgets('message bubble responds to tap', (tester) async {
      bool tapped = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessageBubble(
              message: testMessage,
              isOutgoing: true,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(GestureDetector));
      expect(tapped, isTrue);
    });
  });

  group('TypingIndicator Widget Tests', () {
    testWidgets('displays when visible is true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TypingIndicator(isVisible: true),
          ),
        ),
      );

      expect(find.byType(TypingIndicator), findsOneWidget);
    });

    testWidgets('hides when visible is false', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TypingIndicator(isVisible: false),
          ),
        ),
      );

      expect(find.byType(SizedBox), findsOneWidget);
    });

    testWidgets('animates dots', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TypingIndicator(isVisible: true),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      
      expect(find.byType(Container), findsWidgets);
    });
  });
}
