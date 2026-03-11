# Requirements Document

## Introduction

The BrewMaster app currently displays user profile information on the ProfileScreen but lacks the ability to edit that information. The Edit Profile Screen feature adds a dedicated screen that allows users to modify their editable profile fields (display name, photo URL, and role-specific details), validate input, persist changes through UserProvider, and navigate back to the ProfileScreen upon successful save.

## Glossary

- **EditProfileScreen**: The Flutter screen widget that presents an editable form pre-populated with the current user profile data.
- **ProfileScreen**: The existing read-only screen that displays user profile information and contains the "Edit Profile" navigation button.
- **UserProvider**: The ChangeNotifier-based state management class responsible for loading, creating, and updating user profiles via UserService.
- **UserProfile**: The domain model representing a user's profile, including common fields and role-specific fields for farmers and buyers.
- **Form**: The Flutter Form widget wrapping all editable fields, providing validation via a GlobalKey<FormState>.
- **Display_Name_Field**: The text input field for editing the user's display name.
- **Photo_URL_Field**: The text input field for editing the user's avatar photo URL.
- **Farm_Size_Field**: The numeric input field for editing a farmer's farm size in hectares.
- **Farm_Location_Field**: The text input field for editing a farmer's farm location.
- **Coffee_Varieties_Field**: The text input field for editing a farmer's comma-separated coffee varieties.
- **Farm_Registration_Number_Field**: The text input field for editing a farmer's registration number.
- **Business_Name_Field**: The text input field for editing a buyer's business name.
- **Business_Type_Field**: The text input field for editing a buyer's business type.
- **Monthly_Volume_Field**: The numeric input field for editing a buyer's monthly purchase volume in kilograms.

## Requirements

### Requirement 1: Navigation to Edit Profile Screen

**User Story:** As a user, I want to navigate to the Edit Profile Screen from the Profile Screen, so that I can modify my profile information.

#### Acceptance Criteria

1. WHEN the user taps the "Edit Profile" button on the ProfileScreen, THE EditProfileScreen SHALL navigate to the EditProfileScreen with the current UserProfile data.
2. THE EditProfileScreen SHALL display an AppBar with the title "Edit Profile" and a back navigation button.
3. WHEN the user taps the back navigation button on the EditProfileScreen, THE EditProfileScreen SHALL navigate back to the ProfileScreen without saving changes.

### Requirement 2: Pre-population of Editable Fields

**User Story:** As a user, I want to see my current profile information pre-filled in the edit form, so that I can see what values exist before making changes.

#### Acceptance Criteria

1. WHEN the EditProfileScreen loads, THE EditProfileScreen SHALL pre-populate the Display_Name_Field with the current UserProfile displayName value.
2. WHEN the EditProfileScreen loads, THE EditProfileScreen SHALL pre-populate the Photo_URL_Field with the current UserProfile photoUrl value, or leave the field empty when photoUrl is null.
3. WHILE the UserProfile role is farmer, THE EditProfileScreen SHALL pre-populate the Farm_Size_Field, Farm_Location_Field, Coffee_Varieties_Field, and Farm_Registration_Number_Field with the corresponding current UserProfile values.
4. WHILE the UserProfile role is buyer, THE EditProfileScreen SHALL pre-populate the Business_Name_Field, Business_Type_Field, and Monthly_Volume_Field with the corresponding current UserProfile values.

### Requirement 3: Role-Specific Field Display

**User Story:** As a user, I want to see only the fields relevant to my role, so that the edit form is not cluttered with irrelevant options.

#### Acceptance Criteria

1. WHILE the UserProfile role is farmer, THE EditProfileScreen SHALL display the Farm_Size_Field, Farm_Location_Field, Coffee_Varieties_Field, and Farm_Registration_Number_Field.
2. WHILE the UserProfile role is buyer, THE EditProfileScreen SHALL display the Business_Name_Field, Business_Type_Field, and Monthly_Volume_Field.
3. WHILE the UserProfile role is farmer, THE EditProfileScreen SHALL hide the Business_Name_Field, Business_Type_Field, and Monthly_Volume_Field.
4. WHILE the UserProfile role is buyer, THE EditProfileScreen SHALL hide the Farm_Size_Field, Farm_Location_Field, Coffee_Varieties_Field, and Farm_Registration_Number_Field.
5. THE EditProfileScreen SHALL display the UserProfile role as a read-only label, not as an editable field.
6. THE EditProfileScreen SHALL display the UserProfile verificationStatus as a read-only label, not as an editable field.

### Requirement 4: Form Input Validation

**User Story:** As a user, I want the app to validate my input before saving, so that I do not accidentally save invalid profile data.

#### Acceptance Criteria

1. WHEN the user submits the Form, THE Form SHALL validate that the Display_Name_Field contains a non-empty value after trimming whitespace.
2. IF the Display_Name_Field is empty after trimming, THEN THE Form SHALL display the validation message "Display name is required" below the Display_Name_Field.
3. WHEN the user enters a value in the Farm_Size_Field, THE Form SHALL validate that the value is a positive number.
4. IF the Farm_Size_Field contains a non-numeric or non-positive value, THEN THE Form SHALL display the validation message "Enter a valid farm size" below the Farm_Size_Field.
5. WHEN the user enters a value in the Monthly_Volume_Field, THE Form SHALL validate that the value is a non-negative number.
6. IF the Monthly_Volume_Field contains a non-numeric or negative value, THEN THE Form SHALL display the validation message "Enter a valid volume" below the Monthly_Volume_Field.
7. WHEN the user enters a value in the Photo_URL_Field, THE Form SHALL accept any string value including an empty string.

### Requirement 5: Saving Profile Changes

**User Story:** As a user, I want to save my edited profile information, so that my changes are persisted and visible on the Profile Screen.

#### Acceptance Criteria

1. WHEN the user taps the "Save Changes" button and the Form validation passes, THE EditProfileScreen SHALL call UserProvider.updateProfile with the UserProfile id and a map of the changed fields.
2. WHILE the UserProvider is processing the update, THE EditProfileScreen SHALL display a loading indicator on the "Save Changes" button and disable the button to prevent duplicate submissions.
3. WHEN UserProvider.updateProfile returns true, THE EditProfileScreen SHALL navigate back to the ProfileScreen.
4. IF UserProvider.updateProfile returns false, THEN THE EditProfileScreen SHALL display the UserProvider errorMessage in an error banner at the top of the Form.
5. THE EditProfileScreen SHALL include the updatedAt field set to the current DateTime in the update map sent to UserProvider.updateProfile.

### Requirement 6: Unsaved Changes Handling

**User Story:** As a user, I want to be warned if I try to leave the edit screen with unsaved changes, so that I do not accidentally lose my edits.

#### Acceptance Criteria

1. WHEN the user taps the back button and the Form contains modified values compared to the original UserProfile, THE EditProfileScreen SHALL display a confirmation dialog asking "Discard changes?".
2. WHEN the user confirms the discard action in the confirmation dialog, THE EditProfileScreen SHALL navigate back to the ProfileScreen without saving.
3. WHEN the user cancels the discard action in the confirmation dialog, THE EditProfileScreen SHALL remain on the EditProfileScreen with the current form values preserved.
4. WHEN the user taps the back button and the Form contains no modified values, THE EditProfileScreen SHALL navigate back to the ProfileScreen without displaying the confirmation dialog.

### Requirement 7: Accessibility

**User Story:** As a user with accessibility needs, I want the Edit Profile Screen to be usable with assistive technologies, so that I can edit my profile regardless of ability.

#### Acceptance Criteria

1. THE EditProfileScreen SHALL provide semantic labels for all input fields using the labelText property of each CustomTextField.
2. THE EditProfileScreen SHALL support keyboard navigation between all input fields using the tab order.
3. WHEN a validation error is displayed, THE EditProfileScreen SHALL make the error message accessible to screen readers via the field's errorText semantic property.
