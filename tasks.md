# Implementation Plan: BrewMaster Coffee Marketplace

## Overview

This implementation plan breaks down the BrewMaster mobile application into discrete coding tasks for a team of 6 developers working in parallel. The plan follows clean architecture principles (Models → Services → Providers → UI) and prioritizes offline-first functionality with Firebase integration.

**CRITICAL: This plan uses a foundation-first approach. Phase 0 MUST be completed before any other work begins to prevent conflicts, blockers, and friction between developers.**

## Developer Assignment Strategy

- **Developer 1**: Firebase + Authentication + Profiles + Verification + Security
- **Developer 2**: Listings + Search + Discovery
- **Developer 3**: Messaging + Notifications
- **Developer 4**: Payments + Escrow + Compliance
- **Developer 5**: Dashboard + Market Prices + Analytics
- **Developer 6**: UI/UX + Offline Sync + Integration + Testing

## Clean Architecture Folder Structure

**CRITICAL**: All code must follow the clean architecture folder structure defined in design.md "Project Structure" section:

- **presentation/**: UI layer (screens, widgets)
- **domain/**: Business logic layer (models, validators)
- **data/**: Data layer (services, providers, repositories)
- **config/**: App-wide configuration (theme, constants, routes)
- **utils/**: Helper utilities

See design.md for complete folder structure with all subfolders. Task 0.1 includes the bash commands to create all folders.

## Execution Strategy

See **EXECUTION_ORDER.md** and **PHASE_0_CHECKLIST.md** for detailed guidance on the foundation-first approach.

---

## Tasks

### 🚨 Phase 0: Critical Foundation (MUST COMPLETE FIRST - BLOCKS ALL OTHER WORK)

**NO OTHER WORK CAN START UNTIL THESE TASKS ARE COMPLETE**

These tasks establish the foundation that all other developers depend on. Estimated time: 2 days.

- [x] 0.1 Project initialization and Firebase configuration (Developer 1) - **BLOCKING TASK**
  - Create Flutter project with required dependencies (provider, firebase_core, firebase_auth, cloud_firestore, firebase_storage, firebase_messaging, image_picker, intl, connectivity_plus)
  - Set up Firebase project in Firebase Console (Firestore, Authentication, Storage, FCM)
  - Configure Firebase for Android (download google-services.json)
  - Generate firebase_options.dart using FlutterFire CLI
  - Enable Firestore offline persistence in code
  - Create firestore.rules file with basic security rules
  - Create firestore.indexes.json file
  - Set up clean architecture folder structure (see design.md "Project Structure" section):
    ```bash
    mkdir -p lib/presentation/screens/{auth,listings,search,messaging,payments,dashboard,profile}
    mkdir -p lib/presentation/widgets/{common,listing,message,dashboard}
    mkdir -p lib/domain/{models,validators}
    mkdir -p lib/data/{services,providers,repositories}
    mkdir -p lib/config/localization
    mkdir -p lib/utils
    mkdir -p test/{unit,properties,widgets}
    mkdir -p integration_test
    ```
  - Test Firebase connection (read/write to Firestore)
  - _Requirements: 9.1, 13.1, 13.2, 16.1 (Clean Architecture)_
  - _Developer: Developer 1_
  - **DELIVERABLE: Working Flutter project with Firebase configured that all developers can clone**

- [ ] 0.2 Create app theme and common widgets (Developer 6) - **BLOCKING TASK**
  - [ ] 0.2.1 Define app theme (Developer 6)
    - Create lib/config/theme.dart with AppTheme class
    - Define color scheme (primary: coffee brown/green, secondary, error: red, success: green, warning: yellow)
    - Define text styles (heading1: 24px bold, heading2: 20px bold, body: 16px regular, caption: 14px light)
    - Set up icon-driven navigation theme
    - Define spacing constants (padding8, padding16, padding24, margin8, margin16)
    - Define border radius constants
    - _Requirements: 10.1, 10.4, 16.1 (Clean Architecture)_
    - _Developer: Developer 6_
  
  - [ ] 0.2.2 Create reusable form widgets (Developer 6)
    - Create lib/presentation/widgets/common/custom_text_field.dart - **CRITICAL - everyone needs this**
    - Create lib/presentation/widgets/common/custom_button.dart - **CRITICAL - everyone needs this**
    - Create lib/presentation/widgets/common/custom_dropdown.dart
    - Create lib/presentation/widgets/common/date_picker_widget.dart
    - _Requirements: 1.5, 10.2, 16.1 (Clean Architecture)_
    - _Developer: Developer 6_
  
  - [ ] 0.2.3 Create common UI widgets (Developer 6)
    - Create lib/presentation/widgets/common/loading_indicator.dart
    - Create lib/presentation/widgets/common/empty_state_widget.dart
    - Create lib/presentation/widgets/common/error_state_widget.dart
    - Create lib/presentation/widgets/common/confirmation_dialog.dart
    - Create lib/presentation/widgets/common/status_badge.dart
    - _Requirements: 10.4, 10.5, 16.1 (Clean Architecture)_
    - _Developer: Developer 6_
  - **DELIVERABLE: Complete widget library that all UI developers will use**

- [ ] 0.3 Define ALL core data models (All Developers) - **BLOCKING TASK**
  - [x] 0.3.1 Create UserProfile model with validation (Developer 1)
    - Create lib/domain/models/user_profile.dart with UserProfile class
    - Fields: userId, email, phone, role, farmName, farmSize, location, varieties (farmer), businessName, businessType, purchaseVolume (buyer), verificationStatus, createdAt, updatedAt
    - Implement toJson() and fromJson() methods
    - Create lib/domain/validators/user_profile_validator.dart with validation logic
    - _Requirements: 1.3, 1.4, 15.4, 16.1 (Clean Architecture)_
    - _Developer: Developer 1_
  
  - [ ] 0.3.2 Create CoffeeListing model with validation (Developer 2)
    - Create lib/domain/models/coffee_listing.dart with CoffeeListing class
    - Fields: listingId, farmerId, variety, quantity, pricePerKg, processingMethod, altitude, harvestDate, qualityScore, description, images, location, status, createdAt, updatedAt
    - Define ProcessingMethod enum (washed, natural, honey)
    - Define ListingStatus enum (draft, active, sold, expired)
    - Implement toJson() and fromJson() methods
    - Create lib/domain/validators/coffee_listing_validator.dart with altitude and score validation
    - _Requirements: 2.1, 2.6, 8.4, 15.1, 16.1 (Clean Architecture)_
    - _Developer: Developer 2_
  
  - [ ] 0.3.3 Create Message and Conversation models (Developer 3)
    - Create lib/domain/models/message.dart with Message class
    - Fields: messageId, conversationId, senderId, receiverId, content, messageType, listingId (optional), isRead, createdAt
    - Define MessageType enum (text, listing_reference)
    - Create lib/domain/models/conversation.dart with Conversation class
    - Fields: conversationId, participantIds, lastMessage, unreadCount, createdAt, updatedAt
    - Implement toJson() and fromJson() for both
    - _Requirements: 5.2, 5.5, 16.1 (Clean Architecture)_
    - _Developer: Developer 3_
  
  - [ ] 0.3.4 Create EscrowTransaction model (Developer 4)
    - Create lib/domain/models/escrow_transaction.dart with EscrowTransaction class
    - Fields: transactionId, listingId, buyerId, farmerId, amount, paymentMethod, status, deliveryConfirmed, receiptConfirmed, disputeReason, createdAt, updatedAt
    - Define TransactionStatus enum (pending, paid, delivered, completed, disputed)
    - Define PaymentMethod enum (mpesa, mtn_mobile_money)
    - Implement toJson() and fromJson() methods
    - _Requirements: 6.1, 15.2, 16.1 (Clean Architecture)_
    - _Developer: Developer 4_
  
  - [ ] 0.3.5 Create supporting models (Developer 5)
    - Create lib/domain/models/market_price.dart (variety, lowPrice, avgPrice, highPrice, date)
    - Create lib/domain/models/enums.dart with VerificationStatus enum (unverified, pending, verified, rejected)
    - Create lib/domain/models/notification_payload.dart (type, title, body, data)
    - Create lib/domain/models/search_filters.dart (variety, method, minPrice, maxPrice, location, minAltitude, maxAltitude)
    - Create lib/domain/models/farmer_dashboard.dart (activeListings, totalEarnings, conversations, views, responseRate)
    - Create lib/domain/models/buyer_dashboard.dart (totalPurchases, conversations, savedListings)
    - Implement toJson() and fromJson() for all
    - _Requirements: 3.2, 7.1, 11.1, 11.2, 16.1 (Clean Architecture)_
    - _Developer: Developer 5_
  - **DELIVERABLE: All models defined so services can use them**

- [ ] 0.4 Create Entity Relationship Diagram (ERD) (Developer 1 + All Developers) - **BLOCKING TASK - ACADEMIC REQUIREMENT**
  - [x] 0.4.1 Create ERD before implementing Firestore (Developer 1 leads, All review)
    - Create ERD diagram showing all Firestore collections
    - Include all fields with exact names and types that will be in Firestore
    - Show relationships between collections (foreign keys, references)
    - Include primary keys for each collection
    - Document cardinality (one-to-one, one-to-many, many-to-many)
    - Save as ERD.png or ERD.pdf in project root
    - **CRITICAL**: ERD must be created BEFORE writing any Firestore code
    - **CRITICAL**: Field names in ERD must match Firestore exactly (same spelling, same casing)
    - _Requirements: 18.1 (ERD before implementation), 18.2 (ERD matches Firestore)_
    - _Developer: Developer 1 (lead), All developers review and approve_
  
  - [ ] 0.4.2 Review ERD with team (All Developers)
    - All developers review ERD for completeness
    - Verify all collections needed for their features are included
    - Verify field names match the models defined in Task 0.3
    - Get team consensus before proceeding
    - **DELIVERABLE: Approved ERD that all developers agree matches the models**
    - _Developer: All developers participate in review_

- [ ] 0.5 CHECKPOINT - Foundation complete (All Developers)
  - Verify Firebase connection works (can read/write to Firestore)
  - Verify all common widgets exist and can be imported
  - Verify AppTheme exists and can be used
  - Verify all models are defined and can be imported
  - Verify ERD is created and approved by all developers
  - Verify no compilation errors
  - Test basic app runs with theme applied
  - **CRITICAL: Announce in team chat that Phase 0 is complete and parallel development can begin**
  - _Developer: All developers verify they can use the foundation_

---

### ✅ Phase 1: Core Features (CAN START AFTER PHASE 0 COMPLETE)

**After Phase 0 is complete, these features can be developed in parallel without blocking each other.**

#### Authentication & Profiles (Developer 1)

- [ ] 1. Implement authentication system (Developer 1)
  - [ ] 1.1 Create AuthService
    - Create lib/data/services/auth_service.dart
    - Implement signUpWithEmail() and signUpWithPhone()
    - Implement signInWithEmail() and signInWithPhone()
    - Implement signOut() and password reset
    - Expose authStateChanges stream
    - _Requirements: 1.2, 1.7, 16.1 (Clean Architecture)_
    - _Developer: Developer 1_
  
  - [ ]* 1.2 Write property test for authentication methods
    - **Property 1: Authentication Method Support**
    - **Validates: Requirements 1.2**
    - _Developer: Developer 1_
  
  - [ ] 1.3 Create AuthProvider for state management
    - Create lib/data/providers/auth_provider.dart
    - Implement ChangeNotifier with currentUser state
    - Add loading and error state management
    - Implement signUp(), signIn(), signOut() methods
    - _Requirements: 1.2, 1.7, 16.1 (Clean Architecture), 16.2 (Provider state management)_
    - _Developer: Developer 1_
  
  - [ ]* 1.4 Write property test for session persistence
    - **Property 3: Session State Persistence**
    - **Validates: Requirements 1.7**
    - _Developer: Developer 1_

- [ ] 2. Build authentication UI screens (Developer 1)
  - [ ] 2.1 Create LoginScreen
    - Create lib/presentation/screens/auth/login_screen.dart
    - Build email/phone input forms with validation using CustomTextField from Phase 0
    - Add sign-in button with loading state using CustomButton from Phase 0
    - Add navigation to SignupScreen
    - Implement error message display using ErrorStateWidget from Phase 0
    - _Requirements: 1.2, 10.7, 16.1 (Clean Architecture)_
    - _Developer: Developer 1_
  
  - [ ] 2.2 Create SignupScreen
    - Create lib/presentation/screens/auth/signup_screen.dart
    - Build registration form with role selection (farmer/buyer) using CustomDropdown from Phase 0
    - Implement 3-step registration flow with icons
    - Add form validation
    - Navigate to ProfileSetupScreen after signup
    - Use CustomTextField and CustomButton from Phase 0
    - _Requirements: 1.1, 1.2, 16.1 (Clean Architecture)_
    - _Developer: Developer 1_
  
  - [ ] 2.3 Create ProfileSetupScreen
    - Create lib/presentation/screens/auth/profile_setup_screen.dart
    - Build farmer profile form (farm size, location, varieties) using CustomTextField and CustomDropdown
    - Build buyer profile form (business name, type, volume)
    - Add voice input buttons for text fields (placeholder for now, VoiceInputWidget comes later)
    - Implement profile save functionality
    - _Requirements: 1.3, 1.4, 1.5, 16.1 (Clean Architecture)_
    - _Developer: Developer 1_

- [ ] 3. Implement user profile management (Developer 1)
  - [ ] 3.1 Create UserService
    - Create lib/data/services/user_service.dart
    - Implement getUserProfile() and createUserProfile()
    - Implement updateUserProfile()
    - Implement uploadVerificationDocuments()
    - Expose watchUserProfile() stream
    - _Requirements: 1.6, 1.8, 7.2, 16.1 (Clean Architecture)_
    - _Developer: Developer 1_
  
  - [ ]* 3.2 Write property test for profile updates
    - **Property 4: Profile Update Synchronization**
    - **Validates: Requirements 1.8**
    - _Developer: Developer 1_
  
  - [ ] 3.3 Create UserProvider for state management
    - Create lib/data/providers/user_provider.dart
    - Manage user profile state
    - Handle profile loading and updates
    - Cache profile data for offline access
    - _Requirements: 1.6, 1.8, 16.1 (Clean Architecture), 16.2 (Provider state management)_
    - _Developer: Developer 1_
  
  - [ ] 3.4 Create ProfileScreen
    - Create lib/presentation/screens/profile/profile_screen.dart
    - Display user profile information
    - Add edit profile functionality
    - Show verification status badge using StatusBadge from Phase 0
    - Add verification request button
    - _Requirements: 7.1, 7.2, 16.1 (Clean Architecture)_
    - _Developer: Developer 1_

  - [ ]* 3.5 Write property test for UserProfile serialization
    - **Property 2: Profile Data Persistence Round-Trip**
    - **Validates: Requirements 1.3, 1.4, 1.6**
    - _Developer: Developer 1_

- [ ] 4. Checkpoint - Authentication and profiles complete (Developer 1 + Developer 6)
  - Ensure all authentication and profile tests pass
  - Verify offline profile caching works
  - Test on emulator/device
  - _Developer: Developer 1 (lead), Developer 6 (testing support)_


---

#### Listings & Search (Developer 2)

- [ ] 5. Implement listing management system (Developer 2)
  - [ ] 5.1 Create ListingService with CRUD operations, image upload, search with filters
    - Create lib/data/services/listing_service.dart
  - [ ]* 5.2 Write property tests for listing creation, offline queue, updates
  - [ ] 5.3 Create ListingProvider for state management
    - Create lib/data/providers/listing_provider.dart
  - _Requirements: 2.1, 2.2, 2.5, 2.7, 2.8, 4.2, 4.8, 16.1 (Clean Architecture), 16.2 (Provider state management)_
  - _Developer: Developer 2_

- [ ] 6. Build listing management UI (Developer 2)
  - [ ] 6.1 Create ListingFormScreen using CustomTextField, CustomDropdown, CustomButton from Phase 0
    - Create lib/presentation/screens/listings/listing_form_screen.dart
  - [ ] 6.2 Create ListingDetailScreen
    - Create lib/presentation/screens/listings/listing_detail_screen.dart
  - [ ] 6.3 Create MyListingsScreen
    - Create lib/presentation/screens/listings/my_listings_screen.dart
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.7, 4.6, 8.1, 8.3, 16.1 (Clean Architecture)_
  - _Developer: Developer 2_

- [ ] 7. Implement search and discovery system (Developer 2)
  - [ ] 7.1 Create SearchScreen with filters, sort options, using common widgets from Phase 0
    - Create lib/presentation/screens/search/search_screen.dart
  - [ ]* 7.2 Write property tests for search filters, text search, quality filtering
  - [ ] 7.3 Create listing card widget using StatusBadge from Phase 0
    - Create lib/presentation/widgets/listing/listing_card.dart
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.7, 4.8, 8.6, 16.1 (Clean Architecture)_
  - _Developer: Developer 2_

- [ ] 8. Checkpoint - Listings and search complete (Developer 2 + Developer 6)
  - _Developer: Developer 2 (lead), Developer 6 (testing support)_

---

#### Messaging & Notifications (Developer 3)

- [ ] 9. Implement messaging system (Developer 3)
  - [ ] 9.1 Create MessageService with conversation management, offline queue
    - Create lib/data/services/message_service.dart
  - [ ]* 9.2 Write property tests for message delivery, unread counts, read status
  - [ ] 9.3 Create MessageProvider for state management
    - Create lib/data/providers/message_provider.dart
  - _Requirements: 5.2, 5.3, 5.5, 5.6, 16.1 (Clean Architecture), 16.2 (Provider state management)_
  - _Developer: Developer 3_

- [ ] 10. Build messaging UI (Developer 3)
  - [ ] 10.1 Create ConversationsScreen using common widgets from Phase 0
    - Create lib/presentation/screens/messaging/conversations_screen.dart
  - [ ] 10.2 Create ChatScreen with message bubbles, voice input placeholder
    - Create lib/presentation/screens/messaging/chat_screen.dart
  - [ ]* 10.3 Write property test for listing references
  - _Requirements: 5.2, 5.5, 5.6, 5.7, 5.8, 16.1 (Clean Architecture)_
  - _Developer: Developer 3_

- [ ] 11. Implement notification system (Developer 3)
  - [ ] 11.1 Create NotificationService with FCM integration
  - [ ] 11.2 Create NotificationProvider
  - [ ]* 11.3 Write property test for notification preferences
  - [ ] 11.4 Integrate notifications with messaging
  - _Requirements: 5.4, 12.1, 12.2, 12.3, 12.6, 12.7_
  - _Developer: Developer 3_

- [ ] 12. Checkpoint - Messaging and notifications complete (Developer 3 + Developer 6)
  - _Developer: Developer 3 (lead), Developer 6 (testing support)_

---

#### Payments & Escrow (Developer 4)

- [ ] 13. Implement payment integration (Developer 4)
  - [ ] 13.1 Create PaymentService with escrow, M-Pesa/MTN integration, retry logic
  - [ ]* 13.2 Write property tests for transactions, status transitions, fund release, disputes, retry
  - [ ] 13.3 Create PaymentProvider for state management
  - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 6.6, 6.7, 6.8_
  - _Developer: Developer 4_

- [ ] 14. Build payment UI (Developer 4)
  - [ ] 14.1 Create PaymentScreen using CustomTextField, CustomButton from Phase 0
  - [ ] 14.2 Create TransactionDetailScreen with StatusBadge, ConfirmationDialog from Phase 0
  - [ ] 14.3 Create TransactionHistoryScreen
  - [ ]* 14.4 Write property test for transaction history
  - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 6.6, 6.7, 6.8, 15.3_
  - _Developer: Developer 4_

- [ ] 15. Implement payment security measures (Developer 4)
  - [ ] 15.1 Add payment data validation
  - [ ]* 15.2 Write property test for payment data security
  - _Requirements: 13.4_
  - _Developer: Developer 4_

- [ ] 16. Checkpoint - Payment system complete (Developer 4 + Developer 6)
  - _Developer: Developer 4 (lead), Developer 6 (testing support)_

---

#### Dashboard & Market Prices (Developer 5)

- [ ] 17. Implement market price system (Developer 5)
  - [ ] 17.1 Create MarketPriceService with daily sync, offline caching
  - [ ]* 17.2 Write property tests for market price structure, offline caching
  - [ ] 17.3 Create MarketPriceProvider
  - _Requirements: 3.1, 3.2, 3.4, 3.5_
  - _Developer: Developer 5_

- [ ] 18. Build market price UI (Developer 5)
  - [ ] 18.1 Create MarketPricesScreen using common widgets from Phase 0
  - [ ] 18.2 Create PriceGuidanceWidget
  - [ ]* 18.3 Write property test for price deviation warning
  - _Requirements: 3.1, 3.2, 3.3, 3.5, 3.6_
  - _Developer: Developer 5_

- [ ] 19. Implement dashboard system (Developer 5)
  - [ ] 19.1 Create DashboardService with metrics aggregation, trends, analytics
  - [ ]* 19.2 Write property tests for dashboard calculations, trends, caching
  - [ ] 19.3 Create DashboardProvider
  - _Requirements: 11.1, 11.2, 11.3, 11.4, 11.5_
  - _Developer: Developer 5_

- [ ] 20. Build dashboard UI (Developer 5)
  - [ ] 20.1 Create FarmerDashboardScreen using StatusBadge, LoadingIndicator from Phase 0
  - [ ] 20.2 Create BuyerDashboardScreen
  - _Requirements: 11.1, 11.2, 11.3, 11.4_
  - _Developer: Developer 5_

- [ ] 21. Checkpoint - Dashboard and prices complete (Developer 5 + Developer 6)
  - _Developer: Developer 5 (lead), Developer 6 (testing support)_

---

#### Offline Sync (Developer 6)

- [ ] 22. Implement offline sync system (Developer 6)
  - [ ] 22.1 Create OfflineSyncService with queue, retry logic, conflict resolution
  - [ ]* 22.2 Write property tests for offline queue, conflict resolution, sync timestamp
  - [ ] 22.3 Create ConnectivityProvider
  - _Requirements: 9.2, 9.3, 9.4, 9.5, 9.6_
  - _Developer: Developer 6_

- [ ] 23. Build offline support UI (Developer 6)
  - [ ] 23.1 Create SyncStatusIndicator widget
  - [ ] 23.2 Integrate offline indicators across app
  - _Requirements: 9.5, 9.6, 9.8_
  - _Developer: Developer 6_

- [ ] 24. Implement image handling for offline (Developer 6)
  - [ ] 24.1 Create ImageCompressionService with compression, queue, retry
  - [ ]* 24.2 Write property tests for image compression, caching
  - _Requirements: 9.7, 14.2_
  - _Developer: Developer 6_

---

### ✅ Phase 2: Integration & Polish (After Phase 1 Complete)

#### Verification System

- [ ] 25. Implement verification system (Developer 1)
  - [ ] 25.1 Create VerificationService with document upload
  - [ ]* 25.2 Write property tests for verification status, document collection
  - [ ] 25.3 Create VerificationProvider
  - _Requirements: 7.1, 7.2, 7.3_
  - _Developer: Developer 1_

- [ ] 26. Build verification UI (Developer 1 + Developer 2)
  - [ ] 26.1 Create VerificationRequestScreen (Developer 1)
  - [ ] 26.2 Create VerificationBadge widget and integrate into profiles and listings (Developer 2 creates widget, Developer 1 integrates into profiles, Developer 2 integrates into listings)
  - [ ]* 26.3 Write property tests for badge propagation, search prioritization, trusted buyer badge
  - _Requirements: 7.2, 7.4, 7.5, 7.6_
  - _Developer: Developer 1 + Developer 2_

#### Security & Compliance

- [ ] 27. Implement security measures (Developer 1)
  - [ ] 27.1 Configure Firestore security rules and deploy
  - [ ]* 27.2 Write property test for security rules
  - [ ] 27.3 Implement account deletion with cascading deletes
  - [ ]* 27.4 Write property test for data deletion
  - _Requirements: 13.3, 13.5_
  - _Developer: Developer 1_

- [ ] 28. Implement compliance features (Developer 4 + Developer 2)
  - [ ] 28.1 Add traceability data to models (Developer 2: listings, Developer 4: transactions, Developer 1: profiles)
  - [ ]* 28.2 Write property test for compliance data (Developer 4)
  - [ ] 28.3 Implement PDF export for transactions (Developer 4)
  - [ ]* 28.4 Write property test for PDF export (Developer 4)
  - _Requirements: 15.1, 15.2, 15.3, 15.4_
  - _Developer: Developer 4 (lead), Developer 2, Developer 1_

#### Accessibility & UI Polish

- [ ] 29. Implement accessibility features (Developer 6)
  - [ ] 29.1 Create VoiceInputWidget with speech recognition
  - [ ] 29.2 Implement localization (English, Kinyarwanda, Swahili)
  - [ ]* 29.3 Write property test for localization
  - [ ] 29.4 Implement error handling UI improvements
  - [ ]* 29.5 Write property test for error messages
  - _Requirements: 1.5, 5.7, 10.3, 10.6, 10.7_
  - _Developer: Developer 6_

- [ ] 30. Create main app integration (Developer 6 + Developer 1)
  - [ ] 30.1 Implement navigation structure with named routes, deep linking
  - [ ] 30.2 Create main app scaffold with navigation
  - [ ] 30.3 Wire all providers in main.dart (Developer 6 + Developer 1 for Firebase init)
  - [ ] 30.4 Connect all screens to navigation
  - [ ] 30.5 Integrate offline sync across all features
  - _Requirements: 9.1, 9.2, 9.3, 9.5, 10.1, 11.6_
  - _Developer: Developer 6 (lead), Developer 1 (Firebase), Developer 3 (notifications)_

---

### ✅ Phase 3: Performance, Testing & Deployment

#### Performance Optimization

- [ ] 31. Implement performance optimizations (Developer 6)
  - [ ] 31.1 Add pagination to all lists (ListingService, MessageService, TransactionService)
  - [ ]* 31.2 Write property test for pagination
  - [ ] 31.3 Implement Firestore batching with BatchWriteService
  - [ ]* 31.4 Write property test for batching
  - [ ] 31.5 Optimize image loading (lazy loading, caching, thumbnails)
  - [ ] 31.6 Profile app performance on low-end device (2GB RAM)
  - _Requirements: 14.1, 14.2, 14.3, 14.4, 14.5_
  - _Developer: Developer 6_

- [ ] 32. Checkpoint - Performance optimizations complete (Developer 6 + All)
  - _Developer: Developer 6 (lead), All developers test their features_

#### Testing

- [ ] 33. Set up testing infrastructure (Developer 6)
  - [ ] 33.1 Configure test environment with dependencies (test, faker, mockito)
  - [ ] 33.2 Create test folder structure (unit/, properties/, widgets/, integration/)
  - [ ] 33.3 Set up mock Firebase services
  - [ ] 33.4 Create TestDataGenerator utility
  - _Requirements: All_
  - _Developer: Developer 6_

- [ ] 34. Write integration tests (Developer 6 + Specialists)
  - [ ]* 34.1 Write end-to-end user flow tests (Developer 6 + Developer 1)
  - [ ]* 34.2 Write Firebase integration tests (Developer 6 + Developer 1)
  - [ ]* 34.3 Write payment integration tests (Developer 6 + Developer 4)
  - _Requirements: All_
  - _Developer: Developer 6 (lead), Developer 1, Developer 4_

- [ ] 35. Write widget tests (All Developers + Developer 6)
  - [ ]* 35.1 Test authentication screens (Developer 1 + Developer 6)
  - [ ]* 35.2 Test listing screens (Developer 2 + Developer 6)
  - [ ]* 35.3 Test messaging screens (Developer 3 + Developer 6)
  - [ ]* 35.4 Test payment screens (Developer 4 + Developer 6)
  - [ ]* 35.5 Test dashboard screens (Developer 5 + Developer 6)
  - _Developer: Each feature owner (lead), Developer 6 (testing support)_

- [ ] 36. Run all tests and fix issues (Developer 6 + All)
  - [ ] 36.1 Run all unit tests (Developer 6)
  - [ ]* 36.2 Run all property tests (100+ iterations each) (Developer 6)
  - [ ]* 36.3 Run all widget tests (Developer 6)
  - [ ]* 36.4 Run all integration tests (Developer 6)
  - [ ] 36.5 Verify test coverage (80%+ for services and models) (Developer 6)
  - _Requirements: All_
  - _Developer: Developer 6_

- [ ] 37. Checkpoint - All tests passing (Developer 6 + All)
  - _Developer: Developer 6 (lead), All developers review their feature tests_

#### Final Polish & Deployment

- [ ] 38. Polish UI and UX (Developer 6 + All)
  - [ ] 38.1 Refine visual design (consistent spacing, icons, color coding) (Developer 6)
  - [ ] 38.2 Improve error handling across all features (Developer 6 + All)
  - [ ] 38.3 Optimize user flows (reduce steps, add confirmations, auto-save) (Developer 6 + All)
  - _Requirements: 1.1, 10.1, 10.4, 10.5, 10.7_
  - _Developer: Developer 6 (lead), All developers improve their features_

- [ ] 39. Documentation and deployment preparation (Developer 6 + Developer 1 + Developer 4)
  - [ ] 39.1 Write technical documentation (Developer 6 + All for service docs)
  - [ ] 39.2 Create user documentation (Developer 6 + Developer 2)
  - [ ] 39.3 Prepare for deployment (Developer 6: app signing, Developer 1: Firebase production, Developer 4: payment APIs, All: device testing)
  - _Requirements: All_
  - _Developer: Developer 6 (lead), Developer 1 (Firebase), Developer 4 (payment APIs), Developer 2 (user guides)_

- [ ] 40. Final checkpoint - App ready for launch (All Developers)
  - All features implemented and tested
  - All tests passing
  - Documentation complete
  - Release build tested
  - Ready for deployment
  - _Developer: All developers participate in final review_

---

### ✅ Phase 4: Wrap-up Week (Week 5)

**Final polish, bug fixes, and deployment preparation**

- [ ] 41. Bug fixes and performance tuning (All Developers)
  - [ ] 41.1 Address remaining bugs from testing (All Developers)
    - Fix any bugs found during Phase 3 testing
    - Prioritize critical and high-priority bugs
    - Test fixes thoroughly
    - _Developer: All developers fix bugs in their areas_
  
  - [ ] 41.2 Final performance optimizations (Developer 6 + All)
    - Profile app on multiple devices
    - Optimize any performance bottlenecks found
    - Verify app meets performance targets (smooth on 2GB RAM devices)
    - _Developer: Developer 6 (lead), All developers optimize their features_
  
  - [ ] 41.3 Final UI/UX polish (Developer 6 + All)
    - Review entire app for consistency
    - Fix any UI inconsistencies
    - Improve animations and transitions
    - Verify accessibility features work correctly
    - _Developer: Developer 6 (lead), All developers review their screens_

- [ ] 42. Documentation completion (Developer 6 + All)
  - [ ] 42.1 Complete technical documentation (Developer 6 + All)
    - Finalize architecture documentation
    - Complete API documentation for all services
    - Document deployment procedures
    - Create troubleshooting guide
    - _Developer: Developer 6 (lead), All developers document their services_
  
  - [ ] 42.2 Complete user documentation (Developer 6 + Developer 2)
    - Finalize user guides for farmers and buyers
    - Create video tutorials (optional)
    - Complete FAQ document
    - Create quick start guide
    - _Developer: Developer 6 (lead), Developer 2 (user guides)_
  
  - [ ] 42.3 Create maintenance documentation (Developer 1 + Developer 6)
    - Document Firebase maintenance procedures
    - Document backup and recovery procedures
    - Create monitoring and alerting guide
    - Document common issues and solutions
    - _Developer: Developer 1 (Firebase), Developer 6 (general)_

- [ ] 43. User acceptance testing (All Developers)
  - [ ] 43.1 Conduct UAT with real users (All Developers)
    - Recruit test users (farmers and buyers)
    - Observe users using the app
    - Gather feedback on usability
    - Document issues and suggestions
    - _Developer: All developers participate in UAT sessions_
  
  - [ ] 43.2 Implement critical UAT feedback (All Developers)
    - Prioritize UAT feedback
    - Implement critical fixes and improvements
    - Re-test with users if needed
    - _Developer: All developers implement fixes in their areas_

- [ ] 44. Deployment preparation (Developer 1 + Developer 4 + Developer 6)
  - [ ] 44.1 Final security audit (Developer 1)
    - Review all Firestore security rules
    - Verify authentication flows are secure
    - Check for any security vulnerabilities
    - Test security rules thoroughly
    - _Developer: Developer 1_
  
  - [ ] 44.2 Production environment setup (Developer 1 + Developer 4)
    - Set up production Firebase project
    - Configure production payment APIs (Developer 4)
    - Set up production FCM
    - Verify all production credentials
    - Test production environment
    - _Developer: Developer 1 (Firebase), Developer 4 (payment APIs)_
  
  - [ ] 44.3 App store submission preparation (Developer 6)
    - Create app store listings (Google Play)
    - Prepare screenshots and promotional materials
    - Write app descriptions
    - Create privacy policy and terms of service
    - Generate signed release APK/AAB
    - _Developer: Developer 6_
  
  - [ ] 44.4 Set up monitoring and analytics (Developer 1 + Developer 6)
    - Set up Firebase Analytics
    - Set up Crashlytics for error tracking
    - Configure performance monitoring
    - Set up alerts for critical issues
    - _Developer: Developer 1 (Firebase), Developer 6 (configuration)_

- [ ] 45. Knowledge transfer and handoff (All Developers)
  - [ ] 45.1 Team knowledge sharing session (All Developers)
    - Each developer presents their feature area
    - Share lessons learned
    - Document known issues and workarounds
    - Ensure all team members understand the full system
    - _Developer: All developers participate_
  
  - [ ] 45.2 Create support processes (Developer 6 + All)
    - Set up bug tracking system
    - Create support ticket workflow
    - Document escalation procedures
    - Assign on-call rotation (if applicable)
    - _Developer: Developer 6 (lead), All developers contribute_

- [ ] 46. Final checkpoint - Ready for production launch (All Developers)
  - All bugs fixed
  - All documentation complete
  - UAT successful
  - Production environment ready
  - App store submission ready
  - Monitoring and support processes in place
  - Team ready for launch
  - _Developer: All developers sign off_

---

### ✅ Phase 5: Academic Compliance & Submission (Week 5 - Final Days)

**Ensure all academic requirements are met for maximum marks**

- [ ] 47. Create Entity-Relationship Diagram (Developer 1 + All)
  - [ ] 47.1 Design ERD showing all Firestore collections (Developer 1)
    - Include all collections: users, listings, conversations, messages, transactions, marketPrices, verifications, notifications
    - Show all fields with data types
    - Show relationships between collections (foreign keys)
    - Show primary keys for each collection
    - Use standard ERD notation
    - _Requirements: 18.1_
    - _Developer: Developer 1_
  
  - [ ] 47.2 Verify ERD matches Firestore implementation exactly (All Developers)
    - Compare ERD field names to actual Firestore field names
    - Verify no extra or missing fields
    - Ensure data types match
    - Fix any discrepancies
    - _Requirements: 18.2_
    - _Developer: All developers verify their collections_

- [ ] 48. Implement and test academic requirements (Developer 6 + All)
  - [ ] 48.1 Implement SharedPreferences (Developer 6)
    - Theme preference (light/dark mode)
    - Language preference (English/Kinyarwanda/Swahili)
    - Notification preference (enabled/disabled)
    - Test persistence after app restart
    - _Requirements: 19.1, 19.2, 19.3, 19.4_
    - _Developer: Developer 6_
  
  - [ ] 48.2 Test responsive design on multiple screen sizes (All Developers)
    - Test on ≤ 5.5″ screen emulator
    - Test on ≥ 6.7″ screen emulator
    - Test landscape orientation on all screens
    - Fix any pixel overflow errors
    - Verify button tap target sizes (48x48dp minimum)
    - Verify color contrast ratios (4.5:1 minimum)
    - _Requirements: 20.1, 20.2, 20.3, 20.4, 20.5, 20.6_
    - _Developer: All developers test their screens_
  
  - [ ] 48.3 Write widget tests (Developer 6 + All)
    - Write widget test for LoginScreen (Developer 1 + Developer 6)
    - Write widget test for ListingFormScreen (Developer 2 + Developer 6)
    - Write widget test for SearchScreen (Developer 2 + Developer 6)
    - Ensure all widget tests pass
    - _Requirements: 17.1_
    - _Developer: Developer 6 (lead), feature owners assist_
  
  - [ ] 48.4 Write unit tests (All Developers)
    - Write unit test for UserProfile toJson/fromJson (Developer 1)
    - Write unit test for CoffeeListing toJson/fromJson (Developer 2)
    - Write unit test for UserProfileValidator (Developer 1)
    - Write unit test for CoffeeListingValidator (Developer 2)
    - Write unit test for AuthService method (Developer 1)
    - Write unit test for ListingService method (Developer 2)
    - Write unit test for MessageService method (Developer 3)
    - Ensure at least 3 unit tests total
    - _Requirements: 17.2_
    - _Developer: All developers write tests for their code_
  
  - [ ] 48.5 Achieve test coverage ≥ 70% (Developer 6)
    - Run `flutter test --coverage`
    - Generate coverage report
    - Identify untested code
    - Add tests to reach 70% coverage
    - Take screenshots of coverage report
    - _Requirements: 17.3, 17.5_
    - _Developer: Developer 6_
  
  - [ ] 48.6 Run flutter analyze and fix all issues (All Developers)
    - Run `flutter analyze`
    - Fix all warnings and errors
    - Run `dart format lib/ test/`
    - Take screenshot showing 0 issues
    - _Requirements: 16.1_
    - _Developer: All developers fix issues in their code_

- [ ] 49. Prepare project report (All Developers)
  - [ ] 49.1 Write report sections (All Developers)
    - Cover page with project title, group number, members, date (Developer 6)
    - Table of contents (Developer 6)
    - Executive summary (Developer 6)
    - Introduction: problem statement, objectives (Developer 2)
    - Methodology: development approach, technologies, AI disclosure (Developer 6)
    - Database architecture: ERD, collection descriptions, security rules (Developer 1)
    - Implemented functionalities: auth, CRUD, features (All contribute their features)
    - Testing: coverage screenshots, test results (Developer 6)
    - Known limitations and future work (All contribute)
    - Conclusion (Developer 6)
    - References in APA format (All contribute)
    - _Requirements: 22.1, 22.2, 22.3, 22.4, 22.5_
    - _Developer: All developers contribute sections_
  
  - [ ] 49.2 Add appendices to report (Developer 6 + All)
    - GitHub repository link (public or shared-access)
    - Setup instructions from README
    - App screenshots
    - Contribution table matching Git stats
    - Test coverage screenshots
    - Flutter analyze screenshot (0 issues)
    - _Requirements: 22.5_
    - _Developer: Developer 6 compiles, All provide content_
  
  - [ ] 49.3 Format and finalize report (Developer 6)
    - Apply Times New Roman font (12pt body, 14pt headings)
    - Verify all citations and references
    - Add relevant images/visuals
    - Proofread for errors
    - Save as Group40_Final_Project_Submission.pdf
    - _Requirements: 22.2, 22.6_
    - _Developer: Developer 6_

- [ ] 50. Record demo video (All Developers)
  - [ ] 50.1 Prepare for video recording (All Developers)
    - Build release APK: `flutter build apk --release`
    - Install APK on physical device
    - Set up screen recording on phone (AZ Screen Recorder or similar)
    - Set up Firebase Console screen recording on computer
    - Test audio quality
    - Plan who demonstrates which feature
    - _Requirements: 23.2_
    - _Developer: All developers participate_
  
  - [ ] 50.2 Record demo video showing all 7 required actions (All Developers)
    - Action 1: Cold-start launch from phone home screen (Developer 1)
    - Action 2: Register → logout → login (Developer 1)
    - Action 3: Visit every screen, rotate one to landscape (All take turns)
    - Action 4: CRUD with Firebase Console visible (Developer 2)
      - Create listing in app
      - Show in Firebase Console
      - Update listing
      - Show update in Console
      - Delete listing
      - Show deletion in Console
    - Action 5: State update affecting two widgets (Developer 3)
      - Send message
      - Show unread count updates in conversation list and app bar
    - Action 6: SharedPreferences persistence (Developer 6)
      - Change theme to dark mode
      - Close app completely
      - Reopen app
      - Show dark mode persisted
    - Action 7: Validation error with polite message (Developer 1)
      - Try invalid input
      - Show SnackBar error message
    - _Requirements: 23.1, 23.3, 23.4_
    - _Developer: All developers participate_
  
  - [ ] 50.3 Finalize video (Developer 6)
    - Verify video is 10-15 minutes
    - Verify ≥ 1080p quality
    - Verify clear audio
    - Verify no cuts or speed-ups
    - Verify every member spoke
    - Upload to required platform
    - _Requirements: 23.5, 23.6_
    - _Developer: Developer 6_

- [ ] 51. Final submission checklist (All Developers)
  - [ ] 51.1 Verify all academic requirements (Developer 6)
    - ERD created and matches Firestore exactly
    - Code organized into presentation/domain/data folders
    - Provider used for state management (no setState)
    - Widget tests + 3 unit tests with ≥70% coverage
    - Three SharedPreferences implemented and tested
    - Flutter analyze shows 0 issues
    - Tested on ≤ 5.5″ and ≥ 6.7″ screens
    - No pixel overflow in landscape
    - All team members contributed ≥ 15% of commits
    - Report follows template with proper formatting
    - Video shows all 7 required actions
    - _Requirements: All academic requirements_
    - _Developer: Developer 6 (lead), All verify_
  
  - [ ] 51.2 Final Git cleanup (All Developers)
    - Ensure all code is committed
    - Verify GitHub repository is public or shared-access
    - Verify README is complete
    - Verify all branches are merged
    - Tag final release: `git tag v1.0.0`
    - _Requirements: 21.6_
    - _Developer: All developers_
  
  - [ ] 51.3 Submit all deliverables (Developer 6)
    - Submit Group40_Final_Project_Submission.pdf
    - Submit GitHub repository link
    - Submit demo video link
    - Verify all files are accessible
    - _Requirements: 22.6, 23.1_
    - _Developer: Developer 6_

- [ ] 52. FINAL CHECKPOINT - Ready for academic submission (All Developers)
  - All academic requirements met
  - ERD matches Firestore
  - Tests pass with ≥70% coverage
  - Flutter analyze shows 0 issues
  - Report complete and formatted correctly
  - Video shows all 7 actions
  - GitHub repository accessible
  - All deliverables submitted
  - **READY FOR GRADING**
  - _Developer: All developers sign off_

---

## Notes

### Foundation-First Approach

This plan uses a **foundation-first approach** to prevent conflicts, blockers, and friction:

1. **Phase 0 (Days 1-2)**: Firebase setup, theme, common widgets, and all models MUST be completed first
2. **Phase 1 (Days 3-10)**: All developers work in parallel on their features using the foundation
3. **Phase 2 (Days 11-15)**: Integration and polish
4. **Phase 3 (Days 16-20)**: Testing and deployment

### Why Phase 0 Matters

**Without Phase 0:**
- Developer 2 builds ListingFormScreen but has no CustomTextField → has to rebuild later
- Developer 3 builds ChatScreen with custom styling → doesn't match app theme
- Developer 4 needs UserProfile model but Developer 1 hasn't defined it → blocked
- Everyone creates their own loading spinners → inconsistent UI

**With Phase 0:**
- Everyone uses the same CustomTextField → consistent UX
- Everyone uses AppTheme → consistent styling
- All models defined upfront → no blocking dependencies
- Common widgets exist → no duplication

### Developer Accountability

Each task and sub-task has been assigned to a specific developer to ensure clear ownership and accountability for remote team collaboration:

- **Developer 1 (Firebase & Auth Lead)**: 
  - Primary: Authentication, user profiles, verification, Firebase configuration, security rules
  - Support: Integration assistance, Firebase troubleshooting
  - Key deliverables: Auth system, profile management, verification system, security implementation

- **Developer 2 (Listings & Search Lead)**:
  - Primary: Coffee listings, search functionality, discovery features
  - Support: Verification badge integration, compliance data in listings
  - Key deliverables: Listing CRUD, search/filter system, listing UI

- **Developer 3 (Messaging & Notifications Lead)**:
  - Primary: In-app messaging, conversations, push notifications
  - Support: Notification integration in main.dart
  - Key deliverables: Messaging system, notification system, chat UI

- **Developer 4 (Payments & Compliance Lead)**:
  - Primary: Payment integration, escrow system, transaction management, compliance features
  - Support: PDF export, regulatory data capture
  - Key deliverables: Payment system, escrow flow, transaction history, compliance tools

- **Developer 5 (Dashboard & Analytics Lead)**:
  - Primary: Market prices, farmer/buyer dashboards, analytics, metrics
  - Support: Supporting models for other features
  - Key deliverables: Dashboard system, market price system, analytics UI

- **Developer 6 (Integration & Testing Lead)**:
  - Primary: UI/UX, offline sync, app integration, testing infrastructure, performance optimization
  - Support: Testing support for all features, integration coordination
  - Key deliverables: App theme, navigation, offline system, test suite, final integration

### Task Execution Guidelines

- **Phase 0 is mandatory** - no exceptions, no shortcuts
- Tasks marked with `*` are optional property-based tests and can be skipped for faster MVP delivery
- Each task references specific requirements for traceability
- Use the common widgets from Phase 0 in all UI code
- Follow the models defined in Phase 0 for all data
- Use feature branches and pull requests for code review
- Run tests locally before pushing code
- Merge frequently (daily) to avoid large conflicts
- Communicate when you need to change a shared interface
- Each developer is accountable for their assigned tasks

### Property-Based Testing

- Each property test should run minimum 100 iterations
- Use faker package to generate random test data
- Tag each test with: `// Feature: brewmaster-marketplace, Property {number}: {property_text}`
- Property tests validate universal correctness across all inputs
- Unit tests validate specific examples and edge cases

### Parallel Development Tips

- Phase 0 enables parallel development - don't skip it
- Developers 1-5 work on independent features in parallel after Phase 0
- Developer 6 coordinates integration and testing
- Use mock services for testing before Firebase is fully configured
- Communicate interface changes in team chat
- Hold daily standups to coordinate dependencies

### Testing Strategy

- Write tests alongside implementation (not after)
- Test services and models thoroughly (80%+ coverage)
- Test UI components for rendering and interactions
- Test integration points between components
- Test offline-to-online transitions extensively
- Test on low-end devices regularly

### Success Criteria

- All 57 correctness properties validated
- All 15 requirements fully implemented
- 80%+ test coverage for services and models
- App runs smoothly on devices with 2GB RAM
- Offline functionality works reliably
- Payment integration tested in staging
- Security rules prevent unauthorized access
- Compliance data captured for all transactions

## Developer Workload Summary

### Phase 0 (Foundation) - 2 days
- **Developer 1**: Firebase setup (~2 days)
- **Developer 6**: Theme + common widgets (~2 days)
- **All Developers**: Define their models (~2 days)

### Phase 1 (Parallel Features) - 8 days
- **Developer 1**: ~18 main tasks (Auth, profiles, verification prep)
- **Developer 2**: ~15 main tasks (Listings, search)
- **Developer 3**: ~12 main tasks (Messaging, notifications)
- **Developer 4**: ~16 main tasks (Payments, escrow)
- **Developer 5**: ~13 main tasks (Dashboard, market prices)
- **Developer 6**: ~12 main tasks (Offline sync, image handling)

### Phase 2 (Integration) - 5 days
- **All Developers**: Verification, security, compliance, accessibility, integration

### Phase 3 (Testing & Deployment) - 5 days
- **Developer 6 + All**: Performance, testing, polish, deployment

### Phase 4 (Wrap-up Week) - 5 days
- **All Developers**: Bug fixes, final polish, documentation updates, deployment preparation, user acceptance testing

**Total: ~25 days (5 weeks) for 6 developers - 4 weeks development + 1 week wrap-up**

## Additional Resources

- See **EXECUTION_ORDER.md** for detailed execution strategy and timeline
- See **PHASE_0_CHECKLIST.md** for detailed Phase 0 completion checklist
- See **requirements.md** for full requirements specification
- See **design.md** for technical architecture and correctness properties

