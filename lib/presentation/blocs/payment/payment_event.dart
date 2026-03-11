part of 'payment_bloc.dart';

abstract class PaymentEvent extends Equatable {
  const PaymentEvent();

  @override
  List<Object?> get props => [];
}

class PaymentInitiateRequested extends PaymentEvent {
  final String buyerId;
  final String farmerId;
  final String listingId;
  final double amount;
  final PaymentMethod paymentMethod;

  const PaymentInitiateRequested({
    required this.buyerId,
    required this.farmerId,
    required this.listingId,
    required this.amount,
    required this.paymentMethod,
  });

  @override
  List<Object?> get props =>
      [buyerId, farmerId, listingId, amount, paymentMethod];
}

class PaymentProcessRequested extends PaymentEvent {
  final String transactionId;
  const PaymentProcessRequested(this.transactionId);

  @override
  List<Object?> get props => [transactionId];
}

class PaymentDeliveryConfirmed extends PaymentEvent {
  final String transactionId;
  const PaymentDeliveryConfirmed(this.transactionId);

  @override
  List<Object?> get props => [transactionId];
}

class PaymentReceiptConfirmed extends PaymentEvent {
  final String transactionId;
  const PaymentReceiptConfirmed(this.transactionId);

  @override
  List<Object?> get props => [transactionId];
}

class PaymentDisputeRaised extends PaymentEvent {
  final String transactionId;
  final String reason;
  const PaymentDisputeRaised({
    required this.transactionId,
    required this.reason,
  });

  @override
  List<Object?> get props => [transactionId, reason];
}

class PaymentCancelRequested extends PaymentEvent {
  final String transactionId;
  const PaymentCancelRequested(this.transactionId);

  @override
  List<Object?> get props => [transactionId];
}

class PaymentTransactionsSubscribed extends PaymentEvent {
  final String userId;
  const PaymentTransactionsSubscribed(this.userId);

  @override
  List<Object?> get props => [userId];
}

class PaymentStatisticsRequested extends PaymentEvent {
  final String userId;
  const PaymentStatisticsRequested(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// Load a single transaction for the detail screen.
class PaymentTransactionLoadRequested extends PaymentEvent {
  final String transactionId;
  const PaymentTransactionLoadRequested(this.transactionId);

  @override
  List<Object?> get props => [transactionId];
}

/// Subscribe to transactions AND load statistics together (history screen).
class PaymentHistoryRequested extends PaymentEvent {
  final String userId;
  const PaymentHistoryRequested(this.userId);

  @override
  List<Object?> get props => [userId];
}
