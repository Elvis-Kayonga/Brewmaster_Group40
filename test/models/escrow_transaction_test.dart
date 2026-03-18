/// Unit tests for Transaction (Escrow Transaction) model
///
/// Testing patterns:
/// 1. Object creation and instantiation
/// 2. Firestore serialization and deserialization
/// 3. Transaction status transitions
/// 4. Business logic (retry, funds release)
/// 5. Status history tracking
/// 6. Payment method handling
/// 7. Edge cases and validation
///
/// Requirements: 3.1, 3.2, 3.3, 16.1
/// Developer: Developer 2
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:brewmaster/domain/models/escrow_transaction.dart';
import 'package:brewmaster/domain/models/enums.dart';

void main() {
  group('Transaction Model Tests', () {
    late DateTime testDate;
    late FakeFirebaseFirestore firestore;

    setUp(() {
      testDate = DateTime(2024, 1, 15, 10, 30, 0);
      firestore = FakeFirebaseFirestore();
    });

    group('Object Creation Tests', () {
      test('Should create transaction with all required fields', () {
        final transaction = Transaction(
          id: 'txn-001',
          buyerId: 'buyer-123',
          farmerId: 'farmer-456',
          listingId: 'listing-789',
          amount: 15000.0,
          status: TransactionStatus.pending,
          paymentMethod: PaymentMethod.mpesa,
          createdAt: testDate,
        );

        expect(transaction.id, 'txn-001');
        expect(transaction.buyerId, 'buyer-123');
        expect(transaction.farmerId, 'farmer-456');
        expect(transaction.listingId, 'listing-789');
        expect(transaction.amount, 15000.0);
        expect(transaction.status, TransactionStatus.pending);
        expect(transaction.paymentMethod, PaymentMethod.mpesa);
        expect(transaction.createdAt, testDate);
        expect(transaction.retryCount, 0);
        expect(transaction.statusHistory, isEmpty);
      });

      test('Should create transaction with all optional fields', () {
        final fundsDate = testDate.add(const Duration(hours: 1));
        final deliveryDate = testDate.add(const Duration(days: 3));
        final completionDate = testDate.add(const Duration(days: 5));
        final statusHist = {
          'pending': testDate,
          'fundsHeld': fundsDate,
        };

        final transaction = Transaction(
          id: 'txn-complete',
          buyerId: 'buyer-123',
          farmerId: 'farmer-456',
          listingId: 'listing-789',
          amount: 25000.0,
          status: TransactionStatus.completed,
          paymentMethod: PaymentMethod.mpesa,
          createdAt: testDate,
          fundsHeldAt: fundsDate,
          deliveredAt: deliveryDate,
          completedAt: completionDate,
          retryCount: 2,
          statusHistory: statusHist,
        );

        expect(transaction.fundsHeldAt, fundsDate);
        expect(transaction.deliveredAt, deliveryDate);
        expect(transaction.completedAt, completionDate);
        expect(transaction.retryCount, 2);
        expect(transaction.statusHistory.length, 2);
      });

      test('Should create transaction with dispute information', () {
        final transaction = Transaction(
          id: 'txn-disputed',
          buyerId: 'buyer-123',
          farmerId: 'farmer-456',
          listingId: 'listing-789',
          amount: 20000.0,
          status: TransactionStatus.disputed,
          paymentMethod: PaymentMethod.mpesa,
          createdAt: testDate,
          disputeReason: 'Product quality not as described',
        );

        expect(transaction.status, TransactionStatus.disputed);
        expect(transaction.disputeReason, 'Product quality not as described');
      });

      test('Should create transaction with failure information', () {
        final transaction = Transaction(
          id: 'txn-failed',
          buyerId: 'buyer-123',
          farmerId: 'farmer-456',
          listingId: 'listing-789',
          amount: 10000.0,
          status: TransactionStatus.pending,
          paymentMethod: PaymentMethod.mpesa,
          createdAt: testDate,
          retryCount: 3,
          failureReason: 'Insufficient funds',
        );

        expect(transaction.retryCount, 3);
        expect(transaction.failureReason, 'Insufficient funds');
      });

      test('Should handle MTN Mobile Money payment method', () {
        final transaction = Transaction(
          id: 'txn-mtn',
          buyerId: 'buyer-123',
          farmerId: 'farmer-456',
          listingId: 'listing-789',
          amount: 12000.0,
          status: TransactionStatus.pending,
          paymentMethod: PaymentMethod.mtnMobileMoney,
          createdAt: testDate,
        );

        expect(transaction.paymentMethod, PaymentMethod.mtnMobileMoney);
      });
    });

    group('Firestore Serialization Tests', () {
      test('Should convert to Firestore correctly', () {
        final transaction = Transaction(
          id: 'txn-001',
          buyerId: 'buyer-123',
          farmerId: 'farmer-456',
          listingId: 'listing-789',
          amount: 15000.0,
          status: TransactionStatus.fundsHeld,
          paymentMethod: PaymentMethod.mpesa,
          createdAt: testDate,
          fundsHeldAt: testDate.add(const Duration(hours: 1)),
          retryCount: 1,
        );

        final firestoreData = transaction.toFirestore();

        expect(firestoreData['buyerId'], 'buyer-123');
        expect(firestoreData['farmerId'], 'farmer-456');
        expect(firestoreData['listingId'], 'listing-789');
        expect(firestoreData['amount'], 15000.0);
        expect(firestoreData['status'], 'fundsHeld');
        expect(firestoreData['paymentMethod'], 'mpesa');
        expect(firestoreData['createdAt'], isA<Timestamp>());
        expect(firestoreData['fundsHeldAt'], isA<Timestamp>());
        expect(firestoreData['retryCount'], 1);
      });

      test('Should handle null optional fields in Firestore', () {
        final transaction = Transaction(
          id: 'txn-minimal',
          buyerId: 'buyer-123',
          farmerId: 'farmer-456',
          listingId: 'listing-789',
          amount: 15000.0,
          status: TransactionStatus.pending,
          paymentMethod: PaymentMethod.mpesa,
          createdAt: testDate,
        );

        final firestoreData = transaction.toFirestore();

        expect(firestoreData['fundsHeldAt'], isNull);
        expect(firestoreData['deliveredAt'], isNull);
        expect(firestoreData['completedAt'], isNull);
        expect(firestoreData['disputeReason'], isNull);
        expect(firestoreData['failureReason'], isNull);
      });

      test('Should deserialize from Firestore correctly', () async {
        final docRef = firestore.collection('transactions').doc('txn-002');

        await docRef.set({
          'buyerId': 'buyer-999',
          'farmerId': 'farmer-888',
          'listingId': 'listing-777',
          'amount': 30000.0,
          'status': 'completed',
          'paymentMethod': 'mpesa',
          'createdAt': Timestamp.fromDate(testDate),
          'fundsHeldAt': Timestamp.fromDate(testDate.add(const Duration(hours: 2))),
          'deliveredAt': Timestamp.fromDate(testDate.add(const Duration(days: 4))),
          'completedAt': Timestamp.fromDate(testDate.add(const Duration(days: 6))),
          'retryCount': 0,
        });

        final doc = await docRef.get();
        final transaction = Transaction.fromFirestore(doc);

        expect(transaction.id, 'txn-002');
        expect(transaction.buyerId, 'buyer-999');
        expect(transaction.farmerId, 'farmer-888');
        expect(transaction.listingId, 'listing-777');
        expect(transaction.amount, 30000.0);
        expect(transaction.status, TransactionStatus.completed);
        expect(transaction.paymentMethod, PaymentMethod.mpesa);
        expect(transaction.createdAt.year, 2024);
        expect(transaction.fundsHeldAt, isNotNull);
        expect(transaction.deliveredAt, isNotNull);
        expect(transaction.completedAt, isNotNull);
        expect(transaction.retryCount, 0);
      });

      test('Should handle status history in Firestore', () async {
        final statusHist = {
          'pending': Timestamp.fromDate(testDate),
          'fundsHeld': Timestamp.fromDate(testDate.add(const Duration(hours: 1))),
          'delivered': Timestamp.fromDate(testDate.add(const Duration(days: 3))),
        };

        final docRef = firestore.collection('transactions').doc('txn-hist');

        await docRef.set({
          'buyerId': 'buyer-123',
          'farmerId': 'farmer-456',
          'listingId': 'listing-789',
          'amount': 18000.0,
          'status': 'delivered',
          'paymentMethod': 'mtnMobileMoney',
          'createdAt': Timestamp.fromDate(testDate),
          'retryCount': 0,
          'statusHistory': statusHist,
        });

        final doc = await docRef.get();
        final transaction = Transaction.fromFirestore(doc);

        expect(transaction.statusHistory.length, 3);
        expect(transaction.statusHistory.containsKey('pending'), isTrue);
        expect(transaction.statusHistory.containsKey('fundsHeld'), isTrue);
        expect(transaction.statusHistory.containsKey('delivered'), isTrue);
      });

      test('Should roundtrip through Firestore successfully', () async {
        final original = Transaction(
          id: 'txn-roundtrip',
          buyerId: 'buyer-rt',
          farmerId: 'farmer-rt',
          listingId: 'listing-rt',
          amount: 22000.0,
          status: TransactionStatus.fundsHeld,
          paymentMethod: PaymentMethod.mtnMobileMoney,
          createdAt: testDate,
          fundsHeldAt: testDate.add(const Duration(hours: 2)),
          retryCount: 1,
          statusHistory: {
            'pending': testDate,
            'fundsHeld': testDate.add(const Duration(hours: 2)),
          },
        );

        final docRef = firestore.collection('transactions').doc(original.id);
        await docRef.set(original.toFirestore());

        final doc = await docRef.get();
        final restored = Transaction.fromFirestore(doc);

        expect(restored.id, original.id);
        expect(restored.buyerId, original.buyerId);
        expect(restored.farmerId, original.farmerId);
        expect(restored.listingId, original.listingId);
        expect(restored.amount, original.amount);
        expect(restored.status, original.status);
        expect(restored.paymentMethod, original.paymentMethod);
        expect(restored.retryCount, original.retryCount);
        expect(restored.statusHistory.length, original.statusHistory.length);
      });
    });

    group('copyWith Tests', () {
      late Transaction baseTransaction;

      setUp(() {
        baseTransaction = Transaction(
          id: 'txn-base',
          buyerId: 'buyer-123',
          farmerId: 'farmer-456',
          listingId: 'listing-789',
          amount: 20000.0,
          status: TransactionStatus.pending,
          paymentMethod: PaymentMethod.mpesa,
          createdAt: testDate,
          retryCount: 0,
        );
      });

      test('Should copy with new status', () {
        final updated = baseTransaction.copyWith(
          status: TransactionStatus.fundsHeld,
        );

        expect(updated.status, TransactionStatus.fundsHeld);
        expect(updated.id, baseTransaction.id);
        expect(updated.amount, baseTransaction.amount);
      });

      test('Should copy with fundsHeldAt timestamp', () {
        final fundsDate = testDate.add(const Duration(hours: 1));
        final updated = baseTransaction.copyWith(
          status: TransactionStatus.fundsHeld,
          fundsHeldAt: fundsDate,
        );

        expect(updated.status, TransactionStatus.fundsHeld);
        expect(updated.fundsHeldAt, fundsDate);
      });

      test('Should copy with delivery information', () {
        final deliveryDate = testDate.add(const Duration(days: 3));
        final updated = baseTransaction.copyWith(
          status: TransactionStatus.delivered,
          deliveredAt: deliveryDate,
        );

        expect(updated.status, TransactionStatus.delivered);
        expect(updated.deliveredAt, deliveryDate);
      });

      test('Should copy with completion information', () {
        final completionDate = testDate.add(const Duration(days: 5));
        final updated = baseTransaction.copyWith(
          status: TransactionStatus.completed,
          completedAt: completionDate,
        );

        expect(updated.status, TransactionStatus.completed);
        expect(updated.completedAt, completionDate);
      });

      test('Should copy with dispute information', () {
        final updated = baseTransaction.copyWith(
          status: TransactionStatus.disputed,
          disputeReason: 'Quality issue',
        );

        expect(updated.status, TransactionStatus.disputed);
        expect(updated.disputeReason, 'Quality issue');
      });

      test('Should copy with retry count increment', () {
        final updated = baseTransaction.copyWith(retryCount: 1);

        expect(updated.retryCount, 1);
        expect(updated.status, baseTransaction.status);
      });

      test('Should copy with failure reason', () {
        final updated = baseTransaction.copyWith(
          failureReason: 'Payment gateway timeout',
        );

        expect(updated.failureReason, 'Payment gateway timeout');
      });

      test('Should copy with status history update', () {
        final history = {
          'pending': testDate,
          'fundsHeld': testDate.add(const Duration(hours: 1)),
        };

        final updated = baseTransaction.copyWith(statusHistory: history);

        expect(updated.statusHistory.length, 2);
        expect(updated.statusHistory.containsKey('pending'), isTrue);
        expect(updated.statusHistory.containsKey('fundsHeld'), isTrue);
      });

      test('Should copy without changes when no parameters provided', () {
        final updated = baseTransaction.copyWith();

        expect(updated.id, baseTransaction.id);
        expect(updated.status, baseTransaction.status);
        expect(updated.amount, baseTransaction.amount);
        expect(updated.retryCount, baseTransaction.retryCount);
      });
    });

    group('Business Logic - canRetry Tests', () {
      test('Should allow retry when retryCount < 3 and status is pending', () {
        final transaction = Transaction(
          id: 'txn-retry',
          buyerId: 'buyer-123',
          farmerId: 'farmer-456',
          listingId: 'listing-789',
          amount: 15000.0,
          status: TransactionStatus.pending,
          paymentMethod: PaymentMethod.mpesa,
          createdAt: testDate,
          retryCount: 0,
        );

        expect(transaction.canRetry(), isTrue);
      });

      test('Should allow retry at retryCount 1', () {
        final transaction = Transaction(
          id: 'txn-retry1',
          buyerId: 'buyer-123',
          farmerId: 'farmer-456',
          listingId: 'listing-789',
          amount: 15000.0,
          status: TransactionStatus.pending,
          paymentMethod: PaymentMethod.mpesa,
          createdAt: testDate,
          retryCount: 1,
        );

        expect(transaction.canRetry(), isTrue);
      });

      test('Should allow retry at retryCount 2', () {
        final transaction = Transaction(
          id: 'txn-retry2',
          buyerId: 'buyer-123',
          farmerId: 'farmer-456',
          listingId: 'listing-789',
          amount: 15000.0,
          status: TransactionStatus.pending,
          paymentMethod: PaymentMethod.mpesa,
          createdAt: testDate,
          retryCount: 2,
        );

        expect(transaction.canRetry(), isTrue);
      });

      test('Should not allow retry at retryCount 3', () {
        final transaction = Transaction(
          id: 'txn-max-retry',
          buyerId: 'buyer-123',
          farmerId: 'farmer-456',
          listingId: 'listing-789',
          amount: 15000.0,
          status: TransactionStatus.pending,
          paymentMethod: PaymentMethod.mpesa,
          createdAt: testDate,
          retryCount: 3,
        );

        expect(transaction.canRetry(), isFalse);
      });

      test('Should not allow retry when status is not pending', () {
        final statuses = [
          TransactionStatus.fundsHeld,
          TransactionStatus.delivered,
          TransactionStatus.completed,
          TransactionStatus.disputed,
          TransactionStatus.cancelled,
        ];

        for (final status in statuses) {
          final transaction = Transaction(
            id: 'txn-${status.name}',
            buyerId: 'buyer-123',
            farmerId: 'farmer-456',
            listingId: 'listing-789',
            amount: 15000.0,
            status: status,
            paymentMethod: PaymentMethod.mpesa,
            createdAt: testDate,
            retryCount: 0,
          );

          expect(
            transaction.canRetry(),
            isFalse,
            reason: 'Should not retry for status ${status.name}',
          );
        }
      });
    });

    group('Business Logic - canReleaseFunds Tests', () {
      test('Should allow funds release when delivered with fundsHeldAt', () {
        final transaction = Transaction(
          id: 'txn-release',
          buyerId: 'buyer-123',
          farmerId: 'farmer-456',
          listingId: 'listing-789',
          amount: 25000.0,
          status: TransactionStatus.delivered,
          paymentMethod: PaymentMethod.mpesa,
          createdAt: testDate,
          fundsHeldAt: testDate.add(const Duration(hours: 1)),
          deliveredAt: testDate.add(const Duration(days: 3)),
        );

        expect(transaction.canReleaseFunds(), isTrue);
      });

      test('Should not allow funds release if not delivered', () {
        final transaction = Transaction(
          id: 'txn-not-delivered',
          buyerId: 'buyer-123',
          farmerId: 'farmer-456',
          listingId: 'listing-789',
          amount: 25000.0,
          status: TransactionStatus.fundsHeld,
          paymentMethod: PaymentMethod.mpesa,
          createdAt: testDate,
          fundsHeldAt: testDate.add(const Duration(hours: 1)),
        );

        expect(transaction.canReleaseFunds(), isFalse);
      });

      test('Should not allow funds release if fundsHeldAt is null', () {
        final transaction = Transaction(
          id: 'txn-no-held-date',
          buyerId: 'buyer-123',
          farmerId: 'farmer-456',
          listingId: 'listing-789',
          amount: 25000.0,
          status: TransactionStatus.delivered,
          paymentMethod: PaymentMethod.mpesa,
          createdAt: testDate,
          deliveredAt: testDate.add(const Duration(days: 3)),
        );

        expect(transaction.canReleaseFunds(), isFalse);
      });

      test('Should not allow funds release if already completed', () {
        final transaction = Transaction(
          id: 'txn-completed',
          buyerId: 'buyer-123',
          farmerId: 'farmer-456',
          listingId: 'listing-789',
          amount: 25000.0,
          status: TransactionStatus.delivered,
          paymentMethod: PaymentMethod.mpesa,
          createdAt: testDate,
          fundsHeldAt: testDate.add(const Duration(hours: 1)),
          deliveredAt: testDate.add(const Duration(days: 3)),
          completedAt: testDate.add(const Duration(days: 5)),
        );

        expect(transaction.canReleaseFunds(), isFalse);
      });

      test('Should not allow funds release for disputed transactions', () {
        final transaction = Transaction(
          id: 'txn-disputed',
          buyerId: 'buyer-123',
          farmerId: 'farmer-456',
          listingId: 'listing-789',
          amount: 25000.0,
          status: TransactionStatus.disputed,
          paymentMethod: PaymentMethod.mpesa,
          createdAt: testDate,
          fundsHeldAt: testDate.add(const Duration(hours: 1)),
          disputeReason: 'Quality issue',
        );

        expect(transaction.canReleaseFunds(), isFalse);
      });

      test('Should not allow funds release for cancelled transactions', () {
        final transaction = Transaction(
          id: 'txn-cancelled',
          buyerId: 'buyer-123',
          farmerId: 'farmer-456',
          listingId: 'listing-789',
          amount: 25000.0,
          status: TransactionStatus.cancelled,
          paymentMethod: PaymentMethod.mpesa,
          createdAt: testDate,
          fundsHeldAt: testDate.add(const Duration(hours: 1)),
        );

        expect(transaction.canReleaseFunds(), isFalse);
      });
    });

    group('Transaction Status Flow Tests', () {
      test('Should simulate complete transaction flow', () {
        // 1. Create pending transaction
        var transaction = Transaction(
          id: 'txn-flow',
          buyerId: 'buyer-123',
          farmerId: 'farmer-456',
          listingId: 'listing-789',
          amount: 30000.0,
          status: TransactionStatus.pending,
          paymentMethod: PaymentMethod.mpesa,
          createdAt: testDate,
        );

        expect(transaction.status, TransactionStatus.pending);

        // 2. Funds held
        transaction = transaction.copyWith(
          status: TransactionStatus.fundsHeld,
          fundsHeldAt: testDate.add(const Duration(hours: 1)),
        );

        expect(transaction.status, TransactionStatus.fundsHeld);
        expect(transaction.fundsHeldAt, isNotNull);

        // 3. Delivered
        transaction = transaction.copyWith(
          status: TransactionStatus.delivered,
          deliveredAt: testDate.add(const Duration(days: 3)),
        );

        expect(transaction.status, TransactionStatus.delivered);
        expect(transaction.canReleaseFunds(), isTrue);

        // 4. Completed
        transaction = transaction.copyWith(
          status: TransactionStatus.completed,
          completedAt: testDate.add(const Duration(days: 5)),
        );

        expect(transaction.status, TransactionStatus.completed);
        expect(transaction.canReleaseFunds(), isFalse);
      });

      test('Should simulate transaction with retries', () {
        var transaction = Transaction(
          id: 'txn-retries',
          buyerId: 'buyer-123',
          farmerId: 'farmer-456',
          listingId: 'listing-789',
          amount: 15000.0,
          status: TransactionStatus.pending,
          paymentMethod: PaymentMethod.mpesa,
          createdAt: testDate,
          retryCount: 0,
        );

        expect(transaction.canRetry(), isTrue);

        // First retry
        transaction = transaction.copyWith(retryCount: 1);
        expect(transaction.canRetry(), isTrue);

        // Second retry
        transaction = transaction.copyWith(retryCount: 2);
        expect(transaction.canRetry(), isTrue);

        // Third retry - max reached
        transaction = transaction.copyWith(retryCount: 3);
        expect(transaction.canRetry(), isFalse);
      });

      test('Should simulate disputed transaction', () {
        var transaction = Transaction(
          id: 'txn-dispute-flow',
          buyerId: 'buyer-123',
          farmerId: 'farmer-456',
          listingId: 'listing-789',
          amount: 20000.0,
          status: TransactionStatus.fundsHeld,
          paymentMethod: PaymentMethod.mpesa,
          createdAt: testDate,
          fundsHeldAt: testDate.add(const Duration(hours: 1)),
        );

        // Buyer opens dispute
        transaction = transaction.copyWith(
          status: TransactionStatus.disputed,
          disputeReason: 'Product not as described',
        );

        expect(transaction.status, TransactionStatus.disputed);
        expect(transaction.disputeReason, isNotNull);
        expect(transaction.canReleaseFunds(), isFalse);
      });
    });

    group('Edge Cases and Validation Tests', () {
      test('Should handle very small transaction amounts', () {
        final transaction = Transaction(
          id: 'txn-small',
          buyerId: 'buyer-123',
          farmerId: 'farmer-456',
          listingId: 'listing-789',
          amount: 0.01,
          status: TransactionStatus.pending,
          paymentMethod: PaymentMethod.mpesa,
          createdAt: testDate,
        );

        expect(transaction.amount, 0.01);
      });

      test('Should handle very large transaction amounts', () {
        final transaction = Transaction(
          id: 'txn-large',
          buyerId: 'buyer-123',
          farmerId: 'farmer-456',
          listingId: 'listing-789',
          amount: 999999999.99,
          status: TransactionStatus.pending,
          paymentMethod: PaymentMethod.mpesa,
          createdAt: testDate,
        );

        expect(transaction.amount, 999999999.99);
      });

      test('Should handle decimal amounts', () {
        final transaction = Transaction(
          id: 'txn-decimal',
          buyerId: 'buyer-123',
          farmerId: 'farmer-456',
          listingId: 'listing-789',
          amount: 15678.45,
          status: TransactionStatus.pending,
          paymentMethod: PaymentMethod.mpesa,
          createdAt: testDate,
        );

        expect(transaction.amount, 15678.45);
      });

      test('Should handle empty status history', () {
        final transaction = Transaction(
          id: 'txn-no-history',
          buyerId: 'buyer-123',
          farmerId: 'farmer-456',
          listingId: 'listing-789',
          amount: 20000.0,
          status: TransactionStatus.pending,
          paymentMethod: PaymentMethod.mpesa,
          createdAt: testDate,
        );

        expect(transaction.statusHistory, isEmpty);
      });

      test('Should handle extensive status history', () {
        final history = {
          'pending': testDate,
          'fundsHeld': testDate.add(const Duration(hours: 1)),
          'disputed': testDate.add(const Duration(hours: 2)),
          'delivered': testDate.add(const Duration(days: 5)),
          'completed': testDate.add(const Duration(days: 7)),
        };

        final transaction = Transaction(
          id: 'txn-extensive-history',
          buyerId: 'buyer-123',
          farmerId: 'farmer-456',
          listingId: 'listing-789',
          amount: 20000.0,
          status: TransactionStatus.completed,
          paymentMethod: PaymentMethod.mpesa,
          createdAt: testDate,
          statusHistory: history,
        );

        expect(transaction.statusHistory.length, 5);
        expect(transaction.statusHistory.keys, contains('disputed'));
      });

      test('Should handle very long dispute reasons', () {
        final longReason = 'A' * 500;

        final transaction = Transaction(
          id: 'txn-long-reason',
          buyerId: 'buyer-123',
          farmerId: 'farmer-456',
          listingId: 'listing-789',
          amount: 20000.0,
          status: TransactionStatus.disputed,
          paymentMethod: PaymentMethod.mpesa,
          createdAt: testDate,
          disputeReason: longReason,
        );

        expect(transaction.disputeReason!.length, 500);
      });
    });
  });
}
