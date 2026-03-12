// test/widgets/search_screen_test.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brewmaster/domain/models/coffee_listing.dart';
import 'package:brewmaster/domain/models/enums.dart';
import 'package:brewmaster/domain/models/offline_sync_operation.dart';
import 'package:brewmaster/domain/models/paginated_result.dart';
import 'package:brewmaster/domain/models/search_filters.dart';
import 'package:brewmaster/domain/repositories/listing_repository.dart';
import 'package:brewmaster/domain/repositories/offline_sync_repository.dart';
import 'package:brewmaster/presentation/blocs/connectivity/connectivity_bloc.dart';
import 'package:brewmaster/presentation/blocs/listing/listing_bloc.dart';
import 'package:brewmaster/presentation/screens/search/search_screen.dart';

class _FakeOfflineSyncRepository implements OfflineSyncRepository {
  @override
  Future<void> enqueueOperation(OfflineSyncOperation op) async {}
  @override
  Future<int> processPendingQueue() async => 0;
  @override
  Future<void> clearQueue() async {}
  @override
  Stream<bool> watchConnectivity() => Stream.value(true);
  @override
  Future<List<OfflineSyncOperation>> getPendingOperations() async => [];
}

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
  Stream<List<CoffeeListing>> watchActiveListings() => Stream.value([
        CoffeeListing(
          listingId: 'test1',
          farmerId: 'farmer1',
          variety: 'Bourbon',
          quantity: 100,
          pricePerKg: 5.0,
          processingMethod: ProcessingMethod.washed,
          altitude: 1500,
          harvestDate: DateTime(2024, 1, 1),
          qualityScore: 80,
          description: 'Test coffee',
          images: [],
          location: '0,0',
          status: ListingStatus.active,
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        )
      ]);
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
      home: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => ListingBloc(repository: _FakeListingRepository()),
          ),
          BlocProvider(
            create: (_) => ConnectivityBloc(
                repository: _FakeOfflineSyncRepository()),
          ),
        ],
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
