// test/widgets/listing_form_screen_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:brewmaster/data/providers/listing_provider.dart';
import 'package:brewmaster/presentation/screens/listings/listing_form_screen.dart';

void main() {
  group('ListingFormScreen Widget Tests', () {
    testWidgets('ListingFormScreen renders with all form fields', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => ListingProvider(),
            child: const ListingFormScreen(),
          ),
        ),
      );

      expect(find.text('Create Listing'), findsWidgets);
      expect(find.byType(TextField), findsWidgets);
      expect(find.byType(DropdownButton), findsWidgets);
    });

    testWidgets('ListingFormScreen shows validation error when fields are empty', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => ListingProvider(),
            child: const ListingFormScreen(),
          ),
        ),
      );

      final createButton = find.byType(ElevatedButton).first;
      await tester.tap(createButton);
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsWidgets);
    });

    testWidgets('ListingFormScreen allows image selection', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => ListingProvider(),
            child: const ListingFormScreen(),
          ),
        ),
      );

      expect(find.text('Pick Images'), findsOneWidget);
    });
  });
}
