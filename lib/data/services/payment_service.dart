import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/escrow_transaction.dart' as models;
import '../../domain/models/enums.dart';

/// Service for handling payment transactions with escrow logic
class PaymentService {
  final FirebaseFirestore _firestore;
  final Random _random = Random();

  PaymentService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Create a new escrow transaction
  Future<models.Transaction> createTransaction({
    required String buyerId,
    required String farmerId,
    required String listingId,
    required double amount,
    required PaymentMethod paymentMethod,
  }) async {
    final now = DateTime.now();
    final transaction = models.Transaction(
      id: '', // Will be set by Firestore
      buyerId: buyerId,
      farmerId: farmerId,
      listingId: listingId,
      amount: amount,
      status: TransactionStatus.pending,
      paymentMethod: paymentMethod,
      createdAt: now,
      statusHistory: {'pending': now},
    );

    final docRef = await _firestore
        .collection('transactions')
        .add(transaction.toFirestore());

    return transaction.copyWith(id: docRef.id);
  }

  /// Process payment from buyer (simulated with dummy data)
  Future<models.Transaction> processPayment(String transactionId) async {
    final doc = await _firestore
        .collection('transactions')
        .doc(transactionId)
        .get();

    if (!doc.exists) {
      throw Exception('Transaction not found');
    }

    final transaction = models.Transaction.fromFirestore(doc);

    // Simulate payment processing with 90% success rate
    final success = _random.nextDouble() > 0.1;

    if (success) {
      // Payment successful - update to fundsHeld
      final updatedTransaction = await _updateTransactionStatus(
        transaction,
        TransactionStatus.fundsHeld,
      );
      return updatedTransaction;
    } else {
      // Payment failed - retry logic
      if (transaction.canRetry()) {
        final updated = transaction.copyWith(
          retryCount: transaction.retryCount + 1,
          failureReason: 'Payment gateway timeout',
        );
        await _firestore
            .collection('transactions')
            .doc(transactionId)
            .update(updated.toFirestore());

        // Retry automatically
        await Future.delayed(Duration(seconds: 2));
        return processPayment(transactionId);
      } else {
        // Max retries reached - mark as cancelled
        final updated = transaction.copyWith(
          status: TransactionStatus.cancelled,
          failureReason: 'Maximum retry attempts exceeded',
        );
        await _firestore
            .collection('transactions')
            .doc(transactionId)
            .update(updated.toFirestore());
        throw Exception(
          'Payment failed after ${transaction.retryCount} retries',
        );
      }
    }
  }

  /// Confirm delivery by farmer
  Future<models.Transaction> confirmDelivery(String transactionId) async {
    final doc = await _firestore
        .collection('transactions')
        .doc(transactionId)
        .get();

    if (!doc.exists) {
      throw Exception('Transaction not found');
    }

    final transaction = models.Transaction.fromFirestore(doc);

    if (transaction.status != TransactionStatus.fundsHeld) {
      throw Exception('Cannot confirm delivery - funds not held');
    }

    return _updateTransactionStatus(transaction, TransactionStatus.delivered);
  }

  /// Confirm receipt by buyer and release funds
  Future<models.Transaction> confirmReceiptAndReleaseFunds(
    String transactionId,
  ) async {
    final doc = await _firestore
        .collection('transactions')
        .doc(transactionId)
        .get();

    if (!doc.exists) {
      throw Exception('Transaction not found');
    }

    final transaction = models.Transaction.fromFirestore(doc);

    if (!transaction.canReleaseFunds()) {
      throw Exception('Cannot release funds - invalid transaction state');
    }

    // Simulate fund transfer to farmer (dummy data)
    final success = _random.nextDouble() > 0.05; // 95% success rate

    if (success) {
      return _updateTransactionStatus(transaction, TransactionStatus.completed);
    } else {
      throw Exception('Fund transfer failed - please try again');
    }
  }

  /// Raise a dispute for a transaction
  Future<models.Transaction> raiseDispute(
    String transactionId,
    String reason,
  ) async {
    final doc = await _firestore
        .collection('transactions')
        .doc(transactionId)
        .get();

    if (!doc.exists) {
      throw Exception('Transaction not found');
    }

    final transaction = models.Transaction.fromFirestore(doc);

    if (transaction.status == TransactionStatus.completed ||
        transaction.status == TransactionStatus.cancelled) {
      throw Exception('Cannot dispute a completed or cancelled transaction');
    }

    final updated = transaction.copyWith(
      status: TransactionStatus.disputed,
      disputeReason: reason,
    );

    final now = DateTime.now();
    updated.statusHistory[TransactionStatus.disputed.toJson()] = now;

    await _firestore
        .collection('transactions')
        .doc(transactionId)
        .update(updated.toFirestore());

    return updated;
  }

  /// Cancel a transaction
  Future<models.Transaction> cancelTransaction(String transactionId) async {
    final doc = await _firestore
        .collection('transactions')
        .doc(transactionId)
        .get();

    if (!doc.exists) {
      throw Exception('Transaction not found');
    }

    final transaction = models.Transaction.fromFirestore(doc);

    if (transaction.status != TransactionStatus.pending) {
      throw Exception('Can only cancel pending transactions');
    }

    return _updateTransactionStatus(transaction, TransactionStatus.cancelled);
  }

  /// Get transaction by ID
  Future<models.Transaction?> getTransaction(String transactionId) async {
    final doc = await _firestore
        .collection('transactions')
        .doc(transactionId)
        .get();

    if (!doc.exists) return null;
    return models.Transaction.fromFirestore(doc);
  }

  /// Get transactions for a user (buyer or farmer)
  Stream<List<models.Transaction>> getUserTransactions(String userId) {
    return _firestore
        .collection('transactions')
        .where('buyerId', isEqualTo: userId)
        .snapshots()
        .asyncMap((snapshot) async {
          final buyerTransactions = snapshot.docs
              .map((doc) => models.Transaction.fromFirestore(doc))
              .toList();

          // Also get transactions where user is farmer
          final farmerSnapshot = await _firestore
              .collection('transactions')
              .where('farmerId', isEqualTo: userId)
              .get();

          final farmerTransactions = farmerSnapshot.docs
              .map((doc) => models.Transaction.fromFirestore(doc))
              .toList();

          // Combine and sort by date
          final allTransactions = [...buyerTransactions, ...farmerTransactions];
          allTransactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          return allTransactions;
        });
  }

  /// Get transaction history for a listing
  Stream<List<models.Transaction>> getListingTransactions(String listingId) {
    return _firestore
        .collection('transactions')
        .where('listingId', isEqualTo: listingId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => models.Transaction.fromFirestore(doc))
              .toList(),
        );
  }

  /// Helper method to update transaction status
  Future<models.Transaction> _updateTransactionStatus(
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

    await _firestore
        .collection('transactions')
        .doc(transaction.id)
        .update(updated.toFirestore());

    return updated;
  }

  /// Get transaction statistics for a user
  Future<Map<String, dynamic>> getUserStatistics(String userId) async {
    final transactions = await _firestore
        .collection('transactions')
        .where('farmerId', isEqualTo: userId)
        .get();

    double totalEarnings = 0;
    int completedCount = 0;
    int pendingCount = 0;

    for (final doc in transactions.docs) {
      final transaction = models.Transaction.fromFirestore(doc);
      if (transaction.status == TransactionStatus.completed) {
        totalEarnings += transaction.amount;
        completedCount++;
      } else if (transaction.status == TransactionStatus.pending ||
          transaction.status == TransactionStatus.fundsHeld ||
          transaction.status == TransactionStatus.delivered) {
        pendingCount++;
      }
    }

    return {
      'totalEarnings': totalEarnings,
      'completedTransactions': completedCount,
      'pendingTransactions': pendingCount,
      'totalTransactions': transactions.size,
    };
  }
}
