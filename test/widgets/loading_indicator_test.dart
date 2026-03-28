import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brewmaster/presentation/widgets/common/loading_indicator.dart';

Widget _wrap(Widget child) =>
    MaterialApp(home: Scaffold(body: child));

void main() {
  group('LoadingIndicator', () {
    testWidgets('renders CircularProgressIndicator', (tester) async {
      await tester.pumpWidget(_wrap(const LoadingIndicator()));
      expect(find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));
    });

    testWidgets('renders with small size', (tester) async {
      await tester.pumpWidget(_wrap(const LoadingIndicator(size: LoadingSize.small)));
      expect(find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));
    });

    testWidgets('renders with large size', (tester) async {
      await tester.pumpWidget(_wrap(const LoadingIndicator(size: LoadingSize.large)));
      expect(find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));
    });

    testWidgets('shows message when provided', (tester) async {
      await tester.pumpWidget(_wrap(const LoadingIndicator(message: 'Please wait...')));
      expect(find.text('Please wait...'), findsOneWidget);
    });

    testWidgets('does not show message when not provided', (tester) async {
      await tester.pumpWidget(_wrap(const LoadingIndicator()));
      expect(find.byType(Text), findsNothing);
    });

    testWidgets('centered indicator wraps in Center', (tester) async {
      await tester.pumpWidget(_wrap(const LoadingIndicator(centered: true)));
      expect(find.byType(Center), findsAtLeastNWidgets(1));
    });

    testWidgets('non-centered indicator does not have extra Center', (tester) async {
      await tester.pumpWidget(_wrap(const LoadingIndicator(centered: false)));
      // No Center widget is added by LoadingIndicator itself when centered=false
      final centers = tester.widgetList<Center>(find.byType(Center));
      // The Scaffold adds none, LoadingIndicator(centered:false) adds none
      expect(centers.length, 0);
    });

    testWidgets('custom color is applied', (tester) async {
      await tester.pumpWidget(_wrap(const LoadingIndicator(color: Colors.red)));
      final indicator = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      expect(indicator.valueColor, isA<AlwaysStoppedAnimation<Color>>());
    });

    testWidgets('custom strokeWidth is applied', (tester) async {
      await tester.pumpWidget(_wrap(const LoadingIndicator(strokeWidth: 6.0)));
      final indicator = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      expect(indicator.strokeWidth, equals(6.0));
    });
  });

  group('InlineLoadingIndicator', () {
    testWidgets('renders with default size', (tester) async {
      await tester.pumpWidget(_wrap(const InlineLoadingIndicator()));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders with custom size', (tester) async {
      await tester.pumpWidget(_wrap(const InlineLoadingIndicator(size: 24.0)));
      final sizedBox = tester.widget<SizedBox>(
        find.ancestor(of: find.byType(CircularProgressIndicator), matching: find.byType(SizedBox)).first,
      );
      expect(sizedBox.width, equals(24.0));
    });

    testWidgets('renders with custom color', (tester) async {
      await tester.pumpWidget(_wrap(const InlineLoadingIndicator(color: Colors.green)));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('LoadingOverlay', () {
    testWidgets('shows child always', (tester) async {
      await tester.pumpWidget(_wrap(LoadingOverlay(
        isLoading: false,
        child: const Text('Content'),
      )));
      expect(find.text('Content'), findsOneWidget);
    });

    testWidgets('shows loading indicator when isLoading is true', (tester) async {
      await tester.pumpWidget(_wrap(LoadingOverlay(
        isLoading: true,
        child: const Text('Content'),
      )));
      expect(find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));
    });

    testWidgets('does not show loading indicator when isLoading is false', (tester) async {
      await tester.pumpWidget(_wrap(LoadingOverlay(
        isLoading: false,
        child: const Text('Content'),
      )));
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('shows message with loading overlay', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 800));
      await tester.pumpWidget(_wrap(LoadingOverlay(
        isLoading: true,
        message: 'Saving...',
        child: const SizedBox.expand(child: Text('Content')),
      )));
      await tester.binding.setSurfaceSize(null);
      expect(find.text('Saving...'), findsAtLeastNWidgets(1));
    });
  });

  group('ShimmerLoading', () {
    testWidgets('renders with given dimensions', (tester) async {
      await tester.pumpWidget(_wrap(const ShimmerLoading(width: 200, height: 50)));
      expect(find.byType(ShimmerLoading), findsOneWidget);
    });

    testWidgets('animates (does not crash)', (tester) async {
      await tester.pumpWidget(_wrap(const ShimmerLoading(width: 100, height: 20)));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(ShimmerLoading), findsOneWidget);
    });
  });

  group('LoadingStateWidget', () {
    testWidgets('shows loadingWidget when isLoading is true', (tester) async {
      await tester.pumpWidget(_wrap(LoadingStateWidget<String>(
        isLoading: true,
        data: null,
        contentBuilder: (data) => Text(data),
      )));
      expect(find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));
    });

    testWidgets('shows content when data is available', (tester) async {
      await tester.pumpWidget(_wrap(LoadingStateWidget<String>(
        isLoading: false,
        data: 'Hello',
        contentBuilder: (data) => Text(data),
      )));
      expect(find.text('Hello'), findsOneWidget);
    });

    testWidgets('shows error when errorMessage is set', (tester) async {
      await tester.pumpWidget(_wrap(LoadingStateWidget<String>(
        isLoading: false,
        data: null,
        errorMessage: 'Something went wrong',
        contentBuilder: (data) => Text(data),
      )));
      expect(find.text('Something went wrong'), findsOneWidget);
    });

    testWidgets('shows Retry button when onRetry is provided', (tester) async {
      await tester.pumpWidget(_wrap(LoadingStateWidget<String>(
        isLoading: false,
        data: null,
        errorMessage: 'Error',
        onRetry: () {},
        contentBuilder: (data) => Text(data),
      )));
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('shows empty widget when data is null and no error', (tester) async {
      await tester.pumpWidget(_wrap(LoadingStateWidget<String>(
        isLoading: false,
        data: null,
        contentBuilder: (data) => Text(data),
        emptyWidget: const Text('Empty'),
      )));
      expect(find.text('Empty'), findsOneWidget);
    });

    testWidgets('uses custom error builder', (tester) async {
      await tester.pumpWidget(_wrap(LoadingStateWidget<String>(
        isLoading: false,
        data: null,
        errorMessage: 'Custom error',
        errorBuilder: (e) => Text('Custom: $e'),
        contentBuilder: (data) => Text(data),
      )));
      expect(find.text('Custom: Custom error'), findsOneWidget);
    });
  });
}
