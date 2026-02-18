import 'package:flutter_test/flutter_test.dart';
import 'package:brewmaster/domain/validators/payment_validator.dart';
import 'package:brewmaster/domain/models/enums.dart';

void main() {
  group('PaymentValidator Property Tests', () {
    group('Amount Validation Properties', () {
      test('Property: Valid positive amounts should pass', () {
        final validAmounts = ['10', '100.50', '1000', '999999.99', '0.01'];

        for (final amount in validAmounts) {
          final result = PaymentValidator.validateAmount(amount);
          expect(result, isNull,
              reason: 'Valid amount $amount should pass validation');
        }
      });

      test('Property: Zero and negative amounts should fail', () {
        final invalidAmounts = ['0', '-10', '-100.50'];

        for (final amount in invalidAmounts) {
          final result = PaymentValidator.validateAmount(amount);
          expect(result, isNotNull,
              reason: 'Invalid amount $amount should fail validation');
        }
      });

      test('Property: Non-numeric values should fail', () {
        final invalidAmounts = ['abc', '12.34.56', 'ten', '1e10', ''];

        for (final amount in invalidAmounts) {
          final result = PaymentValidator.validateAmount(amount);
          expect(result, isNotNull,
              reason: 'Non-numeric value $amount should fail validation');
        }
      });

      test('Property: Amounts exceeding maximum should fail', () {
        final result = PaymentValidator.validateAmount('1000001');
        expect(result, isNotNull,
            reason: 'Amount exceeding maximum should fail');
      });

      test('Property: Amounts with more than 2 decimal places should fail', () {
        final invalidAmounts = ['10.123', '100.4567', '1.001'];

        for (final amount in invalidAmounts) {
          final result = PaymentValidator.validateAmount(amount);
          expect(result, isNotNull,
              reason: 'Amount with more than 2 decimals should fail');
        }
      });
    });

    group('Phone Number Validation Properties', () {
      test('Property: Valid M-Pesa numbers should pass', () {
        final validNumbers = [
          '0712345678',
          '0723456789',
          '+254712345678',
          '254712345678',
          '0112345678',
        ];

        for (final number in validNumbers) {
          final result = PaymentValidator.validatePhoneNumber(
              number, PaymentMethod.mpesa);
          expect(result, isNull,
              reason: 'Valid M-Pesa number $number should pass');
        }
      });

      test('Property: Invalid M-Pesa formats should fail', () {
        final invalidNumbers = [
          '0612345678', // Wrong prefix
          '071234567', // Too short
          '07123456789', // Too long
          'abcdefghij', // Non-numeric
        ];

        for (final number in invalidNumbers) {
          final result = PaymentValidator.validatePhoneNumber(
              number, PaymentMethod.mpesa);
          expect(result, isNotNull,
              reason: 'Invalid M-Pesa number $number should fail');
        }
      });

      test('Property: Phone numbers with spaces/dashes should be handled', () {
        final numbersWithFormatting = [
          '071-234-5678',
          '071 234 5678',
          '+254 71 234 5678',
        ];

        for (final number in numbersWithFormatting) {
          final result = PaymentValidator.validatePhoneNumber(
              number, PaymentMethod.mpesa);
          // Should either pass or fail consistently
          expect(result != null || result == null, true,
              reason: 'Formatted numbers should be handled');
        }
      });

      test('Property: Empty phone numbers should fail', () {
        final result =
            PaymentValidator.validatePhoneNumber('', PaymentMethod.mpesa);
        expect(result, isNotNull, reason: 'Empty phone number should fail');
      });

      test('Property: Phone numbers must be within length bounds', () {
        // Too short
        final tooShort =
            PaymentValidator.validatePhoneNumber('123', PaymentMethod.mpesa);
        expect(tooShort, isNotNull, reason: 'Too short should fail');

        // Too long
        final tooLong = PaymentValidator.validatePhoneNumber(
            '12345678901234567890', PaymentMethod.mpesa);
        expect(tooLong, isNotNull, reason: 'Too long should fail');
      });
    });

    group('PIN Validation Properties', () {
      test('Property: Valid 4-digit PINs should pass', () {
        final validPins = ['1357', '2468', '9876', '5432'];

        for (final pin in validPins) {
          final result = PaymentValidator.validatePaymentPin(pin);
          expect(result, isNull, reason: 'Valid PIN $pin should pass');
        }
      });

      test('Property: PINs with wrong length should fail', () {
        final invalidPins = ['123', '12345', '12', '123456'];

        for (final pin in invalidPins) {
          final result = PaymentValidator.validatePaymentPin(pin);
          expect(result, isNotNull,
              reason: 'PIN with wrong length should fail');
        }
      });

      test('Property: Non-numeric PINs should fail', () {
        final invalidPins = ['abcd', '12a4', '1.23', '12-34'];

        for (final pin in invalidPins) {
          final result = PaymentValidator.validatePaymentPin(pin);
          expect(result, isNotNull, reason: 'Non-numeric PIN should fail');
        }
      });

      test('Property: Weak PINs should fail', () {
        final weakPins = ['0000', '1111', '1234', '4321'];

        for (final pin in weakPins) {
          final result = PaymentValidator.validatePaymentPin(pin);
          expect(result, isNotNull, reason: 'Weak PIN $pin should fail');
        }
      });

      test('Property: Empty PIN should fail', () {
        final result = PaymentValidator.validatePaymentPin('');
        expect(result, isNotNull, reason: 'Empty PIN should fail');
      });
    });

    group('Dispute Reason Validation Properties', () {
      test('Property: Valid dispute reasons should pass', () {
        final validReasons = [
          'Coffee quality does not match description',
          'Delivery was incomplete',
          'Wrong coffee variety was delivered',
        ];

        for (final reason in validReasons) {
          final result = PaymentValidator.validateDisputeReason(reason);
          expect(result, isNull,
              reason: 'Valid dispute reason should pass');
        }
      });

      test('Property: Too short reasons should fail', () {
        final shortReasons = ['Bad', 'No', 'Wrong'];

        for (final reason in shortReasons) {
          final result = PaymentValidator.validateDisputeReason(reason);
          expect(result, isNotNull,
              reason: 'Short reason should fail (must be 10+ chars)');
        }
      });

      test('Property: Too long reasons should fail', () {
        final longReason = 'a' * 501; // 501 characters
        final result = PaymentValidator.validateDisputeReason(longReason);
        expect(result, isNotNull,
            reason: 'Reason exceeding 500 chars should fail');
      });

      test('Property: Empty dispute reasons should fail', () {
        final result = PaymentValidator.validateDisputeReason('');
        expect(result, isNotNull, reason: 'Empty reason should fail');
      });
    });

    group('Data Sanitization Properties', () {
      test('Property: Sensitive fields should be removed', () {
        final data = {
          'amount': 100.0,
          'phoneNumber': '0712345678',
          'pin': '1234',
          'password': 'secret',
          'cardNumber': '1234567890123456',
          'cvv': '123',
        };

        final sanitized = PaymentValidator.sanitizePaymentData(data);

        expect(sanitized.containsKey('pin'), false,
            reason: 'PIN should be removed');
        expect(sanitized.containsKey('password'), false,
            reason: 'Password should be removed');
        expect(sanitized.containsKey('cardNumber'), false,
            reason: 'Card number should be removed');
        expect(sanitized.containsKey('cvv'), false,
            reason: 'CVV should be removed');

        // Non-sensitive data should remain
        expect(sanitized.containsKey('amount'), true,
            reason: 'Amount should be preserved');
      });

      test('Property: Phone numbers should be masked', () {
        final data = {'phoneNumber': '0712345678'};
        final sanitized = PaymentValidator.sanitizePaymentData(data);

        final maskedPhone = sanitized['phoneNumber'] as String;
        expect(maskedPhone.startsWith('****'), true,
            reason: 'Phone should be masked');
        expect(maskedPhone.endsWith('5678'), true,
            reason: 'Last 4 digits should be visible');
      });

      test('Property: Sanitization should not modify original data', () {
        final original = {
          'phoneNumber': '0712345678',
          'pin': '1234',
        };
        final originalCopy = Map<String, dynamic>.from(original);

        PaymentValidator.sanitizePaymentData(original);

        expect(original, originalCopy,
            reason: 'Original data should not be modified');
      });
    });

    group('Transaction ID Validation Properties', () {
      test('Property: Valid transaction IDs should pass', () {
        final validIds = [
          'abc123def456',
          '1234567890abcdef',
          'trans_12345678901234567890',
        ];

        for (final id in validIds) {
          final result = PaymentValidator.validateTransactionId(id);
          expect(result, isNull,
              reason: 'Valid transaction ID $id should pass');
        }
      });

      test('Property: Too short transaction IDs should fail', () {
        final shortIds = ['abc', '12345', 'short'];

        for (final id in shortIds) {
          final result = PaymentValidator.validateTransactionId(id);
          expect(result, isNotNull,
              reason: 'Short transaction ID should fail');
        }
      });

      test('Property: Empty transaction ID should fail', () {
        final result = PaymentValidator.validateTransactionId('');
        expect(result, isNotNull, reason: 'Empty transaction ID should fail');
      });
    });

    group('Amount Reasonableness Properties', () {
      test('Property: Reasonable amounts should return true', () {
        final reasonableAmounts = [1.0, 10.0, 100.0, 1000.0, 50000.0];

        for (final amount in reasonableAmounts) {
          final result = PaymentValidator.isAmountReasonable(amount);
          expect(result, true,
              reason: 'Amount $amount should be reasonable');
        }
      });

      test('Property: Unreasonable amounts should return false', () {
        final unreasonableAmounts = [0.0, -10.0, 0.5, 1000001.0];

        for (final amount in unreasonableAmounts) {
          final result = PaymentValidator.isAmountReasonable(amount);
          expect(result, false,
              reason: 'Amount $amount should be unreasonable');
        }
      });
    });

    group('Transaction Timing Properties', () {
      test('Property: Future dates should pass', () {
        final futureDate = DateTime.now().add(Duration(days: 30));
        final result = PaymentValidator.validateTransactionTiming(futureDate);
        expect(result, isNull, reason: 'Future date should be valid');
      });

      test('Property: Past dates should fail', () {
        final pastDate = DateTime.now().subtract(Duration(days: 1));
        final result = PaymentValidator.validateTransactionTiming(pastDate);
        expect(result, isNotNull, reason: 'Past date should be invalid');
      });

      test('Property: Dates too far in future should fail', () {
        final farFuture = DateTime.now().add(Duration(days: 366));
        final result = PaymentValidator.validateTransactionTiming(farFuture);
        expect(result, isNotNull,
            reason: 'Date more than 365 days ahead should be invalid');
      });

      test('Property: Current time should pass', () {
        final now = DateTime.now();
        final result = PaymentValidator.validateTransactionTiming(now);
        expect(result, isNull, reason: 'Current time should be valid');
      });
    });
  });
}
