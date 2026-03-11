import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:brewmaster/domain/models/escrow_transaction.dart' as models;
import 'package:brewmaster/domain/models/enums.dart';
import 'package:brewmaster/domain/repositories/payment_repository.dart';

/// Firebase/Firestore implementation of [PaymentRepository].
class FirebasePaymentRepository implements PaymentRepository {
  final FirebaseFirestore _firestore;
  final Random _random = Random();

  FirebasePaymentRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

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
    return transaction.copyWith(id: docRef.id);
  }

  @override
  Future<models.Transaction> processPayment(String transactionId) async {
    final doc = await _transactions.doc(transactionId).get();
    if (!doc.exists) throw Exception('Transaction not found');

    final transaction = models.Transaction.fromFirestore(doc);
    final success = _random.nextDouble() > 0.1; // 90% success

    if (success) {
      return _updateStatus(transaction, TransactionStatus.fundsHeld);
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
    return _updateStatus(transaction, TransactionStatus.delivered);
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
      return _updateStatus(transaction, TransactionStatus.completed);
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

  Future<models.Transaction> _updateStatus(
    models.Transaction transaction,
    TransactionStatus newStatus,
  ) async {
    final now = DateTime.now();
    final statusHistory = Map<String, DateTime>.from(transaction.statusHistory);
    statusHistory[newStatus.toJson()] = now;

    final updated = transaction.copyWith(
      status: newStatus,
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
}
