// lib/domain/validators/coffee_listing_validator.dart

class CoffeeListingValidator {
  static String? validateAltitude(double altitude) {
    if (altitude <= 0) {
      return 'Altitude must be greater than 0 meters.';
    }
    if (altitude < 800 || altitude > 2500) {
      return 'Altitude must be between 800m and 2500m for quality coffee.';
    }
    return null;
  }

  static String? validateQualityScore(double score) {
    if (score < 0 || score > 100) {
      return 'Quality score must be between 0 and 100.';
    }
    return null;
  }
}
