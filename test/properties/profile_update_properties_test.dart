// Feature: brewmaster-marketplace, Property 4: Profile Update Synchronization
// **Validates: Requirements 1.8**
//
// Property: For any profile update operation, the changes should be persisted
// to Firestore and retrievable in subsequent queries.

import 'package:flutter_test/flutter_test.dart';
import 'package:faker/faker.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

import 'package:brewmaster/domain/models/user_profile.dart';
import 'package:brewmaster/domain/models/enums.dart';
import 'package:brewmaster/data/repositories/firebase_user_repository.dart';

// --- Helpers ---

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
    farmRegistrationNumber:
        'REG-${faker.randomGenerator.integer(99999, min: 10000)}',
    businessName: null,
    businessType: null,
    monthlyVolume: null,
    fcmToken: faker.randomGenerator.boolean() ? faker.guid.guid() : null,
    verificationStatus: faker.randomGenerator.element(
      VerificationStatus.values,
    ),
  );
}

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

UserProfile generateProfile(Faker faker, int iteration) {
  return iteration.isEven
      ? generateFarmerProfile(faker)
      : generateBuyerProfile(faker);
}

// --- Property Tests ---

void main() {
  final faker = Faker();

  group('Property 4: Profile Update Synchronization', () {
    // 4a: Create then retrieve returns the same profile
    test(
      'creating a profile then retrieving it returns equivalent data (100 iterations)',
      () async {
        for (int i = 0; i < 100; i++) {
          final firestore = FakeFirebaseFirestore();
          final repo = FirebaseUserRepository(firestore: firestore);
          final profile = generateProfile(faker, i);

          await repo.createUserProfile(profile);
          final retrieved = await repo.getUserProfile(profile.id);

          expect(
            retrieved,
            isNotNull,
            reason:
                'Profile should be retrievable after creation (iteration $i)',
          );
          expect(
            retrieved!.id,
            equals(profile.id),
            reason: 'id mismatch (iteration $i)',
          );
          expect(
            retrieved.email,
            equals(profile.email),
            reason: 'email mismatch (iteration $i)',
          );
          expect(
            retrieved.displayName,
            equals(profile.displayName),
            reason: 'displayName mismatch (iteration $i)',
          );
          expect(
            retrieved.role,
            equals(profile.role),
            reason: 'role mismatch (iteration $i)',
          );
          expect(
            retrieved.phoneNumber,
            equals(profile.phoneNumber),
            reason: 'phoneNumber mismatch (iteration $i)',
          );
          expect(
            retrieved.isVerified,
            equals(profile.isVerified),
            reason: 'isVerified mismatch (iteration $i)',
          );
          expect(
            retrieved.verificationStatus,
            equals(profile.verificationStatus),
            reason: 'verificationStatus mismatch (iteration $i)',
          );
          expect(
            retrieved.farmSize,
            equals(profile.farmSize),
            reason: 'farmSize mismatch (iteration $i)',
          );
          expect(
            retrieved.farmLocation,
            equals(profile.farmLocation),
            reason: 'farmLocation mismatch (iteration $i)',
          );
          expect(
            retrieved.coffeeVarieties,
            equals(profile.coffeeVarieties),
            reason: 'coffeeVarieties mismatch (iteration $i)',
          );
          expect(
            retrieved.businessName,
            equals(profile.businessName),
            reason: 'businessName mismatch (iteration $i)',
          );
          expect(
            retrieved.businessType,
            equals(profile.businessType),
            reason: 'businessType mismatch (iteration $i)',
          );
          expect(
            retrieved.monthlyVolume,
            equals(profile.monthlyVolume),
            reason: 'monthlyVolume mismatch (iteration $i)',
          );
        }
      },
    );

    // 4b: Updating displayName, farmSize, businessName persists correctly
    test(
      'profile field updates are retrievable after update (100 iterations)',
      () async {
        for (int i = 0; i < 100; i++) {
          final firestore = FakeFirebaseFirestore();
          final repo = FirebaseUserRepository(firestore: firestore);
          final profile = generateProfile(faker, i);

          await repo.createUserProfile(profile);

          final newDisplayName = faker.person.name();
          final updates = <String, dynamic>{'displayName': newDisplayName};

          if (profile.role == UserRole.farmer) {
            updates['farmSize'] = faker.randomGenerator.decimal(
              min: 1,
              scale: 20,
            );
            updates['farmLocation'] = faker.address.city();
          } else {
            updates['businessName'] = faker.company.name();
            updates['monthlyVolume'] = faker.randomGenerator.decimal(
              min: 200,
              scale: 8000,
            );
          }

          await repo.updateUserProfile(profile.id, updates);
          final retrieved = await repo.getUserProfile(profile.id);

          expect(
            retrieved,
            isNotNull,
            reason: 'Profile should exist after update (iteration $i)',
          );
          expect(
            retrieved!.displayName,
            equals(newDisplayName),
            reason: 'displayName should reflect update (iteration $i)',
          );

          if (profile.role == UserRole.farmer) {
            expect(
              retrieved.farmSize,
              equals(updates['farmSize']),
              reason: 'farmSize should reflect update (iteration $i)',
            );
            expect(
              retrieved.farmLocation,
              equals(updates['farmLocation']),
              reason: 'farmLocation should reflect update (iteration $i)',
            );
          } else {
            expect(
              retrieved.businessName,
              equals(updates['businessName']),
              reason: 'businessName should reflect update (iteration $i)',
            );
            expect(
              retrieved.monthlyVolume,
              equals(updates['monthlyVolume']),
              reason: 'monthlyVolume should reflect update (iteration $i)',
            );
          }

          // Unchanged fields should remain intact
          expect(
            retrieved.id,
            equals(profile.id),
            reason: 'id should not change (iteration $i)',
          );
          expect(
            retrieved.email,
            equals(profile.email),
            reason: 'email should not change (iteration $i)',
          );
          expect(
            retrieved.role,
            equals(profile.role),
            reason: 'role should not change (iteration $i)',
          );
        }
      },
    );

    // 4c: Sequential updates — final state reflects the last update
    test(
      'sequential updates result in final state reflecting last update (100 iterations)',
      () async {
        for (int i = 0; i < 100; i++) {
          final firestore = FakeFirebaseFirestore();
          final repo = FirebaseUserRepository(firestore: firestore);
          final profile = generateProfile(faker, i);

          await repo.createUserProfile(profile);

          // Apply 3 sequential displayName updates
          String lastDisplayName = '';
          for (int j = 0; j < 3; j++) {
            lastDisplayName = faker.person.name();
            await repo.updateUserProfile(profile.id, {
              'displayName': lastDisplayName,
            });
          }

          final retrieved = await repo.getUserProfile(profile.id);

          expect(
            retrieved,
            isNotNull,
            reason:
                'Profile should exist after sequential updates (iteration $i)',
          );
          expect(
            retrieved!.displayName,
            equals(lastDisplayName),
            reason:
                'displayName should reflect the last update (iteration $i)',
          );
        }
      },
    );

    // 4d: Farmer-specific field updates persist correctly
    test(
      'farmer-specific field updates persist correctly (100 iterations)',
      () async {
        for (int i = 0; i < 100; i++) {
          final firestore = FakeFirebaseFirestore();
          final repo = FirebaseUserRepository(firestore: firestore);
          final profile = generateFarmerProfile(faker);

          await repo.createUserProfile(profile);

          final newFarmSize =
              faker.randomGenerator.decimal(min: 1, scale: 15);
          final newFarmLocation = faker.address.city();
          final newVarieties = List.generate(
            faker.randomGenerator.integer(3, min: 1),
            (_) => faker.randomGenerator.element([
              'Bourbon',
              'Typica',
              'SL28',
              'Geisha',
            ]),
          );
          final newRegNumber =
              'REG-${faker.randomGenerator.integer(99999, min: 10000)}';

          await repo.updateUserProfile(profile.id, {
            'farmSize': newFarmSize,
            'farmLocation': newFarmLocation,
            'coffeeVarieties': newVarieties,
            'farmRegistrationNumber': newRegNumber,
          });

          final retrieved = await repo.getUserProfile(profile.id);

          expect(
            retrieved,
            isNotNull,
            reason:
                'Farmer profile should exist after update (iteration $i)',
          );
          expect(
            retrieved!.farmSize,
            equals(newFarmSize),
            reason: 'farmSize should be updated (iteration $i)',
          );
          expect(
            retrieved.farmLocation,
            equals(newFarmLocation),
            reason: 'farmLocation should be updated (iteration $i)',
          );
          expect(
            retrieved.coffeeVarieties,
            equals(newVarieties),
            reason: 'coffeeVarieties should be updated (iteration $i)',
          );
          expect(
            retrieved.farmRegistrationNumber,
            equals(newRegNumber),
            reason:
                'farmRegistrationNumber should be updated (iteration $i)',
          );
        }
      },
    );

    // 4e: Buyer-specific field updates persist correctly
    test(
      'buyer-specific field updates persist correctly (100 iterations)',
      () async {
        for (int i = 0; i < 100; i++) {
          final firestore = FakeFirebaseFirestore();
          final repo = FirebaseUserRepository(firestore: firestore);
          final profile = generateBuyerProfile(faker);

          await repo.createUserProfile(profile);

          final newBusinessName = faker.company.name();
          final newBusinessType = faker.randomGenerator.element([
            'Roaster',
            'Exporter',
            'Trader',
            'Retailer',
          ]);
          final newMonthlyVolume = faker.randomGenerator.decimal(
            min: 100,
            scale: 10000,
          );

          await repo.updateUserProfile(profile.id, {
            'businessName': newBusinessName,
            'businessType': newBusinessType,
            'monthlyVolume': newMonthlyVolume,
          });

          final retrieved = await repo.getUserProfile(profile.id);

          expect(
            retrieved,
            isNotNull,
            reason:
                'Buyer profile should exist after update (iteration $i)',
          );
          expect(
            retrieved!.businessName,
            equals(newBusinessName),
            reason: 'businessName should be updated (iteration $i)',
          );
          expect(
            retrieved.businessType,
            equals(newBusinessType),
            reason: 'businessType should be updated (iteration $i)',
          );
          expect(
            retrieved.monthlyVolume,
            equals(newMonthlyVolume),
            reason: 'monthlyVolume should be updated (iteration $i)',
          );
        }
      },
    );
  });
}
