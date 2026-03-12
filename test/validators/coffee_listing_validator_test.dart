/// Unit tests for CoffeeListingValidator
///
/// Testing patterns:
/// 1. Validation rules and constraints
/// 2. Edge cases and boundary values
/// 3. Error message verification
/// 4. Valid input acceptance
///
/// Requirements: 2.1, 2.6, 15.1
/// Developer: Developer 2

import 'package:flutter_test/flutter_test.dart';
import 'package:brewmaster/domain/validators/coffee_listing_validator.dart';

void main() {
  group('CoffeeListingValidator Tests', () {
    group('validateAltitude Tests', () {
      test('Should accept valid altitude within range', () {
        expect(CoffeeListingValidator.validateAltitude(1000.0), isNull);
        expect(CoffeeListingValidator.validateAltitude(1500.0), isNull);
        expect(CoffeeListingValidator.validateAltitude(2000.0), isNull);
        expect(CoffeeListingValidator.validateAltitude(1800.0), isNull);
      });

      test('Should accept minimum valid altitude (800m)', () {
        expect(CoffeeListingValidator.validateAltitude(800.0), isNull);
      });

      test('Should accept maximum valid altitude (2500m)', () {
        expect(CoffeeListingValidator.validateAltitude(2500.0), isNull);
      });

      test('Should reject altitude below minimum', () {
        final result = CoffeeListingValidator.validateAltitude(799.0);
        expect(result, isNotNull);
        expect(result, contains('between 800m and 2500m'));
      });

      test('Should reject altitude above maximum', () {
        final result = CoffeeListingValidator.validateAltitude(2501.0);
        expect(result, isNotNull);
        expect(result, contains('between 800m and 2500m'));
      });

      test('Should reject zero altitude', () {
        final result = CoffeeListingValidator.validateAltitude(0.0);
        expect(result, isNotNull);
        expect(result, contains('must be greater than 0'));
      });

      test('Should reject negative altitude', () {
        final result = CoffeeListingValidator.validateAltitude(-100.0);
        expect(result, isNotNull);
        expect(result, contains('must be greater than 0'));
      });

      test('Should reject very low altitude', () {
        final result = CoffeeListingValidator.validateAltitude(500.0);
        expect(result, isNotNull);
        expect(result, contains('between 800m and 2500m'));
      });

      test('Should reject very high altitude', () {
        final result = CoffeeListingValidator.validateAltitude(3000.0);
        expect(result, isNotNull);
        expect(result, contains('between 800m and 2500m'));
      });

      test('Should handle altitude just below minimum', () {
        final result = CoffeeListingValidator.validateAltitude(799.9);
        expect(result, isNotNull);
      });

      test('Should handle altitude just above maximum', () {
        final result = CoffeeListingValidator.validateAltitude(2500.1);
        expect(result, isNotNull);
      });

      test('Should handle decimal altitudes within range', () {
        expect(CoffeeListingValidator.validateAltitude(1234.56), isNull);
        expect(CoffeeListingValidator.validateAltitude(1800.75), isNull);
        expect(CoffeeListingValidator.validateAltitude(2499.99), isNull);
      });
    });

    group('validateQualityScore Tests', () {
      test('Should accept valid quality scores', () {
        expect(CoffeeListingValidator.validateQualityScore(50.0), isNull);
        expect(CoffeeListingValidator.validateQualityScore(75.5), isNull);
        expect(CoffeeListingValidator.validateQualityScore(87.3), isNull);
        expect(CoffeeListingValidator.validateQualityScore(92.0), isNull);
      });

      test('Should accept minimum quality score (0)', () {
        expect(CoffeeListingValidator.validateQualityScore(0.0), isNull);
      });

      test('Should accept maximum quality score (100)', () {
        expect(CoffeeListingValidator.validateQualityScore(100.0), isNull);
      });

      test('Should reject negative quality score', () {
        final result = CoffeeListingValidator.validateQualityScore(-1.0);
        expect(result, isNotNull);
        expect(result, contains('between 0 and 100'));
      });

      test('Should reject quality score above 100', () {
        final result = CoffeeListingValidator.validateQualityScore(101.0);
        expect(result, isNotNull);
        expect(result, contains('between 0 and 100'));
      });

      test('Should reject very negative score', () {
        final result = CoffeeListingValidator.validateQualityScore(-50.0);
        expect(result, isNotNull);
        expect(result, contains('between 0 and 100'));
      });

      test('Should reject very high score', () {
        final result = CoffeeListingValidator.validateQualityScore(150.0);
        expect(result, isNotNull);
        expect(result, contains('between 0 and 100'));
      });

      test('Should handle decimal scores', () {
        expect(CoffeeListingValidator.validateQualityScore(85.5), isNull);
        expect(CoffeeListingValidator.validateQualityScore(92.75), isNull);
        expect(CoffeeListingValidator.validateQualityScore(0.1), isNull);
        expect(CoffeeListingValidator.validateQualityScore(99.9), isNull);
      });

      test('Should handle score just below 0', () {
        final result = CoffeeListingValidator.validateQualityScore(-0.1);
        expect(result, isNotNull);
      });

      test('Should handle score just above 100', () {
        final result = CoffeeListingValidator.validateQualityScore(100.1);
        expect(result, isNotNull);
      });

      test('Should handle integer scores as doubles', () {
        expect(CoffeeListingValidator.validateQualityScore(0.0), isNull);
        expect(CoffeeListingValidator.validateQualityScore(50.0), isNull);
        expect(CoffeeListingValidator.validateQualityScore(100.0), isNull);
      });
    });

    group('Edge Cases and Boundary Tests', () {
      group('Altitude Boundaries', () {
        test('Should test boundary at 800m', () {
          expect(CoffeeListingValidator.validateAltitude(799.99), isNotNull);
          expect(CoffeeListingValidator.validateAltitude(800.0), isNull);
          expect(CoffeeListingValidator.validateAltitude(800.01), isNull);
        });

        test('Should test boundary at 2500m', () {
          expect(CoffeeListingValidator.validateAltitude(2499.99), isNull);
          expect(CoffeeListingValidator.validateAltitude(2500.0), isNull);
          expect(CoffeeListingValidator.validateAltitude(2500.01), isNotNull);
        });

        test('Should test boundary at 0m', () {
          expect(CoffeeListingValidator.validateAltitude(-0.01), isNotNull);
          expect(CoffeeListingValidator.validateAltitude(0.0), isNotNull);
          expect(CoffeeListingValidator.validateAltitude(0.01), isNotNull);
        });
      });

      group('Quality Score Boundaries', () {
        test('Should test boundary at 0', () {
          expect(CoffeeListingValidator.validateQualityScore(-0.01), isNotNull);
          expect(CoffeeListingValidator.validateQualityScore(0.0), isNull);
          expect(CoffeeListingValidator.validateQualityScore(0.01), isNull);
        });

        test('Should test boundary at 100', () {
          expect(CoffeeListingValidator.validateQualityScore(99.99), isNull);
          expect(CoffeeListingValidator.validateQualityScore(100.0), isNull);
          expect(
            CoffeeListingValidator.validateQualityScore(100.01),
            isNotNull,
          );
        });
      });
    });

    group('Real-World Scenario Tests', () {
      test('Should validate typical Kenya coffee altitudes', () {
        // Kenya coffee typically grows at 1400-2000m
        expect(CoffeeListingValidator.validateAltitude(1400.0), isNull);
        expect(CoffeeListingValidator.validateAltitude(1600.0), isNull);
        expect(CoffeeListingValidator.validateAltitude(1800.0), isNull);
        expect(CoffeeListingValidator.validateAltitude(2000.0), isNull);
      });

      test('Should validate specialty coffee quality scores', () {
        // Specialty coffee typically scores 80-100
        expect(CoffeeListingValidator.validateQualityScore(80.0), isNull);
        expect(CoffeeListingValidator.validateQualityScore(85.5), isNull);
        expect(CoffeeListingValidator.validateQualityScore(90.0), isNull);
        expect(CoffeeListingValidator.validateQualityScore(95.5), isNull);
      });

      test('Should validate premium coffee quality scores', () {
        // Premium coffee typically scores 70-85
        expect(CoffeeListingValidator.validateQualityScore(70.0), isNull);
        expect(CoffeeListingValidator.validateQualityScore(75.0), isNull);
        expect(CoffeeListingValidator.validateQualityScore(80.0), isNull);
        expect(CoffeeListingValidator.validateQualityScore(85.0), isNull);
      });

      test('Should validate standard coffee quality scores', () {
        // Standard coffee might score 60-75
        expect(CoffeeListingValidator.validateQualityScore(60.0), isNull);
        expect(CoffeeListingValidator.validateQualityScore(65.0), isNull);
        expect(CoffeeListingValidator.validateQualityScore(70.0), isNull);
        expect(CoffeeListingValidator.validateQualityScore(75.0), isNull);
      });
    });

    group('Error Message Verification', () {
      test('Should return descriptive error for zero altitude', () {
        final error = CoffeeListingValidator.validateAltitude(0.0);
        expect(error, contains('greater than 0 meters'));
      });

      test('Should return descriptive error for out of range altitude', () {
        final error = CoffeeListingValidator.validateAltitude(3000.0);
        expect(error, contains('between 800m and 2500m'));
        expect(error, contains('quality coffee'));
      });

      test('Should return descriptive error for invalid quality score', () {
        final error = CoffeeListingValidator.validateQualityScore(-10.0);
        expect(error, contains('between 0 and 100'));
      });
    });

    group('Multiple Validation Tests', () {
      test('Should validate multiple altitudes in sequence', () {
        final altitudes = [800.0, 1000.0, 1500.0, 2000.0, 2500.0];
        
        for (final altitude in altitudes) {
          final result = CoffeeListingValidator.validateAltitude(altitude);
          expect(result, isNull, reason: 'Altitude $altitude should be valid');
        }
      });

      test('Should reject multiple invalid altitudes', () {
        final invalidAltitudes = [0.0, 500.0, 3000.0, -100.0];
        
        for (final altitude in invalidAltitudes) {
          final result = CoffeeListingValidator.validateAltitude(altitude);
          expect(
            result,
            isNotNull,
            reason: 'Altitude $altitude should be invalid',
          );
        }
      });

      test('Should validate multiple quality scores in sequence', () {
        final scores = [0.0, 25.0, 50.0, 75.0, 100.0];
        
        for (final score in scores) {
          final result = CoffeeListingValidator.validateQualityScore(score);
          expect(result, isNull, reason: 'Score $score should be valid');
        }
      });

      test('Should reject multiple invalid quality scores', () {
        final invalidScores = [-1.0, -50.0, 101.0, 150.0];
        
        for (final score in invalidScores) {
          final result = CoffeeListingValidator.validateQualityScore(score);
          expect(
            result,
            isNotNull,
            reason: 'Score $score should be invalid',
          );
        }
      });
    });
  });
}
