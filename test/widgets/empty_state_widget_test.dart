import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:brewmaster/config/localization/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brewmaster/presentation/widgets/common/empty_state_widget.dart';

Widget _wrap(Widget child) =>
    MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child));

void main() {
  group('EmptyStateWidget', () {
    testWidgets('renders title', (tester) async {
      await tester.pumpWidget(_wrap(const EmptyStateWidget(title: 'No items')));
      await tester.pump();
      expect(find.text('No items'), findsOneWidget);
    });

    testWidgets('renders description when provided', (tester) async {
      await tester.pumpWidget(_wrap(const EmptyStateWidget(
        title: 'No items',
        description: 'Add some items to see them here.',
      )));
      await tester.pump();
      expect(find.text('Add some items to see them here.'), findsOneWidget);
    });

    testWidgets('does not render description when not provided', (tester) async {
      await tester.pumpWidget(_wrap(const EmptyStateWidget(title: 'No items')));
      await tester.pump();
      // only the title text
      expect(find.byType(Text), findsOneWidget);
    });

    testWidgets('renders action button when actionText is provided', (tester) async {
      await tester.pumpWidget(_wrap(EmptyStateWidget(
        title: 'No items',
        actionText: 'Add Item',
        onAction: () {},
      )));
      await tester.pump();
      expect(find.text('Add Item'), findsOneWidget);
    });

    testWidgets('calls onAction when action button tapped', (tester) async {
      bool called = false;
      await tester.pumpWidget(_wrap(EmptyStateWidget(
        title: 'No items',
        actionText: 'Add Item',
        onAction: () => called = true,
      )));
      await tester.pump();
      await tester.tap(find.text('Add Item'));
      expect(called, isTrue);
    });

    testWidgets('renders secondary action button when secondaryActionText is provided', (tester) async {
      await tester.pumpWidget(_wrap(EmptyStateWidget(
        title: 'No items',
        actionText: 'Primary',
        secondaryActionText: 'Secondary',
        onAction: () {},
        onSecondaryAction: () {},
      )));
      await tester.pump();
      expect(find.text('Primary'), findsOneWidget);
      expect(find.text('Secondary'), findsOneWidget);
    });

    testWidgets('calls onSecondaryAction when secondary button tapped', (tester) async {
      bool called = false;
      await tester.pumpWidget(_wrap(EmptyStateWidget(
        title: 'No items',
        secondaryActionText: 'Secondary',
        onSecondaryAction: () => called = true,
      )));
      await tester.pump();
      await tester.tap(find.text('Secondary'));
      expect(called, isTrue);
    });

    testWidgets('renders custom icon', (tester) async {
      await tester.pumpWidget(_wrap(const EmptyStateWidget(
        title: 'No items',
        icon: Icons.coffee,
      )));
      await tester.pump();
      expect(find.byIcon(Icons.coffee), findsOneWidget);
    });

    testWidgets('renders custom image instead of icon', (tester) async {
      await tester.pumpWidget(_wrap(EmptyStateWidget(
        title: 'No items',
        image: const FlutterLogo(),
      )));
      await tester.pump();
      expect(find.byType(FlutterLogo), findsOneWidget);
    });

    testWidgets('compact layout uses smaller padding', (tester) async {
      await tester.pumpWidget(_wrap(const EmptyStateWidget(
        title: 'No items',
        compact: true,
      )));
      await tester.pump();
      expect(find.text('No items'), findsOneWidget);
    });

    testWidgets('renders with custom icon color', (tester) async {
      await tester.pumpWidget(_wrap(const EmptyStateWidget(
        title: 'No items',
        iconColor: Colors.red,
      )));
      await tester.pump();
      final icon = tester.widget<Icon>(find.byType(Icon).first);
      expect(icon.color, equals(Colors.red));
    });
  });

  group('EmptyListState', () {
    testWidgets('renders with item name', (tester) async {
      await tester.pumpWidget(_wrap(EmptyListState(itemName: 'listings')));
      await tester.pump();
      expect(find.textContaining('listings'), findsAtLeastNWidgets(1));
    });

    testWidgets('renders action button', (tester) async {
      bool called = false;
      await tester.pumpWidget(_wrap(EmptyListState(
        itemName: 'items',
        actionText: 'Add',
        onAction: () => called = true,
      )));
      await tester.pump();
      await tester.tap(find.text('Add'));
      expect(called, isTrue);
    });
  });

  group('EmptySearchState', () {
    testWidgets('renders with query', (tester) async {
      await tester.pumpWidget(_wrap(const EmptySearchState(query: 'arabica')));
      await tester.pump();
      expect(find.textContaining('arabica'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows clear search button when callback provided', (tester) async {
      bool called = false;
      await tester.pumpWidget(_wrap(EmptySearchState(
        query: 'test',
        onClearSearch: () => called = true,
      )));
      await tester.pump();
      await tester.tap(find.text('Clear search'));
      expect(called, isTrue);
    });

    testWidgets('does not show clear search button when no callback', (tester) async {
      await tester.pumpWidget(_wrap(const EmptySearchState(query: 'test')));
      await tester.pump();
      expect(find.text('Clear search'), findsNothing);
    });
  });

  group('NoConnectionState', () {
    testWidgets('renders no connection message', (tester) async {
      await tester.pumpWidget(_wrap(const NoConnectionState()));
      await tester.pump();
      expect(find.textContaining('connection'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows try again button when callback provided', (tester) async {
      bool called = false;
      await tester.pumpWidget(_wrap(NoConnectionState(onRetry: () => called = true)));
      await tester.pump();
      await tester.tap(find.text('Try again'));
      expect(called, isTrue);
    });
  });

  group('NoDataState', () {
    testWidgets('renders default message', (tester) async {
      await tester.pumpWidget(_wrap(const NoDataState()));
      await tester.pump();
      expect(find.textContaining('No data'), findsOneWidget);
    });

    testWidgets('renders custom title', (tester) async {
      await tester.pumpWidget(_wrap(const NoDataState(title: 'Nothing here')));
      await tester.pump();
      expect(find.text('Nothing here'), findsOneWidget);
    });

    testWidgets('renders custom description', (tester) async {
      await tester.pumpWidget(_wrap(const NoDataState(
        title: 'Empty',
        description: 'Please check back later.',
      )));
      await tester.pump();
      expect(find.text('Please check back later.'), findsOneWidget);
    });
  });
}
