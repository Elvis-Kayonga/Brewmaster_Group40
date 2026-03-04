# Implementation Plan: Edit Profile Screen

## Overview

Build the `EditProfileScreen` as a `StatefulWidget` with form pre-population, role-based conditional fields, validation, dirty-tracking, save via `UserProvider.updateProfile`, and unsaved-changes guard. Wire navigation from the existing `ProfileScreen`. Follow patterns established in `ProfileSetupScreen`.

## Tasks

- [x] 1. Create EditProfileScreen widget with form scaffold
  - [x] 1.1 Create `lib/presentation/screens/profile/edit_profile_screen.dart` with `EditProfileScreen` StatefulWidget
    - Accept `UserProfile` as a required constructor parameter
    - Initialize `GlobalKey<FormState>`, all `TextEditingController`s, and `_isSaving` state
    - Pre-populate controllers in `initState` from `userProfile` fields (null → empty string, `List<String>` joined by `', '`, `double` via `toString()`)
    - Dispose all controllers in `dispose`
    - Build `Scaffold` with `AppBar` titled "Edit Profile"
    - Wrap body in `SafeArea` → `SingleChildScrollView` → `Consumer<UserProvider>` → `Form`
    - Display role and verification status as read-only `StatusBadge` widgets
    - Add `CustomTextField` for Display Name (required, with validator) and Photo URL (no validation)
    - _Requirements: 1.2, 2.1, 2.2, 3.5, 3.6, 4.1, 4.2, 4.7, 7.1, 7.2, 7.3_

  - [x] 1.2 Implement `_buildFarmerFields()` and `_buildBuyerFields()` methods
    - Farmer fields: Farm Size, Farm Location, Coffee Varieties, Farm Registration Number — shown only when `role == UserRole.farmer`
    - Buyer fields: Business Name, Business Type, Monthly Volume — shown only when `role == UserRole.buyer`
    - Add validators for Farm Size (positive number) and Monthly Volume (non-negative number)
    - Pre-populate from `userProfile` values per Requirement 2.3, 2.4
    - _Requirements: 2.3, 2.4, 3.1, 3.2, 3.3, 3.4, 4.3, 4.4, 4.5, 4.6_

  - [ ]* 1.3 Write property tests for pre-population round trip (Property 1)
    - **Property 1: Pre-population round trip**
    - **Validates: Requirements 2.1, 2.2, 2.3, 2.4**

  - [ ]* 1.4 Write property tests for role-based field visibility (Property 2)
    - **Property 2: Role-based field visibility**
    - **Validates: Requirements 3.1, 3.2, 3.3, 3.4**

- [x] 2. Implement validation, dirty-tracking, and save logic
  - [x] 2.1 Implement `_hasChanges()` method
    - Compare each controller's current text against the original `userProfile` field value
    - Handle null-to-empty-string, `List<String>` join, and `double.toString()` conversions
    - Return `true` if any field differs
    - _Requirements: 6.1, 6.4_

  - [x] 2.2 Implement `_buildUpdateMap()` method
    - Construct `Map<String, dynamic>` from current form values with proper type conversions
    - Include `updatedAt: DateTime.now()`
    - Convert coffee varieties from comma-separated string to `List<String>`
    - Parse numeric fields via `double.tryParse`
    - Include only role-relevant fields
    - _Requirements: 5.1, 5.5_

  - [x] 2.3 Implement `_handleSave()` method
    - Validate form via `_formKey.currentState!.validate()`
    - Set `_isSaving = true`, call `UserProvider.updateProfile` with profile id and update map
    - On success (`true`): pop back to ProfileScreen
    - On failure (`false`): display `UserProvider.errorMessage` in an `ErrorBanner`
    - Set `_isSaving = false` after completion
    - Wire `CustomButton` with `isLoading: _isSaving` and disabled state
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5_

  - [ ]* 2.4 Write property tests for validation logic (Properties 3, 4, 5)
    - **Property 3: Display name rejects whitespace-only input**
    - **Property 4: Numeric field validation**
    - **Property 5: Photo URL accepts all strings**
    - **Validates: Requirements 4.1, 4.2, 4.3, 4.4, 4.5, 4.6, 4.7**

  - [ ]* 2.5 Write property tests for update map construction (Property 6)
    - **Property 6: Update map construction**
    - **Validates: Requirements 5.1, 5.5**

  - [ ]* 2.6 Write property tests for dirty detection (Property 7)
    - **Property 7: Dirty detection symmetry**
    - **Validates: Requirements 6.1, 6.4**

- [x] 3. Implement unsaved changes guard and navigation wiring
  - [x] 3.1 Implement `_confirmDiscard()` and `PopScope` guard
    - Wrap `Scaffold` with `PopScope` (or `WillPopScope` depending on Flutter version)
    - In `onPopInvokedWithResult`, check `_hasChanges()` — if true, show `AlertDialog` with "Discard changes?" title, "Cancel" and "Discard" actions
    - "Discard" pops the screen; "Cancel" keeps the user on the screen
    - If no changes, allow pop without dialog
    - _Requirements: 6.1, 6.2, 6.3, 6.4_

  - [x] 3.2 Wire navigation from ProfileScreen to EditProfileScreen
    - In `lib/presentation/screens/profile/profile_screen.dart`, replace the TODO in the "Edit Profile" button's `onPressed` with `Navigator.push` to `EditProfileScreen(userProfile: profile)`
    - Add the import for `EditProfileScreen`
    - _Requirements: 1.1, 1.2, 1.3_

- [x] 4. Checkpoint
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 5. Widget and unit tests
  - [ ]* 5.1 Write widget tests for EditProfileScreen
    - Test AppBar title shows "Edit Profile"
    - Test farmer fields visible for farmer role, hidden for buyer role (and vice versa)
    - Test role and verification status displayed as read-only labels
    - Test loading indicator on save button during save
    - Test error banner shown when save fails
    - Test back navigation without changes pops without dialog
    - Test back navigation with changes shows discard dialog
    - Test successful save navigates back
    - _Requirements: 1.2, 1.3, 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 5.2, 5.3, 5.4, 6.1, 6.2, 6.3, 6.4_

  - [ ]* 5.2 Write unit tests for edge cases
    - Profile with all null optional fields
    - Coffee varieties with trailing commas and extra spaces
    - Farm size of exactly 0 (invalid) vs 0.01 (valid)
    - Monthly volume of exactly 0 (valid) vs -1 (invalid)
    - _Requirements: 4.3, 4.4, 4.5, 4.6_

- [x] 6. Final checkpoint
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Property tests validate universal correctness properties from the design document
- The design uses Dart/Flutter — all code follows existing patterns from `ProfileSetupScreen`
- No changes needed to `UserProvider`, `UserService`, or `UserProfile` domain model
