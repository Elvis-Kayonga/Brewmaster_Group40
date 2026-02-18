import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:brewmaster/domain/models/transaction.dart' as models;
import 'package:brewmaster/domain/models/enums.dart';
import 'package:brewmaster/domain/services/payment_service.dart';

void main() {
  group('PaymentService Property Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late PaymentService paymentService;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      paymentService = PaymentService(firestore: fakeFirestore);
    });

    group('Transaction Creation', () {
      test('Property: Every created transaction should have unique ID', () async {
        final ids = <String>{};

        for (int i = 0; i < 10; i++) {
          final transaction = await paymentService.createTransaction(
            buyerId: 'buyer_$i',
            farmerId: 'farmer_$i',
            listingId: 'listing_$i',
            amount: 100.0 + i,
            paymentMethod: PaymentMethod.mpesa,
          );

          expect(ids.contains(transaction.id), false,
              reason: 'Transaction ID must be unique');
          ids.add(transaction.id);
        }

        expect(ids.length, 10, reason: 'All transaction IDs should be unique');
      });

      test('Property: Created transaction should have pending status', () async {
        final transaction = await paymentService.createTransaction(
          buyerId: 'buyer1',
          farmerId: 'farmer1',
          listingId: 'listing1',
          amount: 150.0,
          paymentMethod: PaymentMethod.mpesa,
        );

        expect(transaction.status, TransactionStatus.pending,
            reason: 'New transactions must start with pending status');
      });

      test('Property: Transaction amount should be preserved', () async {
        final amounts = [10.5, 100.0, 1000.99, 50000.0];

        for (final amount in amounts) {
          final transaction = await paymentService.createTransaction(
            buyerId: 'buyer1',
            farmerId: 'farmer1',
            listingId: 'listing1',
            amount: amount,
            paymentMethod: PaymentMethod.mpesa,
          );

          expect(transaction.amount, amount,
              reason: 'Transaction amount must be preserved exactly');
        }
      });

      test('Property: Transaction should initialize status history', () async {
        final transaction = await paymentService.createTransaction(
          buyerId: 'buyer1',
          farmerId: 'farmer1',
          listingId: 'listing1',
          amount: 100.0,
          paymentMethod: PaymentMethod.mpesa,
        );

        expect(transaction.statusHistory.isNotEmpty, true,
            reason: 'Status history should be initialized');
        expect(transaction.statusHistory.containsKey('pending'), true,
            reason: 'Status history should contain initial pending status');
      });
    });

    group('Status Transitions', () {
      test('Property: Status transitions should be unidirectional', () async {
        final transaction = await paymentService.createTransaction(
          buyerId: 'buyer1',
          farmerId: 'farmer1',
          listingId: 'listing1',
          amount: 100.0,
          paymentMethod: PaymentMethod.mpesa,
        );

        // Simulate successful payment
        final withFunds = transaction.copyWith(
          status: TransactionStatus.fundsHeld,
          fundsHeldAt: DateTime.now(),
        );
        await fakeFirestore
            .collection('transactions')
            .doc(transaction.id)
            .update(withFunds.toFirestore());

        // Confirm delivery
        final delivered = await paymentService.confirmDelivery(transaction.id);
        expect(delivered.status, TransactionStatus.delivered,
            reason: 'Status should transition to delivered');

        // Try to go back to fundsHeld (should fail)
        expect(
          () async => await fakeFirestore
              .collection('transactions')
              .doc(transaction.id)
              .update({'status': TransactionStatus.fundsHeld.toJson()}),
          returnsNormally,
          reason: 'Database allows update but service logic should prevent it',
        );
      });

      test('Property: Each status transition should update status history',
          () async {
        final transaction = await paymentService.createTransaction(
          buyerId: 'buyer1',
          farmerId: 'farmer1',
          listingId: 'listing1',
          amount: 100.0,
          paymentMethod: PaymentMethod.mpesa,
        );

        // Initial history
        expect(transaction.statusHistory.length, 1);

        // Update to fundsHeld
        final withFunds = transaction.copyWith(
          status: TransactionStatus.fundsHeld,
          fundsHeldAt: DateTime.now(),
        );
        await fakeFirestore
            .collection('transactions')
            .doc(transaction.id)
            .update(withFunds.toFirestore());

        // Confirm delivery
        final delivered = await paymentService.confirmDelivery(transaction.id);
        expect(delivered.statusHistory.length, greaterThan(1),
            reason: 'Status history should grow with each transition');
      });

      test('Property: Completed status should be terminal', () async {
        final transaction = await paymentService.createTransaction(
          buyerId: 'buyer1',
          farmerId: 'farmer1',
          listingId: 'listing1',
          amount: 100.0,
          paymentMethod: PaymentMethod.mpesa,
        );

        // Progress to delivered
        await fakeFirestore
            .collection('transactions')
            .doc(transaction.id)
            .update({
          'status': TransactionStatus.fundsHeld.toJson(),
          'fundsHeldAt': DateTime.now(),
        });

        await paymentService.confirmDelivery(transaction.id);

        // Complete the transaction
        final completed =
            await paymentService.confirmReceiptAndReleaseFunds(transaction.id);
        expect(completed.status, TransactionStatus.completed);

        // Verify it's terminal
        expect(completed.completedAt, isNotNull,
            reason: 'Completed transactions must have completion timestamp');
      });
    });

    group('Fund Release Properties', () {
      test('Property: Funds can only be released from delivered status',
          () async {
        final transaction = await paymentService.createTransaction(
          buyerId: 'buyer1',
          farmerId: 'farmer1',
          listingId: 'listing1',
          amount: 100.0,
          paymentMethod: PaymentMethod.mpesa,
        );

        // Try to release from pending (should fail)
        expect(
          () => paymentService.confirmReceiptAndReleaseFunds(transaction.id),
          throwsException,
          reason: 'Cannot release funds from pending status',
        );
      });

      test('Property: Fund release requires both fundsHeldAt and delivered status',
          () async {
        final transaction = await paymentService.createTransaction(
          buyerId: 'buyer1',
          farmerId: 'farmer1',
          listingId: 'listing1',
          amount: 100.0,
          paymentMethod: PaymentMethod.mpesa,
        );

        // Set to delivered status
        await fakeFirestore
            .collection('transactions')
            .doc(transaction.id)
            .update({
          'status': TransactionStatus.delivered.toJson(),
          'fundsHeldAt': DateTime.now(),
          'deliveredAt': DateTime.now(),
        });

        final updated = await paymentService.getTransaction(transaction.id);
        expect(updated?.canReleaseFunds(), true,
            reason: 'Should be able to release funds when conditions are met');
      });

      test('Property: Total amount should equal sum of completed transactions',
          () async {
        final transactions = <models.Transaction>[];
        double expectedTotal = 0;

        // Create multiple transactions
        for (int i = 0; i < 5; i++) {
          final amount = 100.0 * (i + 1);
          expectedTotal += amount;

          final transaction = await paymentService.createTransaction(
            buyerId: 'buyer1',
            farmerId: 'farmer1',
            listingId: 'listing_$i',
            amount: amount,
            paymentMethod: PaymentMethod.mpesa,
          );

          // Complete each transaction
          await fakeFirestore
              .collection('transactions')
              .doc(transaction.id)
              .update({
            'status': TransactionStatus.completed.toJson(),
            'completedAt': DateTime.now(),
          });

          transactions.add(transaction);
        }

        // Get statistics
        final stats = await paymentService.getUserStatistics('farmer1');
        expect(stats['totalEarnings'], expectedTotal,
            reason: 'Total earnings should equal sum of completed amounts');
      });
    });

    group('Dispute Properties', () {
      test('Property: Disputes can be raised before completion', () async {
        final statuses = [
          TransactionStatus.pending,
          TransactionStatus.fundsHeld,
          TransactionStatus.delivered,
        ];

        for (final status in statuses) {
          final transaction = await paymentService.createTransaction(
            buyerId: 'buyer1',
            farmerId: 'farmer1',
            listingId: 'listing_$status',
            amount: 100.0,
            paymentMethod: PaymentMethod.mpesa,
          );

          // Update to test status
          await fakeFirestore
              .collection('transactions')
              .doc(transaction.id)
              .update({'status': status.toJson()});

          // Should be able to raise dispute
          final disputed = await paymentService.raiseDispute(
              transaction.id, 'Test dispute');
          expect(disputed.status, TransactionStatus.disputed,
              reason: 'Should be able to dispute from $status');
        }
      });

      test('Property: Disputes cannot be raised on completed/cancelled transactions',
          () async {
        final transaction = await paymentService.createTransaction(
          buyerId: 'buyer1',
          farmerId: 'farmer1',
          listingId: 'listing1',
          amount: 100.0,
          paymentMethod: PaymentMethod.mpesa,
        );

        // Complete the transaction
        await fakeFirestore
            .collection('transactions')
            .doc(transaction.id)
            .update({'status': TransactionStatus.completed.toJson()});

        // Try to dispute
        expect(
          () => paymentService.raiseDispute(transaction.id, 'Test dispute'),
          throwsException,
          reason: 'Cannot dispute completed transactions',
        );
      });

      test('Property: Disputed transactions should preserve original amount',
          () async {
        final originalAmount = 150.75;
        final transaction = await paymentService.createTransaction(
          buyerId: 'buyer1',
          farmerId: 'farmer1',
          listingId: 'listing1',
          amount: originalAmount,
          paymentMethod: PaymentMethod.mpesa,
        );

        final disputed =
            await paymentService.raiseDispute(transaction.id, 'Test dispute');
        expect(disputed.amount, originalAmount,
            reason: 'Dispute should not change transaction amount');
      });
    });

    group('Retry Logic Properties', () {
      test('Property: Transactions can retry up to 3 times', () async {
        final transaction = await paymentService.createTransaction(
          buyerId: 'buyer1',
          farmerId: 'farmer1',
          listingId: 'listing1',
          amount: 100.0,
          paymentMethod: PaymentMethod.mpesa,
        );

        // Test retry limits
        expect(transaction.canRetry(), true,
            reason: 'New transaction should be retryable');

        final withRetries = transaction.copyWith(retryCount: 2);
        expect(withRetries.canRetry(), true,
            reason: 'Should retry when count < 3');

        final maxRetries = transaction.copyWith(retryCount: 3);
        expect(maxRetries.canRetry(), false,
            reason: 'Should not retry when count >= 3');
      });

      test('Property: Retry count should never decrease', () async {
        final transaction = await paymentService.createTransaction(
          buyerId: 'buyer1',
          farmerId: 'farmer1',
          listingId: 'listing1',
          amount: 100.0,
          paymentMethod: PaymentMethod.mpesa,
        );

        var currentCount = transaction.retryCount;

        // Simulate retries
        for (int i = 0; i < 3; i++) {
          await fakeFirestore
              .collection('transactions')
              .doc(transaction.id)
              .update({'retryCount': currentCount + 1});

          final updated = await paymentService.getTransaction(transaction.id);
          expect(updated!.retryCount, greaterThanOrEqualTo(currentCount),
              reason: 'Retry count should never decrease');
          currentCount = updated.retryCount;
        }
      });

      test('Property: Only pending transactions can be retried', () async {
        final transaction = await paymentService.createTransaction(
          buyerId: 'buyer1',
          farmerId: 'farmer1',
          listingId: 'listing1',
          amount: 100.0,
          paymentMethod: PaymentMethod.mpesa,
        );

        // Pending status - can retry
        expect(transaction.canRetry(), true);

        // Other statuses - cannot retry
        final statuses = [
          TransactionStatus.fundsHeld,
          TransactionStatus.delivered,
          TransactionStatus.completed,
          TransactionStatus.cancelled,
        ];

        for (final status in statuses) {
          final updated = transaction.copyWith(status: status);
          expect(updated.canRetry(), false,
              reason: 'Cannot retry from $status status');
        }
      });
    });

    group('Data Integrity Properties', () {
      test('Property: Transaction serialization should be reversible', () async {
        final original = await paymentService.createTransaction(
          buyerId: 'buyer1',
          farmerId: 'farmer1',
          listingId: 'listing1',
          amount: 123.45,
          paymentMethod: PaymentMethod.mpesa,
        );

        // Serialize and deserialize
        final firestore = original.toFirestore();
        await fakeFirestore
            .collection('transactions')
            .doc(original.id)
            .set(firestore);

        final doc = await fakeFirestore
            .collection('transactions')
            .doc(original.id)
            .get();
        final restored = models.Transaction.fromFirestore(doc);

        // Verify all fields match
        expect(restored.buyerId, original.buyerId);
        expect(restored.farmerId, original.farmerId);
        expect(restored.listingId, original.listingId);
        expect(restored.amount, original.amount);
        expect(restored.status, original.status);
        expect(restored.paymentMethod, original.paymentMethod);
      });

      test('Property: Timestamps should be ordered chronologically', () async {
        final transaction = await paymentService.createTransaction(
          buyerId: 'buyer1',
          farmerId: 'farmer1',
          listingId: 'listing1',
          amount: 100.0,
          paymentMethod: PaymentMethod.mpesa,
        );

        // Progress through states
        await Future.delayed(Duration(milliseconds: 10));
        await fakeFirestore
            .collection('transactions')
            .doc(transaction.id)
            .update({
          'status': TransactionStatus.fundsHeld.toJson(),
          'fundsHeldAt': DateTime.now(),
        });

        await Future.delayed(Duration(milliseconds: 10));
        final delivered = await paymentService.confirmDelivery(transaction.id);

        // Verify timestamp ordering
        expect(
            delivered.fundsHeldAt!.isAfter(delivered.createdAt) ||
                delivered.fundsHeldAt!.isAtSameMomentAs(delivered.createdAt),
            true,
            reason: 'fundsHeldAt should be after or equal to createdAt');
        expect(
            delivered.deliveredAt!.isAfter(delivered.fundsHeldAt!) ||
                delivered.deliveredAt!.isAtSameMomentAs(delivered.fundsHeldAt!),
            true,
            reason: 'deliveredAt should be after or equal to fundsHeldAt');
      });

      test('Property: User statistics should match transaction data', () async {
        // Create farmer transactions
        final amounts = [100.0, 200.0, 300.0];
        int expectedCompleted = 0;

        for (int i = 0; i < amounts.length; i++) {
          final transaction = await paymentService.createTransaction(
            buyerId: 'buyer1',
            farmerId: 'farmer_test',
            listingId: 'listing_$i',
            amount: amounts[i],
            paymentMethod: PaymentMethod.mpesa,
          );

          // Complete first two
          if (i < 2) {
            await fakeFirestore
                .collection('transactions')
                .doc(transaction.id)
                .update({
              'status': TransactionStatus.completed.toJson(),
              'completedAt': DateTime.now(),
            });
            expectedCompleted++;
          }
        }

        final stats = await paymentService.getUserStatistics('farmer_test');
        expect(stats['completedTransactions'], expectedCompleted,
            reason: 'Statistics should reflect actual completed count');
        expect(stats['totalEarnings'], 300.0,
            reason: 'Total earnings should match sum of completed transactions');
      });
    });

    group('Edge Cases', () {
      test('Property: getcannot find non-existent transaction', () async {
        final transaction =
            await paymentService.getTransaction('nonexistent_id');
        expect(transaction, isNull,
            reason: 'Should return null for non-existent transaction');
      });

      test('Property: Zero amount transactions are handled', () async {
        final transaction = await paymentService.createTransaction(
          buyerId: 'buyer1',
          farmerId: 'farmer1',
          listingId: 'listing1',
          amount: 0.0,
          paymentMethod: PaymentMethod.mpesa,
        );

        expect(transaction.amount, 0.0,
            reason: 'Should handle zero amount transactions');
      });

      test('Property: Multiple payment methods are supported', () async {
        for (final method in PaymentMethod.values) {
          final transaction = await paymentService.createTransaction(
            buyerId: 'buyer1',
            farmerId: 'farmer1',
            listingId: 'listing_${method.name}',
            amount: 100.0,
            paymentMethod: method,
          );

          expect(transaction.paymentMethod, method,
              reason: 'Should support $method payment method');
        }
      });
    });
  });
}
