// Widget tests for ListingDetailScreen
// Coverage: loading state, error state, loaded state (no images, with location),
//           messaging loading state (button disabled), close button present.

import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:brewmaster/config/localization/app_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:brewmaster/domain/models/coffee_listing.dart';
import 'package:brewmaster/domain/models/enums.dart';
import 'package:brewmaster/domain/models/paginated_result.dart';
import 'package:brewmaster/domain/models/search_filters.dart';
import 'package:brewmaster/domain/repositories/listing_repository.dart';
import 'package:brewmaster/presentation/blocs/listing_detail/listing_detail_bloc.dart';
import 'package:brewmaster/presentation/blocs/messaging/messaging_bloc.dart';
import 'package:brewmaster/presentation/screens/listings/listing_detail_screen.dart';

import '../helpers/fake_repositories.dart';

// ── Fake repo that never resolves getListing (keeps bloc in loading) ──────────

class _NeverResolvingListingRepository implements ListingRepository {
  @override
  Future<CoffeeListing?> getListing(String listingId) =>
      Completer<CoffeeListing?>().future; // never completes

  @override
  Stream<List<CoffeeListing>> watchFarmerListings(String farmerId) =>
      Stream.value([]);

  @override
  Stream<List<CoffeeListing>> watchActiveListings() => Stream.value([]);

  @override
  Future<String> createListing(CoffeeListing l, {List<File>? images}) async =>
      l.listingId;

  @override
  Future<void> updateListing(CoffeeListing l, {List<File>? newImages}) async {}

  @override
  Future<void> deleteListing(String listingId) async {}

  @override
  Future<List<CoffeeListing>> searchListings(SearchFilters filters) async => [];

  @override
  Future<PaginatedResult<CoffeeListing>> getListingPage(
          {int pageSize = 20, Object? startAfter}) async =>
      const PaginatedResult(items: [], hasMore: false);
}

// ── Fixture ───────────────────────────────────────────────────────────────────

CoffeeListing _makeListing({
  String id = 'listing-1',
  String farmerId = 'farmer-1',
  List<String> images = const [],
  String location = '',
}) =>
    CoffeeListing(
      listingId: id,
      farmerId: farmerId,
      variety: 'Bourbon',
      quantity: 50.0,
      pricePerKg: 12.50,
      processingMethod: ProcessingMethod.washed,
      altitude: 1800.0,
      harvestDate: DateTime(2024, 6, 1),
      qualityScore: 87.0,
      description: 'A bright, fruity coffee with notes of red fruit.',
      images: images,
      location: location,
      status: ListingStatus.active,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );

// ── Helper ────────────────────────────────────────────────────────────────────

/// Builds the screen with blocs created INSIDE create callbacks.
/// [listingForRepo] — if set, getListing returns it (loaded state).
/// [listingError] — if set, getListing throws (error state).
/// [neverResolve] — if true, getListing never completes (loading state).
/// [messagingLoading] — if true, pre-emits MessagingLoading.
Widget _wrap({
  CoffeeListing? listingForRepo,
  bool neverResolve = false,
  bool listingError = false,
  bool messagingLoading = false,
}) {
  final listingRepo = neverResolve
      ? _NeverResolvingListingRepository() as ListingRepository
      : (FakeListingRepository()
          ..listing = listingForRepo
          ..error = listingError ? Exception('Something went wrong') : null);

  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: MultiBlocProvider(
      providers: [
        BlocProvider<ListingDetailBloc>(
          create: (_) => ListingDetailBloc(repository: listingRepo),
        ),
        BlocProvider<MessagingBloc>(
          create: (_) {
            final b = MessagingBloc(repository: FakeMessageRepository());
            if (messagingLoading) b.emit(const MessagingLoading());
            return b;
          },
        ),
      ],
      child: const ListingDetailScreen(listingId: 'listing-1'),
    ),
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    setupFirebaseCoreMocks();
    await Firebase.initializeApp();
  });

  group('ListingDetailScreen', () {
    testWidgets('shows loading indicator while getListing is pending',
        (tester) async {
      await tester.pumpWidget(_wrap(neverResolve: true));
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('shows error state when getListing throws', (tester) async {
      await tester.pumpWidget(_wrap(listingError: true));
      await tester.pump();
      await tester.pump();

      expect(find.textContaining('Something went wrong'), findsOneWidget);
    });

    testWidgets('shows SizedBox.shrink — no COFFEE PROFILE — for error state',
        (tester) async {
      await tester.pumpWidget(_wrap(listingError: true));
      await tester.pump();
      await tester.pump();

      expect(find.text('COFFEE PROFILE'), findsNothing);
    });

    testWidgets('shows listing detail when getListing returns a listing',
        (tester) async {
      final listing = _makeListing();
      await tester.pumpWidget(_wrap(listingForRepo: listing));
      await tester.pump();
      await tester.pump();

      expect(find.text('COFFEE PROFILE'), findsOneWidget);
      expect(find.text('Bourbon'), findsWidgets);
      expect(find.text('PROCESSING STATION'), findsOneWidget);
      expect(find.text('SPECIFICATIONS'), findsOneWidget);
    });

    testWidgets('shows image placeholder when images list is empty',
        (tester) async {
      final listing = _makeListing(images: const []);
      await tester.pumpWidget(_wrap(listingForRepo: listing));
      await tester.pump();
      await tester.pump();

      expect(find.byIcon(Icons.coffee), findsOneWidget);
    });

    testWidgets('shows spec fields in detail card', (tester) async {
      final listing = _makeListing();
      await tester.pumpWidget(_wrap(listingForRepo: listing));
      await tester.pump();
      await tester.pump();

      expect(find.text('Altitude'), findsOneWidget);
      expect(find.text('Quality Score'), findsOneWidget);
      expect(find.text('Available'), findsOneWidget);
      expect(find.text('Price / kg'), findsOneWidget);
    });

    testWidgets('shows CONTACT FARMER button when not loading', (tester) async {
      final listing = _makeListing();
      await tester.pumpWidget(_wrap(listingForRepo: listing));
      await tester.pump();
      await tester.pump();

      expect(find.text('CONTACT FARMER'), findsOneWidget);
    });

    testWidgets(
        'shows CircularProgressIndicator in button during MessagingLoading',
        (tester) async {
      final listing = _makeListing();
      await tester.pumpWidget(
          _wrap(listingForRepo: listing, messagingLoading: true));
      await tester.pump();
      await tester.pump();

      expect(find.text('CONTACT FARMER'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('shows close button in app bar', (tester) async {
      await tester.pumpWidget(_wrap(neverResolve: true));
      await tester.pump();
      await tester.pump();

      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('does not show FARM LOCATION section when location is empty',
        (tester) async {
      final listing = _makeListing(location: '');
      await tester.pumpWidget(_wrap(listingForRepo: listing));
      await tester.pump();
      await tester.pump();

      expect(find.text('FARM LOCATION'), findsNothing);
    });

    testWidgets('shows description text in detail view', (tester) async {
      final listing = _makeListing();
      await tester.pumpWidget(_wrap(listingForRepo: listing));
      await tester.pump();
      await tester.pump();

      expect(
        find.textContaining('A bright, fruity coffee'),
        findsOneWidget,
      );
    });

    testWidgets('shows FARM LOCATION section with JSON location string',
        (tester) async {
      final listing = _makeListing(
        location: '{"latitude": 1.2921, "longitude": 36.8219}',
      );
      await tester.pumpWidget(_wrap(listingForRepo: listing));
      await tester.pump();
      await tester.pump();
      expect(find.text('FARM LOCATION'), findsOneWidget);
    });

    testWidgets('shows FARM LOCATION section with comma-separated location',
        (tester) async {
      final listing = _makeListing(location: '1.2921, 36.8219');
      await tester.pumpWidget(_wrap(listingForRepo: listing));
      await tester.pump();
      await tester.pump();
      expect(find.text('FARM LOCATION'), findsOneWidget);
    });

    testWidgets(
        'does not show FARM LOCATION for invalid (non-parseable) location',
        (tester) async {
      final listing = _makeListing(location: 'invalid-location');
      await tester.pumpWidget(_wrap(listingForRepo: listing));
      await tester.pump();
      await tester.pump();
      expect(find.text('FARM LOCATION'), findsNothing);
    });

    testWidgets('MessagingFailure shows snackbar', (tester) async {
      final listing = _makeListing();
      await tester.pumpWidget(_wrap(listingForRepo: listing));
      await tester.pump();
      await tester.pump();

      // Access the MessagingBloc and emit a failure
      final bloc = tester
          .element(find.byType(Scaffold))
          .read<MessagingBloc>();
      bloc.emit(const MessagingFailure('Could not start chat'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Could not start chat'), findsOneWidget);
    });

    testWidgets('harvest year is displayed in the hero overlay', (tester) async {
      final listing = _makeListing();
      await tester.pumpWidget(_wrap(listingForRepo: listing));
      await tester.pump();
      await tester.pump();
      // The harvest year is 2024
      expect(find.textContaining('2024'), findsWidgets);
    });

    testWidgets('shows WASHED processing method in detail', (tester) async {
      final listing = _makeListing();
      await tester.pumpWidget(_wrap(listingForRepo: listing));
      await tester.pump();
      await tester.pump();
      // processingMethod.name.toUpperCase() → 'WASHED'
      expect(find.text('WASHED'), findsOneWidget);
    });
  });
}
