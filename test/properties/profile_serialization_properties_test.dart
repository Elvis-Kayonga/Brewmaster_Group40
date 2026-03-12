// Feature: brewmaster-marketplace, Property 2: Profile Data Persistence Round-Trip
// **Validates: Requirements 1.3, 1.4, 1.6**
//
// Property: For any user profile (farmer or buyer), saving the profile then
// retrieving it should produce an equivalent profile with all required fields intact.

import 'package:flutter_test/flutter_test.dart';
import 'package:faker/faker.dart';

import 'package:brewmaster/domain/models/user_profile.dart';
import 'package:brewmaster/domain/models/enums.dart';

// --- Helper to generate random farmer profiles ---

UserProfile generateFarmerProfile(Faker faker) {
  final now = DateTime.now();
  return UserProfile(
    id: faker.guid.guid(),
    email: faker.internet.email(),
    phoneNumber: faker.phoneNumber.us(),
    role: UserRole.farmer,
    displayName: faker.person.name(),
    photoUrl: faker.randomGenerator.boolean()
        ? faker.internet.uri('https')
        : null,
    isVerified: faker.randomGenerator.boolean(),
    createdAt: now.subtract(Duration(days: faker.randomGenerator.integer(365))),
    updatedAt: now.subtract(Duration(days: faker.randomGenerator.integer(30))),
    farmSize: faker.randomGenerator.decimal(min: 0.5, scale: 10),
    farmLocation: faker.address.city(),
    coffeeVarieties: List.generate(
      faker.randomGenerator.integer(4, min: 1),
      (_) => faker.randomGenerator.element([
        'Bourbon',
        'Typica',
        'SL28',
        'Geisha',
        'Catuai',
      ]),
    ),
    farmRegistrationNumber: faker.randomGenerator.boolean()
        ? 'REG-${faker.randomGenerator.integer(99999, min: 10000)}'
        : null,
    businessName: null,
    businessType: null,
    monthlyVolume: null,
    fcmToken: faker.randomGenerator.boolean() ? faker.guid.guid() : null,
    verificationStatus: faker.randomGenerator.element(
      VerificationStatus.values,
    ),
  );
}

// --- Helper to generate random buyer profiles ---

UserProfile generateBuyerProfile(Faker faker) {
  final now = DateTime.now();
  return UserProfile(
    id: faker.guid.guid(),
    email: faker.internet.email(),
    phoneNumber: faker.phoneNumber.us(),
    role: UserRole.buyer,
    displayName: faker.person.name(),
    photoUrl: faker.randomGenerator.boolean()
        ? faker.internet.uri('https')
        : null,
    isVerified: faker.randomGenerator.boolean(),
    createdAt: now.subtract(Duration(days: faker.randomGenerator.integer(365))),
    updatedAt: now.subtract(Duration(days: faker.randomGenerator.integer(30))),
    farmSize: null,
    farmLocation: null,
    coffeeVarieties: null,
    farmRegistrationNumber: null,
    businessName: faker.company.name(),
    businessType: faker.randomGenerator.element([
      'Roaster',
      'Exporter',
      'Trader',
      'Retailer',
    ]),
    monthlyVolume: faker.randomGenerator.decimal(min: 100, scale: 5000),
    fcmToken: faker.randomGenerator.boolean() ? faker.guid.guid() : null,
    verificationStatus: faker.randomGenerator.element(
      VerificationStatus.values,
    ),
  );
}

// --- Helper to verify all fields match between original and round-tripped profile ---

void expectProfileFieldsMatch(
  UserProfile original,
  UserProfile roundTripped,
  int iteration,
) {
  // Required fields
  expect(
    roundTripped.id,
    equals(original.id),
    reason: 'id should survive round-trip (iteration $iteration)',
  );
  expect(
    roundTripped.email,
    equals(original.email),
    reason: 'email should survive round-trip (iteration $iteration)',
  );
  expect(
    roundTripped.phoneNumber,
    equals(original.phoneNumber),
    reason: 'phoneNumber should survive round-trip (iteration $iteration)',
  );
  expect(
    roundTripped.role,
    equals(original.role),
    reason: 'role should survive round-trip (iteration $iteration)',
  );
  expect(
    roundTripped.displayName,
    equals(original.displayName),
    reason: 'displayName should survive round-trip (iteration $iteration)',
  );
  expect(
    roundTripped.isVerified,
    equals(original.isVerified),
    reason: 'isVerified should survive round-trip (iteration $iteration)',
  );
  expect(
    roundTripped.verificationStatus,
    equals(original.verificationStatus),
    reason:
        'verificationStatus should survive round-trip (iteration $iteration)',
  );

  // DateTime fields — Timestamp conversion truncates to millisecond precision
  expect(
    roundTripped.createdAt.millisecondsSinceEpoch,
    equals(original.createdAt.millisecondsSinceEpoch),
    reason: 'createdAt should survive round-trip (iteration $iteration)',
  );
  expect(
    roundTripped.updatedAt.millisecondsSinceEpoch,
    equals(original.updatedAt.millisecondsSinceEpoch),
    reason: 'updatedAt should survive round-trip (iteration $iteration)',
  );

  // Optional fields
  expect(
    roundTripped.photoUrl,
    equals(original.photoUrl),
    reason: 'photoUrl should survive round-trip (iteration $iteration)',
  );
  expect(
    roundTripped.fcmToken,
    equals(original.fcmToken),
    reason: 'fcmToken should survive round-trip (iteration $iteration)',
  );

  // Farmer-specific fields
  expect(
    roundTripped.farmSize,
    equals(original.farmSize),
    reason: 'farmSize should survive round-trip (iteration $iteration)',
  );
  expect(
    roundTripped.farmLocation,
    equals(original.farmLocation),
    reason: 'farmLocation should survive round-trip (iteration $iteration)',
  );
  expect(
    roundTripped.coffeeVarieties,
    equals(original.coffeeVarieties),
    reason: 'coffeeVarieties should survive round-trip (iteration $iteration)',
  );
  expect(
    roundTripped.farmRegistrationNumber,
    equals(original.farmRegistrationNumber),
    reason:
        'farmRegistrationNumber should survive round-trip (iteration $iteration)',
  );

  // Buyer-specific fields
  expect(
    roundTripped.businessName,
    equals(original.businessName),
    reason: 'businessName should survive round-trip (iteration $iteration)',
  );
  expect(
    roundTripped.businessType,
    equals(original.businessType),
    reason: 'businessType should survive round-trip (iteration $iteration)',
  );
  expect(
    roundTripped.monthlyVolume,
    equals(original.monthlyVolume),
    reason: 'monthlyVolume should survive round-trip (iteration $iteration)',
  );
}

// --- Property Tests ---

void main() {
  final faker = Faker();

  group('Property 2: Profile Data Persistence Round-Trip', () {
    // Property 2a: Farmer profile round-trip preserves all fields
    test(
      'farmer profile toJson() then fromJson() produces equivalent profile (100 iterations)',
      () {
        for (int i = 0; i < 100; i++) {
          final original = generateFarmerProfile(faker);

          final json = original.toJson();
          final roundTripped = UserProfile.fromJson(json);

          expectProfileFieldsMatch(original, roundTripped, i);

          // Verify role is specifically farmer
          expect(
            roundTripped.role,
            equals(UserRole.farmer),
            reason: 'Farmer role should be preserved (iteration $i)',
          );
        }
      },
    );

    // Property 2b: Buyer profile round-trip preserves all fields
    test(
      'buyer profile toJson() then fromJson() produces equivalent profile (100 iterations)',
      () {
        for (int i = 0; i < 100; i++) {
          final original = generateBuyerProfile(faker);

          final json = original.toJson();
          final roundTripped = UserProfile.fromJson(json);

          expectProfileFieldsMatch(original, roundTripped, i);

          // Verify role is specifically buyer
          expect(
            roundTripped.role,
            equals(UserRole.buyer),
            reason: 'Buyer role should be preserved (iteration $i)',
          );
        }
      },
    );

    // Property 2c: All required fields are present after round-trip
    test(
      'all required fields are non-null after round-trip for any profile (100 iterations)',
      () {
        for (int i = 0; i < 100; i++) {
          final original = i.isEven
              ? generateFarmerProfile(faker)
              : generateBuyerProfile(faker);

          final json = original.toJson();
          final roundTripped = UserProfile.fromJson(json);

          // Required fields must never be null
          expect(
            roundTripped.id,
            isNotNull,
            reason: 'id must be non-null (iteration $i)',
          );
          expect(
            roundTripped.id,
            isNotEmpty,
            reason: 'id must be non-empty (iteration $i)',
          );
          expect(
            roundTripped.email,
            isNotNull,
            reason: 'email must be non-null (iteration $i)',
          );
          expect(
            roundTripped.phoneNumber,
            isNotNull,
            reason: 'phoneNumber must be non-null (iteration $i)',
          );
          expect(
            roundTripped.displayName,
            isNotNull,
            reason: 'displayName must be non-null (iteration $i)',
          );
          expect(
            roundTripped.isVerified,
            isNotNull,
            reason: 'isVerified must be non-null (iteration $i)',
          );
          expect(
            roundTripped.createdAt,
            isNotNull,
            reason: 'createdAt must be non-null (iteration $i)',
          );
          expect(
            roundTripped.updatedAt,
            isNotNull,
            reason: 'updatedAt must be non-null (iteration $i)',
          );
        }
      },
    );

    // Property 2d: Optional fields remain null when not set
    test(
      'optional fields remain null when not set after round-trip (100 iterations)',
      () {
        for (int i = 0; i < 100; i++) {
          final now = DateTime.now();
          // Create a minimal profile with all optional fields null
          final original = UserProfile(
            id: faker.guid.guid(),
            email: faker.internet.email(),
            phoneNumber: faker.phoneNumber.us(),
            role: i.isEven ? UserRole.farmer : UserRole.buyer,
            displayName: faker.person.name(),
            photoUrl: null,
            isVerified: false,
            createdAt: now,
            updatedAt: now,
            farmSize: null,
            farmLocation: null,
            coffeeVarieties: null,
            farmRegistrationNumber: null,
            businessName: null,
            businessType: null,
            monthlyVolume: null,
            fcmToken: null,
          );

          final json = original.toJson();
          final roundTripped = UserProfile.fromJson(json);

          expect(
            roundTripped.photoUrl,
            isNull,
            reason: 'photoUrl should remain null (iteration $i)',
          );
          expect(
            roundTripped.farmSize,
            isNull,
            reason: 'farmSize should remain null (iteration $i)',
          );
          expect(
            roundTripped.farmLocation,
            isNull,
            reason: 'farmLocation should remain null (iteration $i)',
          );
          expect(
            roundTripped.coffeeVarieties,
            isNull,
            reason: 'coffeeVarieties should remain null (iteration $i)',
          );
          expect(
            roundTripped.farmRegistrationNumber,
            isNull,
            reason: 'farmRegistrationNumber should remain null (iteration $i)',
          );
          expect(
            roundTripped.businessName,
            isNull,
            reason: 'businessName should remain null (iteration $i)',
          );
          expect(
            roundTripped.businessType,
            isNull,
            reason: 'businessType should remain null (iteration $i)',
          );
          expect(
            roundTripped.monthlyVolume,
            isNull,
            reason: 'monthlyVolume should remain null (iteration $i)',
          );
          expect(
            roundTripped.fcmToken,
            isNull,
            reason: 'fcmToken should remain null (iteration $i)',
          );
        }
      },
    );

    // Property 2e: Optional fields survive round-trip when present
    test('optional fields survive round-trip when present (100 iterations)', () {
      for (int i = 0; i < 100; i++) {
        // Generate a fully-populated profile (farmer has farmer fields, buyer has buyer fields)
        final original = i.isEven
            ? generateFarmerProfile(faker)
            : generateBuyerProfile(faker);

        final json = original.toJson();
        final roundTripped = UserProfile.fromJson(json);

        if (original.role == UserRole.farmer) {
          expect(
            roundTripped.farmSize,
            equals(original.farmSize),
            reason: 'farmSize should survive when present (iteration $i)',
          );
          expect(
            roundTripped.farmLocation,
            equals(original.farmLocation),
            reason: 'farmLocation should survive when present (iteration $i)',
          );
          expect(
            roundTripped.coffeeVarieties,
            equals(original.coffeeVarieties),
            reason:
                'coffeeVarieties should survive when present (iteration $i)',
          );
        } else {
          expect(
            roundTripped.businessName,
            equals(original.businessName),
            reason: 'businessName should survive when present (iteration $i)',
          );
          expect(
            roundTripped.businessType,
            equals(original.businessType),
            reason: 'businessType should survive when present (iteration $i)',
          );
          expect(
            roundTripped.monthlyVolume,
            equals(original.monthlyVolume),
            reason: 'monthlyVolume should survive when present (iteration $i)',
          );
        }
      }
    });
  });
}
