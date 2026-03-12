import 'package:brewmaster/domain/models/escrow_transaction.dart';
import 'package:brewmaster/domain/models/enums.dart';
import 'package:brewmaster/domain/models/paginated_result.dart';

/// Abstract interface for escrow payment operations.
abstract class PaymentRepository {
  /// Create a new pending escrow transaction.
  Future<Transaction> createTransaction({
    required String buyerId,
    required String farmerId,
    required String listingId,
    required double amount,
    required PaymentMethod paymentMethod,
  });

  /// Process payment for a transaction (moves to fundsHeld on success).
  Future<Transaction> processPayment(String transactionId);

  /// Confirm delivery by the farmer (moves to delivered).
  Future<Transaction> confirmDelivery(String transactionId);

  /// Confirm receipt by the buyer and release escrow funds (moves to completed).
  Future<Transaction> confirmReceiptAndReleaseFunds(String transactionId);

  /// Raise a dispute on a transaction.
  Future<Transaction> raiseDispute(String transactionId, String reason);

  /// Cancel a pending transaction.
  Future<Transaction> cancelTransaction(String transactionId);

  /// Fetch a single transaction by ID.
  Future<Transaction?> getTransaction(String transactionId);

  /// Real-time stream of all transactions for a user (buyer or farmer).
  Stream<List<Transaction>> getUserTransactions(String userId);

  /// Real-time stream of all transactions for a listing.
  Stream<List<Transaction>> getListingTransactions(String listingId);

  /// Fetch aggregated statistics for a farmer user.
  Future<Map<String, dynamic>> getUserStatistics(String userId);

  /// Paginated fetch of transactions for [userId] ordered by createdAt
  /// descending. Pass [startAfter] from [PaginatedResult.cursor] for the
  /// next page.
  Future<PaginatedResult<Transaction>> getTransactionPage({
    required String userId,
    int pageSize = 20,
    Object? startAfter,
  });
}
