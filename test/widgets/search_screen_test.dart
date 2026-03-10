// test/widgets/search_screen_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:brewmaster/data/providers/listing_provider.dart';
import 'package:brewmaster/presentation/screens/search/search_screen.dart';

void main() {
  group('SearchScreen Widget Tests', () {
    testWidgets('SearchScreen renders with filter button', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => ListingProvider(),
            child: const SearchScreen(),
          ),
        ),
      );

      expect(find.text('Search Listings'), findsOneWidget);
      expect(find.text('Show Filters'), findsOneWidget);
    });

    testWidgets('SearchScreen shows filter options when toggled', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => ListingProvider(),
            child: const SearchScreen(),
          ),
        ),
      );

      await tester.tap(find.text('Show Filters'));
      await tester.pumpAndSettle();

      expect(find.text('Hide Filters'), findsOneWidget);
      expect(find.text('Variety'), findsOneWidget);
      expect(find.text('Processing Method'), findsOneWidget);
    });

    testWidgets('SearchScreen allows clearing filters', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => ListingProvider(),
            child: const SearchScreen(),
          ),
        ),
      );

      expect(find.text('Clear'), findsOneWidget);
    });

    testWidgets('SearchScreen displays listings in list view', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => ListingProvider(),
            child: const SearchScreen(),
          ),
        ),
      );

      expect(find.byType(ListView), findsWidgets);
    });
  });
}
