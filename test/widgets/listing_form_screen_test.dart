// test/widgets/listing_form_screen_test.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:brewmaster/config/localization/app_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brewmaster/domain/models/coffee_listing.dart';
import 'package:brewmaster/domain/models/search_filters.dart';
import 'package:brewmaster/domain/models/paginated_result.dart';
import 'package:brewmaster/domain/repositories/listing_repository.dart';
import 'package:brewmaster/presentation/blocs/listing/listing_bloc.dart';
import 'package:brewmaster/presentation/screens/listings/listing_form_screen.dart';

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
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: BlocProvider(
        create: (_) => ListingBloc(repository: _FakeListingRepository()),
        child: child,
      ),
    );

void main() {
  group('ListingFormScreen Widget Tests', () {
    testWidgets('renders with all form fields', (tester) async {
      await tester.pumpWidget(_wrap(const ListingFormScreen()));
      await tester.pump();
      expect(find.text('Create Listing'), findsWidgets);
      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('shows snackbar when required fields are empty',
        (tester) async {
      await tester.pumpWidget(_wrap(const ListingFormScreen()));
      await tester.pump();
      final submitBtn = find.widgetWithText(ElevatedButton, 'Create Listing');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pump();
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('shows image picker button', (tester) async {
      await tester.pumpWidget(_wrap(const ListingFormScreen()));
      await tester.pump();
      expect(find.text('Pick Images'), findsOneWidget);
    });
  });
}
