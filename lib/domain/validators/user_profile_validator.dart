import '../models/user_profile.dart';
import '../models/enums.dart';

/// Validator for UserProfile data
class UserProfileValidator {
  /// Validate a UserProfile instance
  /// Returns null if valid, otherwise returns error message
  static String? validate(UserProfile profile) {
    // Check that either email or phone number is provided
    if (profile.email.isEmpty && profile.phoneNumber.isEmpty) {
      return 'Either email or phone number must be provided';
    }

    // Validate email format if provided
    if (profile.email.isNotEmpty && !_isValidEmail(profile.email)) {
      return 'Invalid email format';
    }

    // Validate phone number format if provided
    if (profile.phoneNumber.isNotEmpty &&
        !_isValidPhoneNumber(profile.phoneNumber)) {
      return 'Invalid phone number format';
    }

    // Check display name is not empty
    if (profile.displayName.isEmpty) {
      return 'Display name is required';
    }

    // Validate farmer-specific fields
    if (profile.role == UserRole.farmer) {
      if (profile.farmSize != null && profile.farmSize! <= 0) {
        return 'Farm size must be greater than 0';
      }

      if (profile.farmSize != null && profile.farmSize! > 1000) {
        return 'Farm size seems unrealistic (max 1000 hectares)';
      }
    }

    // Validate buyer-specific fields
    if (profile.role == UserRole.buyer) {
      if (profile.monthlyVolume != null && profile.monthlyVolume! < 0) {
        return 'Monthly volume cannot be negative';
      }
    }

    return null; // Valid
  }

  /// Validate email format
  static bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  /// Validate phone number format (basic validation)
  static bool _isValidPhoneNumber(String phoneNumber) {
    // Remove spaces, dashes, and parentheses
    final cleaned = phoneNumber.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // Check if it contains only digits and optional + at start
    final phoneRegex = RegExp(r'^\+?[0-9]{10,15}$');
    return phoneRegex.hasMatch(cleaned);
  }

  /// Validate display name
  static String? validateDisplayName(String displayName) {
    if (displayName.isEmpty) {
      return 'Display name is required';
    }

    if (displayName.length < 2) {
      return 'Display name must be at least 2 characters';
    }

    if (displayName.length > 50) {
      return 'Display name must be less than 50 characters';
    }

    return null;
  }

  /// Validate farm size
  static String? validateFarmSize(double? farmSize) {
    if (farmSize == null) {
      return null; // Optional field
    }

    if (farmSize <= 0) {
      return 'Farm size must be greater than 0';
    }

    if (farmSize > 1000) {
      return 'Farm size seems unrealistic (max 1000 hectares)';
    }

    return null;
  }

  /// Validate farm location
  static String? validateFarmLocation(String? location) {
    if (location == null || location.isEmpty) {
      return null; // Optional field
    }

    if (location.length < 2) {
      return 'Location must be at least 2 characters';
    }

    return null;
  }

  /// Validate business name
  static String? validateBusinessName(String? businessName) {
    if (businessName == null || businessName.isEmpty) {
      return null; // Optional field
    }

    if (businessName.length < 2) {
      return 'Business name must be at least 2 characters';
    }

    if (businessName.length > 100) {
      return 'Business name must be less than 100 characters';
    }

    return null;
  }

  /// Validate monthly volume
  static String? validateMonthlyVolume(double? volume) {
    if (volume == null) {
      return null; // Optional field
    }

    if (volume < 0) {
      return 'Monthly volume cannot be negative';
    }

    return null;
  }
}
