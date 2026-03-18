import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:brewmaster/presentation/screens/messaging/conversations_screen.dart';
import 'package:brewmaster/data/providers/message_provider.dart';

void main() {
  group('ConversationsScreen Widget Tests', () {
    late MessageProvider mockProvider;

    setUp(() {
      mockProvider = MessageProvider();
    });

    Widget createTestWidget() {
      return ChangeNotifierProvider<MessageProvider>.value(
        value: mockProvider,
        child: const MaterialApp(
          home: ConversationsScreen(),
        ),
      );
    }

    testWidgets('displays loading indicator when loading', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays empty state when no conversations', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      
      expect(find.text('No Messages'), findsOneWidget);
      expect(find.byIcon(Icons.mail_outline), findsOneWidget);
    });

    testWidgets('displays search field', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Search conversations...'), findsOneWidget);
    });

    testWidgets('search field clears on clear button tap', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'test query');
      await tester.pump();

      expect(find.text('test query'), findsOneWidget);
      expect(find.byIcon(Icons.clear), findsOneWidget);

      await tester.tap(find.byIcon(Icons.clear));
      await tester.pump();

      expect(find.text('test query'), findsNothing);
    });

    testWidgets('displays app bar with title', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Messages'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });
  });
}
