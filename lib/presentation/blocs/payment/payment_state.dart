part of 'payment_bloc.dart';

abstract class PaymentState extends Equatable {
  const PaymentState();

  @override
  List<Object?> get props => [];
}

class PaymentInitial extends PaymentState {
  const PaymentInitial();
}

class PaymentLoading extends PaymentState {
  const PaymentLoading();
}

class PaymentTransactionCreated extends PaymentState {
  final Transaction transaction;
  const PaymentTransactionCreated(this.transaction);

  @override
  List<Object?> get props => [transaction];
}

class PaymentProcessed extends PaymentState {
  final Transaction transaction;
  const PaymentProcessed(this.transaction);

  @override
  List<Object?> get props => [transaction];
}

class PaymentTransactionsLoaded extends PaymentState {
  final List<Transaction> transactions;
  const PaymentTransactionsLoaded(this.transactions);

  @override
  List<Object?> get props => [transactions];
}

class PaymentStatisticsLoaded extends PaymentState {
  final Map<String, dynamic> statistics;
  const PaymentStatisticsLoaded(this.statistics);

  @override
  List<Object?> get props => [statistics];
}

class PaymentActionSuccess extends PaymentState {
  final Transaction transaction;
  const PaymentActionSuccess(this.transaction);

  @override
  List<Object?> get props => [transaction];
}

class PaymentFailure extends PaymentState {
  final String message;
  const PaymentFailure(this.message);

  @override
  List<Object?> get props => [message];
}

/// Single transaction loaded for the detail screen.
class PaymentTransactionLoaded extends PaymentState {
  final Transaction transaction;
  const PaymentTransactionLoaded(this.transaction);

  @override
  List<Object?> get props => [transaction];
}

/// Combined state for the history screen: transactions + statistics.
class PaymentHistoryLoaded extends PaymentState {
  final List<Transaction> transactions;
  final Map<String, dynamic>? statistics;

  const PaymentHistoryLoaded({required this.transactions, this.statistics});

  PaymentHistoryLoaded copyWith({
    List<Transaction>? transactions,
    Map<String, dynamic>? statistics,
  }) {
    return PaymentHistoryLoaded(
      transactions: transactions ?? this.transactions,
      statistics: statistics ?? this.statistics,
    );
  }

  @override
  List<Object?> get props => [transactions, statistics];
}
