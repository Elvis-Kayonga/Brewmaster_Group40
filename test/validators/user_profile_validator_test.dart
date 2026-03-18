/// Unit tests for UserProfileValidator
///
/// Testing patterns:
/// 1. Email format validation
/// 2. Phone number format validation
/// 3. Display name constraints
/// 4. Farmer-specific field validation
/// 5. Buyer-specific field validation
/// 6. Profile validation overall
///
/// Requirements: 1.1, 1.2
/// Developer: Developer 1
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:brewmaster/domain/models/user_profile.dart';
import 'package:brewmaster/domain/models/enums.dart';
import 'package:brewmaster/domain/validators/user_profile_validator.dart';

void main() {
  group('UserProfileValidator Tests', () {
    late DateTime testDate;

    setUp(() {
      testDate = DateTime(2024, 1, 1);
    });

    group('validate() - Full Profile Validation', () {
      test('Should accept valid farmer profile', () {
        final profile = UserProfile(
          id: 'farmer-123',
          email: 'farmer@example.com',
          phoneNumber: '+254712345678',
          role: UserRole.farmer,
          displayName: 'John Farmer',
          createdAt: testDate,
          updatedAt: testDate,
          farmSize: 5.0,
        );

        expect(UserProfileValidator.validate(profile), isNull);
      });

      test('Should accept valid buyer profile', () {
        final profile = UserProfile(
          id: 'buyer-456',
          email: 'buyer@example.com',
          phoneNumber: '+254798765432',
          role: UserRole.buyer,
          displayName: 'Jane Buyer',
          createdAt: testDate,
          updatedAt: testDate,
          monthlyVolume: 1000.0,
        );

        expect(UserProfileValidator.validate(profile), isNull);
      });

      test('Should reject profile with empty email and phone', () {
        final profile = UserProfile(
          id: 'user-invalid',
          email: '',
          phoneNumber: '',
          role: UserRole.farmer,
          displayName: 'Test User',
          createdAt: testDate,
          updatedAt: testDate,
        );

        final error = UserProfileValidator.validate(profile);
        expect(error, isNotNull);
        expect(error, contains('email or phone number must be provided'));
      });

      test('Should reject profile with invalid email format', () {
        final profile = UserProfile(
          id: 'user-invalid-email',
          email: 'not-an-email',
          phoneNumber: '+254712345678',
          role: UserRole.farmer,
          displayName: 'Test User',
          createdAt: testDate,
          updatedAt: testDate,
        );

        final error = UserProfileValidator.validate(profile);
        expect(error, isNotNull);
        expect(error, contains('Invalid email format'));
      });

      test('Should reject profile with invalid phone format', () {
        final profile = UserProfile(
          id: 'user-invalid-phone',
          email: 'test@example.com',
          phoneNumber: 'invalid-phone',
          role: UserRole.farmer,
          displayName: 'Test User',
          createdAt: testDate,
          updatedAt: testDate,
        );

        final error = UserProfileValidator.validate(profile);
        expect(error, isNotNull);
        expect(error, contains('Invalid phone number format'));
      });

      test('Should reject profile with empty display name', () {
        final profile = UserProfile(
          id: 'user-no-name',
          email: 'test@example.com',
          phoneNumber: '+254712345678',
          role: UserRole.farmer,
          displayName: '',
          createdAt: testDate,
          updatedAt: testDate,
        );

        final error = UserProfileValidator.validate(profile);
        expect(error, isNotNull);
        expect(error, contains('Display name is required'));
      });

      test('Should reject farmer with negative farm size', () {
        final profile = UserProfile(
          id: 'farmer-negative-size',
          email: 'farmer@example.com',
          phoneNumber: '+254712345678',
          role: UserRole.farmer,
          displayName: 'Test Farmer',
          createdAt: testDate,
          updatedAt: testDate,
          farmSize: -5.0,
        );

        final error = UserProfileValidator.validate(profile);
        expect(error, isNotNull);
        expect(error, contains('greater than 0'));
      });

      test('Should reject farmer with unrealistic farm size', () {
        final profile = UserProfile(
          id: 'farmer-huge',
          email: 'farmer@example.com',
          phoneNumber: '+254712345678',
          role: UserRole.farmer,
          displayName: 'Test Farmer',
          createdAt: testDate,
          updatedAt: testDate,
          farmSize: 1500.0,
        );

        final error = UserProfileValidator.validate(profile);
        expect(error, isNotNull);
        expect(error, contains('unrealistic'));
      });

      test('Should reject buyer with negative monthly volume', () {
        final profile = UserProfile(
          id: 'buyer-negative',
          email: 'buyer@example.com',
          phoneNumber: '+254712345678',
          role: UserRole.buyer,
          displayName: 'Test Buyer',
          createdAt: testDate,
          updatedAt: testDate,
          monthlyVolume: -100.0,
        );

        final error = UserProfileValidator.validate(profile);
        expect(error, isNotNull);
        expect(error, contains('cannot be negative'));
      });
    });

    group('validateDisplayName() Tests', () {
      test('Should accept valid display names', () {
        expect(UserProfileValidator.validateDisplayName('John Doe'), isNull);
        expect(UserProfileValidator.validateDisplayName('Jane'), isNull);
        expect(UserProfileValidator.validateDisplayName('A B'), isNull);
        expect(UserProfileValidator.validateDisplayName('John M. Doe'), isNull);
      });

      test('Should reject empty display name', () {
        final error = UserProfileValidator.validateDisplayName('');
        expect(error, isNotNull);
        expect(error, contains('required'));
      });

      test('Should reject single character display name', () {
        final error = UserProfileValidator.validateDisplayName('A');
        expect(error, isNotNull);
        expect(error, contains('at least 2 characters'));
      });

      test('Should accept minimum length display name (2 chars)', () {
        expect(UserProfileValidator.validateDisplayName('AB'), isNull);
      });

      test('Should accept maximum length display name (50 chars)', () {
        final maxName = 'A' * 50;
        expect(UserProfileValidator.validateDisplayName(maxName), isNull);
      });

      test('Should reject display name exceeding 50 characters', () {
        final tooLong = 'A' * 51;
        final error = UserProfileValidator.validateDisplayName(tooLong);
        expect(error, isNotNull);
        expect(error, contains('less than 50 characters'));
      });

      test('Should handle display names with special characters', () {
        expect(UserProfileValidator.validateDisplayName("John O'Doe"), isNull);
        expect(UserProfileValidator.validateDisplayName('Mary-Jane'), isNull);
        expect(UserProfileValidator.validateDisplayName('José García'), isNull);
      });
    });

    group('validateFarmSize() Tests', () {
      test('Should accept null farm size (optional field)', () {
        expect(UserProfileValidator.validateFarmSize(null), isNull);
      });

      test('Should accept valid farm sizes', () {
        expect(UserProfileValidator.validateFarmSize(0.5), isNull);
        expect(UserProfileValidator.validateFarmSize(1.0), isNull);
        expect(UserProfileValidator.validateFarmSize(5.5), isNull);
        expect(UserProfileValidator.validateFarmSize(50.0), isNull);
        expect(UserProfileValidator.validateFarmSize(100.0), isNull);
        expect(UserProfileValidator.validateFarmSize(500.0), isNull);
      });

      test('Should accept maximum farm size (1000 hectares)', () {
        expect(UserProfileValidator.validateFarmSize(1000.0), isNull);
      });

      test('Should reject zero farm size', () {
        final error = UserProfileValidator.validateFarmSize(0.0);
        expect(error, isNotNull);
        expect(error, contains('greater than 0'));
      });

      test('Should reject negative farm size', () {
        final error = UserProfileValidator.validateFarmSize(-5.0);
        expect(error, isNotNull);
        expect(error, contains('greater than 0'));
      });

      test('Should reject farm size exceeding maximum', () {
        final error = UserProfileValidator.validateFarmSize(1001.0);
        expect(error, isNotNull);
        expect(error, contains('unrealistic'));
        expect(error, contains('1000 hectares'));
      });

      test('Should accept decimal farm sizes', () {
        expect(UserProfileValidator.validateFarmSize(0.1), isNull);
        expect(UserProfileValidator.validateFarmSize(2.75), isNull);
        expect(UserProfileValidator.validateFarmSize(999.99), isNull);
      });
    });

    group('validateFarmLocation() Tests', () {
      test('Should accept null location (optional field)', () {
        expect(UserProfileValidator.validateFarmLocation(null), isNull);
      });

      test('Should accept empty location (optional field)', () {
        expect(UserProfileValidator.validateFarmLocation(''), isNull);
      });

      test('Should accept valid locations', () {
        expect(
          UserProfileValidator.validateFarmLocation('Kirinyaga County'),
          isNull,
        );
        expect(
          UserProfileValidator.validateFarmLocation('Mt. Kenya Region'),
          isNull,
        );
        expect(UserProfileValidator.validateFarmLocation('Nyeri'), isNull);
        expect(UserProfileValidator.validateFarmLocation('AB'), isNull);
      });

      test('Should reject single character location', () {
        final error = UserProfileValidator.validateFarmLocation('A');
        expect(error, isNotNull);
        expect(error, contains('at least 2 characters'));
      });

      test('Should handle locations with special characters', () {
        expect(UserProfileValidator.validateFarmLocation("Mt. O'Brien"), isNull);
        expect(UserProfileValidator.validateFarmLocation('São Paulo'), isNull);
      });
    });

    group('validateBusinessName() Tests', () {
      test('Should accept null business name (optional field)', () {
        expect(UserProfileValidator.validateBusinessName(null), isNull);
      });

      test('Should accept empty business name (optional field)', () {
        expect(UserProfileValidator.validateBusinessName(''), isNull);
      });

      test('Should accept valid business names', () {
        expect(
          UserProfileValidator.validateBusinessName('Coffee Imports Ltd'),
          isNull,
        );
        expect(
          UserProfileValidator.validateBusinessName('ABC company'),
          isNull,
        );
        expect(UserProfileValidator.validateBusinessName('AB'), isNull);
      });

      test('Should reject single character business name', () {
        final error = UserProfileValidator.validateBusinessName('A');
        expect(error, isNotNull);
        expect(error, contains('at least 2 characters'));
      });

      test('Should accept maximum length (100 characters)', () {
        final maxName = 'A' * 100;
        expect(UserProfileValidator.validateBusinessName(maxName), isNull);
      });

      test('Should reject business name exceeding 100 characters', () {
        final tooLong = 'A' * 101;
        final error = UserProfileValidator.validateBusinessName(tooLong);
        expect(error, isNotNull);
        expect(error, contains('less than 100 characters'));
      });

      test('Should handle business names with special characters', () {
        expect(
          UserProfileValidator.validateBusinessName('Smith & Co.'),
          isNull,
        );
        expect(
          UserProfileValidator.validateBusinessName('ABC-DEF Inc.'),
          isNull,
        );
        expect(
          UserProfileValidator.validateBusinessName("O'Connell Coffee"),
          isNull,
        );
      });
    });

    group('validateMonthlyVolume() Tests', () {
      test('Should accept null monthly volume (optional field)', () {
        expect(UserProfileValidator.validateMonthlyVolume(null), isNull);
      });

      test('Should accept zero monthly volume', () {
        expect(UserProfileValidator.validateMonthlyVolume(0.0), isNull);
      });

      test('Should accept valid monthly volumes', () {
        expect(UserProfileValidator.validateMonthlyVolume(100.0), isNull);
        expect(UserProfileValidator.validateMonthlyVolume(500.5), isNull);
        expect(UserProfileValidator.validateMonthlyVolume(1000.0), isNull);
        expect(UserProfileValidator.validateMonthlyVolume(5000.0), isNull);
        expect(UserProfileValidator.validateMonthlyVolume(50000.0), isNull);
      });

      test('Should reject negative monthly volume', () {
        final error = UserProfileValidator.validateMonthlyVolume(-100.0);
        expect(error, isNotNull);
        expect(error, contains('cannot be negative'));
      });

      test('Should accept decimal monthly volumes', () {
        expect(UserProfileValidator.validateMonthlyVolume(0.1), isNull);
        expect(UserProfileValidator.validateMonthlyVolume(123.45), isNull);
        expect(UserProfileValidator.validateMonthlyVolume(9999.99), isNull);
      });
    });

    group('Email Validation Tests', () {
      test('Should accept valid email formats', () {
        final validEmails = [
          'simple@example.com',
          'with.dots@example.com',
          'with+plus@example.com',
          'with-dash@example.com',
          'user123@example.com',
          'user@subdomain.example.com',
          'user@example.co.uk',
        ];

        for (final email in validEmails) {
          final profile = UserProfile(
            id: 'user',
            email: email,
            phoneNumber: '+254712345678',
            role: UserRole.farmer,
            displayName: 'Test User',
            createdAt: testDate,
            updatedAt: testDate,
          );
          
          expect(
            UserProfileValidator.validate(profile),
            isNull,
            reason: 'Email $email should be valid',
          );
        }
      });

      test('Should reject invalid email formats', () {
        final invalidEmails = [
          'not-an-email',
          'missing-at-domain.com',
          '@no-local-part.com',
          'no-domain@',
          'spaces in@email.com',
          'double@@domain.com',
          'missing.tld@domain',
        ];

        for (final email in invalidEmails) {
          final profile = UserProfile(
            id: 'user',
            email: email,
            phoneNumber: '+254712345678',
            role: UserRole.farmer,
            displayName: 'Test User',
            createdAt: testDate,
            updatedAt: testDate,
          );
          
          expect(
            UserProfileValidator.validate(profile),
            isNotNull,
            reason: 'Email $email should be invalid',
          );
        }
      });
    });

    group('Phone Number Validation Tests', () {
      test('Should accept valid phone number formats', () {
        final validPhones = [
          '+254712345678',
          '+254798765432',
          '+1234567890',
          '+44 1234 567890',
          '+1 (123) 456-7890',
          '+254-712-345-678',
        ];

        for (final phone in validPhones) {
          final profile = UserProfile(
            id: 'user',
            email: 'test@example.com',
            phoneNumber: phone,
            role: UserRole.farmer,
            displayName: 'Test User',
            createdAt: testDate,
            updatedAt: testDate,
          );
          
          expect(
            UserProfileValidator.validate(profile),
            isNull,
            reason: 'Phone $phone should be valid',
          );
        }
      });

      test('Should reject invalid phone number formats', () {
        final invalidPhones = [
          'not-a-phone',
          '123', // Too short
          'abcdefghijklm',
          '++1234567890',
          '1234567890123456', // Too long
        ];

        for (final phone in invalidPhones) {
          final profile = UserProfile(
            id: 'user',
            email: 'test@example.com',
            phoneNumber: phone,
            role: UserRole.farmer,
            displayName: 'Test User',
            createdAt: testDate,
            updatedAt: testDate,
          );
          
          expect(
            UserProfileValidator.validate(profile),
            isNotNull,
            reason: 'Phone $phone should be invalid',
          );
        }
      });
    });

    group('Boundary Tests', () {
      test('Should test display name boundaries', () {
        // 1 char - invalid
        expect(
          UserProfileValidator.validateDisplayName('A'),
          isNotNull,
        );
        // 2 chars - valid
        expect(
          UserProfileValidator.validateDisplayName('AB'),
          isNull,
        );
        // 50 chars - valid
        expect(
          UserProfileValidator.validateDisplayName('A' * 50),
          isNull,
        );
        // 51 chars - invalid
        expect(
          UserProfileValidator.validateDisplayName('A' * 51),
          isNotNull,
        );
      });

      test('Should test farm size boundaries', () {
        expect(UserProfileValidator.validateFarmSize(0.0), isNotNull);
        expect(UserProfileValidator.validateFarmSize(0.1), isNull);
        expect(UserProfileValidator.validateFarmSize(1000.0), isNull);
        expect(UserProfileValidator.validateFarmSize(1000.1), isNotNull);
      });

      test('Should test business name boundaries', () {
        expect(UserProfileValidator.validateBusinessName('A'), isNotNull);
        expect(UserProfileValidator.validateBusinessName('AB'), isNull);
        expect(UserProfileValidator.validateBusinessName('A' * 100), isNull);
        expect(UserProfileValidator.validateBusinessName('A' * 101), isNotNull);
      });
    });
  });
}
