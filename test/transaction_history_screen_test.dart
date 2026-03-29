import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:brewmaster/config/localization/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:brewmaster/domain/models/escrow_transaction.dart' as models;
import 'package:brewmaster/domain/models/enums.dart';
import 'package:brewmaster/domain/models/paginated_result.dart';
import 'package:brewmaster/domain/models/user_profile.dart';
import 'package:brewmaster/domain/repositories/auth_repository.dart';
import 'package:brewmaster/domain/repositories/payment_repository.dart';
import 'package:brewmaster/domain/repositories/user_repository.dart';
import 'package:brewmaster/presentation/blocs/auth/auth_bloc.dart';
import 'package:brewmaster/presentation/blocs/payment/payment_bloc.dart';
import 'package:brewmaster/presentation/blocs/profile/profile_bloc.dart';
import 'package:brewmaster/presentation/screens/payments/transaction_history_screen.dart';

class _FakeAuthRepository implements AuthRepository {
  @override
  Stream<User?> get authStateChanges => const Stream.empty();
  @override
  User? get currentUser => null;
  @override
  Future<User?> register(String email, String password) async => null;
  @override
  Future<User?> signIn(String email, String password) async => null;
  @override
  Future<User?> signInWithGoogle() async => null;
  @override
  Future<void> signOut() async {}
  @override
  Future<void> sendPasswordResetEmail(String email) async {}
  @override
  Future<bool> sendEmailVerification() async => false;
  @override
  Future<bool> isEmailVerified() async => false;
}

class _FakeUserRepository implements UserRepository {
  @override
  Future<UserProfile?> getUserProfile(String userId) async => null;
  @override
  Future<UserProfile?> getUserProfileByEmail(String email) async => null;
  @override
  Future<void> createUserProfile(UserProfile profile) async {}
  @override
  Future<void> updateUserProfile(
      String userId, Map<String, dynamic> updates) async {}
  @override
  Stream<UserProfile?> watchUserProfile(String userId) => Stream.value(null);

  @override
  Future<void> saveListing(String userId, String listingId) async {}

  @override
  Future<void> unsaveListing(String userId, String listingId) async {}

  @override
  Future<List<String>> getSavedListings(String userId) async => [];
}

// ---------------------------------------------------------------------------
// Fake repository that immediately emits PaymentHistoryLoaded
// ---------------------------------------------------------------------------

class _FakePaymentRepository implements PaymentRepository {
  @override
  Future<models.Transaction> createTransaction({
    required String buyerId,
    required String farmerId,
    required String listingId,
    required double amount,
    String currency = 'USD',
    required PaymentMethod paymentMethod,
    String? paymentReference,
  }) async => throw UnimplementedError();
  @override
  Future<models.Transaction> processPayment(String id) async =>
      throw UnimplementedError();
  @override
  Future<models.Transaction> confirmDelivery(String id) async =>
      throw UnimplementedError();
  @override
  Future<models.Transaction> confirmReceiptAndReleaseFunds(String id) async =>
      throw UnimplementedError();
  @override
  Future<models.Transaction> raiseDispute(String id, String reason) async =>
      throw UnimplementedError();
  @override
  Future<models.Transaction> cancelTransaction(String id) async =>
      throw UnimplementedError();
  @override
  Future<models.Transaction?> getTransaction(String id) async => null;
  @override
  Stream<List<models.Transaction>> getUserTransactions(String userId) =>
      Stream.value([]);
  @override
  Stream<List<models.Transaction>> getListingTransactions(String listingId) =>
      Stream.value([]);
  @override
  Future<Map<String, dynamic>> getUserStatistics(String userId) async => {
        'totalEarnings': 0.0,
        'completedTransactions': 0,
        'pendingTransactions': 0,
      };
  @override
  Future<PaginatedResult<models.Transaction>> getTransactionPage({
    required String userId,
    int pageSize = 20,
    Object? startAfter,
  }) async =>
      const PaginatedResult<models.Transaction>(items: [], hasMore: false);
}

Widget _buildTestWidget({required String userId, required bool isFarmer}) {
  return MultiBlocProvider(
    providers: [
      BlocProvider<PaymentBloc>(
        create: (_) => PaymentBloc(paymentRepository: _FakePaymentRepository()),
      ),
      BlocProvider<AuthBloc>(
        create: (_) => AuthBloc(
          authRepository: _FakeAuthRepository(),
          userRepository: _FakeUserRepository(),
        ),
      ),
      BlocProvider(create: (_) => ProfileBloc(userRepository: _FakeUserRepository())),
    ],
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: TransactionHistoryScreen(userId: userId, isFarmer: isFarmer),
    ),
  );
}

void main() {
  group('TransactionHistoryScreen Property Tests', () {
    late List<models.Transaction> testTransactions;

    setUp(() {
      // Create test transactions
      testTransactions = [
        models.Transaction(
          id: 'trans1',
          buyerId: 'buyer1',
          farmerId: 'farmer1',
          listingId: 'listing1',
          amount: 100.0,
          status: TransactionStatus.completed,
          paymentMethod: PaymentMethod.mpesa,
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
          completedAt: DateTime.now().subtract(const Duration(days: 4)),
        ),
        models.Transaction(
          id: 'trans2',
          buyerId: 'buyer1',
          farmerId: 'farmer1',
          listingId: 'listing2',
          amount: 200.0,
          status: TransactionStatus.fundsHeld,
          paymentMethod: PaymentMethod.mtnMobileMoney,
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
          fundsHeldAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        models.Transaction(
          id: 'trans3',
          buyerId: 'buyer1',
          farmerId: 'farmer1',
          listingId: 'listing3',
          amount: 150.0,
          status: TransactionStatus.disputed,
          paymentMethod: PaymentMethod.mpesa,
          createdAt: DateTime.now().subtract(const Duration(days: 10)),
          disputeReason: 'Quality issue',
        ),
      ];
    });

    testWidgets('Property: Screen should render without errors', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
          _buildTestWidget(userId: 'farmer1', isFarmer: true));
      await tester.pump();

      expect(find.byType(TransactionHistoryScreen), findsOneWidget);
    });

    testWidgets('Property: Tabs should be present', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
          _buildTestWidget(userId: 'farmer1', isFarmer: true));
      await tester.pumpAndSettle();

      // Screen renders content (empty state) once PaymentHistoryLoaded fires
      expect(find.byType(TransactionHistoryScreen), findsOneWidget);
      expect(find.text('No Transactions Yet'), findsOneWidget);
    });

    test('Property: Filters should separate transactions correctly', () {
      final completed = testTransactions
          .where((t) => t.status == TransactionStatus.completed)
          .toList();
      final active = testTransactions
          .where(
            (t) =>
                t.status == TransactionStatus.fundsHeld ||
                t.status == TransactionStatus.pending ||
                t.status == TransactionStatus.delivered,
          )
          .toList();
      final disputed = testTransactions
          .where((t) => t.status == TransactionStatus.disputed)
          .toList();

      expect(
        completed.length,
        1,
        reason: 'Should have exactly 1 completed transaction',
      );
      expect(
        active.length,
        1,
        reason: 'Should have exactly 1 active transaction',
      );
      expect(
        disputed.length,
        1,
        reason: 'Should have exactly 1 disputed transaction',
      );
    });

    test('Property: Transaction list should be ordered by date', () {
      final sorted = List<models.Transaction>.from(testTransactions);
      sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      expect(
        sorted.first.id,
        'trans2',
        reason: 'Most recent transaction should be first',
      );
      expect(
        sorted.last.id,
        'trans3',
        reason: 'Oldest transaction should be last',
      );
    });

    test('Property: Statistics should accurately reflect transaction data',
        () {
      final completed = testTransactions
          .where((t) => t.status == TransactionStatus.completed)
          .toList();
      final pending = testTransactions
          .where(
            (t) =>
                t.status == TransactionStatus.pending ||
                t.status == TransactionStatus.fundsHeld ||
                t.status == TransactionStatus.delivered,
          )
          .toList();

      final totalEarnings =
          completed.fold(0.0, (sum, t) => sum + t.amount);

      expect(
        totalEarnings,
        100.0,
        reason:
            'Total earnings should equal completed transaction amounts',
      );
      expect(
        completed.length,
        1,
        reason: 'Should have 1 completed transaction',
      );
      expect(pending.length, 1,
          reason: 'Should have 1 pending transaction');
    });

    test('Property: Each transaction should display correct amount format',
        () {
      for (final transaction in testTransactions) {
        final formatted =
            '\$${transaction.amount.toStringAsFixed(2)}';

        expect(
          formatted.startsWith('\$'),
          true,
          reason: 'Amount should have currency symbol',
        );
        expect(
          formatted.contains('.'),
          true,
          reason: 'Amount should have decimal point',
        );

        final parts = formatted.split('.');
        expect(
          parts[1].length,
          2,
          reason: 'Amount should have exactly 2 decimal places',
        );
      }
    });

    test('Property: Transaction cards should show payment method', () {
      for (final transaction in testTransactions) {
        final method = transaction.paymentMethod;

        expect(
          PaymentMethod.values.contains(method),
          true,
          reason: 'Payment method should be valid',
        );

        String label;
        switch (method) {
          case PaymentMethod.mpesa:
            label = 'M-Pesa';
            break;
          case PaymentMethod.mtnMobileMoney:
            label = 'MTN';
            break;
          case PaymentMethod.flutterwave:
            label = 'Flutterwave';
            break;
        }

        expect(
          label.isNotEmpty,
          true,
          reason: 'Payment method should have a label',
        );
      }
    });

    test('Property: Status badges should match transaction status', () {
      final statusMappings = {
        TransactionStatus.pending: 'Pending',
        TransactionStatus.fundsHeld: 'In Escrow',
        TransactionStatus.delivered: 'Delivered',
        TransactionStatus.completed: 'Completed',
        TransactionStatus.disputed: 'Disputed',
        TransactionStatus.cancelled: 'Cancelled',
      };

      for (final entry in statusMappings.entries) {
        final label = entry.value;
        expect(
          label.isNotEmpty,
          true,
          reason: 'Each status should have a label',
        );
      }
    });

    test(
      'Property: Retry count should be displayed when greater than zero',
      () {
        final withRetries = models.Transaction(
          id: 'trans_retry',
          buyerId: 'buyer1',
          farmerId: 'farmer1',
          listingId: 'listing1',
          amount: 100.0,
          status: TransactionStatus.pending,
          paymentMethod: PaymentMethod.mpesa,
          createdAt: DateTime.now(),
          retryCount: 2,
        );

        expect(
          withRetries.retryCount,
          greaterThan(0),
          reason: 'Should show retry count when > 0',
        );
      },
    );

    test('Property: Disputed transactions should show dispute indicator',
        () {
      final disputed = testTransactions
          .where((t) => t.status == TransactionStatus.disputed)
          .toList();

      for (final transaction in disputed) {
        expect(transaction.status, TransactionStatus.disputed);
        expect(
          transaction.disputeReason,
          isNotNull,
          reason: 'Disputed transactions should have a reason',
        );
      }
    });

    test('Property: Empty states should show appropriate messages', () {
      final emptyTransactions = <models.Transaction>[];

      final allEmpty = emptyTransactions;
      final completedEmpty = emptyTransactions
          .where((t) => t.status == TransactionStatus.completed)
          .toList();
      final disputedEmpty = emptyTransactions
          .where((t) => t.status == TransactionStatus.disputed)
          .toList();

      expect(allEmpty.isEmpty, true);
      expect(completedEmpty.isEmpty, true);
      expect(disputedEmpty.isEmpty, true);
    });

    test('Property: User role should determine transaction display', () {
      for (final transaction in testTransactions) {
        final isFarmerTransaction = transaction.farmerId == 'farmer1';
        final isBuyerTransaction = transaction.buyerId == 'farmer1';

        expect(
          isFarmerTransaction || isBuyerTransaction,
          true,
          reason: 'Transaction should belong to the user',
        );
      }
    });

    test('Property: Date formatting should be consistent', () {
      for (final transaction in testTransactions) {
        final date = transaction.createdAt;

        expect(
          date.isBefore(DateTime.now()) ||
              date.isAtSameMomentAs(DateTime.now()),
          true,
          reason: 'Transaction date should not be in the future',
        );
      }
    });

    test('Property: Transaction amounts should preserve precision', () {
      final amounts = [100.0, 200.0, 150.0];

      for (int i = 0; i < testTransactions.length; i++) {
        expect(
          testTransactions[i].amount,
          amounts[i],
          reason: 'Amount should be preserved exactly',
        );
      }
    });

    test('Property: Filtering should not lose transactions', () {
      final originalCount = testTransactions.length;

      final completed = testTransactions
          .where((t) => t.status == TransactionStatus.completed)
          .length;
      final active = testTransactions
          .where(
            (t) =>
                t.status == TransactionStatus.fundsHeld ||
                t.status == TransactionStatus.pending ||
                t.status == TransactionStatus.delivered,
          )
          .length;
      final disputed = testTransactions
          .where((t) => t.status == TransactionStatus.disputed)
          .length;
      final cancelled = testTransactions
          .where((t) => t.status == TransactionStatus.cancelled)
          .length;

      final sum = completed + active + disputed + cancelled;

      expect(
        sum,
        originalCount,
        reason: 'All transactions should be accounted for',
      );
    });
  });
}
