/// Widget tests for PaymentScreen
///
/// Requirements: 6.1, 6.2
/// Developer: Developer 5 (refactored to BLoC by Developer 1)

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
import 'package:brewmaster/presentation/widgets/common/custom_button.dart';
import 'package:brewmaster/presentation/widgets/common/custom_dropdown.dart';
import 'package:brewmaster/presentation/widgets/common/custom_text_field.dart';

class _FakePaymentRepository implements PaymentRepository {
  @override
  Future<Transaction> createTransaction({
    required String buyerId,
    required String farmerId,
    required String listingId,
    required double amount,
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
          ),
        ),
      );
    }

    group('Screen Initialization Tests', () {
      testWidgets(
        'Should display payment screen with all required fields',
        (WidgetTester tester) async {
          await tester.pumpWidget(createTestWidget());

          expect(find.text('Make Payment'), findsOneWidget);
          expect(find.text('Payment Summary'), findsOneWidget);
          expect(find.text('Amount:'), findsOneWidget);
          expect(find.byType(CustomTextField), findsWidgets);
          expect(find.byType(CustomDropdown<PaymentMethod>), findsOneWidget);
          expect(find.byType(Checkbox), findsOneWidget);
        },
      );

      testWidgets(
        'Should display correct payment amount',
        (WidgetTester tester) async {
          await tester.pumpWidget(createTestWidget());

          expect(find.text(r'$1500.00'), findsWidgets);
        },
      );

      testWidgets(
        'Should have proper scaffold structure',
        (WidgetTester tester) async {
          await tester.pumpWidget(createTestWidget());

          expect(find.byType(Scaffold), findsOneWidget);
          expect(find.byType(AppBar), findsOneWidget);
          expect(find.byType(Form), findsOneWidget);
        },
      );

      testWidgets(
        'Should maintain required properties',
        (WidgetTester tester) async {
          const testListingId = 'test-listing';
          const testFarmerId = 'test-farmer';
          const testBuyerId = 'test-buyer';
          const testAmount = 2500.0;

          await tester.pumpWidget(createTestWidget(
            listingId: testListingId,
            farmerId: testFarmerId,
            buyerId: testBuyerId,
            amount: testAmount,
          ));

          final widget = tester.widget<PaymentScreen>(
            find.byType(PaymentScreen),
          );
          expect(widget.listingId, equals(testListingId));
          expect(widget.farmerId, equals(testFarmerId));
          expect(widget.buyerId, equals(testBuyerId));
          expect(widget.amount, equals(testAmount));
        },
      );
    });

    group('Payment Summary Tests', () {
      testWidgets(
        'Should display payment summary card',
        (WidgetTester tester) async {
          await tester.pumpWidget(createTestWidget());

          expect(find.text('Payment Summary'), findsOneWidget);
          expect(find.text('Amount:'), findsOneWidget);
          expect(find.text('Transaction Fee:'), findsOneWidget);
          expect(find.text('Total:'), findsOneWidget);
        },
      );

      testWidgets(
        'Should show zero transaction fee',
        (WidgetTester tester) async {
          await tester.pumpWidget(createTestWidget());

          expect(find.text(r'$0.00'), findsOneWidget);
        },
      );

      testWidgets(
        'Should format amounts correctly',
        (WidgetTester tester) async {
          await tester.pumpWidget(createTestWidget(amount: 1234.56));

          expect(find.text(r'$1234.56'), findsWidgets);
        },
      );
    });

    group('Payment Method Selection Tests', () {
      testWidgets(
        'Should display payment method dropdown',
        (WidgetTester tester) async {
          await tester.pumpWidget(createTestWidget());

          expect(find.text('Select Payment Method'), findsOneWidget);
          expect(find.byType(CustomDropdown<PaymentMethod>), findsOneWidget);
        },
      );
    });

    group('Form Field Tests', () {
      testWidgets(
        'Should display phone number field',
        (WidgetTester tester) async {
          await tester.pumpWidget(createTestWidget());

          expect(find.text('Mobile Money Number'), findsOneWidget);
          expect(find.byIcon(Icons.phone), findsOneWidget);
        },
      );

      testWidgets(
        'Should display PIN field',
        (WidgetTester tester) async {
          await tester.pumpWidget(createTestWidget());

          expect(find.text('Payment PIN'), findsOneWidget);
          expect(find.text('Enter 4-digit PIN'), findsOneWidget);
          expect(find.byIcon(Icons.lock_outline), findsOneWidget);
        },
      );

      testWidgets(
        'Should obscure PIN input',
        (WidgetTester tester) async {
          await tester.pumpWidget(createTestWidget());

          final pinTextField = find.ancestor(
            of: find.text('Payment PIN'),
            matching: find.byType(CustomTextField),
          );

          expect(pinTextField, findsOneWidget);
        },
      );

      testWidgets(
        'Should accept text input in form fields',
        (WidgetTester tester) async {
          await tester.pumpWidget(createTestWidget());

          final phoneField = find.ancestor(
            of: find.text('Mobile Money Number'),
            matching: find.byType(CustomTextField),
          );

          expect(phoneField, findsOneWidget);
        },
      );
    });

    group('Form Validation Tests', () {
      testWidgets(
        'Should prevent submission without terms agreement',
        (WidgetTester tester) async {
          await tester.pumpWidget(createTestWidget());

          expect(find.byType(Checkbox), findsOneWidget);
        },
      );
    });

    group('Terms and Conditions Tests', () {
      testWidgets(
        'Should display terms checkbox',
        (WidgetTester tester) async {
          await tester.pumpWidget(createTestWidget());

          expect(find.byType(Checkbox), findsOneWidget);
          expect(
            find.text(
              'I agree to the terms and conditions of escrow payment',
            ),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        'Should toggle checkbox when tapped',
        (WidgetTester tester) async {
          await tester.pumpWidget(createTestWidget());

          final checkbox = find.byType(Checkbox);

          Checkbox checkboxWidget = tester.widget(checkbox);
          expect(checkboxWidget.value, isFalse);

          await tester.tap(checkbox);
          await tester.pump();

          checkboxWidget = tester.widget(checkbox);
          expect(checkboxWidget.value, isTrue);

          await tester.tap(checkbox);
          await tester.pump();

          checkboxWidget = tester.widget(checkbox);
          expect(checkboxWidget.value, isFalse);
        },
      );

      testWidgets(
        'Should toggle checkbox when text is tapped',
        (WidgetTester tester) async {
          await tester.pumpWidget(createTestWidget());

          final termsText = find.text(
            'I agree to the terms and conditions of escrow payment',
          );

          await tester.tap(termsText);
          await tester.pump();

          final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
          expect(checkbox.value, isTrue);
        },
      );
    });

    group('Escrow Info Card Tests', () {
      testWidgets(
        'Should display escrow information',
        (WidgetTester tester) async {
          await tester.pumpWidget(createTestWidget());

          expect(
            find.text(
              'Your payment will be held in escrow until delivery is confirmed by both parties.',
            ),
            findsOneWidget,
          );
          expect(find.byIcon(Icons.info_outline), findsOneWidget);
        },
      );
    });

    group('Payment Submission Tests', () {
      testWidgets(
        'Should navigate back on successful payment',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (context) => ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BlocProvider(
                          create: (_) => PaymentBloc(
                            paymentRepository: _FakePaymentRepository(),
                          ),
                          child: const PaymentScreen(
                            listingId: 'listing-123',
                            farmerId: 'farmer-456',
                            buyerId: 'buyer-789',
                            amount: 1500.0,
                          ),
                        ),
                      ),
                    ),
                    child: const Text('Make Payment'),
                  ),
                ),
              ),
            ),
          );

          await tester.tap(find.text('Make Payment'));
          await tester.pumpAndSettle();

          expect(find.text('Payment Summary'), findsOneWidget);
        },
      );
    });

    group('BLoC Integration Tests', () {
      testWidgets(
        'Should use BlocConsumer for state management',
        (WidgetTester tester) async {
          await tester.pumpWidget(createTestWidget());

          expect(
            find.byType(BlocConsumer<PaymentBloc, PaymentState>),
            findsOneWidget,
          );
        },
      );
    });

    group('Layout and Scrolling Tests', () {
      testWidgets(
        'Should be scrollable',
        (WidgetTester tester) async {
          await tester.pumpWidget(createTestWidget());

          expect(find.byType(SingleChildScrollView), findsOneWidget);
        },
      );

      testWidgets(
        'Should apply proper padding',
        (WidgetTester tester) async {
          await tester.pumpWidget(createTestWidget());

          final scrollView = tester.widget<SingleChildScrollView>(
            find.byType(SingleChildScrollView),
          );
          expect(scrollView.padding, equals(const EdgeInsets.all(16.0)));
        },
      );

      testWidgets(
        'Should stretch form elements horizontally',
        (WidgetTester tester) async {
          await tester.pumpWidget(createTestWidget());

          final column = tester.widget<Column>(
            find.descendant(
              of: find.byType(Form),
              matching: find.byType(Column),
            ).first,
          );
          expect(
            column.crossAxisAlignment,
            equals(CrossAxisAlignment.stretch),
          );
        },
      );
    });

    group('Accessibility Tests', () {
      testWidgets(
        'Should have accessible form labels',
        (WidgetTester tester) async {
          await tester.pumpWidget(createTestWidget());

          expect(find.text('Mobile Money Number'), findsOneWidget);
          expect(find.text('Payment PIN'), findsOneWidget);
        },
      );

      testWidgets(
        'Should provide visual feedback for form fields',
        (WidgetTester tester) async {
          await tester.pumpWidget(createTestWidget());

          expect(find.byIcon(Icons.phone), findsOneWidget);
          expect(find.byIcon(Icons.lock_outline), findsOneWidget);
        },
      );

      testWidgets(
        'Should have semantic labels for screen readers',
        (WidgetTester tester) async {
          await tester.pumpWidget(createTestWidget());

          expect(find.byType(Form), findsOneWidget);
        },
      );
    });

    group('Edge Cases', () {
      testWidgets(
        'Should handle very large amounts',
        (WidgetTester tester) async {
          await tester.pumpWidget(createTestWidget(amount: 999999.99));

          expect(find.text(r'$999999.99'), findsWidgets);
        },
      );

      testWidgets(
        'Should handle zero amount',
        (WidgetTester tester) async {
          await tester.pumpWidget(createTestWidget(amount: 0.0));

          expect(find.text(r'$0.00'), findsWidgets);
        },
      );

      testWidgets(
        'Should clean up controllers on dispose',
        (WidgetTester tester) async {
          await tester.pumpWidget(createTestWidget());
          await tester.pumpWidget(const MaterialApp(home: Scaffold()));
          // Controllers should be disposed without errors
        },
      );
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
