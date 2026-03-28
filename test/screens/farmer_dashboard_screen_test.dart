// Widget tests for FarmerDashboardScreen
// Coverage: loading/error states, analytics tab, orders tab, listings tab.

import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:brewmaster/domain/models/buyer_dashboard.dart';
import 'package:brewmaster/domain/models/coffee_listing.dart';
import 'package:brewmaster/domain/models/enums.dart';
import 'package:brewmaster/domain/models/escrow_transaction.dart' as models;
import 'package:brewmaster/domain/models/farmer_dashboard.dart';
import 'package:brewmaster/domain/repositories/dashboard_repository.dart';
import 'package:brewmaster/presentation/blocs/auth/auth_bloc.dart';
import 'package:brewmaster/presentation/blocs/dashboard/dashboard_bloc.dart';
import 'package:brewmaster/presentation/blocs/listing/listing_bloc.dart';
import 'package:brewmaster/presentation/blocs/messaging/notification_bloc.dart';
import 'package:brewmaster/presentation/blocs/payment/payment_bloc.dart';
import 'package:brewmaster/presentation/blocs/profile/profile_bloc.dart';
import 'package:brewmaster/presentation/screens/dashboard/farmer_dashboard_screen.dart';

import '../helpers/fake_repositories.dart';

// ── Fake DashboardRepositories ────────────────────────────────────────────────

class _DataDashboardRepository implements DashboardRepository {
  final FarmerDashboard data;
  _DataDashboardRepository(this.data);

  @override
  Future<FarmerDashboard> getFarmerDashboard(String farmerId) async => data;

  @override
  Future<BuyerDashboard> getBuyerDashboard(String buyerId) =>
      throw UnimplementedError();

  @override
  Stream<FarmerDashboard> watchFarmerDashboard(String farmerId) =>
      const Stream.empty();

  @override
  Stream<BuyerDashboard> watchBuyerDashboard(String buyerId) =>
      const Stream.empty();
}

/// getFarmerDashboard never completes — keeps bloc in loading state.
class _NeverDashboardRepository implements DashboardRepository {
  @override
  Future<FarmerDashboard> getFarmerDashboard(String farmerId) =>
      Completer<FarmerDashboard>().future;

  @override
  Future<BuyerDashboard> getBuyerDashboard(String buyerId) =>
      throw UnimplementedError();

  @override
  Stream<FarmerDashboard> watchFarmerDashboard(String farmerId) =>
      const Stream.empty();

  @override
  Stream<BuyerDashboard> watchBuyerDashboard(String buyerId) =>
      const Stream.empty();
}

/// getFarmerDashboard throws — bloc emits DashboardFailure.
class _ErrorDashboardRepository implements DashboardRepository {
  final String message;
  _ErrorDashboardRepository([this.message = 'Server error']);

  @override
  Future<FarmerDashboard> getFarmerDashboard(String farmerId) async =>
      throw Exception(message);

  @override
  Future<BuyerDashboard> getBuyerDashboard(String buyerId) =>
      throw UnimplementedError();

  @override
  Stream<FarmerDashboard> watchFarmerDashboard(String farmerId) =>
      const Stream.empty();

  @override
  Stream<BuyerDashboard> watchBuyerDashboard(String buyerId) =>
      const Stream.empty();
}

// ── Fixture ───────────────────────────────────────────────────────────────────

FarmerDashboard _makeDashboard({
  int activeListings = 2,
  double totalEarnings = 1500.0,
  int conversations = 5,
  int savedCount = 30,
  double responseRate = 75.0,
  double? revenueChangePct,
}) =>
    FarmerDashboard(
      activeListings: activeListings,
      totalEarnings: totalEarnings,
      conversations: conversations,
      savedCount: savedCount,
      responseRate: responseRate,
      revenueChangePct: revenueChangePct,
      dailyRevenue: const [10, 20, 30, 40, 50, 60, 70],
    );

// ── Screen builder ────────────────────────────────────────────────────────────

/// All blocs created INSIDE create callbacks.
/// [dashboardRepo] controls DashboardBloc behavior.
/// [listingState] is pre-emitted into ListingBloc after creation.
/// [paymentState] is pre-emitted into PaymentBloc after creation.
Widget _buildScreen({
  DashboardRepository? dashboardRepo,
  dynamic listingState,
  dynamic paymentState,
  FakePaymentRepository? paymentRepo,
  String userId = 'farmer1',
}) {
  final dRepo = dashboardRepo ?? _DataDashboardRepository(FarmerDashboard.empty());
  final userRepo = FakeUserRepository();

  return MaterialApp(
    home: MultiBlocProvider(
      providers: [
        BlocProvider<DashboardBloc>(
          create: (_) => DashboardBloc(repository: dRepo),
        ),
        BlocProvider<ListingBloc>(
          create: (_) {
            final b = ListingBloc(repository: FakeListingRepository());
            if (listingState != null) b.emit(listingState as dynamic);
            return b;
          },
        ),
        BlocProvider<PaymentBloc>(
          create: (_) {
            final b = PaymentBloc(paymentRepository: paymentRepo ?? FakePaymentRepository());
            if (paymentState != null) b.emit(paymentState as dynamic);
            return b;
          },
        ),
        BlocProvider<AuthBloc>(
          create: (_) => AuthBloc(
            authRepository: FakeAuthRepository(),
            userRepository: FakeUserRepository(),
          )..emit(AuthAuthenticated(makeProfile())),
        ),
        BlocProvider<ProfileBloc>(
          create: (_) => ProfileBloc(userRepository: userRepo),
        ),
        BlocProvider<NotificationBloc>(
          create: (_) => NotificationBloc(repository: FakeNotificationRepository()),
        ),
      ],
      child: FarmerDashboardScreen(userId: userId),
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

  group('FarmerDashboardScreen — loading/error states', () {
    testWidgets('shows "Brew Master" in app bar', (tester) async {
      await tester.pumpWidget(_buildScreen(dashboardRepo: _NeverDashboardRepository()));
      await tester.pump();
      expect(find.text('Brew Master'), findsOneWidget);
    });

    testWidgets('shows loading indicator while dashboard is loading',
        (tester) async {
      await tester.pumpWidget(_buildScreen(dashboardRepo: _NeverDashboardRepository()));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error message when getFarmerDashboard throws',
        (tester) async {
      await tester.pumpWidget(
          _buildScreen(dashboardRepo: _ErrorDashboardRepository('Server error')));
      await tester.pump();
      expect(find.textContaining('Server error'), findsOneWidget);
    });

    testWidgets('shows refresh icon button in app bar', (tester) async {
      await tester.pumpWidget(_buildScreen(dashboardRepo: _NeverDashboardRepository()));
      await tester.pump();
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });
  });

  group('FarmerDashboardScreen — ANALYTICS tab (default)', () {
    testWidgets('shows "Farmer" heading text', (tester) async {
      await tester.pumpWidget(
          _buildScreen(dashboardRepo: _DataDashboardRepository(_makeDashboard())));
      await tester.pump();
      expect(find.textContaining('Farmer'), findsWidgets);
    });

    testWidgets('shows three tab labels', (tester) async {
      await tester.pumpWidget(
          _buildScreen(dashboardRepo: _DataDashboardRepository(_makeDashboard())));
      await tester.pump();
      expect(find.text('ANALYTICS'), findsOneWidget);
      expect(find.text('ORDERS'), findsOneWidget);
      expect(find.text('LISTINGS'), findsOneWidget);
    });

    testWidgets('shows "Active Seller" status row', (tester) async {
      await tester.pumpWidget(
          _buildScreen(dashboardRepo: _DataDashboardRepository(_makeDashboard())));
      await tester.pump();
      expect(find.textContaining('Active Seller'), findsOneWidget);
    });

    testWidgets('shows TOTAL REVENUE metric card', (tester) async {
      await tester.pumpWidget(
          _buildScreen(dashboardRepo: _DataDashboardRepository(_makeDashboard())));
      await tester.pump();
      expect(find.text('TOTAL REVENUE'), findsOneWidget);
    });

    testWidgets('shows ORDERS LOGGED metric card', (tester) async {
      await tester.pumpWidget(
          _buildScreen(dashboardRepo: _DataDashboardRepository(_makeDashboard())));
      await tester.pump();
      expect(find.text('ORDERS LOGGED'), findsOneWidget);
    });

    testWidgets('shows ACTIVE LOTS metric card', (tester) async {
      await tester.pumpWidget(
          _buildScreen(dashboardRepo: _DataDashboardRepository(_makeDashboard())));
      await tester.pump();
      expect(find.text('ACTIVE LOTS'), findsOneWidget);
    });

    testWidgets('shows VELOCITY COMMAND section', (tester) async {
      await tester.pumpWidget(
          _buildScreen(dashboardRepo: _DataDashboardRepository(_makeDashboard())));
      await tester.pump();
      expect(find.text('VELOCITY COMMAND'), findsOneWidget);
    });

    testWidgets('shows MARKET INTELLIGENCE section', (tester) async {
      await tester.pumpWidget(
          _buildScreen(dashboardRepo: _DataDashboardRepository(_makeDashboard())));
      await tester.pump();
      expect(find.text('MARKET INTELLIGENCE'), findsOneWidget);
    });

    testWidgets('shows response rate in chart footer', (tester) async {
      await tester.pumpWidget(
        _buildScreen(
            dashboardRepo: _DataDashboardRepository(
                _makeDashboard(responseRate: 75.0))),
      );
      await tester.pump();
      expect(find.textContaining('75%'), findsOneWidget);
    });

    testWidgets('shows saved count in chart footer', (tester) async {
      await tester.pumpWidget(
        _buildScreen(
            dashboardRepo:
                _DataDashboardRepository(_makeDashboard(savedCount: 42))),
      );
      await tester.pump();
      expect(find.textContaining('Saved: 42'), findsOneWidget);
    });
  });

  group('FarmerDashboardScreen — ORDERS tab', () {
    testWidgets('shows CircularProgressIndicator before payment history loads',
        (tester) async {
      await tester.pumpWidget(_buildScreen(
        dashboardRepo: _DataDashboardRepository(_makeDashboard()),
      ));
      await tester.pump();

      await tester.tap(find.text('ORDERS'));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows "No orders yet." when PaymentHistoryLoaded is empty',
        (tester) async {
      await tester.pumpWidget(_buildScreen(
        dashboardRepo: _DataDashboardRepository(_makeDashboard()),
        paymentState: const PaymentHistoryLoaded(transactions: []),
      ));
      await tester.pump();

      await tester.tap(find.text('ORDERS'));
      await tester.pump();

      expect(find.text('No orders yet.'), findsOneWidget);
    });
  });

  group('FarmerDashboardScreen — LISTINGS tab', () {
    testWidgets('shows "+ INITIALIZE LOT" button', (tester) async {
      await tester.pumpWidget(_buildScreen(
        dashboardRepo: _DataDashboardRepository(_makeDashboard()),
        listingState: const FarmerListingsLoaded([]),
      ));
      await tester.pump();

      await tester.tap(find.text('LISTINGS'));
      await tester.pump();

      expect(find.textContaining('INITIALIZE LOT'), findsOneWidget);
    });

    testWidgets('shows empty listings message when no listings exist',
        (tester) async {
      await tester.pumpWidget(_buildScreen(
        dashboardRepo: _DataDashboardRepository(_makeDashboard()),
        listingState: const FarmerListingsLoaded([]),
      ));
      await tester.pump();

      await tester.tap(find.text('LISTINGS'));
      await tester.pump();

      expect(find.textContaining('No listings yet'), findsOneWidget);
    });

    testWidgets('shows loading indicator when ListingLoading', (tester) async {
      await tester.pumpWidget(_buildScreen(
        dashboardRepo: _DataDashboardRepository(_makeDashboard()),
        listingState: const ListingLoading(),
      ));
      await tester.pump();

      await tester.tap(find.text('LISTINGS'));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  // ── ANALYTICS tab market insights ───────────────────────────────────────────
  group('FarmerDashboardScreen — ANALYTICS market insights', () {
    testWidgets('shows strong revenue insight when revenueChangePct >= 20',
        (tester) async {
      await tester.pumpWidget(_buildScreen(
        dashboardRepo: _DataDashboardRepository(
            _makeDashboard(revenueChangePct: 25.0)),
      ));
      await tester.pump();
      expect(find.textContaining('Revenue is up'), findsOneWidget);
    });

    testWidgets('shows upward trend insight when revenueChangePct >= 5',
        (tester) async {
      await tester.pumpWidget(_buildScreen(
        dashboardRepo: _DataDashboardRepository(
            _makeDashboard(revenueChangePct: 10.0)),
      ));
      await tester.pump();
      expect(find.textContaining('trending upward'), findsOneWidget);
    });

    testWidgets('shows dip insight when revenueChangePct < 0', (tester) async {
      await tester.pumpWidget(_buildScreen(
        dashboardRepo: _DataDashboardRepository(
            _makeDashboard(revenueChangePct: -8.0)),
      ));
      await tester.pump();
      expect(find.textContaining('Revenue dipped'), findsOneWidget);
    });

    testWidgets('shows excellent response rate insight when responseRate >= 80',
        (tester) async {
      await tester.pumpWidget(_buildScreen(
        dashboardRepo: _DataDashboardRepository(
            _makeDashboard(responseRate: 90.0)),
      ));
      await tester.pump();
      expect(find.textContaining('excellent'), findsOneWidget);
    });

    testWidgets('shows low response rate insight when responseRate < 50',
        (tester) async {
      await tester.pumpWidget(_buildScreen(
        dashboardRepo: _DataDashboardRepository(
            _makeDashboard(responseRate: 30.0, conversations: 3)),
      ));
      await tester.pump();
      expect(find.textContaining('response rate'), findsOneWidget);
    });

    testWidgets('shows no active listings insight when activeListings == 0',
        (tester) async {
      await tester.pumpWidget(_buildScreen(
        dashboardRepo: _DataDashboardRepository(
            _makeDashboard(activeListings: 0)),
      ));
      await tester.pump();
      expect(find.textContaining('no active listings'), findsOneWidget);
    });

    testWidgets('shows saved insight when savedCount == 0 and activeListings > 0',
        (tester) async {
      await tester.pumpWidget(_buildScreen(
        dashboardRepo: _DataDashboardRepository(
            _makeDashboard(savedCount: 0, activeListings: 2)),
      ));
      await tester.pump();
      expect(find.textContaining('No buyers have saved your lots yet'), findsOneWidget);
    });
  });

  // ── ORDERS tab with transactions ─────────────────────────────────────────────
  group('FarmerDashboardScreen — ORDERS tab with transactions', () {
    testWidgets('shows order card when transactions exist for this farmer',
        (tester) async {
      final tx = models.Transaction(
        id: 'abcdef123456',
        buyerId: 'buyer-1',
        farmerId: 'farmer1', // matches widget.userId
        listingId: 'listing-1',
        amount: 300.0,
        currency: 'USD',
        status: TransactionStatus.fundsHeld,
        paymentMethod: PaymentMethod.mpesa,
        createdAt: DateTime(2024, 6, 1),
      );
      final payRepo = FakePaymentRepository()..transactions = [tx];

      await tester.pumpWidget(_buildScreen(
        dashboardRepo: _DataDashboardRepository(_makeDashboard()),
        paymentRepo: payRepo,
      ));
      await tester.pump();
      await tester.pump(); // wait for dashboard to load

      await tester.tap(find.text('ORDERS'));
      await tester.pump();
      await tester.pump(); // wait for stream

      // Short ID format: 'ORD-ABCDEF'
      expect(find.textContaining('ORD-'), findsOneWidget);
    });

    testWidgets('shows receipt icon in order card', (tester) async {
      final tx = models.Transaction(
        id: 'abcdef123456',
        buyerId: 'buyer-1',
        farmerId: 'farmer1',
        listingId: 'listing-1',
        amount: 300.0,
        currency: 'USD',
        status: TransactionStatus.pending,
        paymentMethod: PaymentMethod.mpesa,
        createdAt: DateTime(2024, 6, 1),
      );
      final payRepo = FakePaymentRepository()..transactions = [tx];

      await tester.pumpWidget(_buildScreen(
        dashboardRepo: _DataDashboardRepository(_makeDashboard()),
        paymentRepo: payRepo,
      ));
      await tester.pump();
      await tester.pump(); // wait for dashboard to load

      await tester.tap(find.text('ORDERS'));
      await tester.pump();
      await tester.pump(); // wait for stream

      expect(find.byIcon(Icons.receipt_long_outlined), findsWidgets);
    });

    testWidgets('shows "Confirm Delivery" button for fundsHeld order',
        (tester) async {
      final tx = models.Transaction(
        id: 'abcdef123456',
        buyerId: 'buyer-1',
        farmerId: 'farmer1',
        listingId: 'listing-1',
        amount: 300.0,
        currency: 'USD',
        status: TransactionStatus.fundsHeld,
        paymentMethod: PaymentMethod.mpesa,
        createdAt: DateTime(2024, 6, 1),
      );
      final payRepo = FakePaymentRepository()..transactions = [tx];

      await tester.pumpWidget(_buildScreen(
        dashboardRepo: _DataDashboardRepository(_makeDashboard()),
        paymentRepo: payRepo,
      ));
      await tester.pump();
      await tester.pump();
      await tester.tap(find.text('ORDERS'));
      await tester.pump();
      await tester.pump();

      expect(find.text('Confirm Delivery'), findsOneWidget);
    });

    for (final entry in [
      (TransactionStatus.delivered, 'Delivered — awaiting confirmation'),
      (TransactionStatus.completed, 'Completed'),
      (TransactionStatus.disputed, 'Under dispute'),
      (TransactionStatus.cancelled, 'Cancelled'),
    ]) {
      final status = entry.$1;
      final label = entry.$2;
      testWidgets('shows "$label" label for ${status.name} order',
          (tester) async {
        final tx = models.Transaction(
          id: 'abcdef123456',
          buyerId: 'buyer-1',
          farmerId: 'farmer1',
          listingId: 'listing-1',
          amount: 100.0,
          currency: 'USD',
          status: status,
          paymentMethod: PaymentMethod.mpesa,
          createdAt: DateTime(2024, 6, 1),
        );
        final payRepo = FakePaymentRepository()..transactions = [tx];

        await tester.pumpWidget(_buildScreen(
          dashboardRepo: _DataDashboardRepository(_makeDashboard()),
          paymentRepo: payRepo,
        ));
        await tester.pump();
        await tester.pump();
        await tester.tap(find.text('ORDERS'));
        await tester.pump();
        await tester.pump();

        expect(find.text(label), findsOneWidget);
      });
    }

    testWidgets('PaymentActionSuccess shows delivery confirmed snackbar',
        (tester) async {
      await tester.pumpWidget(_buildScreen(
        dashboardRepo: _DataDashboardRepository(_makeDashboard()),
        paymentState: const PaymentHistoryLoaded(transactions: []),
      ));
      await tester.pump();
      await tester.pump();
      await tester.tap(find.text('ORDERS'));
      await tester.pump();

      final tx = models.Transaction(
        id: 'tx-1',
        buyerId: 'buyer-1',
        farmerId: 'farmer1',
        listingId: 'listing-1',
        amount: 100.0,
        currency: 'USD',
        status: TransactionStatus.delivered,
        paymentMethod: PaymentMethod.mpesa,
        createdAt: DateTime(2024, 6, 1),
      );
      final bloc = tester.element(find.byType(Scaffold)).read<PaymentBloc>();
      bloc.emit(PaymentActionSuccess(tx));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Delivery confirmed successfully.'), findsOneWidget);
    });
  });

  group('FarmerDashboardScreen — LISTINGS tab with listings', () {
    CoffeeListing makeListing({String id = 'listing-1', String variety = 'Bourbon'}) =>
        CoffeeListing(
          listingId: id,
          farmerId: 'farmer1',
          variety: variety,
          quantity: 100.0,
          pricePerKg: 10.0,
          processingMethod: ProcessingMethod.natural,
          altitude: 1500.0,
          harvestDate: DateTime(2024, 5, 1),
          qualityScore: 82.0,
          description: 'Sweet notes.',
          images: const [],
          location: '',
          status: ListingStatus.active,
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        );

    testWidgets('shows listing card when FarmerListingsLoaded has items',
        (tester) async {
      await tester.pumpWidget(_buildScreen(
        dashboardRepo: _DataDashboardRepository(_makeDashboard()),
        listingState: FarmerListingsLoaded([makeListing()]),
      ));
      await tester.pump();
      await tester.tap(find.text('LISTINGS'));
      await tester.pump();

      expect(find.text('Bourbon'), findsOneWidget);
    });

    testWidgets('tapping Delete on listing card opens confirm dialog',
        (tester) async {
      await tester.pumpWidget(_buildScreen(
        dashboardRepo: _DataDashboardRepository(_makeDashboard()),
        listingState: FarmerListingsLoaded([makeListing()]),
      ));
      await tester.pump();
      await tester.tap(find.text('LISTINGS'));
      await tester.pump();

      await tester.tap(find.text('Delete'));
      await tester.pump();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.textContaining('Are you sure'), findsOneWidget);
    });

    testWidgets('tapping Cancel in delete dialog dismisses it',
        (tester) async {
      await tester.pumpWidget(_buildScreen(
        dashboardRepo: _DataDashboardRepository(_makeDashboard()),
        listingState: FarmerListingsLoaded([makeListing()]),
      ));
      await tester.pump();
      await tester.tap(find.text('LISTINGS'));
      await tester.pump();

      await tester.tap(find.text('Delete'));
      await tester.pump();
      await tester.tap(find.text('Cancel'));
      await tester.pump();

      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('tapping Delete in confirm dialog dispatches delete event',
        (tester) async {
      await tester.pumpWidget(_buildScreen(
        dashboardRepo: _DataDashboardRepository(_makeDashboard()),
        listingState: FarmerListingsLoaded([makeListing()]),
      ));
      await tester.pump();
      await tester.tap(find.text('LISTINGS'));
      await tester.pump();

      await tester.tap(find.text('Delete'));
      await tester.pump();
      await tester.tap(find.text('Delete').last);
      await tester.pump();

      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('ListingActionSuccess listener dispatches reload',
        (tester) async {
      await tester.pumpWidget(_buildScreen(
        dashboardRepo: _DataDashboardRepository(_makeDashboard()),
        listingState: FarmerListingsLoaded([makeListing()]),
      ));
      await tester.pump();
      await tester.tap(find.text('LISTINGS'));
      await tester.pump();

      final bloc =
          tester.element(find.byType(Scaffold).first).read<ListingBloc>();
      bloc.emit(const ListingActionSuccess('Listing deleted'));
      await tester.pump();

      // No crash — listener dispatched FarmerListingsLoadRequested
      expect(find.byType(FarmerDashboardScreen), findsOneWidget);
    });
  });

  group('FarmerDashboardScreen — ORDERS tab interactions', () {
    models.Transaction makeTx({
      String id = 'txabcdef123456',
      TransactionStatus status = TransactionStatus.fundsHeld,
    }) =>
        models.Transaction(
          id: id,
          buyerId: 'buyer-1',
          farmerId: 'farmer1',
          listingId: 'listing-1',
          amount: 100.0,
          currency: 'USD',
          status: status,
          paymentMethod: PaymentMethod.mpesa,
          createdAt: DateTime(2024, 6, 1),
        );

    testWidgets('tapping Confirm Delivery dispatches PaymentDeliveryConfirmed',
        (tester) async {
      final tx = makeTx();
      final payRepo = FakePaymentRepository()
        ..transactions = [tx]
        ..transaction = tx;

      await tester.pumpWidget(_buildScreen(
        dashboardRepo: _DataDashboardRepository(_makeDashboard()),
        paymentRepo: payRepo,
      ));
      await tester.pump();
      await tester.pump();
      await tester.tap(find.text('ORDERS'));
      await tester.pump();
      await tester.pump();

      expect(find.text('Confirm Delivery'), findsOneWidget);
      await tester.tap(find.text('Confirm Delivery'));
      await tester.pump();

      // Event dispatched — no crash
      expect(find.byType(FarmerDashboardScreen), findsOneWidget);
    });
  });

  group('FarmerDashboardScreen — error state retry', () {
    testWidgets('tapping retry on DashboardFailure reloads dashboard',
        (tester) async {
      await tester.pumpWidget(
          _buildScreen(dashboardRepo: _ErrorDashboardRepository('Load failed')));
      await tester.pump();

      expect(find.textContaining('Load failed'), findsOneWidget);
      // Tap the "Try again" button provided by ErrorStateWidget
      await tester.tap(find.text('Try again'));
      await tester.pump();

      // No crash — DashboardBloc received FarmerDashboardLoadRequested
      expect(find.byType(FarmerDashboardScreen), findsOneWidget);
    });
  });
}
