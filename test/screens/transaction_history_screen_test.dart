// Widget tests for TransactionHistoryScreen
// Coverage: loading state, empty state, list with transactions (active/inactive).

import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:brewmaster/domain/models/enums.dart';
import 'package:brewmaster/domain/models/escrow_transaction.dart' as models;
import 'package:brewmaster/domain/models/paginated_result.dart';
import 'package:brewmaster/domain/repositories/payment_repository.dart';
import 'package:brewmaster/presentation/blocs/auth/auth_bloc.dart';
import 'package:brewmaster/presentation/blocs/messaging/notification_bloc.dart';
import 'package:brewmaster/presentation/blocs/payment/payment_bloc.dart';
import 'package:brewmaster/presentation/blocs/profile/profile_bloc.dart';
import 'package:brewmaster/presentation/screens/payments/transaction_history_screen.dart';

import '../helpers/fake_repositories.dart';

// ── Fake repos ────────────────────────────────────────────────────────────────

/// getUserTransactions never emits — keeps bloc in loading state.
class _NeverStreamingPaymentRepository implements PaymentRepository {
  @override
  Stream<List<models.Transaction>> getUserTransactions(String userId) =>
      StreamController<List<models.Transaction>>().stream; // never emits

  @override
  Stream<List<models.Transaction>> getListingTransactions(String listingId) =>
      Stream.value([]);

  @override
  Future<models.Transaction> createTransaction({
    required String buyerId,
    required String farmerId,
    required String listingId,
    required double amount,
    String currency = 'USD',
    required PaymentMethod paymentMethod,
    String? paymentReference,
  }) =>
      throw UnimplementedError();

  @override
  Future<models.Transaction> processPayment(String transactionId) =>
      throw UnimplementedError();

  @override
  Future<models.Transaction> confirmDelivery(String transactionId) =>
      throw UnimplementedError();

  @override
  Future<models.Transaction> confirmReceiptAndReleaseFunds(
          String transactionId) =>
      throw UnimplementedError();

  @override
  Future<models.Transaction> raiseDispute(
          String transactionId, String reason) =>
      throw UnimplementedError();

  @override
  Future<models.Transaction> cancelTransaction(String transactionId) =>
      throw UnimplementedError();

  @override
  Future<models.Transaction?> getTransaction(String transactionId) async =>
      null;

  @override
  Future<Map<String, dynamic>> getUserStatistics(String userId) =>
      Completer<Map<String, dynamic>>().future; // never completes

  @override
  Future<PaginatedResult<models.Transaction>> getTransactionPage({
    required String userId,
    int pageSize = 20,
    Object? startAfter,
  }) async =>
      const PaginatedResult(items: [], hasMore: false);
}

// ── Fixture ───────────────────────────────────────────────────────────────────

models.Transaction _makeTransaction({
  String id = 'abcdef12',
  TransactionStatus status = TransactionStatus.fundsHeld,
  double amount = 500.0,
}) =>
    models.Transaction(
      id: id,
      buyerId: 'buyer-1',
      farmerId: 'farmer-1',
      listingId: 'listing-1',
      amount: amount,
      currency: 'USD',
      status: status,
      paymentMethod: PaymentMethod.mpesa,
      createdAt: DateTime(2024, 6, 15, 10, 30),
    );

// ── Helper ────────────────────────────────────────────────────────────────────

/// [neverLoad]     — getUserTransactions never emits (loading state).
/// [transactions]  — transactions returned immediately (loaded state).
Widget _wrap({
  List<models.Transaction> transactions = const [],
  bool neverLoad = false,
}) {
  final PaymentRepository payRepo = neverLoad
      ? _NeverStreamingPaymentRepository()
      : (FakePaymentRepository()..transactions = transactions);

  final userRepo = FakeUserRepository();

  return MaterialApp(
    home: MultiBlocProvider(
      providers: [
        BlocProvider<PaymentBloc>(
          create: (_) => PaymentBloc(paymentRepository: payRepo),
        ),
        BlocProvider<AuthBloc>(
          create: (_) => AuthBloc(
            authRepository: FakeAuthRepository(),
            userRepository: FakeUserRepository(),
          ),
        ),
        BlocProvider<ProfileBloc>(
          create: (_) => ProfileBloc(userRepository: userRepo),
        ),
        BlocProvider<NotificationBloc>(
          create: (_) => NotificationBloc(repository: FakeNotificationRepository()),
        ),
      ],
      child: const TransactionHistoryScreen(userId: 'user-1', isFarmer: false),
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

  group('TransactionHistoryScreen', () {
    testWidgets('shows loading indicator while getUserTransactions is pending',
        (tester) async {
      await tester.pumpWidget(_wrap(neverLoad: true));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('shows "My Orders" header when PaymentHistoryLoaded',
        (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      expect(find.text('My Orders'), findsOneWidget);
    });

    testWidgets('shows subtitle text when loaded', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      expect(find.textContaining('Track your coffee purchases'), findsOneWidget);
    });

    testWidgets('shows empty state widget when transactions list is empty',
        (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      expect(find.text('No Transactions Yet'), findsOneWidget);
      expect(
        find.textContaining('Your coffee orders and payments will appear here'),
        findsOneWidget,
      );
    });

    testWidgets('shows "View all" button when empty', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      expect(find.text('View all'), findsOneWidget);
    });

    testWidgets('shows transaction card for fundsHeld status', (tester) async {
      await tester.pumpWidget(
        _wrap(transactions: [_makeTransaction(status: TransactionStatus.fundsHeld)]),
      );
      await tester.pump();
      expect(find.text('In Escrow'), findsOneWidget);
    });

    testWidgets('shows LIVE TRACE: ACTIVE badge for active statuses',
        (tester) async {
      await tester.pumpWidget(
        _wrap(transactions: [_makeTransaction(status: TransactionStatus.fundsHeld)]),
      );
      await tester.pump();
      expect(find.text('LIVE TRACE: ACTIVE'), findsOneWidget);
    });

    testWidgets('shows completed transaction card title', (tester) async {
      await tester.pumpWidget(
        _wrap(transactions: [_makeTransaction(status: TransactionStatus.completed)]),
      );
      await tester.pump();
      expect(find.text('Delivered'), findsOneWidget);
    });

    testWidgets('shows cancelled transaction card title', (tester) async {
      await tester.pumpWidget(
        _wrap(transactions: [_makeTransaction(status: TransactionStatus.cancelled)]),
      );
      await tester.pump();
      expect(find.text('Cancelled'), findsOneWidget);
    });

    testWidgets('shows disputed transaction card title', (tester) async {
      await tester.pumpWidget(
        _wrap(transactions: [_makeTransaction(status: TransactionStatus.disputed)]),
      );
      await tester.pump();
      expect(find.text('Under Dispute'), findsOneWidget);
    });

    testWidgets('shows pending transaction card title', (tester) async {
      await tester.pumpWidget(
        _wrap(transactions: [_makeTransaction(status: TransactionStatus.pending)]),
      );
      await tester.pump();
      expect(find.text('Awaiting Payment'), findsOneWidget);
    });

    testWidgets('shows delivered transaction card title', (tester) async {
      await tester.pumpWidget(
        _wrap(transactions: [_makeTransaction(status: TransactionStatus.delivered)]),
      );
      await tester.pump();
      expect(find.text('In Transit'), findsOneWidget);
    });

    testWidgets('shows short transaction ID in card', (tester) async {
      // id = 'abcdef12' → shortId = 'TRC-ORD-ABCD'
      await tester.pumpWidget(
        _wrap(transactions: [_makeTransaction(id: 'abcdef12')]),
      );
      await tester.pump();
      expect(find.text('TRC-ORD-ABCD'), findsOneWidget);
    });

    testWidgets('shows progress bar steps in card', (tester) async {
      await tester.pumpWidget(
        _wrap(transactions: [_makeTransaction(status: TransactionStatus.fundsHeld)]),
      );
      await tester.pump();
      expect(find.text('Origin'), findsOneWidget);
      expect(find.text('Delivery'), findsOneWidget);
    });

    testWidgets('shows "Brew Master" app bar title', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      expect(find.text('Brew Master'), findsOneWidget);
    });

    testWidgets('shows multiple transaction cards', (tester) async {
      await tester.pumpWidget(
        _wrap(transactions: [
          _makeTransaction(id: 'aaaa1111', status: TransactionStatus.pending),
          _makeTransaction(id: 'bbbb2222', status: TransactionStatus.completed),
        ]),
      );
      await tester.pump();
      expect(find.text('Awaiting Payment'), findsOneWidget);
      expect(find.text('Delivered'), findsOneWidget);
    });
  });
}
