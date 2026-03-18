/// Widget tests for PaymentScreen
///
/// Requirements: 6.1, 6.2
/// Developer: Developer 5 (refactored to BLoC by Developer 1)
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:brewmaster/domain/models/enums.dart';
import 'package:brewmaster/domain/models/escrow_transaction.dart';
import 'package:brewmaster/domain/models/paginated_result.dart';
import 'package:brewmaster/domain/repositories/payment_repository.dart';
import 'package:brewmaster/domain/validators/payment_validator.dart';
import 'package:brewmaster/presentation/blocs/payment/payment_bloc.dart';
import 'package:brewmaster/presentation/screens/payments/payment_screen.dart';
import 'package:brewmaster/presentation/widgets/common/custom_dropdown.dart';

class _FakePaymentRepository implements PaymentRepository {
  @override
  Future<Transaction> createTransaction({
    required String buyerId,
    required String farmerId,
    required String listingId,
    required double amount,
    String currency = 'USD',
    required PaymentMethod paymentMethod,
  }) async =>
      throw UnimplementedError('not needed in tests');

  @override
  Future<Transaction> processPayment(String transactionId) async =>
      throw UnimplementedError();
  @override
  Future<Transaction> confirmDelivery(String transactionId) async =>
      throw UnimplementedError();
  @override
  Future<Transaction> confirmReceiptAndReleaseFunds(
          String transactionId) async =>
      throw UnimplementedError();
  @override
  Future<Transaction> raiseDispute(
          String transactionId, String reason) async =>
      throw UnimplementedError();
  @override
  Future<Transaction> cancelTransaction(String transactionId) async =>
      throw UnimplementedError();
  @override
  Future<Transaction?> getTransaction(String transactionId) async => null;
  @override
  Stream<List<Transaction>> getUserTransactions(String userId) =>
      Stream.value([]);
  @override
  Stream<List<Transaction>> getListingTransactions(String listingId) =>
      Stream.value([]);
  @override
  Future<Map<String, dynamic>> getUserStatistics(String userId) async => {};
  @override
  Future<PaginatedResult<Transaction>> getTransactionPage({
    required String userId,
    int pageSize = 20,
    Object? startAfter,
  }) async =>
      const PaginatedResult<Transaction>(items: [], hasMore: false);
}

void main() {
  group('PaymentScreen Widget Tests', () {
    Widget createTestWidget({
      String listingId = 'listing-123',
      String farmerId = 'farmer-456',
      String buyerId = 'buyer-789',
      double amount = 1500.0,
      String? farmerCountry,
    }) {
      return MaterialApp(
        home: BlocProvider(
          create: (_) =>
              PaymentBloc(paymentRepository: _FakePaymentRepository()),
          child: PaymentScreen(
            listingId: listingId,
            farmerId: farmerId,
            buyerId: buyerId,
            amount: amount,
            farmerCountry: farmerCountry,
          ),
        ),
      );
    }

    testWidgets('renders summary, terms and Flutterwave step buttons',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Make Payment'), findsOneWidget);
      expect(find.text('Payment Summary'), findsOneWidget);
      expect(find.text('Amount:'), findsOneWidget);
      expect(find.text('Transaction Fee:'), findsOneWidget);
      expect(find.text('Total:'), findsOneWidget);
      expect(find.text('Pay with Flutterwave'), findsOneWidget);
      expect(find.text("I've completed payment"), findsNothing);
      expect(find.byType(Checkbox), findsOneWidget);
      expect(find.byType(CustomDropdown<PaymentMethod>), findsOneWidget);
    });

    testWidgets('formats amount with country currency when provided',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(amount: 1200, farmerCountry: 'Kenya'),
      );

      expect(find.text('KSh 1,200.00'), findsWidgets);
      expect(find.text('KSh 0.00'), findsOneWidget);
    });

    testWidgets('toggles terms checkbox from row interaction',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      final checkboxFinder = find.byType(Checkbox);
      expect(tester.widget<Checkbox>(checkboxFinder).value, isFalse);

      await tester.tap(checkboxFinder);
      await tester.pump();
      expect(tester.widget<Checkbox>(checkboxFinder).value, isTrue);

      await tester.tap(
        find.text('I agree to the terms and conditions of escrow payment'),
      );
      await tester.pump();
      expect(tester.widget<Checkbox>(checkboxFinder).value, isFalse);
    });

    testWidgets('maintains constructor properties', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          listingId: 'listing-x',
          farmerId: 'farmer-x',
          buyerId: 'buyer-x',
          amount: 2500,
          farmerCountry: 'Uganda',
        ),
      );

      final widget = tester.widget<PaymentScreen>(find.byType(PaymentScreen));
      expect(widget.listingId, 'listing-x');
      expect(widget.farmerId, 'farmer-x');
      expect(widget.buyerId, 'buyer-x');
      expect(widget.amount, 2500);
      expect(widget.farmerCountry, 'Uganda');
    });
  });

  group('PaymentValidator Unit Tests', () {
    test('Should validate payment PIN length', () {
      // 1234, 0000, 1111, 4321 are weak and rejected — use valid PINs
      expect(PaymentValidator.validatePaymentPin('2468'), isNull);
      expect(PaymentValidator.validatePaymentPin('5555'), isNull);
      expect(PaymentValidator.validatePaymentPin('9999'), isNull);
    });

    test('Should reject invalid PIN formats', () {
      expect(PaymentValidator.validatePaymentPin('123'), isNotNull);
      expect(PaymentValidator.validatePaymentPin('12345'), isNotNull);
      expect(PaymentValidator.validatePaymentPin(''), isNotNull);
      expect(PaymentValidator.validatePaymentPin('abcd'), isNotNull);
    });
  });
}
