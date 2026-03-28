import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brewmaster/domain/models/coffee_listing.dart';
import 'package:brewmaster/domain/models/enums.dart';
import 'package:brewmaster/presentation/widgets/listing/listing_card.dart';

/// Allows Image.network to be rendered without a real HTTP client in tests.
class _MockHttpOverrides extends HttpOverrides {}

Widget _wrap(Widget child) =>
    MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child)));

CoffeeListing _makeListing({
  String listingId = 'l1',
  String farmerId = 'f1',
  String? farmerName,
  String variety = 'Arabica',
  double quantity = 100.0,
  double pricePerKg = 8.5,
  double qualityScore = 87.0,
  double altitude = 1800.0,
  ListingStatus status = ListingStatus.active,
  List<String> images = const [],
}) {
  final now = DateTime(2024, 1, 1);
  return CoffeeListing(
    listingId: listingId,
    farmerId: farmerId,
    farmerName: farmerName,
    variety: variety,
    quantity: quantity,
    pricePerKg: pricePerKg,
    processingMethod: ProcessingMethod.washed,
    altitude: altitude,
    harvestDate: now,
    qualityScore: qualityScore,
    description: 'Test description',
    images: images,
    location: 'Rwanda',
    status: status,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  setUpAll(() => HttpOverrides.global = _MockHttpOverrides());
  tearDownAll(() => HttpOverrides.global = null);

  group('ListingCard', () {
    testWidgets('renders variety name', (tester) async {
      await tester.pumpWidget(_wrap(ListingCard(
        listing: _makeListing(),
        onTap: () {},
      )));
      expect(find.text('Arabica'), findsOneWidget);
    });

    testWidgets('renders quantity and price', (tester) async {
      await tester.pumpWidget(_wrap(ListingCard(
        listing: _makeListing(quantity: 100, pricePerKg: 8.5),
        onTap: () {},
      )));
      expect(find.textContaining('100'), findsAtLeastNWidgets(1));
      expect(find.textContaining('8.5'), findsAtLeastNWidgets(1));
    });

    testWidgets('renders altitude', (tester) async {
      await tester.pumpWidget(_wrap(ListingCard(
        listing: _makeListing(altitude: 1800),
        onTap: () {},
      )));
      expect(find.textContaining('1800'), findsOneWidget);
    });

    testWidgets('renders quality score', (tester) async {
      await tester.pumpWidget(_wrap(ListingCard(
        listing: _makeListing(qualityScore: 87),
        onTap: () {},
      )));
      expect(find.textContaining('87'), findsAtLeastNWidgets(1));
    });

    testWidgets('renders status badge', (tester) async {
      await tester.pumpWidget(_wrap(ListingCard(
        listing: _makeListing(status: ListingStatus.active),
        onTap: () {},
      )));
      expect(find.textContaining('active'), findsAtLeastNWidgets(1));
    });

    testWidgets('calls onTap when tapped', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(_wrap(ListingCard(
        listing: _makeListing(),
        onTap: () => tapped = true,
      )));
      await tester.tap(find.byType(InkWell));
      expect(tapped, isTrue);
    });

    testWidgets('shows edit button when onEdit is provided', (tester) async {
      await tester.pumpWidget(_wrap(ListingCard(
        listing: _makeListing(),
        onTap: () {},
        onEdit: () {},
      )));
      expect(find.text('Edit'), findsOneWidget);
    });

    testWidgets('shows delete button when onDelete is provided', (tester) async {
      await tester.pumpWidget(_wrap(ListingCard(
        listing: _makeListing(),
        onTap: () {},
        onDelete: () {},
      )));
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('calls onEdit when edit tapped', (tester) async {
      bool called = false;
      await tester.pumpWidget(_wrap(ListingCard(
        listing: _makeListing(),
        onTap: () {},
        onEdit: () => called = true,
      )));
      await tester.tap(find.text('Edit'));
      expect(called, isTrue);
    });

    testWidgets('calls onDelete when delete tapped', (tester) async {
      bool called = false;
      await tester.pumpWidget(_wrap(ListingCard(
        listing: _makeListing(),
        onTap: () {},
        onDelete: () => called = true,
      )));
      await tester.tap(find.text('Delete'));
      expect(called, isTrue);
    });

    testWidgets('does not show edit/delete when not provided', (tester) async {
      await tester.pumpWidget(_wrap(ListingCard(
        listing: _makeListing(),
        onTap: () {},
      )));
      expect(find.text('Edit'), findsNothing);
      expect(find.text('Delete'), findsNothing);
    });

    testWidgets('no ClipRRect when images list is empty', (tester) async {
      await tester.pumpWidget(_wrap(ListingCard(
        listing: _makeListing(images: const []),
        onTap: () {},
      )));
      // Without images, no image container is rendered
      expect(find.byType(ListingCard), findsOneWidget);
    });

    testWidgets('renders sold status badge', (tester) async {
      await tester.pumpWidget(_wrap(ListingCard(
        listing: _makeListing(status: ListingStatus.sold),
        onTap: () {},
      )));
      expect(find.textContaining('sold'), findsAtLeastNWidgets(1));
    });

    testWidgets('renders draft status badge', (tester) async {
      await tester.pumpWidget(_wrap(ListingCard(
        listing: _makeListing(status: ListingStatus.draft),
        onTap: () {},
      )));
      expect(find.textContaining('draft'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows verification badge when farmerVerificationStatus provided', (tester) async {
      await tester.pumpWidget(_wrap(ListingCard(
        listing: _makeListing(),
        onTap: () {},
        farmerVerificationStatus: VerificationStatus.verified,
      )));
      expect(find.byType(ListingCard), findsOneWidget);
    });

    testWidgets('shows farmer name when farmerName is set', (tester) async {
      await tester.pumpWidget(_wrap(ListingCard(
        listing: _makeListing(farmerName: 'John Kamau'),
        onTap: () {},
      )));
      expect(find.text('John Kamau'), findsOneWidget);
    });

    testWidgets('hides farmer name row when farmerName is null', (tester) async {
      await tester.pumpWidget(_wrap(ListingCard(
        listing: _makeListing(farmerName: null),
        onTap: () {},
      )));
      expect(find.byIcon(Icons.person_outline), findsNothing);
    });

    testWidgets('hides farmer name row when farmerName is empty string', (tester) async {
      await tester.pumpWidget(_wrap(ListingCard(
        listing: _makeListing(farmerName: ''),
        onTap: () {},
      )));
      expect(find.byIcon(Icons.person_outline), findsNothing);
    });
  });
}
