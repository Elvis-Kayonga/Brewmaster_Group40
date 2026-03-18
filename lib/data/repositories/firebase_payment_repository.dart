import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:brewmaster/domain/models/escrow_transaction.dart' as models;
import 'package:brewmaster/domain/models/enums.dart' hide NotificationType;
import 'package:brewmaster/domain/models/notification.dart';
import 'package:brewmaster/domain/models/paginated_result.dart';
import 'package:brewmaster/domain/repositories/notification_repository.dart';
import 'package:brewmaster/domain/repositories/payment_repository.dart';

/// Firebase/Firestore implementation of [PaymentRepository].
class FirebasePaymentRepository implements PaymentRepository {
  final FirebaseFirestore _firestore;
  final NotificationRepository _notifications;
  final Random _random = Random();

  FirebasePaymentRepository({
    FirebaseFirestore? firestore,
    required NotificationRepository notificationRepository,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _notifications = notificationRepository;

  CollectionReference<Map<String, dynamic>> get _transactions =>
      _firestore.collection('transactions');

  @override
  Future<models.Transaction> createTransaction({
    required String buyerId,
    required String farmerId,
    required String listingId,
    required double amount,
    required PaymentMethod paymentMethod,
  }) async {
    final now = DateTime.now();
    final transaction = models.Transaction(
      id: '',
      buyerId: buyerId,
      farmerId: farmerId,
      listingId: listingId,
      amount: amount,
      status: TransactionStatus.pending,
      paymentMethod: paymentMethod,
      createdAt: now,
      statusHistory: {'pending': now},
    );
    final docRef = await _transactions.add(transaction.toFirestore());
    final created = transaction.copyWith(id: docRef.id);
    _notify(
      userId: farmerId,
      title: 'New Purchase Request',
      body: 'A buyer has initiated a purchase of \$${amount.toStringAsFixed(2)}.',
      type: NotificationType.purchaseInitiated,
      data: {'transactionId': docRef.id},
    );
    return created;
  }

  @override
  Future<models.Transaction> processPayment(String transactionId) async {
    final doc = await _transactions.doc(transactionId).get();
    if (!doc.exists) throw Exception('Transaction not found');

    final transaction = models.Transaction.fromFirestore(doc);
    final success = _random.nextDouble() > 0.1; // 90% success

    if (success) {
      final updated = await _updateStatus(transaction, TransactionStatus.fundsHeld);
      _notify(
        userId: transaction.farmerId,
        title: 'Payment Received',
        body: 'Funds of \$${transaction.amount.toStringAsFixed(2)} are now held in escrow.',
        type: NotificationType.paymentReceived,
        data: {'transactionId': transactionId},
      );
      return updated;
    } else {
      if (transaction.canRetry()) {
        final updated = transaction.copyWith(
          retryCount: transaction.retryCount + 1,
          failureReason: 'Payment gateway timeout',
        );
        await _transactions.doc(transactionId).update(updated.toFirestore());
        await Future.delayed(const Duration(seconds: 2));
        return processPayment(transactionId);
      } else {
        final updated = transaction.copyWith(
          status: TransactionStatus.cancelled,
          failureReason: 'Maximum retry attempts exceeded',
        );
        await _transactions.doc(transactionId).update(updated.toFirestore());
        throw Exception('Payment failed after ${transaction.retryCount} retries');
      }
    }
  }

  @override
  Future<models.Transaction> confirmDelivery(String transactionId) async {
    final doc = await _transactions.doc(transactionId).get();
    if (!doc.exists) throw Exception('Transaction not found');

    final transaction = models.Transaction.fromFirestore(doc);
    if (transaction.status != TransactionStatus.fundsHeld) {
      throw Exception('Cannot confirm delivery - funds not held');
    }
    final updated = await _updateStatus(transaction, TransactionStatus.delivered);
    _notify(
      userId: transaction.buyerId,
      title: 'Delivery Confirmed',
      body: 'The farmer has confirmed your order is on its way.',
      type: NotificationType.deliveryConfirmed,
      data: {'transactionId': transactionId},
    );
    return updated;
  }

  @override
  Future<models.Transaction> confirmReceiptAndReleaseFunds(
      String transactionId) async {
    final doc = await _transactions.doc(transactionId).get();
    if (!doc.exists) throw Exception('Transaction not found');

    final transaction = models.Transaction.fromFirestore(doc);
    if (!transaction.canReleaseFunds()) {
      throw Exception('Cannot release funds - invalid transaction state');
    }

    final success = _random.nextDouble() > 0.05; // 95% success
    if (success) {
      final updated = await _updateStatus(transaction, TransactionStatus.completed);
      _notify(
        userId: transaction.farmerId,
        title: 'Funds Released',
        body: 'The buyer confirmed receipt. \$${transaction.amount.toStringAsFixed(2)} has been released to you.',
        type: NotificationType.paymentReceived,
        data: {'transactionId': transactionId},
      );
      return updated;
    } else {
      throw Exception('Fund transfer failed - please try again');
    }
  }

  @override
  Future<models.Transaction> raiseDispute(
      String transactionId, String reason) async {
    final doc = await _transactions.doc(transactionId).get();
    if (!doc.exists) throw Exception('Transaction not found');

    final transaction = models.Transaction.fromFirestore(doc);
    if (transaction.status == TransactionStatus.completed ||
        transaction.status == TransactionStatus.cancelled) {
      throw Exception('Cannot dispute a completed or cancelled transaction');
    }

    final now = DateTime.now();
    final statusHistory = Map<String, DateTime>.from(transaction.statusHistory);
    statusHistory[TransactionStatus.disputed.toJson()] = now;

    final updated = transaction.copyWith(
      status: TransactionStatus.disputed,
      disputeReason: reason,
      statusHistory: statusHistory,
    );
    await _transactions.doc(transactionId).update(updated.toFirestore());
    return updated;
  }

  @override
  Future<models.Transaction> cancelTransaction(String transactionId) async {
    final doc = await _transactions.doc(transactionId).get();
    if (!doc.exists) throw Exception('Transaction not found');

    final transaction = models.Transaction.fromFirestore(doc);
    if (transaction.status != TransactionStatus.pending) {
      throw Exception('Can only cancel pending transactions');
    }
    return _updateStatus(transaction, TransactionStatus.cancelled);
  }

  @override
  Future<models.Transaction?> getTransaction(String transactionId) async {
    final doc = await _transactions.doc(transactionId).get();
    if (!doc.exists) return null;
    return models.Transaction.fromFirestore(doc);
  }

  @override
  Stream<List<models.Transaction>> getUserTransactions(String userId) {
    return _transactions
        .where('buyerId', isEqualTo: userId)
        .snapshots()
        .asyncMap((snapshot) async {
      final buyerTxs = snapshot.docs
          .map((d) => models.Transaction.fromFirestore(d))
          .toList();

      final farmerSnapshot = await _transactions
          .where('farmerId', isEqualTo: userId)
          .get();
      final farmerTxs = farmerSnapshot.docs
          .map((d) => models.Transaction.fromFirestore(d))
          .toList();

      final all = [...buyerTxs, ...farmerTxs];
      all.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return all;
    });
  }

  @override
  Stream<List<models.Transaction>> getListingTransactions(String listingId) {
    return _transactions
        .where('listingId', isEqualTo: listingId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => models.Transaction.fromFirestore(d)).toList());
  }

  @override
  Future<Map<String, dynamic>> getUserStatistics(String userId) async {
    final snapshot =
        await _transactions.where('farmerId', isEqualTo: userId).get();

    double totalEarnings = 0;
    int completedCount = 0;
    int pendingCount = 0;

    for (final doc in snapshot.docs) {
      final tx = models.Transaction.fromFirestore(doc);
      if (tx.status == TransactionStatus.completed) {
        totalEarnings += tx.amount;
        completedCount++;
      } else if (tx.status == TransactionStatus.pending ||
          tx.status == TransactionStatus.fundsHeld ||
          tx.status == TransactionStatus.delivered) {
        pendingCount++;
      }
    }

    return {
      'totalEarnings': totalEarnings,
      'completedTransactions': completedCount,
      'pendingTransactions': pendingCount,
      'totalTransactions': snapshot.size,
    };
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  void _notify({
    required String userId,
    required String title,
    required String body,
    required NotificationType type,
    required Map<String, dynamic> data,
  }) {
    final id = _firestore.collection('notifications').doc().id;
    _notifications.saveNotification(AppNotification(
      id: id,
      userId: userId,
      title: title,
      body: body,
      type: type,
      data: data,
      isRead: false,
      createdAt: DateTime.now(),
    ));
  }

  Future<models.Transaction> _updateStatus(
    models.Transaction transaction,
    TransactionStatus newStatus,
  ) async {
    final now = DateTime.now();
    final statusHistory = Map<String, DateTime>.from(transaction.statusHistory);
    statusHistory[newStatus.toJson()] = now;

    final updated = transaction.copyWith(
      status: newStatus,
      updatedAt: now,
      fundsHeldAt: newStatus == TransactionStatus.fundsHeld
          ? now
          : transaction.fundsHeldAt,
      deliveredAt: newStatus == TransactionStatus.delivered
          ? now
          : transaction.deliveredAt,
      completedAt: newStatus == TransactionStatus.completed
          ? now
          : transaction.completedAt,
      statusHistory: statusHistory,
    );

    await _transactions.doc(transaction.id).update(updated.toFirestore());
    return updated;
  }

  @override
  Future<PaginatedResult<models.Transaction>> getTransactionPage({
    required String userId,
    int pageSize = 20,
    Object? startAfter,
  }) async {
    Query<Map<String, dynamic>> query = _transactions
        .where('buyerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(pageSize + 1);

    if (startAfter is DocumentSnapshot) {
      query = query.startAfterDocument(startAfter);
    }

    final snapshot = await query.get();
    final hasMore = snapshot.docs.length > pageSize;
    final docs = hasMore ? snapshot.docs.sublist(0, pageSize) : snapshot.docs;

    return PaginatedResult<models.Transaction>(
      items: docs.map((d) => models.Transaction.fromFirestore(d)).toList(),
      hasMore: hasMore,
      cursor: docs.isNotEmpty ? docs.last : null,
    );
  }
}
