import 'package:flutter/foundation.dart';
import '../../domain/models/transaction.dart' as models;
import '../../domain/models/enums.dart';
import '../../domain/services/payment_service.dart';

/// Provider for managing payment state
class PaymentProvider extends ChangeNotifier {
  final PaymentService _paymentService;

  PaymentProvider({PaymentService? paymentService})
      : _paymentService = paymentService ?? PaymentService();

  // State variables
  bool _isLoading = false;
  String? _error;
  models.Transaction? _currentTransaction;
  List<models.Transaction> _transactions = [];
  Map<String, dynamic>? _statistics;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  models.Transaction? get currentTransaction => _currentTransaction;
  List<models.Transaction> get transactions => _transactions;
  Map<String, dynamic>? get statistics => _statistics;

  /// Create a new payment transaction
  Future<models.Transaction?> createTransaction({
    required String buyerId,
    required String farmerId,
    required String listingId,
    required double amount,
    required PaymentMethod paymentMethod,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final transaction = await _paymentService.createTransaction(
        buyerId: buyerId,
        farmerId: farmerId,
        listingId: listingId,
        amount: amount,
        paymentMethod: paymentMethod,
      );

      _currentTransaction = transaction;
      notifyListeners();
      return transaction;
    } catch (e) {
      _setError('Failed to create transaction: ${e.toString()}');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Process payment for a transaction
  Future<bool> processPayment(String transactionId) async {
    _setLoading(true);
    _clearError();

    try {
      final transaction = await _paymentService.processPayment(transactionId);
      _currentTransaction = transaction;
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Payment failed: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Confirm delivery
  Future<bool> confirmDelivery(String transactionId) async {
    _setLoading(true);
    _clearError();

    try {
      final transaction =
          await _paymentService.confirmDelivery(transactionId);
      _currentTransaction = transaction;
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to confirm delivery: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Confirm receipt and release funds
  Future<bool> confirmReceiptAndReleaseFunds(String transactionId) async {
    _setLoading(true);
    _clearError();

    try {
      final transaction =
          await _paymentService.confirmReceiptAndReleaseFunds(transactionId);
      _currentTransaction = transaction;
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to release funds: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Raise a dispute
  Future<bool> raiseDispute(String transactionId, String reason) async {
    _setLoading(true);
    _clearError();

    try {
      final transaction =
          await _paymentService.raiseDispute(transactionId, reason);
      _currentTransaction = transaction;
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to raise dispute: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Cancel a transaction
  Future<bool> cancelTransaction(String transactionId) async {
    _setLoading(true);
    _clearError();

    try {
      final transaction =
          await _paymentService.cancelTransaction(transactionId);
      _currentTransaction = transaction;
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to cancel transaction: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Get transaction by ID
  Future<void> loadTransaction(String transactionId) async {
    _setLoading(true);
    _clearError();

    try {
      final transaction = await _paymentService.getTransaction(transactionId);
      _currentTransaction = transaction;
      notifyListeners();
    } catch (e) {
      _setError('Failed to load transaction: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Subscribe to user transactions
  void subscribeToUserTransactions(String userId) {
    _paymentService.getUserTransactions(userId).listen(
      (transactions) {
        _transactions = transactions;
        notifyListeners();
      },
      onError: (error) {
        _setError('Failed to load transactions: ${error.toString()}');
      },
    );
  }

  /// Load user statistics
  Future<void> loadUserStatistics(String userId) async {
    try {
      _statistics = await _paymentService.getUserStatistics(userId);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load statistics: ${e.toString()}');
    }
  }

  /// Filter transactions by status
  List<models.Transaction> getTransactionsByStatus(TransactionStatus status) {
    return _transactions.where((t) => t.status == status).toList();
  }

  /// Get pending transactions count
  int get pendingTransactionsCount {
    return _transactions
        .where((t) =>
            t.status == TransactionStatus.pending ||
            t.status == TransactionStatus.fundsHeld ||
            t.status == TransactionStatus.delivered)
        .length;
  }

  /// Get completed transactions count
  int get completedTransactionsCount {
    return _transactions
        .where((t) => t.status == TransactionStatus.completed)
        .length;
  }

  /// Calculate total earnings from completed transactions
  double get totalEarnings {
    return _transactions
        .where((t) => t.status == TransactionStatus.completed)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  /// Helper methods
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _error = message;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  /// Clear current transaction
  void clearCurrentTransaction() {
    _currentTransaction = null;
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _clearError();
    notifyListeners();
  }
}
