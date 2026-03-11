import '../models/enums.dart';

/// Validator for payment data
class PaymentValidator {
  /// Validate transaction amount
  static String? validateAmount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Amount is required';
    }

    final amount = double.tryParse(value);
    if (amount == null) {
      return 'Please enter a valid number';
    }

    if (amount <= 0) {
      return 'Amount must be greater than zero';
    }

    if (amount > 1000000) {
      return 'Amount exceeds maximum allowed';
    }

    // Check for reasonable decimal places (max 2)
    final parts = value.split('.');
    if (parts.length > 1 && parts[1].length > 2) {
      return 'Amount can have at most 2 decimal places';
    }

    return null;
  }

  /// Validate phone number for mobile money
  static String? validatePhoneNumber(String? value, PaymentMethod method) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }

    // Remove spaces and dashes
    final cleaned = value.replaceAll(RegExp(r'[\s-]'), '');

    // Check if contains only digits and optional + prefix
    if (!RegExp(r'^\+?[0-9]+$').hasMatch(cleaned)) {
      return 'Phone number must contain only digits';
    }

    // Validate length (10-15 digits)
    final digitsOnly = cleaned.replaceAll('+', '');
    if (digitsOnly.length < 10 || digitsOnly.length > 15) {
      return 'Phone number must be 10-15 digits';
    }

    // Method-specific validation
    if (method == PaymentMethod.mpesa) {
      // M-Pesa Kenya typically starts with 254 (country code) or 07/01
      if (cleaned.startsWith('+254') || cleaned.startsWith('254')) {
        final number = cleaned.replaceFirst('+254', '').replaceFirst('254', '');
        if (!RegExp(r'^[71][0-9]{8}$').hasMatch(number)) {
          return 'Invalid M-Pesa number format';
        }
      } else if (cleaned.startsWith('0')) {
        if (!RegExp(r'^0[71][0-9]{8}$').hasMatch(cleaned)) {
          return 'Invalid M-Pesa number format';
        }
      }
    } else if (method == PaymentMethod.mtnMobileMoney) {
      // MTN typically uses different prefixes depending on country
      // This is a simplified validation
      if (digitsOnly.length < 10) {
        return 'Invalid MTN Mobile Money number';
      }
    }

    return null;
  }

  /// Validate payment PIN (for security)
  static String? validatePaymentPin(String? value) {
    if (value == null || value.isEmpty) {
      return 'PIN is required';
    }

    if (value.length != 4) {
      return 'PIN must be exactly 4 digits';
    }

    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return 'PIN must contain only digits';
    }

    // Check for weak PINs
    if (value == '0000' ||
        value == '1111' ||
        value == '1234' ||
        value == '4321') {
      return 'PIN is too weak';
    }

    return null;
  }

  /// Validate dispute reason
  static String? validateDisputeReason(String? value) {
    if (value == null || value.isEmpty) {
      return 'Dispute reason is required';
    }

    if (value.length < 10) {
      return 'Please provide more details (minimum 10 characters)';
    }

    if (value.length > 500) {
      return 'Reason is too long (maximum 500 characters)';
    }

    return null;
  }

  /// Sanitize payment data (remove sensitive info for logging)
  static Map<String, dynamic> sanitizePaymentData(
      Map<String, dynamic> data) {
    final sanitized = Map<String, dynamic>.from(data);

    // Remove sensitive fields
    sanitized.remove('pin');
    sanitized.remove('password');
    sanitized.remove('cardNumber');
    sanitized.remove('cvv');

    // Mask phone number (show only last 4 digits)
    if (sanitized.containsKey('phoneNumber')) {
      final phone = sanitized['phoneNumber'] as String;
      if (phone.length > 4) {
        sanitized['phoneNumber'] =
            '****${phone.substring(phone.length - 4)}';
      }
    }

    return sanitized;
  }

  /// Validate transaction ID format
  static String? validateTransactionId(String? value) {
    if (value == null || value.isEmpty) {
      return 'Transaction ID is required';
    }

    // Firestore document IDs are typically 20 characters
    if (value.length < 10) {
      return 'Invalid transaction ID format';
    }

    return null;
  }

  /// Check if amount is within reasonable limits for the platform
  static bool isAmountReasonable(double amount) {
    // Coffee prices typically range from $1-50 per kg
    // Allow buffer for larger transactions
    return amount >= 1.0 && amount <= 1000000.0;
  }

  /// Validate that buyer has sufficient notice before transaction
  static String? validateTransactionTiming(DateTime transactionDate) {
    final now = DateTime.now();
    final difference = transactionDate.difference(now);

    if (difference.isNegative) {
      return 'Transaction date cannot be in the past';
    }

    if (difference.inDays > 365) {
      return 'Transaction date is too far in the future';
    }

    return null;
  }
}
