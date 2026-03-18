/// Unit tests for UserProfile model
///
/// Testing patterns:
/// 1. Farmer and buyer profile creation
/// 2. JSON serialization with Firestore Timestamp
/// 3. copyWith functionality
/// 4. Role-specific field validation
/// 5. Verification status management
///
/// Requirements: 1.1, 1.2, 16.1
/// Developer: Developer 1
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:brewmaster/domain/models/user_profile.dart';
import 'package:brewmaster/domain/models/enums.dart';

void main() {
  group('UserProfile Model Tests', () {
    late DateTime testCreatedAt;
    late DateTime testUpdatedAt;

    setUp(() {
      testCreatedAt = DateTime(2024, 1, 15, 10, 30);
      testUpdatedAt = DateTime(2024, 2, 20, 14, 45);
    });

    group('Farmer Profile Tests', () {
      late UserProfile farmerProfile;

      setUp(() {
        farmerProfile = UserProfile(
          id: 'farmer-123',
          email: 'john.doe@example.com',
          phoneNumber: '+254712345678',
          role: UserRole.farmer,
          displayName: 'John Doe',
          photoUrl: 'https://example.com/photo.jpg',
          isVerified: true,
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
          farmSize: 5.5,
          farmLocation: 'Kirinyaga County',
          coffeeVarieties: ['Arabica SL28', 'SL34'],
          farmRegistrationNumber: 'FR-2024-001',
          verificationStatus: VerificationStatus.verified,
          fcmToken: 'fcm-token-123',
        );
      });

      test('Should create farmer profile with all fields', () {
        expect(farmerProfile.id, equals('farmer-123'));
        expect(farmerProfile.email, equals('john.doe@example.com'));
        expect(farmerProfile.phoneNumber, equals('+254712345678'));
        expect(farmerProfile.role, equals(UserRole.farmer));
        expect(farmerProfile.displayName, equals('John Doe'));
        expect(farmerProfile.photoUrl, equals('https://example.com/photo.jpg'));
        expect(farmerProfile.isVerified, isTrue);
        expect(farmerProfile.createdAt, equals(testCreatedAt));
        expect(farmerProfile.updatedAt, equals(testUpdatedAt));
        expect(farmerProfile.farmSize, equals(5.5));
        expect(farmerProfile.farmLocation, equals('Kirinyaga County'));
        expect(farmerProfile.coffeeVarieties, equals(['Arabica SL28', 'SL34']));
        expect(farmerProfile.farmRegistrationNumber, equals('FR-2024-001'));
        expect(
          farmerProfile.verificationStatus,
          equals(VerificationStatus.verified),
        );
        expect(farmerProfile.fcmToken, equals('fcm-token-123'));
      });

      test('Should have null buyer-specific fields', () {
        expect(farmerProfile.businessName, isNull);
        expect(farmerProfile.businessType, isNull);
        expect(farmerProfile.monthlyVolume, isNull);
      });

      test('Should convert farmer profile to JSON', () {
        final json = farmerProfile.toJson();

        expect(json['id'], equals('farmer-123'));
        expect(json['email'], equals('john.doe@example.com'));
        expect(json['phoneNumber'], equals('+254712345678'));
        expect(json['role'], equals('farmer'));
        expect(json['displayName'], equals('John Doe'));
        expect(json['photoUrl'], equals('https://example.com/photo.jpg'));
        expect(json['isVerified'], isTrue);
        expect(json['createdAt'], isA<Timestamp>());
        expect(json['updatedAt'], isA<Timestamp>());
        expect(json['farmSize'], equals(5.5));
        expect(json['farmLocation'], equals('Kirinyaga County'));  
        expect(json['coffeeVarieties'], equals(['Arabica SL28', 'SL34']));
        expect(json['farmRegistrationNumber'], equals('FR-2024-001'));
        expect(json['verificationStatus'], equals('verified'));
        expect(json['fcmToken'], equals('fcm-token-123'));
      });

      test('Should create farmer profile from JSON', () {
        final json = farmerProfile.toJson();
        final recreated = UserProfile.fromJson(json);

        expect(recreated.id, equals(farmerProfile.id));
        expect(recreated.email, equals(farmerProfile.email));
        expect(recreated.phoneNumber, equals(farmerProfile.phoneNumber));
        expect(recreated.role, equals(farmerProfile.role));
        expect(recreated.displayName, equals(farmerProfile.displayName));
        expect(recreated.photoUrl, equals(farmerProfile.photoUrl));
        expect(recreated.isVerified, equals(farmerProfile.isVerified));
        expect(recreated.farmSize, equals(farmerProfile.farmSize));
        expect(recreated.farmLocation, equals(farmerProfile.farmLocation));
        expect(recreated.coffeeVarieties, equals(farmerProfile.coffeeVarieties));
        expect(
          recreated.farmRegistrationNumber,
          equals(farmerProfile.farmRegistrationNumber),
        );
        expect(
          recreated.verificationStatus,
          equals(farmerProfile.verificationStatus),
        );
      });

      test('Should copy farmer profile with updated fields', () {
        final updated = farmerProfile.copyWith(
          displayName: 'John M. Doe',
          farmSize: 6.0,
          isVerified: false,
        );

        expect(updated.displayName, equals('John M. Doe'));
        expect(updated.farmSize, equals(6.0));
        expect(updated.isVerified, isFalse);
        
        // Unchanged fields
        expect(updated.id, equals(farmerProfile.id));
        expect(updated.email, equals(farmerProfile.email));
        expect(updated.farmLocation, equals(farmerProfile.farmLocation));
      });
    });

    group('Buyer Profile Tests', () {
      late UserProfile buyerProfile;

      setUp(() {
        buyerProfile = UserProfile(
          id: 'buyer-456',
          email: 'jane.smith@coffeeimport.com',
          phoneNumber: '+254798765432',
          role: UserRole.buyer,
          displayName: 'Jane Smith',
          photoUrl: 'https://example.com/jane.jpg',
          isVerified: false,
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
          businessName: 'Premium Coffee Imports Ltd',
          businessType: 'Importer',
          monthlyVolume: 2000.0,
          verificationStatus: VerificationStatus.pending,
          fcmToken: 'fcm-token-456',
        );
      });

      test('Should create buyer profile with all fields', () {
        expect(buyerProfile.id, equals('buyer-456'));
        expect(buyerProfile.email, equals('jane.smith@coffeeimport.com'));
        expect(buyerProfile.phoneNumber, equals('+254798765432'));
        expect(buyerProfile.role, equals(UserRole.buyer));
        expect(buyerProfile.displayName, equals('Jane Smith'));
        expect(buyerProfile.photoUrl, equals('https://example.com/jane.jpg'));
        expect(buyerProfile.isVerified, isFalse);
        expect(buyerProfile.businessName, equals('Premium Coffee Imports Ltd'));
        expect(buyerProfile.businessType, equals('Importer'));
        expect(buyerProfile.monthlyVolume, equals(2000.0));
        expect(
          buyerProfile.verificationStatus,
          equals(VerificationStatus.pending),
        );
      });

      test('Should have null farmer-specific fields', () {
        expect(buyerProfile.farmSize, isNull);
        expect(buyerProfile.farmLocation, isNull);
        expect(buyerProfile.coffeeVarieties, isNull);
        expect(buyerProfile.farmRegistrationNumber, isNull);
      });

      test('Should convert buyer profile to JSON', () {
        final json = buyerProfile.toJson();

        expect(json['id'], equals('buyer-456'));
        expect(json['role'], equals('buyer'));
        expect(json['businessName'], equals('Premium Coffee Imports Ltd'));
        expect(json['businessType'], equals('Importer'));
        expect(json['monthlyVolume'], equals(2000.0));
        expect(json['verificationStatus'], equals('pending'));
      });

      test('Should create buyer profile from JSON', () {
        final json = buyerProfile.toJson();
        final recreated = UserProfile.fromJson(json);

        expect(recreated.id, equals(buyerProfile.id));
        expect(recreated.role, equals(buyerProfile.role));
        expect(recreated.businessName, equals(buyerProfile.businessName));
        expect(recreated.businessType, equals(buyerProfile.businessType));
        expect(recreated.monthlyVolume, equals(buyerProfile.monthlyVolume));
      });

      test('Should copy buyer profile with updated fields', () {
        final updated = buyerProfile.copyWith(
          businessName: 'Premium Coffee Imports International',
          monthlyVolume: 2500.0,
          isVerified: true,
          verificationStatus: VerificationStatus.verified,
        );

        expect(
          updated.businessName,
          equals('Premium Coffee Imports International'),
        );
        expect(updated.monthlyVolume, equals(2500.0));
        expect(updated.isVerified, isTrue);
        expect(updated.verificationStatus, equals(VerificationStatus.verified));
        
        // Unchanged
        expect(updated.id, equals(buyerProfile.id));
        expect(updated.email, equals(buyerProfile.email));
      });
    });

    group('Verification Status Tests', () {
      test('Should create unverified profile by default', () {
        final profile = UserProfile(
          id: 'user-789',
          email: 'test@example.com',
          phoneNumber: '+254712345678',
          role: UserRole.farmer,
          displayName: 'Test User',
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        expect(profile.isVerified, isFalse);
        expect(profile.verificationStatus, equals(VerificationStatus.unverified));
      });

      test('Should handle all verification statuses', () {
        final statuses = [
          VerificationStatus.unverified,
          VerificationStatus.pending,
          VerificationStatus.verified,
          VerificationStatus.rejected,
        ];

        for (final status in statuses) {
          final profile = UserProfile(
            id: 'user-test',
            email: 'test@example.com',
            phoneNumber: '+254712345678',
            role: UserRole.farmer,
            displayName: 'Test User',
            createdAt: testCreatedAt,
            updatedAt: testUpdatedAt,
            verificationStatus: status,
          );

          expect(profile.verificationStatus, equals(status));
        }
      });
    });

    group('Optional Fields Tests', () {
      test('Should create profile without photo URL', () {
        final profile = UserProfile(
          id: 'user-no-photo',
          email: 'nophoto@example.com',
          phoneNumber: '+254712345678',
          role: UserRole.farmer,
          displayName: 'No Photo User',
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        expect(profile.photoUrl, isNull);
      });

      test('Should create profile without FCM token', () {
        final profile = UserProfile(
          id: 'user-no-fcm',
          email: 'nofcm@example.com',
          phoneNumber: '+254712345678',
          role: UserRole.farmer,
          displayName: 'No FCM User',
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        expect(profile.fcmToken, isNull);
      });

      test('Should create farmer without optional farmer fields', () {
        final farmer = UserProfile(
          id: 'minimal-farmer',
          email: 'farmer@example.com',
          phoneNumber: '+254712345678',
          role: UserRole.farmer,
          displayName: 'Minimal Farmer',
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        expect(farmer.farmSize, isNull);
        expect(farmer.farmLocation, isNull);
        expect(farmer.coffeeVarieties, isNull);
        expect(farmer.farmRegistrationNumber, isNull);
      });

      test('Should create buyer without optional buyer fields', () {
        final buyer = UserProfile(
          id: 'minimal-buyer',
          email: 'buyer@example.com',
          phoneNumber: '+254712345678',
          role: UserRole.buyer,
          displayName: 'Minimal Buyer',
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        expect(buyer.businessName, isNull);
        expect(buyer.businessType, isNull);
        expect(buyer.monthlyVolume, isNull);
      });
    });

    group('Edge Cases Tests', () {
      test('Should handle empty coffee varieties list', () {
        final farmer = UserProfile(
          id: 'farmer-empty-varieties',
          email: 'farmer@example.com',
          phoneNumber: '+254712345678',
          role: UserRole.farmer,
          displayName: 'Test Farmer',
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
          coffeeVarieties: [],
        );

        expect(farmer.coffeeVarieties, isEmpty);
      });

      test('Should handle single coffee variety', () {
        final farmer = UserProfile(
          id: 'farmer-one-variety',
          email: 'farmer@example.com',
          phoneNumber: '+254712345678',
          role: UserRole.farmer,
          displayName: 'Test Farmer',
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
          coffeeVarieties: ['Arabica'],
        );

        expect(farmer.coffeeVarieties, hasLength(1));
        expect(farmer.coffeeVarieties!.first, equals('Arabica'));
      });

      test('Should handle multiple coffee varieties', () {
        final varieties = ['Arabica', 'Robusta', 'SL28', 'SL34', 'Batian'];
        final farmer = UserProfile(
          id: 'farmer-many-varieties',
          email: 'farmer@example.com',
          phoneNumber: '+254712345678',
          role: UserRole.farmer,
          displayName: 'Test Farmer',
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
          coffeeVarieties: varieties,
        );

        expect(farmer.coffeeVarieties, hasLength(5));
        expect(farmer.coffeeVarieties, equals(varieties));
      });

      test('Should handle zero farm size', () {
        final farmer = UserProfile(
          id: 'farmer-zero-size',
          email: 'farmer@example.com',
          phoneNumber: '+254712345678',
          role: UserRole.farmer,
          displayName: 'Test Farmer',
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
          farmSize: 0.0,
        );

        expect(farmer.farmSize, equals(0.0));
      });

      test('Should handle large farm size', () {
        final farmer = UserProfile(
          id: 'farmer-large',
          email: 'farmer@example.com',
          phoneNumber: '+254712345678',
          role: UserRole.farmer,
          displayName: 'Test Farmer',
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
          farmSize: 999.9,
        );

        expect(farmer.farmSize, equals(999.9));
      });

      test('Should handle zero monthly volume', () {
        final buyer = UserProfile(
          id: 'buyer-zero-volume',
          email: 'buyer@example.com',
          phoneNumber: '+254712345678',
          role: UserRole.buyer,
          displayName: 'Test Buyer',
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
          monthlyVolume: 0.0,
        );

        expect(buyer.monthlyVolume, equals(0.0));
      });

      test('Should handle large monthly volume', () {
        final buyer = UserProfile(
          id: 'buyer-large-volume',
          email: 'buyer@example.com',
          phoneNumber: '+254712345678',
          role: UserRole.buyer,
          displayName: 'Test Buyer',
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
          monthlyVolume: 50000.0,
        );

        expect(buyer.monthlyVolume, equals(50000.0));
      });
    });

    group('Contact Information Tests', () {
      test('Should handle different email formats', () {
        final emails = [
          'simple@example.com',
          'with.dots@example.com',
          'with+plus@example.com',
          'with-dash@example.com',
          'user@subdomain.example.com',
        ];

        for (final email in emails) {
          final profile = UserProfile(
            id: 'user-$email',
            email: email,
            phoneNumber: '+254712345678',
            role: UserRole.farmer,
            displayName: 'Test User',
            createdAt: testCreatedAt,
            updatedAt: testUpdatedAt,
          );

          expect(profile.email, equals(email));
        }
      });

      test('Should handle different phone number formats', () {
        final phoneNumbers = [
          '+254712345678',
          '+254798765432',
          '+1234567890123',
          '+44123456789',
        ];

        for (final phone in phoneNumbers) {
          final profile = UserProfile(
            id: 'user-$phone',
            email: 'test@example.com',
            phoneNumber: phone,
            role: UserRole.farmer,
            displayName: 'Test User',
            createdAt: testCreatedAt,
            updatedAt: testUpdatedAt,
          );

          expect(profile.phoneNumber, equals(phone));
        }
      });
    });

    group('Timestamp Tests', () {
      test('Should handle same createdAt and updatedAt', () {
        final now = DateTime.now();
        final profile = UserProfile(
          id: 'user-same-time',
          email: 'test@example.com',
          phoneNumber: '+254712345678',
          role: UserRole.farmer,
          displayName: 'Test User',
          createdAt: now,
          updatedAt: now,
        );

        expect(profile.createdAt, equals(profile.updatedAt));
      });

      test('Should have updatedAt after createdAt', () {
        final created = DateTime(2024, 1, 1);
        final updated = DateTime(2024, 2, 1);
        
        final profile = UserProfile(
          id: 'user-timeline',
          email: 'test@example.com',
          phoneNumber: '+254712345678',
          role: UserRole.farmer,
          displayName: 'Test User',
          createdAt: created,
          updatedAt: updated,
        );

        expect(profile.updatedAt.isAfter(profile.createdAt), isTrue);
      });
    });
  });
}
