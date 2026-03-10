// test/unit/coffee_listing_validator_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:brewmaster/domain/validators/coffee_listing_validator.dart';

void main() {
  group('CoffeeListingValidator Tests', () {
    test('validateAltitude returns null for valid altitude', () {
      expect(CoffeeListingValidator.validateAltitude(1500), isNull);
      expect(CoffeeListingValidator.validateAltitude(800), isNull);
      expect(CoffeeListingValidator.validateAltitude(2500), isNull);
    });

    test('validateAltitude returns error for altitude below 800m', () {
      final error = CoffeeListingValidator.validateAltitude(700);
      expect(error, isNotNull);
      expect(error, contains('800m'));
    });

    test('validateAltitude returns error for altitude above 2500m', () {
      final error = CoffeeListingValidator.validateAltitude(2600);
      expect(error, isNotNull);
      expect(error, contains('2500m'));
    });

    test('validateAltitude returns error for zero or negative altitude', () {
      final error = CoffeeListingValidator.validateAltitude(0);
      expect(error, isNotNull);
      expect(error, contains('greater than 0'));
    });

    test('validateQualityScore returns null for valid score', () {
      expect(CoffeeListingValidator.validateQualityScore(0), isNull);
      expect(CoffeeListingValidator.validateQualityScore(50), isNull);
      expect(CoffeeListingValidator.validateQualityScore(100), isNull);
    });

    test('validateQualityScore returns error for score below 0', () {
      final error = CoffeeListingValidator.validateQualityScore(-1);
      expect(error, isNotNull);
      expect(error, contains('0 and 100'));
    });

    test('validateQualityScore returns error for score above 100', () {
      final error = CoffeeListingValidator.validateQualityScore(101);
      expect(error, isNotNull);
      expect(error, contains('0 and 100'));
    });
  });
}
