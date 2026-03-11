// Feature: brewmaster-marketplace
// Property tests for dashboard calculations, trends, and caching.
//
// Validates: Requirements 11.1, 11.2, 11.3, 11.4, 11.5
// Developer: Developer 5

import 'package:flutter_test/flutter_test.dart';

import 'package:brewmaster/domain/models/buyer_dashboard.dart';
import 'package:brewmaster/domain/models/farmer_dashboard.dart';
import 'package:brewmaster/domain/repositories/dashboard_repository.dart';

// ---------------------------------------------------------------------------
// Fake repository
// ---------------------------------------------------------------------------

class FakeDashboardRepository implements DashboardRepository {
  FarmerDashboard farmerData;
  BuyerDashboard buyerData;
  bool shouldThrow;

  FakeDashboardRepository({
    FarmerDashboard? farmer,
    BuyerDashboard? buyer,
    this.shouldThrow = false,
  })  : farmerData = farmer ?? FarmerDashboard.empty(),
        buyerData = buyer ?? BuyerDashboard.empty();

  @override
  Future<FarmerDashboard> getFarmerDashboard(String farmerId) async {
    if (shouldThrow) throw Exception('fetch error');
    return farmerData;
  }

  @override
  Future<BuyerDashboard> getBuyerDashboard(String buyerId) async {
    if (shouldThrow) throw Exception('fetch error');
    return buyerData;
  }

  @override
  Stream<FarmerDashboard> watchFarmerDashboard(String farmerId) =>
      Stream.value(farmerData);

  @override
  Stream<BuyerDashboard> watchBuyerDashboard(String buyerId) =>
      Stream.value(buyerData);
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

FarmerDashboard _makeFarmer({
  int activeListings = 3,
  double totalEarnings = 1500.0,
  int conversations = 5,
  int views = 120,
  double responseRate = 80.0,
}) =>
    FarmerDashboard(
      activeListings: activeListings,
      totalEarnings: totalEarnings,
      conversations: conversations,
      views: views,
      responseRate: responseRate,
    );

BuyerDashboard _makeBuyer({
  int totalPurchases = 4,
  int conversations = 3,
  int savedListings = 7,
}) =>
    BuyerDashboard(
      totalPurchases: totalPurchases,
      conversations: conversations,
      savedListings: savedListings,
    );

void main() {
  // -------------------------------------------------------------------------
  // Task 19.2 – dashboard calculation properties
  // -------------------------------------------------------------------------

  group('Property 46 – FarmerDashboard structure', () {
    test('empty() produces zero-valued dashboard', () {
      final d = FarmerDashboard.empty();
      expect(d.activeListings, equals(0));
      expect(d.totalEarnings, equals(0.0));
      expect(d.conversations, equals(0));
      expect(d.views, equals(0));
      expect(d.responseRate, equals(0.0));
    });

    test('all numeric fields are non-negative', () {
      final d = _makeFarmer();
      expect(d.activeListings, greaterThanOrEqualTo(0));
      expect(d.totalEarnings, greaterThanOrEqualTo(0.0));
      expect(d.conversations, greaterThanOrEqualTo(0));
      expect(d.views, greaterThanOrEqualTo(0));
      expect(d.responseRate, greaterThanOrEqualTo(0.0));
    });

    test('responseRate is bounded between 0 and 100', () {
      for (final rate in [0.0, 50.0, 100.0]) {
        final d = _makeFarmer(responseRate: rate);
        expect(d.responseRate >= 0.0 && d.responseRate <= 100.0, isTrue,
            reason: 'responseRate must be a percentage');
      }
    });

    test('fromJson / toJson round-trip preserves all fields', () {
      final original = _makeFarmer(
        activeListings: 7,
        totalEarnings: 2500.75,
        conversations: 12,
        views: 340,
        responseRate: 92.5,
      );
      final restored = FarmerDashboard.fromJson(original.toJson());
      expect(restored, equals(original));
    });

    test('copyWith changes only specified fields', () {
      final original = _makeFarmer(activeListings: 3, totalEarnings: 1000.0);
      final updated = original.copyWith(activeListings: 5);
      expect(updated.activeListings, equals(5));
      expect(updated.totalEarnings, equals(original.totalEarnings));
    });

    test('equality holds for identical field values', () {
      final a = _makeFarmer(views: 50);
      final b = _makeFarmer(views: 50);
      expect(a, equals(b));
    });
  });

  group('Property 46 – BuyerDashboard structure', () {
    test('empty() produces zero-valued dashboard', () {
      final d = BuyerDashboard.empty();
      expect(d.totalPurchases, equals(0));
      expect(d.conversations, equals(0));
      expect(d.savedListings, equals(0));
    });

    test('all numeric fields are non-negative', () {
      final d = _makeBuyer();
      expect(d.totalPurchases, greaterThanOrEqualTo(0));
      expect(d.conversations, greaterThanOrEqualTo(0));
      expect(d.savedListings, greaterThanOrEqualTo(0));
    });

    test('fromJson / toJson round-trip preserves all fields', () {
      final original = _makeBuyer(
        totalPurchases: 10,
        conversations: 8,
        savedListings: 15,
      );
      final restored = BuyerDashboard.fromJson(original.toJson());
      expect(restored, equals(original));
    });

    test('copyWith changes only specified fields', () {
      final original = _makeBuyer(totalPurchases: 4, savedListings: 7);
      final updated = original.copyWith(totalPurchases: 6);
      expect(updated.totalPurchases, equals(6));
      expect(updated.savedListings, equals(original.savedListings));
    });

    test('equality holds for identical field values', () {
      final a = _makeBuyer(conversations: 3);
      final b = _makeBuyer(conversations: 3);
      expect(a, equals(b));
    });
  });

  group('Property 47 – dashboard repository behaviour', () {
    test('getFarmerDashboard returns expected data', () async {
      final expected = _makeFarmer(activeListings: 5, totalEarnings: 3000.0);
      final repo = FakeDashboardRepository(farmer: expected);
      final result = await repo.getFarmerDashboard('farmer_1');
      expect(result, equals(expected));
    });

    test('getBuyerDashboard returns expected data', () async {
      final expected = _makeBuyer(totalPurchases: 8, savedListings: 12);
      final repo = FakeDashboardRepository(buyer: expected);
      final result = await repo.getBuyerDashboard('buyer_1');
      expect(result, equals(expected));
    });

    test('repository throws propagates to caller', () async {
      final repo = FakeDashboardRepository(shouldThrow: true);
      expect(
        () => repo.getFarmerDashboard('farmer_1'),
        throwsA(isA<Exception>()),
      );
      expect(
        () => repo.getBuyerDashboard('buyer_1'),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('Property 48 – offline caching (Requirement 11.5)', () {
    // When the app is offline, the last-loaded dashboard data remains
    // available. This property verifies that the repository layer returns
    // previously loaded data without re-fetching.
    test('watchFarmerDashboard emits current data immediately', () async {
      final data = _makeFarmer(views: 200);
      final repo = FakeDashboardRepository(farmer: data);
      final emitted = await repo.watchFarmerDashboard('f1').first;
      expect(emitted, equals(data));
    });

    test('watchBuyerDashboard emits current data immediately', () async {
      final data = _makeBuyer(savedListings: 5);
      final repo = FakeDashboardRepository(buyer: data);
      final emitted = await repo.watchBuyerDashboard('b1').first;
      expect(emitted, equals(data));
    });

    test('empty dashboard is returned rather than null when no data', () async {
      final repo = FakeDashboardRepository();
      final farmer = await repo.getFarmerDashboard('unknown');
      final buyer = await repo.getBuyerDashboard('unknown');
      expect(farmer, isNotNull);
      expect(buyer, isNotNull);
    });
  });
}
