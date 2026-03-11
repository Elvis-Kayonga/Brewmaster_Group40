// test/widgets/listing_form_screen_test.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brewmaster/domain/models/coffee_listing.dart';
import 'package:brewmaster/domain/models/search_filters.dart';
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
}

Widget _wrap(Widget child) => MaterialApp(
      home: BlocProvider(
        create: (_) => ListingBloc(repository: _FakeListingRepository()),
        child: child,
      ),
    );

void main() {
  group('ListingFormScreen Widget Tests', () {
    testWidgets('renders with all form fields', (tester) async {
      await tester.pumpWidget(_wrap(const ListingFormScreen()));
      expect(find.text('Create Listing'), findsWidgets);
      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('shows snackbar when required fields are empty',
        (tester) async {
      await tester.pumpWidget(_wrap(const ListingFormScreen()));
      await tester.tap(find.text('Create Listing').last);
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('shows image picker button', (tester) async {
      await tester.pumpWidget(_wrap(const ListingFormScreen()));
      expect(find.text('Pick Images'), findsOneWidget);
    });
  });
}
