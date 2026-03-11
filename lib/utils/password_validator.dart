import 'package:flutter/material.dart';

/// Utility for validating password strength
class PasswordValidator {
  /// Minimum password length
  static const minLength = 8;

  /// Validates password strength and returns error message if invalid
  /// Returns null if password is valid
  static String? validate(String? password) {
    if (password == null || password.isEmpty) {
      return 'Password is required';
    }

    if (password.length < minLength) {
      return 'Password must be at least $minLength characters';
    }

    if (!_hasUppercase(password)) {
      return 'Password must contain at least one uppercase letter';
    }

    if (!_hasLowercase(password)) {
      return 'Password must contain at least one lowercase letter';
    }

    if (!_hasNumber(password)) {
      return 'Password must contain at least one number';
    }

    if (!_hasSpecialChar(password)) {
      return 'Password must contain at least one special character (!@#\$%^&*)';
    }

    return null;
  }

  /// Get strength feedback for a password (for UI display)
  static PasswordStrength getStrength(String password) {
    if (password.isEmpty) {
      return PasswordStrength.none;
    }

    int score = 0;

    if (password.length >= minLength) score++;
    if (_hasUppercase(password)) score++;
    if (_hasLowercase(password)) score++;
    if (_hasNumber(password)) score++;
    if (_hasSpecialChar(password)) score++;

    if (score <= 1) return PasswordStrength.weak;
    if (score <= 2) return PasswordStrength.fair;
    if (score <= 3) return PasswordStrength.good;
    return PasswordStrength.strong;
  }

  static bool _hasUppercase(String str) => str.contains(RegExp(r'[A-Z]'));
  static bool _hasLowercase(String str) => str.contains(RegExp(r'[a-z]'));
  static bool _hasNumber(String str) => str.contains(RegExp(r'[0-9]'));
  static bool _hasSpecialChar(String str) {
    const specialChars = '!@#\$%^&*()_+-=[]{}:;\'",.<>?/\\|`~';
    return str.split('').any((char) => specialChars.contains(char));
  }
}

enum PasswordStrength { none, weak, fair, good, strong }

extension PasswordStrengthExtension on PasswordStrength {
  String get label {
    switch (this) {
      case PasswordStrength.none:
        return 'None';
      case PasswordStrength.weak:
        return 'Weak';
      case PasswordStrength.fair:
        return 'Fair';
      case PasswordStrength.good:
        return 'Good';
      case PasswordStrength.strong:
        return 'Strong';
    }
  }

  Color get color {
    switch (this) {
      case PasswordStrength.none:
        return const Color(0xFFCCCCCC);
      case PasswordStrength.weak:
        return const Color(0xFFEF5350);
      case PasswordStrength.fair:
        return const Color(0xFFFFA726);
      case PasswordStrength.good:
        return const Color(0xFFFFCA28);
      case PasswordStrength.strong:
        return const Color(0xFF66BB6A);
    }
  }
}
