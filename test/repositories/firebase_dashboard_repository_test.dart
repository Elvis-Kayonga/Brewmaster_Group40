// Tests for FirebaseDashboardRepository.
// Uses FakeFirebaseFirestore to verify aggregation logic without real Firebase.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:brewmaster/data/repositories/firebase_dashboard_repository.dart';
import 'package:brewmaster/domain/models/farmer_dashboard.dart';
import 'package:brewmaster/domain/models/buyer_dashboard.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    setupFirebaseCoreMocks();
    await Firebase.initializeApp();
  });

  group('FirebaseDashboardRepository', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FirebaseDashboardRepository repo;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      repo = FirebaseDashboardRepository(firestore: fakeFirestore);
    });

    // -------------------------------------------------------------------------
    // getFarmerDashboard
    // -------------------------------------------------------------------------

    group('getFarmerDashboard', () {
      test('returns zero metrics when no data exists for farmer', () async {
        final dashboard = await repo.getFarmerDashboard('farmer-empty');

        expect(dashboard.activeListings, equals(0));
        expect(dashboard.totalEarnings, equals(0.0));
        expect(dashboard.conversations, equals(0));
        expect(dashboard.savedCount, equals(0));
        expect(dashboard.responseRate, equals(0.0));
      });

      test('counts active listings correctly', () async {
        const farmerId = 'farmer-1';
        await fakeFirestore.collection('listings').add({
          'farmerId': farmerId,
          'status': 'active',
          'viewCount': 10,
        });
        await fakeFirestore.collection('listings').add({
          'farmerId': farmerId,
          'status': 'active',
          'viewCount': 5,
        });
        await fakeFirestore.collection('listings').add({
          'farmerId': farmerId,
          'status': 'sold',
          'viewCount': 3,
        });

        final dashboard = await repo.getFarmerDashboard(farmerId);

        expect(dashboard.activeListings, equals(2));
      });

      test('counts users who have saved any of the farmer\'s listings', () async {
        const farmerId = 'farmer-views';
        final listingRef1 = await fakeFirestore.collection('listings').add({
          'farmerId': farmerId,
          'status': 'active',
        });
        final listingRef2 = await fakeFirestore.collection('listings').add({
          'farmerId': farmerId,
          'status': 'sold',
        });
        // buyer-A saved both listings (counts as 2), buyer-B saved one (counts as 1)
        await fakeFirestore.collection('users').add({
          'savedListings': [listingRef1.id, listingRef2.id],
        });
        await fakeFirestore.collection('users').add({
          'savedListings': [listingRef2.id],
        });

        final dashboard = await repo.getFarmerDashboard(farmerId);

        expect(dashboard.savedCount, equals(3));
      });

      test('sums total earnings from completed transactions', () async {
        const farmerId = 'farmer-earnings';
        final now = Timestamp.fromDate(DateTime.now());
        await fakeFirestore.collection('transactions').add({
          'farmerId': farmerId,
          'status': 'completed',
          'amount': 150.0,
          'createdAt': now,
        });
        await fakeFirestore.collection('transactions').add({
          'farmerId': farmerId,
          'status': 'completed',
          'amount': 75.5,
          'createdAt': now,
        });
        // pending — should not be counted
        await fakeFirestore.collection('transactions').add({
          'farmerId': farmerId,
          'status': 'pending',
          'amount': 999.0,
          'createdAt': now,
        });

        final dashboard = await repo.getFarmerDashboard(farmerId);

        expect(dashboard.totalEarnings, closeTo(225.5, 0.01));
      });

      test('counts conversations the farmer participates in', () async {
        const farmerId = 'farmer-convos';
        await fakeFirestore.collection('conversations').add({
          'participantIds': [farmerId, 'buyer-1'],
          'unreadCount': 0,
        });
        await fakeFirestore.collection('conversations').add({
          'participantIds': [farmerId, 'buyer-2'],
          'unreadCount': 1,
        });

        final dashboard = await repo.getFarmerDashboard(farmerId);

        expect(dashboard.conversations, equals(2));
      });

      test('calculates 100% response rate when all conversations have unreadCount=0',
          () async {
        const farmerId = 'farmer-rate';
        await fakeFirestore.collection('conversations').add({
          'participantIds': [farmerId, 'buyer-x'],
          'unreadCount': 0,
        });
        await fakeFirestore.collection('conversations').add({
          'participantIds': [farmerId, 'buyer-y'],
          'unreadCount': 0,
        });

        final dashboard = await repo.getFarmerDashboard(farmerId);

        expect(dashboard.responseRate, closeTo(100.0, 0.01));
      });

      test('calculates partial response rate correctly', () async {
        const farmerId = 'farmer-partial';
        await fakeFirestore.collection('conversations').add({
          'participantIds': [farmerId, 'buyer-a'],
          'unreadCount': 0, // responded
        });
        await fakeFirestore.collection('conversations').add({
          'participantIds': [farmerId, 'buyer-b'],
          'unreadCount': 2, // not responded
        });

        final dashboard = await repo.getFarmerDashboard(farmerId);

        // 1 of 2 responded = 50%
        expect(dashboard.responseRate, closeTo(50.0, 0.01));
      });

      test('dailyRevenue list has exactly 7 elements', () async {
        final dashboard = await repo.getFarmerDashboard('farmer-x');
        expect(dashboard.dailyRevenue.length, equals(7));
      });

      test('revenueChangePct is null when no transactions exist', () async {
        final dashboard = await repo.getFarmerDashboard('farmer-no-tx');
        expect(dashboard.revenueChangePct, isNull);
      });

      test('revenueChangePct is 100 when there were no previous-period sales',
          () async {
        const farmerId = 'farmer-first-sales';
        // Transaction within the current 30-day window only.
        final now = Timestamp.fromDate(DateTime.now());
        await fakeFirestore.collection('transactions').add({
          'farmerId': farmerId,
          'status': 'completed',
          'amount': 200.0,
          'createdAt': now,
        });

        final dashboard = await repo.getFarmerDashboard(farmerId);

        expect(dashboard.revenueChangePct, closeTo(100.0, 0.01));
      });

      test('returns FarmerDashboard instance', () async {
        final dashboard = await repo.getFarmerDashboard('any-farmer');
        expect(dashboard, isA<FarmerDashboard>());
      });
    });

    // -------------------------------------------------------------------------
    // watchFarmerDashboard
    // -------------------------------------------------------------------------

    group('watchFarmerDashboard', () {
      test('emits a FarmerDashboard from the stream', () async {
        const farmerId = 'farmer-watch';
        await fakeFirestore.collection('listings').add({
          'farmerId': farmerId,
          'status': 'active',
          'viewCount': 0,
        });

        final dashboard =
            await repo.watchFarmerDashboard(farmerId).first;

        expect(dashboard, isA<FarmerDashboard>());
        expect(dashboard.activeListings, equals(1));
      });
    });

    // -------------------------------------------------------------------------
    // getBuyerDashboard
    // -------------------------------------------------------------------------

    group('getBuyerDashboard', () {
      test('returns zero metrics when no data exists for buyer', () async {
        const buyerId = 'buyer-empty';
        // Ensure user doc exists (even without savedListings)
        await fakeFirestore.collection('users').doc(buyerId).set({});

        final dashboard = await repo.getBuyerDashboard(buyerId);

        expect(dashboard.totalPurchases, equals(0));
        expect(dashboard.conversations, equals(0));
        expect(dashboard.savedListings, equals(0));
      });

      test('counts completed transactions as purchases', () async {
        const buyerId = 'buyer-purchases';
        await fakeFirestore.collection('users').doc(buyerId).set({});
        await fakeFirestore.collection('transactions').add({
          'buyerId': buyerId,
          'status': 'completed',
        });
        await fakeFirestore.collection('transactions').add({
          'buyerId': buyerId,
          'status': 'completed',
        });
        await fakeFirestore.collection('transactions').add({
          'buyerId': buyerId,
          'status': 'pending',
        });

        final dashboard = await repo.getBuyerDashboard(buyerId);

        expect(dashboard.totalPurchases, equals(2));
      });

      test('counts conversations buyer participates in', () async {
        const buyerId = 'buyer-convos';
        await fakeFirestore.collection('users').doc(buyerId).set({});
        await fakeFirestore.collection('conversations').add({
          'participantIds': [buyerId, 'farmer-1'],
        });

        final dashboard = await repo.getBuyerDashboard(buyerId);

        expect(dashboard.conversations, equals(1));
      });

      test('reads savedListings count from user profile', () async {
        const buyerId = 'buyer-saved';
        await fakeFirestore.collection('users').doc(buyerId).set({
          'savedListings': ['l1', 'l2', 'l3'],
        });

        final dashboard = await repo.getBuyerDashboard(buyerId);

        expect(dashboard.savedListings, equals(3));
      });

      test('returns BuyerDashboard instance', () async {
        const buyerId = 'buyer-type';
        await fakeFirestore.collection('users').doc(buyerId).set({});

        final dashboard = await repo.getBuyerDashboard(buyerId);

        expect(dashboard, isA<BuyerDashboard>());
      });
    });

    // -------------------------------------------------------------------------
    // watchBuyerDashboard
    // -------------------------------------------------------------------------

    group('watchBuyerDashboard', () {
      test('emits a BuyerDashboard from the stream', () async {
        const buyerId = 'buyer-watch';
        await fakeFirestore.collection('users').doc(buyerId).set({});
        await fakeFirestore.collection('transactions').add({
          'buyerId': buyerId,
          'status': 'completed',
        });

        final dashboard =
            await repo.watchBuyerDashboard(buyerId).first;

        expect(dashboard, isA<BuyerDashboard>());
        expect(dashboard.totalPurchases, equals(1));
      });
    });
  });
}
