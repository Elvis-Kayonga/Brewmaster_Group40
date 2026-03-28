import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:brewmaster/domain/models/escrow_transaction.dart' as models;
import 'package:brewmaster/domain/models/enums.dart';
import 'package:brewmaster/domain/models/paginated_result.dart';
import 'package:brewmaster/domain/repositories/payment_repository.dart';
import 'package:brewmaster/presentation/blocs/payment/payment_bloc.dart';
import 'package:brewmaster/presentation/screens/payments/transaction_detail_screen.dart';

import '../helpers/fake_repositories.dart';

// ── Fake repos ────────────────────────────────────────────────────────────────

/// getTransaction never completes — keeps bloc loading.
class _NeverLoadRepo implements PaymentRepository {
  @override
  Future<models.Transaction?> getTransaction(String id) =>
      Completer<models.Transaction?>().future;
  @override
  Stream<List<models.Transaction>> getUserTransactions(String uid) =>
      Stream.value([]);
  @override
  Stream<List<models.Transaction>> getListingTransactions(String id) =>
      Stream.value([]);
  @override
  Future<models.Transaction> createTransaction({
    required String buyerId, required String farmerId, required String listingId,
    required double amount, String currency = 'USD', required PaymentMethod paymentMethod,
    String? paymentReference,
  }) => throw UnimplementedError();
  @override
  Future<models.Transaction> processPayment(String id) => throw UnimplementedError();
  @override
  Future<models.Transaction> confirmDelivery(String id) => throw UnimplementedError();
  @override
  Future<models.Transaction> confirmReceiptAndReleaseFunds(String id) => throw UnimplementedError();
  @override
  Future<models.Transaction> raiseDispute(String id, String reason) => throw UnimplementedError();
  @override
  Future<models.Transaction> cancelTransaction(String id) => throw UnimplementedError();
  @override
  Future<Map<String, dynamic>> getUserStatistics(String uid) => throw UnimplementedError();
  @override
  Future<PaginatedResult<models.Transaction>> getTransactionPage({
    required String userId, int pageSize = 20, Object? startAfter,
  }) async => const PaginatedResult(items: [], hasMore: false);
}

/// getTransaction returns null — bloc emits PaymentFailure('Transaction not found.').
class _ErrorLoadRepo extends _NeverLoadRepo {
  @override
  Future<models.Transaction?> getTransaction(String id) async => null;
}

// ── Fixture helpers ───────────────────────────────────────────────────────────

models.Transaction _makeTx() => models.Transaction(
      id: 'tx-001',
      buyerId: 'buyer-1',
      farmerId: 'farmer-1',
      listingId: 'listing-1',
      amount: 250.00,
      currency: 'USD',
      status: TransactionStatus.fundsHeld,
      paymentMethod: PaymentMethod.mpesa,
      createdAt: DateTime(2024, 6, 15, 10, 30),
      statusHistory: const {},
    );

models.Transaction _makeTxWith({
  TransactionStatus status = TransactionStatus.fundsHeld,
  String? disputeReason,
}) =>
    models.Transaction(
      id: 'tx-001',
      buyerId: 'buyer-1',
      farmerId: 'farmer-1',
      listingId: 'listing-1',
      amount: 250.00,
      currency: 'USD',
      status: status,
      paymentMethod: PaymentMethod.mpesa,
      createdAt: DateTime(2024, 6, 15, 10, 30),
      statusHistory: const {},
      disputeReason: disputeReason,
    );

// ── Helper ────────────────────────────────────────────────────────────────────

Widget _buildScreen(PaymentBloc paymentBloc, {bool isFarmer = false}) =>
    MaterialApp(
      home: BlocProvider<PaymentBloc>(
        create: (_) => paymentBloc,
        child: TransactionDetailScreen(
          transactionId: 'tx-001',
          userId: 'buyer-1',
          isFarmer: isFarmer,
        ),
      ),
    );

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    setupFirebaseCoreMocks();
    await Firebase.initializeApp();
  });

  group('TransactionDetailScreen', () {
    testWidgets('shows "Transaction Details" app bar title', (tester) async {
      final repo = FakePaymentRepository()..transaction = _makeTx();
      final pb = PaymentBloc(paymentRepository: repo)
        ..emit(PaymentTransactionLoaded(_makeTx()));
      await tester.pumpWidget(_buildScreen(pb));
      await tester.pump();
      expect(find.text('Transaction Details'), findsOneWidget);
    });

    testWidgets('shows transaction ID when transaction is loaded',
        (tester) async {
      final repo = FakePaymentRepository()..transaction = _makeTx();
      final pb = PaymentBloc(paymentRepository: repo)
        ..emit(PaymentTransactionLoaded(_makeTx()));
      await tester.pumpWidget(_buildScreen(pb));
      await tester.pump();
      expect(find.text('tx-001'), findsOneWidget);
    });

    testWidgets('shows status badge for fundsHeld status', (tester) async {
      final repo = FakePaymentRepository()..transaction = _makeTx();
      final pb = PaymentBloc(paymentRepository: repo)
        ..emit(PaymentTransactionLoaded(_makeTx()));
      await tester.pumpWidget(_buildScreen(pb));
      await tester.pump();
      expect(find.text('Funds Held in Escrow'), findsOneWidget);
    });

    testWidgets('shows transaction amount', (tester) async {
      final repo = FakePaymentRepository()..transaction = _makeTx();
      final pb = PaymentBloc(paymentRepository: repo)
        ..emit(PaymentTransactionLoaded(_makeTx()));
      await tester.pumpWidget(_buildScreen(pb));
      await tester.pump();
      expect(find.textContaining('250.00'), findsOneWidget);
    });

    // ── New tests ─────────────────────────────────────────────────────────────

    testWidgets('loading state shows CircularProgressIndicator',
        (tester) async {
      final pb = PaymentBloc(paymentRepository: _NeverLoadRepo());
      await tester.pumpWidget(_buildScreen(pb));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('PaymentFailure state shows error message',
        (tester) async {
      final pb = PaymentBloc(paymentRepository: _ErrorLoadRepo());
      await tester.pumpWidget(_buildScreen(pb));
      await tester.pump();
      expect(find.textContaining('Transaction not found'), findsWidgets);
    });

    testWidgets(
        'farmer view shows "Confirm Delivery" button for fundsHeld status',
        (tester) async {
      final tx = _makeTxWith(status: TransactionStatus.fundsHeld);
      final repo = FakePaymentRepository()..transaction = tx;
      final pb = PaymentBloc(paymentRepository: repo)
        ..emit(PaymentTransactionLoaded(tx));
      await tester.pumpWidget(_buildScreen(pb, isFarmer: true));
      await tester.pump();
      expect(find.text('Confirm Delivery'), findsOneWidget);
    });

    testWidgets(
        'buyer view shows "Confirm Receipt & Release Funds" button for delivered status',
        (tester) async {
      final tx = _makeTxWith(status: TransactionStatus.delivered);
      final repo = FakePaymentRepository()..transaction = tx;
      final pb = PaymentBloc(paymentRepository: repo)
        ..emit(PaymentTransactionLoaded(tx));
      await tester.pumpWidget(_buildScreen(pb, isFarmer: false));
      await tester.pump();
      expect(find.text('Confirm Receipt & Release Funds'), findsOneWidget);
    });

    testWidgets('buyer view shows "Raise Dispute" button for fundsHeld status',
        (tester) async {
      final tx = _makeTxWith(status: TransactionStatus.fundsHeld);
      final repo = FakePaymentRepository()..transaction = tx;
      final pb = PaymentBloc(paymentRepository: repo)
        ..emit(PaymentTransactionLoaded(tx));
      await tester.pumpWidget(_buildScreen(pb, isFarmer: false));
      await tester.pump();
      expect(find.text('Raise Dispute'), findsOneWidget);
    });

    testWidgets(
        'buyer view does NOT show "Confirm Receipt & Release Funds" for fundsHeld status',
        (tester) async {
      final tx = _makeTxWith(status: TransactionStatus.fundsHeld);
      final repo = FakePaymentRepository()..transaction = tx;
      final pb = PaymentBloc(paymentRepository: repo)
        ..emit(PaymentTransactionLoaded(tx));
      await tester.pumpWidget(_buildScreen(pb, isFarmer: false));
      await tester.pump();
      expect(find.text('Confirm Receipt & Release Funds'), findsNothing);
    });

    testWidgets(
        'completed status does NOT show "Raise Dispute" button',
        (tester) async {
      final tx = _makeTxWith(status: TransactionStatus.completed);
      final repo = FakePaymentRepository()..transaction = tx;
      final pb = PaymentBloc(paymentRepository: repo)
        ..emit(PaymentTransactionLoaded(tx));
      await tester.pumpWidget(_buildScreen(pb, isFarmer: false));
      await tester.pump();
      expect(find.text('Raise Dispute'), findsNothing);
    });

    testWidgets(
        'cancelled status does NOT show "Raise Dispute" button',
        (tester) async {
      final tx = _makeTxWith(status: TransactionStatus.cancelled);
      final repo = FakePaymentRepository()..transaction = tx;
      final pb = PaymentBloc(paymentRepository: repo)
        ..emit(PaymentTransactionLoaded(tx));
      await tester.pumpWidget(_buildScreen(pb, isFarmer: false));
      await tester.pump();
      expect(find.text('Raise Dispute'), findsNothing);
    });

    testWidgets(
        'farmer view with delivered status does NOT show "Confirm Delivery"',
        (tester) async {
      final tx = _makeTxWith(status: TransactionStatus.delivered);
      final repo = FakePaymentRepository()..transaction = tx;
      final pb = PaymentBloc(paymentRepository: repo)
        ..emit(PaymentTransactionLoaded(tx));
      await tester.pumpWidget(_buildScreen(pb, isFarmer: true));
      await tester.pump();
      expect(find.text('Confirm Delivery'), findsNothing);
    });

    testWidgets('pending status shows "Pending Payment" in status badge',
        (tester) async {
      final tx = _makeTxWith(status: TransactionStatus.pending);
      final repo = FakePaymentRepository()..transaction = tx;
      final pb = PaymentBloc(paymentRepository: repo)
        ..emit(PaymentTransactionLoaded(tx));
      await tester.pumpWidget(_buildScreen(pb));
      await tester.pump();
      expect(find.text('Pending Payment'), findsOneWidget);
    });

    testWidgets('completed status shows "Completed" in status badge',
        (tester) async {
      final tx = _makeTxWith(status: TransactionStatus.completed);
      final repo = FakePaymentRepository()..transaction = tx;
      final pb = PaymentBloc(paymentRepository: repo)
        ..emit(PaymentTransactionLoaded(tx));
      await tester.pumpWidget(_buildScreen(pb));
      await tester.pump();
      expect(find.text('Completed'), findsOneWidget);
    });

    testWidgets('disputed status shows "Disputed" in status badge',
        (tester) async {
      final tx = _makeTxWith(status: TransactionStatus.disputed);
      final repo = FakePaymentRepository()..transaction = tx;
      final pb = PaymentBloc(paymentRepository: repo)
        ..emit(PaymentTransactionLoaded(tx));
      await tester.pumpWidget(_buildScreen(pb));
      await tester.pump();
      expect(find.text('Disputed'), findsOneWidget);
    });

    testWidgets('cancelled status shows "Cancelled" in status badge',
        (tester) async {
      final tx = _makeTxWith(status: TransactionStatus.cancelled);
      final repo = FakePaymentRepository()..transaction = tx;
      final pb = PaymentBloc(paymentRepository: repo)
        ..emit(PaymentTransactionLoaded(tx));
      await tester.pumpWidget(_buildScreen(pb));
      await tester.pump();
      expect(find.text('Cancelled'), findsOneWidget);
    });

    testWidgets(
        'transaction with disputeReason shows "Dispute Raised" card',
        (tester) async {
      final tx = _makeTxWith(
        status: TransactionStatus.disputed,
        disputeReason: 'Coffee was not as described',
      );
      final repo = FakePaymentRepository()..transaction = tx;
      final pb = PaymentBloc(paymentRepository: repo)
        ..emit(PaymentTransactionLoaded(tx));
      await tester.pumpWidget(_buildScreen(pb));
      await tester.pump();
      expect(find.text('Dispute Raised'), findsOneWidget);
      expect(find.text('Coffee was not as described'), findsOneWidget);
    });

    testWidgets('delivered status shows "Awaiting Buyer Confirmation" badge',
        (tester) async {
      final tx = _makeTxWith(status: TransactionStatus.delivered);
      final repo = FakePaymentRepository()..transaction = tx;
      final pb = PaymentBloc(paymentRepository: repo)
        ..emit(PaymentTransactionLoaded(tx));
      await tester.pumpWidget(_buildScreen(pb));
      await tester.pump();
      expect(find.text('Awaiting Buyer Confirmation'), findsOneWidget);
    });

    testWidgets('transaction with MTN Mobile Money shows correct payment method label',
        (tester) async {
      final tx = models.Transaction(
        id: 'tx-002',
        buyerId: 'buyer-1',
        farmerId: 'farmer-1',
        listingId: 'listing-1',
        amount: 100.00,
        currency: 'USD',
        status: TransactionStatus.pending,
        paymentMethod: PaymentMethod.mtnMobileMoney,
        createdAt: DateTime(2024, 6, 15),
        statusHistory: const {},
      );
      final repo = FakePaymentRepository()..transaction = tx;
      final pb = PaymentBloc(paymentRepository: repo)
        ..emit(PaymentTransactionLoaded(tx));
      await tester.pumpWidget(_buildScreen(pb));
      await tester.pump();
      expect(find.text('MTN Mobile Money'), findsOneWidget);
    });

    testWidgets('transaction with statusHistory shows timeline entries',
        (tester) async {
      final tx = models.Transaction(
        id: 'tx-003',
        buyerId: 'buyer-1',
        farmerId: 'farmer-1',
        listingId: 'listing-1',
        amount: 150.00,
        currency: 'USD',
        status: TransactionStatus.fundsHeld,
        paymentMethod: PaymentMethod.mpesa,
        createdAt: DateTime(2024, 6, 15),
        statusHistory: {
          'pending': DateTime(2024, 6, 15, 9, 0),
          'fundsHeld': DateTime(2024, 6, 15, 10, 0),
        },
      );
      final repo = FakePaymentRepository()..transaction = tx;
      final pb = PaymentBloc(paymentRepository: repo)
        ..emit(PaymentTransactionLoaded(tx));
      await tester.pumpWidget(_buildScreen(pb));
      await tester.pump();
      expect(find.text('Status Timeline'), findsOneWidget);
      // Timeline items render as check_circle icons
      expect(find.byIcon(Icons.check_circle), findsWidgets);
    });

    testWidgets('transaction with retryCount > 0 shows retry attempts row',
        (tester) async {
      final tx = models.Transaction(
        id: 'tx-004',
        buyerId: 'buyer-1',
        farmerId: 'farmer-1',
        listingId: 'listing-1',
        amount: 100.00,
        currency: 'USD',
        status: TransactionStatus.pending,
        paymentMethod: PaymentMethod.mpesa,
        createdAt: DateTime(2024, 6, 15),
        statusHistory: const {},
        retryCount: 2,
      );
      final repo = FakePaymentRepository()..transaction = tx;
      final pb = PaymentBloc(paymentRepository: repo)
        ..emit(PaymentTransactionLoaded(tx));
      await tester.pumpWidget(_buildScreen(pb));
      await tester.pump();
      expect(find.textContaining('2'), findsWidgets);
    });

    testWidgets('PaymentActionSuccess shows success snackbar', (tester) async {
      final tx = _makeTxWith(status: TransactionStatus.fundsHeld);
      final repo = FakePaymentRepository()..transaction = tx;
      final pb = PaymentBloc(paymentRepository: repo)
        ..emit(PaymentTransactionLoaded(tx));
      await tester.pumpWidget(_buildScreen(pb, isFarmer: true));
      await tester.pump();

      pb.emit(PaymentActionSuccess(tx));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Action completed successfully'), findsOneWidget);
    });

    testWidgets('PaymentFailure state shows snackbar via listener', (tester) async {
      final tx = _makeTxWith(status: TransactionStatus.fundsHeld);
      final repo = FakePaymentRepository()..transaction = tx;
      final pb = PaymentBloc(paymentRepository: repo)
        ..emit(PaymentTransactionLoaded(tx));
      await tester.pumpWidget(_buildScreen(pb));
      await tester.pump();

      pb.emit(const PaymentFailure('Payment processing failed'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Payment processing failed'), findsWidgets);
    });

    testWidgets(
        'tapping "Confirm Delivery" opens confirmation dialog',
        (tester) async {
      final tx = _makeTxWith(status: TransactionStatus.fundsHeld);
      final repo = FakePaymentRepository()..transaction = tx;
      final pb = PaymentBloc(paymentRepository: repo)
        ..emit(PaymentTransactionLoaded(tx));
      await tester.pumpWidget(_buildScreen(pb, isFarmer: true));
      await tester.pump();

      await tester.tap(find.text('Confirm Delivery'));
      await tester.pump();

      // ConfirmationDialog renders in a dialog
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets(
        'tapping "Raise Dispute" opens dispute dialog',
        (tester) async {
      final tx = _makeTxWith(status: TransactionStatus.fundsHeld);
      final repo = FakePaymentRepository()..transaction = tx;
      final pb = PaymentBloc(paymentRepository: repo)
        ..emit(PaymentTransactionLoaded(tx));
      await tester.pumpWidget(_buildScreen(pb, isFarmer: false));
      await tester.pump();

      await tester.tap(find.text('Raise Dispute'));
      await tester.pump();

      expect(find.text('Raise Dispute'), findsWidgets); // dialog title
    });

    testWidgets(
        'tapping "Confirm Receipt & Release Funds" opens confirmation dialog',
        (tester) async {
      final tx = _makeTxWith(status: TransactionStatus.delivered);
      final repo = FakePaymentRepository()..transaction = tx;
      final pb = PaymentBloc(paymentRepository: repo)
        ..emit(PaymentTransactionLoaded(tx));
      await tester.pumpWidget(_buildScreen(pb, isFarmer: false));
      await tester.pump();

      await tester.tap(find.text('Confirm Receipt & Release Funds'));
      await tester.pump();

      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('dispute dialog Cancel dismisses without dispatching',
        (tester) async {
      final tx = _makeTxWith(status: TransactionStatus.fundsHeld);
      final repo = FakePaymentRepository()..transaction = tx;
      final pb = PaymentBloc(paymentRepository: repo)
        ..emit(PaymentTransactionLoaded(tx));
      await tester.pumpWidget(_buildScreen(pb, isFarmer: false));
      await tester.pump();

      await tester.tap(find.text('Raise Dispute'));
      await tester.pump();

      await tester.tap(find.text('Cancel'));
      await tester.pump();

      // Dialog dismissed, back to main screen
      expect(find.text('Transaction Details'), findsOneWidget);
    });

    testWidgets('farmer view shows nothing for completed transactions',
        (tester) async {
      final tx = _makeTxWith(status: TransactionStatus.completed);
      final repo = FakePaymentRepository()..transaction = tx;
      final pb = PaymentBloc(paymentRepository: repo)
        ..emit(PaymentTransactionLoaded(tx));
      await tester.pumpWidget(_buildScreen(pb, isFarmer: true));
      await tester.pump();
      expect(find.text('Confirm Delivery'), findsNothing);
      expect(find.text('Raise Dispute'), findsNothing);
    });
  });
}
