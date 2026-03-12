// test/widgets/search_screen_test.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brewmaster/domain/models/coffee_listing.dart';
import 'package:brewmaster/domain/models/search_filters.dart';
import 'package:brewmaster/domain/models/paginated_result.dart';
import 'package:brewmaster/domain/repositories/listing_repository.dart';
import 'package:brewmaster/presentation/blocs/listing/listing_bloc.dart';
import 'package:brewmaster/presentation/screens/search/search_screen.dart';

class _FakeListingRepository implements ListingRepository {
  @override
  Future<String> createListing(CoffeeListing listing,
          {List<File>? images}) async =>
      'fake_id';
  @override
  Future<void> updateListing(CoffeeListing listing,
      {List<File>? newImages}) async {}
  @override
  Future<void> deleteListing(String listingId) async {}
  @override
  Future<CoffeeListing?> getListing(String listingId) async => null;
  @override
  Stream<List<CoffeeListing>> watchFarmerListings(String farmerId) =>
      Stream.value([]);
  @override
  Stream<List<CoffeeListing>> watchActiveListings() => Stream.value([]);
  @override
  Future<List<CoffeeListing>> searchListings(SearchFilters filters) async =>
      [];
  @override
  Future<PaginatedResult<CoffeeListing>> getListingPage({
    int pageSize = 20,
    Object? startAfter,
  }) async =>
      const PaginatedResult<CoffeeListing>(items: [], hasMore: false);
}

Widget _wrap(Widget child) => MaterialApp(
      home: BlocProvider(
        create: (_) => ListingBloc(repository: _FakeListingRepository()),
        child: child,
      ),
    );

void main() {
  group('SearchScreen Widget Tests', () {
    testWidgets('renders with filter button', (tester) async {
      await tester.pumpWidget(_wrap(const SearchScreen()));
      await tester.pump();
      expect(find.text('Search Listings'), findsOneWidget);
      expect(find.text('Show Filters'), findsOneWidget);
    });

    testWidgets('shows filter options when toggled', (tester) async {
      await tester.pumpWidget(_wrap(const SearchScreen()));
      await tester.pump();
      await tester.tap(find.text('Show Filters'));
      await tester.pumpAndSettle();
      expect(find.text('Hide Filters'), findsOneWidget);
    });

    testWidgets('has clear button', (tester) async {
      await tester.pumpWidget(_wrap(const SearchScreen()));
      await tester.pump();
      expect(find.text('Clear'), findsOneWidget);
    });

    testWidgets('displays list view', (tester) async {
      await tester.pumpWidget(_wrap(const SearchScreen()));
      await tester.pump();
      expect(find.byType(ListView), findsWidgets);
    });
  });
}
