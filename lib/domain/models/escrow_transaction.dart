import 'package:cloud_firestore/cloud_firestore.dart';
import 'enums.dart';

/// Represents an escrow transaction in the payment system
class Transaction {
  final String id;
  final String buyerId;
  /// Denormalized buyer display name for showing on the farmer's order view.
  final String? buyerName;
  final String farmerId;
  final String listingId;
  final double amount;
  /// Currency code e.g. "KES", "USD" (ERD: currency).
  final String currency;
  final TransactionStatus status;
  final PaymentMethod paymentMethod;
  /// Reference returned by the payment provider e.g. M-Pesa code (ERD: paymentReference).
  final String? paymentReference;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? fundsHeldAt;
  final DateTime? deliveredAt;
  final DateTime? completedAt;
  final String? disputeReason;
  final int retryCount;
  final String? failureReason;
  final Map<String, DateTime> statusHistory;

  // Compliance / traceability fields (Requirements: 15.1, 15.3)
  final String? receiptNumber;
  final Map<String, String>? traceabilityData; // e.g. certificationIds, exportRef

  Transaction({
    required this.id,
    required this.buyerId,
    this.buyerName,
    required this.farmerId,
    required this.listingId,
    required this.amount,
    this.currency = 'USD',
    required this.status,
    required this.paymentMethod,
    this.paymentReference,
    required this.createdAt,
    this.updatedAt,
    this.fundsHeldAt,
    this.deliveredAt,
    this.completedAt,
    this.disputeReason,
    this.retryCount = 0,
    this.failureReason,
    Map<String, DateTime>? statusHistory,
    this.receiptNumber,
    this.traceabilityData,
  }) : statusHistory = statusHistory ?? {};

  /// Create Transaction from Firestore document
  factory Transaction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Transaction(
      id: doc.id,
      buyerId: data['buyerId'] as String,
      buyerName: data['buyerName'] as String?,
      farmerId: data['farmerId'] as String,
      listingId: data['listingId'] as String,
      amount: (data['amount'] as num).toDouble(),
      currency: data['currency'] as String? ?? 'USD',
      status: TransactionStatusExtension.fromJson(data['status'] as String),
      paymentMethod:
          PaymentMethodExtension.fromJson(data['paymentMethod'] as String),
      paymentReference: data['paymentReference'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
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
      receiptNumber: data['receiptNumber'] as String?,
      traceabilityData: (data['traceabilityData'] as Map<String, dynamic>?)
          ?.map((k, v) => MapEntry(k, v as String)),
    );
  }

  /// Convert Transaction to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'buyerId': buyerId,
      'buyerName': buyerName,
      'farmerId': farmerId,
      'listingId': listingId,
      'amount': amount,
      'currency': currency,
      'status': status.toJson(),
      'paymentMethod': paymentMethod.toJson(),
      'paymentReference': paymentReference,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
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
      'receiptNumber': receiptNumber,
      'traceabilityData': traceabilityData,
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
    String? buyerName,
    String? farmerId,
    String? listingId,
    double? amount,
    String? currency,
    TransactionStatus? status,
    PaymentMethod? paymentMethod,
    String? paymentReference,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? fundsHeldAt,
    DateTime? deliveredAt,
    DateTime? completedAt,
    String? disputeReason,
    int? retryCount,
    String? failureReason,
    Map<String, DateTime>? statusHistory,
    String? receiptNumber,
    Map<String, String>? traceabilityData,
  }) {
    return Transaction(
      id: id ?? this.id,
      buyerId: buyerId ?? this.buyerId,
      buyerName: buyerName ?? this.buyerName,
      farmerId: farmerId ?? this.farmerId,
      listingId: listingId ?? this.listingId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentReference: paymentReference ?? this.paymentReference,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      fundsHeldAt: fundsHeldAt ?? this.fundsHeldAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      completedAt: completedAt ?? this.completedAt,
      disputeReason: disputeReason ?? this.disputeReason,
      retryCount: retryCount ?? this.retryCount,
      failureReason: failureReason ?? this.failureReason,
      statusHistory: statusHistory ?? this.statusHistory,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      traceabilityData: traceabilityData ?? this.traceabilityData,
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
