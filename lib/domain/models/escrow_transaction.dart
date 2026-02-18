import 'package:cloud_firestore/cloud_firestore.dart';
import 'enums.dart';

/// Represents an escrow transaction in the payment system
class Transaction {
  final String id;
  final String buyerId;
  final String farmerId;
  final String listingId;
  final double amount;
  final TransactionStatus status;
  final PaymentMethod paymentMethod;
  final DateTime createdAt;
  final DateTime? fundsHeldAt;
  final DateTime? deliveredAt;
  final DateTime? completedAt;
  final String? disputeReason;
  final int retryCount;
  final String? failureReason;
  final Map<String, DateTime> statusHistory;

  Transaction({
    required this.id,
    required this.buyerId,
    required this.farmerId,
    required this.listingId,
    required this.amount,
    required this.status,
    required this.paymentMethod,
    required this.createdAt,
    this.fundsHeldAt,
    this.deliveredAt,
    this.completedAt,
    this.disputeReason,
    this.retryCount = 0,
    this.failureReason,
    Map<String, DateTime>? statusHistory,
  }) : statusHistory = statusHistory ?? {};

  /// Create Transaction from Firestore document
  factory Transaction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Transaction(
      id: doc.id,
      buyerId: data['buyerId'] as String,
      farmerId: data['farmerId'] as String,
      listingId: data['listingId'] as String,
      amount: (data['amount'] as num).toDouble(),
      status: TransactionStatusExtension.fromJson(data['status'] as String),
      paymentMethod:
          PaymentMethodExtension.fromJson(data['paymentMethod'] as String),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      fundsHeldAt: data['fundsHeldAt'] != null
          ? (data['fundsHeldAt'] as Timestamp).toDate()
          : null,
      deliveredAt: data['deliveredAt'] != null
          ? (data['deliveredAt'] as Timestamp).toDate()
          : null,
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
      disputeReason: data['disputeReason'] as String?,
      retryCount: data['retryCount'] as int? ?? 0,
      failureReason: data['failureReason'] as String?,
      statusHistory: _parseStatusHistory(data['statusHistory'] as Map?),
    );
  }

  /// Convert Transaction to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'buyerId': buyerId,
      'farmerId': farmerId,
      'listingId': listingId,
      'amount': amount,
      'status': status.toJson(),
      'paymentMethod': paymentMethod.toJson(),
      'createdAt': Timestamp.fromDate(createdAt),
      'fundsHeldAt':
          fundsHeldAt != null ? Timestamp.fromDate(fundsHeldAt!) : null,
      'deliveredAt':
          deliveredAt != null ? Timestamp.fromDate(deliveredAt!) : null,
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'disputeReason': disputeReason,
      'retryCount': retryCount,
      'failureReason': failureReason,
      'statusHistory': _serializeStatusHistory(statusHistory),
    };
  }

  /// Parse status history from Firestore
  static Map<String, DateTime> _parseStatusHistory(Map? data) {
    if (data == null) return {};
    return data.map((key, value) =>
        MapEntry(key as String, (value as Timestamp).toDate()));
  }

  /// Serialize status history for Firestore
  static Map<String, Timestamp> _serializeStatusHistory(
      Map<String, DateTime> history) {
    return history.map(
        (key, value) => MapEntry(key, Timestamp.fromDate(value)));
  }

  /// Create a copy with updated fields
  Transaction copyWith({
    String? id,
    String? buyerId,
    String? farmerId,
    String? listingId,
    double? amount,
    TransactionStatus? status,
    PaymentMethod? paymentMethod,
    DateTime? createdAt,
    DateTime? fundsHeldAt,
    DateTime? deliveredAt,
    DateTime? completedAt,
    String? disputeReason,
    int? retryCount,
    String? failureReason,
    Map<String, DateTime>? statusHistory,
  }) {
    return Transaction(
      id: id ?? this.id,
      buyerId: buyerId ?? this.buyerId,
      farmerId: farmerId ?? this.farmerId,
      listingId: listingId ?? this.listingId,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      createdAt: createdAt ?? this.createdAt,
      fundsHeldAt: fundsHeldAt ?? this.fundsHeldAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      completedAt: completedAt ?? this.completedAt,
      disputeReason: disputeReason ?? this.disputeReason,
      retryCount: retryCount ?? this.retryCount,
      failureReason: failureReason ?? this.failureReason,
      statusHistory: statusHistory ?? this.statusHistory,
    );
  }

  /// Check if transaction can be retried
  bool canRetry() => retryCount < 3 && status == TransactionStatus.pending;

  /// Check if funds can be released
  bool canReleaseFunds() =>
      status == TransactionStatus.delivered &&
      fundsHeldAt != null &&
      completedAt == null;
}
