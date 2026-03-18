import 'package:intl/intl.dart';

class CurrencyUtils {
  static String codeFromCountry(String? country) {
    switch (country) {
      case 'Kenya':
        return 'KES';
      case 'Rwanda':
        return 'RWF';
      case 'Uganda':
        return 'UGX';
      case 'Tanzania':
        return 'TZS';
      case 'Ethiopia':
        return 'ETB';
      case 'Burundi':
        return 'BIF';
      default:
        return 'USD';
    }
  }

  static String symbolFromCode(String code) {
    switch (code.toUpperCase()) {
      case 'KES':
        return 'KSh';
      case 'UGX':
        return 'USh';
      case 'TZS':
        return 'TSh';
      case 'RWF':
        return 'RWF';
      case 'USD':
        return r'$';
      default:
        return code.toUpperCase();
    }
  }

  static String format(double amount, String code) {
    final normalizedCode = code.toUpperCase();
    final formatted = NumberFormat('#,##0.00').format(amount);
    return '${symbolFromCode(normalizedCode)} $formatted';
  }
}
