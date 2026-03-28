// test/bloc/payment_bloc_test.dart
//
// Unit tests for PaymentBloc — covers all event handlers.
// Requirements: 6.1, 6.2

import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:brewmaster/domain/models/enums.dart';
import 'package:brewmaster/domain/models/escrow_transaction.dart';
import 'package:brewmaster/domain/models/paginated_result.dart';
import 'package:brewmaster/domain/repositories/payment_repository.dart';
import 'package:brewmaster/presentation/blocs/payment/payment_bloc.dart';

// ─── Fixtures ─────────────────────────────────────────────────────────────────

final _now = DateTime(2026, 1, 1);

Transaction _fakeTx({String id = 'tx-1', TransactionStatus status = TransactionStatus.pending}) =>
    Transaction(
      id: id,
      buyerId: 'buyer-1',
      farmerId: 'farmer-1',
      listingId: 'listing-1',
      amount: 100.0,
      currency: 'KES',
      status: status,
      paymentMethod: PaymentMethod.mpesa,
      createdAt: _now,
    );

// ─── Fake repository ──────────────────────────────────────────────────────────

class _FakePaymentRepository implements PaymentRepository {
  Transaction _tx = _fakeTx();
  Exception? _error;
  final StreamController<List<Transaction>> _txController =
      StreamController<List<Transaction>>.broadcast();
  Map<String, dynamic> _stats = {'totalEarnings': 500.0, 'completedOrders': 2};

  void setTx(Transaction t) => _tx = t;
  void setError(Exception e) => _error = e;
  void setStats(Map<String, dynamic> s) => _stats = s;
  void pushTransactions(List<Transaction> txs) => _txController.add(txs);

  String? lastPaymentReference;

  @override
  Future<Transaction> createTransaction({
    required String buyerId,
    required String farmerId,
    required String listingId,
    required double amount,
    String currency = 'USD',
    required PaymentMethod paymentMethod,
    String? paymentReference,
  }) async {
    if (_error != null) throw _error!;
    lastPaymentReference = paymentReference;
    return _tx;
  }

  @override
  Future<Transaction> processPayment(String transactionId) async {
    if (_error != null) throw _error!;
    return _tx;
  }

  @override
  Future<Transaction> confirmDelivery(String transactionId) async {
    if (_error != null) throw _error!;
    return _fakeTx(status: TransactionStatus.delivered);
  }

  @override
  Future<Transaction> confirmReceiptAndReleaseFunds(String transactionId) async {
    if (_error != null) throw _error!;
    return _fakeTx(status: TransactionStatus.completed);
  }

  @override
  Future<Transaction> raiseDispute(String transactionId, String reason) async {
    if (_error != null) throw _error!;
    return _fakeTx(status: TransactionStatus.disputed);
  }

  @override
  Future<Transaction> cancelTransaction(String transactionId) async {
    if (_error != null) throw _error!;
    return _fakeTx(status: TransactionStatus.cancelled);
  }

  @override
  Future<Transaction?> getTransaction(String transactionId) async {
    if (_error != null) throw _error!;
    return _tx;
  }

  @override
  Stream<List<Transaction>> getUserTransactions(String userId) =>
      _txController.stream;

  @override
  Stream<List<Transaction>> getListingTransactions(String listingId) =>
      const Stream.empty();

  @override
  Future<Map<String, dynamic>> getUserStatistics(String userId) async {
    if (_error != null) throw _error!;
    return _stats;
  }

  @override
  Future<PaginatedResult<Transaction>> getTransactionPage(
          {required String userId, int pageSize = 20, Object? startAfter}) async =>
      PaginatedResult(items: [], cursor: null, hasMore: false);

  void dispose() => _txController.close();
}

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  group('PaymentBloc — initial state', () {
    test('starts in PaymentInitial', () {
      final repo = _FakePaymentRepository();
      final bloc = PaymentBloc(paymentRepository: repo);
      expect(bloc.state, isA<PaymentInitial>());
      bloc.close();
      repo.dispose();
    });
  });

  group('PaymentBloc — PaymentInitiateRequested', () {
    test('emits PaymentLoading then PaymentProcessed on success', () async {
      final repo = _FakePaymentRepository();
      final bloc = PaymentBloc(paymentRepository: repo);
      final states = <PaymentState>[];
      final sub = bloc.stream.listen(states.add);

      bloc.add(const PaymentInitiateRequested(
        buyerId: 'buyer-1',
        farmerId: 'farmer-1',
        listingId: 'listing-1',
        amount: 100.0,
        paymentMethod: PaymentMethod.mpesa,
      ));
      await Future<void>.delayed(Duration.zero);

      expect(states.any((s) => s is PaymentLoading), isTrue);
      expect(states.last, isA<PaymentProcessed>());

      await sub.cancel();
      bloc.close();
      repo.dispose();
    });

    test('emits PaymentFailure on exception', () async {
      final repo = _FakePaymentRepository();
      repo.setError(Exception('payment failed'));
      final bloc = PaymentBloc(paymentRepository: repo);

      bloc.add(const PaymentInitiateRequested(
        buyerId: 'buyer-1',
        farmerId: 'farmer-1',
        listingId: 'listing-1',
        amount: 100.0,
        paymentMethod: PaymentMethod.mpesa,
      ));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state, isA<PaymentFailure>());
      bloc.close();
      repo.dispose();
    });
  });

  group('PaymentBloc — PaymentDeliveryConfirmed', () {
    test('emits PaymentActionSuccess with delivered transaction', () async {
      final repo = _FakePaymentRepository();
      final bloc = PaymentBloc(paymentRepository: repo);

      bloc.add(const PaymentDeliveryConfirmed('tx-1'));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state, isA<PaymentActionSuccess>());
      expect(
        (bloc.state as PaymentActionSuccess).transaction.status,
        TransactionStatus.delivered,
      );

      bloc.close();
      repo.dispose();
    });

    test('emits PaymentFailure on exception', () async {
      final repo = _FakePaymentRepository();
      repo.setError(Exception('confirm failed'));
      final bloc = PaymentBloc(paymentRepository: repo);

      bloc.add(const PaymentDeliveryConfirmed('tx-1'));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state, isA<PaymentFailure>());
      bloc.close();
      repo.dispose();
    });
  });

  group('PaymentBloc — PaymentReceiptConfirmed', () {
    test('emits PaymentActionSuccess with completed transaction', () async {
      final repo = _FakePaymentRepository();
      final bloc = PaymentBloc(paymentRepository: repo);

      bloc.add(const PaymentReceiptConfirmed('tx-1'));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state, isA<PaymentActionSuccess>());
      expect(
        (bloc.state as PaymentActionSuccess).transaction.status,
        TransactionStatus.completed,
      );

      bloc.close();
      repo.dispose();
    });

    test('emits PaymentFailure on exception', () async {
      final repo = _FakePaymentRepository();
      repo.setError(Exception('receipt failed'));
      final bloc = PaymentBloc(paymentRepository: repo);

      bloc.add(const PaymentReceiptConfirmed('tx-1'));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state, isA<PaymentFailure>());
      bloc.close();
      repo.dispose();
    });
  });

  group('PaymentBloc — PaymentDisputeRaised', () {
    test('emits PaymentActionSuccess with disputed transaction', () async {
      final repo = _FakePaymentRepository();
      final bloc = PaymentBloc(paymentRepository: repo);

      bloc.add(const PaymentDisputeRaised(
          transactionId: 'tx-1', reason: 'Not delivered'));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state, isA<PaymentActionSuccess>());
      expect(
        (bloc.state as PaymentActionSuccess).transaction.status,
        TransactionStatus.disputed,
      );

      bloc.close();
      repo.dispose();
    });
  });

  group('PaymentBloc — PaymentCancelRequested', () {
    test('emits PaymentActionSuccess with cancelled transaction', () async {
      final repo = _FakePaymentRepository();
      final bloc = PaymentBloc(paymentRepository: repo);

      bloc.add(const PaymentCancelRequested('tx-1'));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state, isA<PaymentActionSuccess>());
      expect(
        (bloc.state as PaymentActionSuccess).transaction.status,
        TransactionStatus.cancelled,
      );

      bloc.close();
      repo.dispose();
    });
  });

  group('PaymentBloc — PaymentStatisticsRequested', () {
    test('emits PaymentStatisticsLoaded on success', () async {
      final repo = _FakePaymentRepository();
      final bloc = PaymentBloc(paymentRepository: repo);

      bloc.add(const PaymentStatisticsRequested('user-1'));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state, isA<PaymentStatisticsLoaded>());
      final loaded = bloc.state as PaymentStatisticsLoaded;
      expect(loaded.statistics['totalEarnings'], 500.0);

      bloc.close();
      repo.dispose();
    });

    test('emits PaymentFailure on exception', () async {
      final repo = _FakePaymentRepository();
      repo.setError(Exception('stats failed'));
      final bloc = PaymentBloc(paymentRepository: repo);

      bloc.add(const PaymentStatisticsRequested('user-1'));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state, isA<PaymentFailure>());
      bloc.close();
      repo.dispose();
    });
  });

  group('PaymentBloc — PaymentTransactionLoadRequested', () {
    test('emits PaymentTransactionLoaded when found', () async {
      final repo = _FakePaymentRepository();
      final bloc = PaymentBloc(paymentRepository: repo);

      bloc.add(const PaymentTransactionLoadRequested('tx-1'));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state, isA<PaymentTransactionLoaded>());

      bloc.close();
      repo.dispose();
    });

    test('emits PaymentFailure when transaction not found', () async {
      final bloc = PaymentBloc(paymentRepository: _NullTxRepo());

      bloc.add(const PaymentTransactionLoadRequested('missing'));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state, isA<PaymentFailure>());
      expect((bloc.state as PaymentFailure).message, 'Transaction not found.');

      bloc.close();
    });
  });

  group('PaymentBloc — Flutterwave integration', () {
    test('PaymentInitiateRequested passes flutterwaveTxId as paymentReference',
        () async {
      final repo = _FakePaymentRepository();
      final bloc = PaymentBloc(paymentRepository: repo);

      bloc.add(const PaymentInitiateRequested(
        buyerId: 'buyer-1',
        farmerId: 'farmer-1',
        listingId: 'listing-1',
        amount: 250.0,
        currency: 'KES',
        paymentMethod: PaymentMethod.flutterwave,
        flutterwaveTxId: '123456789',
      ));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state, isA<PaymentProcessed>());
      expect(repo.lastPaymentReference, '123456789');

      bloc.close();
      repo.dispose();
    });

    test('PaymentInitiateRequested with flutterwave method and no txId still succeeds',
        () async {
      final repo = _FakePaymentRepository();
      final bloc = PaymentBloc(paymentRepository: repo);

      bloc.add(const PaymentInitiateRequested(
        buyerId: 'buyer-1',
        farmerId: 'farmer-1',
        listingId: 'listing-1',
        amount: 100.0,
        paymentMethod: PaymentMethod.flutterwave,
      ));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state, isA<PaymentProcessed>());
      expect(repo.lastPaymentReference, isNull);

      bloc.close();
      repo.dispose();
    });

    test('PaymentMethod.flutterwave serializes and deserializes correctly', () {
      expect(PaymentMethod.flutterwave.toJson(), 'flutterwave');
      expect(
        PaymentMethodExtension.fromJson('flutterwave'),
        PaymentMethod.flutterwave,
      );
    });

    test('PaymentMethodExtension.fromJson falls back to flutterwave for unknown values',
        () {
      expect(
        PaymentMethodExtension.fromJson('unknown_provider'),
        PaymentMethod.flutterwave,
      );
    });

    test('PaymentInitiateRequested props include flutterwaveTxId', () {
      const event = PaymentInitiateRequested(
        buyerId: 'b',
        farmerId: 'f',
        listingId: 'l',
        amount: 10.0,
        paymentMethod: PaymentMethod.flutterwave,
        flutterwaveTxId: 'fw-tx-99',
      );
      expect(event.props, contains('fw-tx-99'));
    });
  });
}

/// Helper stub that returns null for getTransaction.

class _NullTxRepo extends _FakePaymentRepository {
  @override
  Future<Transaction?> getTransaction(String transactionId) async => null;
}
