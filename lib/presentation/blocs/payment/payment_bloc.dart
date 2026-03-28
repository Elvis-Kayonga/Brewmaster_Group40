import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:brewmaster/domain/models/escrow_transaction.dart';
import 'package:brewmaster/domain/models/enums.dart';
import 'package:brewmaster/domain/repositories/payment_repository.dart';

part 'payment_event.dart';
part 'payment_state.dart';

class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  final PaymentRepository _paymentRepository;

  // Internal cache for the history screen's combined state
  List<Transaction> _historyTransactions = [];
  Map<String, dynamic>? _historyStatistics;

  PaymentBloc({required PaymentRepository paymentRepository})
      : _paymentRepository = paymentRepository,
        super(const PaymentInitial()) {
    on<PaymentInitiateRequested>(_onInitiate);
    on<PaymentProcessRequested>(_onProcess);
    on<PaymentDeliveryConfirmed>(_onConfirmDelivery);
    on<PaymentReceiptConfirmed>(_onConfirmReceipt);
    on<PaymentDisputeRaised>(_onRaiseDispute);
    on<PaymentCancelRequested>(_onCancel);
    on<PaymentTransactionsSubscribed>(_onSubscribeTransactions);
    on<PaymentStatisticsRequested>(_onLoadStatistics);
    on<PaymentTransactionLoadRequested>(_onLoadTransaction);
    on<PaymentHistoryRequested>(_onHistoryRequested);
  }

  Future<void> _onInitiate(
    PaymentInitiateRequested event,
    Emitter<PaymentState> emit,
  ) async {
    emit(const PaymentLoading());
    try {
      final tx = await _paymentRepository.createTransaction(
        buyerId: event.buyerId,
        farmerId: event.farmerId,
        listingId: event.listingId,
        amount: event.amount,
        currency: event.currency,
        paymentMethod: event.paymentMethod,
        paymentReference: event.flutterwaveTxId,
      );
      final processed = await _paymentRepository.processPayment(tx.id);
      emit(PaymentProcessed(processed));
    } catch (e) {
      emit(PaymentFailure(e.toString()));
    }
  }

  Future<void> _onProcess(
    PaymentProcessRequested event,
    Emitter<PaymentState> emit,
  ) async {
    emit(const PaymentLoading());
    try {
      final tx = await _paymentRepository.processPayment(event.transactionId);
      emit(PaymentProcessed(tx));
    } catch (e) {
      emit(PaymentFailure(e.toString()));
    }
  }

  Future<void> _onConfirmDelivery(
    PaymentDeliveryConfirmed event,
    Emitter<PaymentState> emit,
  ) async {
    emit(const PaymentLoading());
    try {
      final tx =
          await _paymentRepository.confirmDelivery(event.transactionId);
      emit(PaymentActionSuccess(tx));
    } catch (e) {
      emit(PaymentFailure(e.toString()));
    }
  }

  Future<void> _onConfirmReceipt(
    PaymentReceiptConfirmed event,
    Emitter<PaymentState> emit,
  ) async {
    emit(const PaymentLoading());
    try {
      final tx = await _paymentRepository
          .confirmReceiptAndReleaseFunds(event.transactionId);
      emit(PaymentActionSuccess(tx));
    } catch (e) {
      emit(PaymentFailure(e.toString()));
    }
  }

  Future<void> _onRaiseDispute(
    PaymentDisputeRaised event,
    Emitter<PaymentState> emit,
  ) async {
    emit(const PaymentLoading());
    try {
      final tx = await _paymentRepository.raiseDispute(
          event.transactionId, event.reason);
      emit(PaymentActionSuccess(tx));
    } catch (e) {
      emit(PaymentFailure(e.toString()));
    }
  }

  Future<void> _onCancel(
    PaymentCancelRequested event,
    Emitter<PaymentState> emit,
  ) async {
    emit(const PaymentLoading());
    try {
      final tx =
          await _paymentRepository.cancelTransaction(event.transactionId);
      emit(PaymentActionSuccess(tx));
    } catch (e) {
      emit(PaymentFailure(e.toString()));
    }
  }

  Future<void> _onSubscribeTransactions(
    PaymentTransactionsSubscribed event,
    Emitter<PaymentState> emit,
  ) async {
    await emit.forEach<List<Transaction>>(
      _paymentRepository.getUserTransactions(event.userId),
      onData: (txs) => PaymentTransactionsLoaded(txs),
      onError: (e, _) => PaymentFailure(e.toString()),
    );
  }

  Future<void> _onLoadStatistics(
    PaymentStatisticsRequested event,
    Emitter<PaymentState> emit,
  ) async {
    emit(const PaymentLoading());
    try {
      final stats = await _paymentRepository.getUserStatistics(event.userId);
      emit(PaymentStatisticsLoaded(stats));
    } catch (e) {
      emit(PaymentFailure(e.toString()));
    }
  }

  Future<void> _onLoadTransaction(
    PaymentTransactionLoadRequested event,
    Emitter<PaymentState> emit,
  ) async {
    emit(const PaymentLoading());
    try {
      final tx =
          await _paymentRepository.getTransaction(event.transactionId);
      if (tx != null) {
        emit(PaymentTransactionLoaded(tx));
      } else {
        emit(const PaymentFailure('Transaction not found.'));
      }
    } catch (e) {
      emit(PaymentFailure(e.toString()));
    }
  }

  /// Subscribes to the user's transaction stream AND loads statistics,
  /// emitting [PaymentHistoryLoaded] whenever either updates.
  Future<void> _onHistoryRequested(
    PaymentHistoryRequested event,
    Emitter<PaymentState> emit,
  ) async {
    // Reset cached data for this user
    _historyTransactions = [];
    _historyStatistics = null;

    // Load statistics once (fire-and-forget into cached field)
    _paymentRepository.getUserStatistics(event.userId).then((stats) {
      _historyStatistics = stats;
      if (!emit.isDone) {
        emit(PaymentHistoryLoaded(
          transactions: _historyTransactions,
          statistics: _historyStatistics,
        ));
      }
    }).catchError((_) {});

    // Subscribe to the live transaction stream
    await emit.forEach<List<Transaction>>(
      _paymentRepository.getUserTransactions(event.userId),
      onData: (txs) {
        _historyTransactions = txs;
        return PaymentHistoryLoaded(
          transactions: _historyTransactions,
          statistics: _historyStatistics,
        );
      },
      onError: (e, _) => PaymentFailure(e.toString()),
    );
  }
}
