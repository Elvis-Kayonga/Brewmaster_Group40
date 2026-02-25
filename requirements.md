# Requirements Document

## Introduction

BrewMaster is a direct coffee marketplace platform that connects smallholder coffee farmers with specialty buyers, eliminating middlemen and providing price transparency, payment security, and quality verification. The platform addresses the critical challenge of 40-60% income loss to intermediaries while supporting farmers with intermittent connectivity (55% affected) and limited digital literacy.

The system must support offline-first operations, low-literacy users through voice input and icon-driven navigation, and work on low-end Android devices with minimal data usage. The platform targets smallholder farmers (0.5-5 hectare farms, ages 28-52) and specialty coffee buyers (roasters/exporters, ages 28-45).

## Glossary

- **Farmer**: A smallholder coffee producer who creates listings to sell coffee directly to buyers
- **Buyer**: A specialty coffee roaster, exporter, or trader who purchases coffee from farmers
- **Coffee_Listing**: A product listing created by a farmer containing coffee specifications, photos, quantity, and pricing
- **Market_Price_Index**: Real-time reference prices for different coffee varieties to guide fair pricing
- **Escrow_System**: A secure payment mechanism that holds buyer funds until delivery confirmation
- **Verification_Badge**: A trust indicator showing that a farmer or buyer has been verified by the platform
- **Quality_Profile**: Detailed coffee specifications including variety, altitude, processing method, and cupping scores
- **Offline_Sync**: The capability to use the app without internet and synchronize data when connectivity returns
- **Mobile_Money**: Digital payment systems like M-Pesa and MTN Mobile Money used in East Africa
- **Cupping_Score**: A standardized quality rating (0-100) used in specialty coffee evaluation
- **Processing_Method**: The technique used to prepare coffee (washed, natural, honey, etc.)
- **Coffee_Variety**: The specific type of coffee plant (e.g., Bourbon, Typica, SL28)

## Requirements

### Requirement 1: User Authentication and Profiles

**User Story:** As a farmer or buyer, I want to create an account and manage my profile, so that I can access the marketplace and build trust with trading partners.

#### Acceptance Criteria

1. WHEN a new user opens the app THEN THE Authentication_System SHALL display a simple 3-step registration process with icon-driven navigation
2. WHEN a user registers THEN THE Authentication_System SHALL support both email/password and Google sign-in authentication via Firebase
3. WHEN a farmer creates a profile THEN THE Profile_System SHALL collect farm size, location, coffee varieties grown, and contact information
4. WHEN a buyer creates a profile THEN THE Profile_System SHALL collect business name, business type, location, and purchasing volume
5. WHERE voice input is enabled THEN THE Profile_System SHALL allow users to dictate text fields using device speech recognition
6. WHEN a user completes profile setup THEN THE Profile_System SHALL persist all data to Firestore with offline support
7. WHEN a user logs in THEN THE Authentication_System SHALL maintain session state across app restarts
8. WHEN a user updates their profile THEN THE Profile_System SHALL sync changes to Firestore when connectivity is available

### Requirement 2: Coffee Listing Management

**User Story:** As a farmer, I want to create detailed coffee listings with photos and specifications, so that buyers can discover and evaluate my coffee.

#### Acceptance Criteria

1. WHEN a farmer creates a listing THEN THE Listing_System SHALL collect coffee variety, quantity (kg), altitude, processing method, harvest date, and asking price
2. WHEN a farmer adds photos THEN THE Listing_System SHALL allow up to 5 images and compress them for minimal data usage
3. WHEN a farmer enters a price THEN THE Listing_System SHALL display the current market price index for comparison
4. WHERE cupping scores are available THEN THE Listing_System SHALL allow farmers to add quality ratings (0-100 scale)
5. WHEN a farmer saves a listing offline THEN THE Listing_System SHALL queue it for upload when connectivity returns
6. WHEN a listing is created THEN THE Listing_System SHALL assign a unique identifier and timestamp
7. WHEN a farmer views their listings THEN THE Listing_System SHALL display all active, sold, and draft listings with status indicators
8. WHEN a farmer edits a listing THEN THE Listing_System SHALL update Firestore and maintain version history

### Requirement 3: Market Price Transparency

**User Story:** As a farmer, I want to see real-time market prices for different coffee varieties, so that I can price my coffee fairly and maximize my income.

#### Acceptance Criteria

1. WHEN a farmer views the market prices screen THEN THE Market_Price_System SHALL display current prices for major coffee varieties
2. WHEN market prices are displayed THEN THE Market_Price_System SHALL show price ranges (low, average, high) based on quality grades
3. WHEN a farmer creates a listing THEN THE Market_Price_System SHALL provide inline price guidance based on the selected variety and quality
4. WHEN market data is updated THEN THE Market_Price_System SHALL sync new prices from Firestore at least once per day
5. WHERE connectivity is unavailable THEN THE Market_Price_System SHALL display the most recent cached prices with a timestamp
6. WHEN a farmer's asking price deviates significantly from market price THEN THE Market_Price_System SHALL display a warning indicator

### Requirement 4: Search and Discovery

**User Story:** As a buyer, I want to search and filter coffee listings by variety, altitude, processing method, and location, so that I can find coffee that meets my quality requirements.

#### Acceptance Criteria

1. WHEN a buyer opens the search screen THEN THE Search_System SHALL display all available coffee listings with thumbnail images
2. WHEN a buyer applies filters THEN THE Search_System SHALL support filtering by variety, processing method, altitude range, location, and price range
3. WHEN a buyer searches by text THEN THE Search_System SHALL match against coffee variety, location, and farmer name
4. WHEN search results are displayed THEN THE Search_System SHALL show key attributes (variety, quantity, price, location, verification badge)
5. WHEN a buyer sorts results THEN THE Search_System SHALL support sorting by price, quantity, altitude, and listing date
6. WHEN a buyer views a listing detail THEN THE Search_System SHALL display all specifications, photos, farmer profile, and contact options
7. WHERE cupping scores exist THEN THE Search_System SHALL allow filtering by minimum quality score
8. WHEN search is performed offline THEN THE Search_System SHALL search cached listings and indicate data freshness

### Requirement 5: Direct Messaging

**User Story:** As a farmer or buyer, I want to message trading partners directly within the app, so that I can discuss quality, logistics, and negotiate terms.

#### Acceptance Criteria

1. WHEN a buyer views a listing THEN THE Messaging_System SHALL provide a "Contact Farmer" button to initiate a conversation
2. WHEN a message is sent THEN THE Messaging_System SHALL deliver it via Firestore real-time updates
3. WHEN a message is sent offline THEN THE Messaging_System SHALL queue it for delivery when connectivity returns
4. WHEN a new message arrives THEN THE Messaging_System SHALL display a push notification if the app is in background
5. WHEN a user views conversations THEN THE Messaging_System SHALL display all active chats with unread message counts
6. WHEN a user opens a conversation THEN THE Messaging_System SHALL load message history and mark messages as read
7. WHERE voice input is enabled THEN THE Messaging_System SHALL allow users to dictate messages
8. WHEN a message contains a listing reference THEN THE Messaging_System SHALL display a preview card with listing details

### Requirement 6: Escrow Payment System

**User Story:** As a farmer, I want secure escrow payments through mobile money, so that I am guaranteed to receive payment after delivery.

#### Acceptance Criteria

1. WHEN a buyer initiates a purchase THEN THE Payment_System SHALL create an escrow transaction with buyer, farmer, amount, and listing details
2. WHEN escrow is created THEN THE Payment_System SHALL integrate with M-Pesa and MTN Mobile Money APIs to collect buyer payment
3. WHEN buyer payment is received THEN THE Payment_System SHALL update transaction status to "Funds Held" and notify both parties
4. WHEN a farmer confirms delivery THEN THE Payment_System SHALL require buyer confirmation before releasing funds
5. WHEN buyer confirms receipt THEN THE Payment_System SHALL transfer funds to farmer's mobile money account within 24 hours
6. IF a dispute occurs THEN THE Payment_System SHALL hold funds and flag the transaction for manual review
7. WHEN a transaction completes THEN THE Payment_System SHALL record the transaction history with timestamps and status changes
8. WHEN payment fails THEN THE Payment_System SHALL retry up to 3 times and notify the user of the failure reason

### Requirement 7: Verification System

**User Story:** As a buyer, I want to see verification badges on farmer profiles, so that I can trust the seller and make informed purchasing decisions.

#### Acceptance Criteria

1. WHEN a farmer completes profile setup THEN THE Verification_System SHALL display their verification status (unverified, pending, verified)
2. WHEN a farmer requests verification THEN THE Verification_System SHALL collect supporting documents (farm registration, ID, photos)
3. WHEN verification documents are submitted THEN THE Verification_System SHALL flag the profile for admin review
4. WHEN a profile is verified THEN THE Verification_System SHALL display a verification badge on the farmer's profile and listings
5. WHEN a buyer views listings THEN THE Verification_System SHALL prioritize verified farmers in search results
6. WHEN a buyer completes multiple successful transactions THEN THE Verification_System SHALL award a "Trusted Buyer" badge
7. WHERE verification status changes THEN THE Verification_System SHALL notify the user via push notification

### Requirement 8: Quality Profiles and Specifications

**User Story:** As a buyer, I want to view detailed coffee specifications and quality ratings, so that I can assess if the coffee meets my standards before purchasing.

#### Acceptance Criteria

1. WHEN a buyer views a listing THEN THE Quality_Profile_System SHALL display variety, altitude, processing method, harvest date, and cupping score
2. WHEN quality attributes are displayed THEN THE Quality_Profile_System SHALL use standardized terminology (SCA standards)
3. WHERE cupping scores exist THEN THE Quality_Profile_System SHALL display flavor notes and defect counts
4. WHEN a farmer adds quality data THEN THE Quality_Profile_System SHALL validate that altitude is between 1000-2500m for specialty coffee
5. WHEN processing method is selected THEN THE Quality_Profile_System SHALL provide descriptions (washed, natural, honey, etc.)
6. WHEN a buyer filters by quality THEN THE Quality_Profile_System SHALL support minimum cupping score thresholds (80+, 85+, 90+)

### Requirement 9: Offline-First Architecture

**User Story:** As a farmer with intermittent connectivity, I want to use the app offline and have my data sync automatically, so that poor network conditions don't prevent me from managing my business.

#### Acceptance Criteria

1. WHEN the app starts THEN THE Offline_System SHALL enable Firestore offline persistence for all collections
2. WHEN a user performs actions offline THEN THE Offline_System SHALL queue all writes (listings, messages, profile updates) for synchronization
3. WHEN connectivity returns THEN THE Offline_System SHALL automatically sync queued operations to Firestore
4. WHEN data conflicts occur THEN THE Offline_System SHALL use last-write-wins strategy with timestamp comparison
5. WHEN the app is offline THEN THE Offline_System SHALL display a connectivity indicator in the app bar
6. WHEN cached data is displayed THEN THE Offline_System SHALL show the last sync timestamp
7. WHEN images are uploaded offline THEN THE Offline_System SHALL compress and queue them for background upload
8. WHEN sync completes THEN THE Offline_System SHALL notify the user of successful synchronization

### Requirement 10: Low-Literacy Support

**User Story:** As a farmer with limited literacy, I want icon-driven navigation and voice input, so that I can use the app effectively without extensive reading.

#### Acceptance Criteria

1. WHEN the app displays navigation THEN THE UI_System SHALL use clear icons with minimal text labels
2. WHEN a user interacts with forms THEN THE UI_System SHALL provide voice input buttons for all text fields
3. WHEN voice input is activated THEN THE UI_System SHALL use device speech recognition to transcribe speech to text
4. WHEN critical actions are required THEN THE UI_System SHALL use color coding (green for success, red for errors, yellow for warnings)
5. WHEN the app displays instructions THEN THE UI_System SHALL use simple language and visual demonstrations
6. WHERE language preferences are set THEN THE UI_System SHALL support English, Kinyarwanda, and Swahili
7. WHEN errors occur THEN THE UI_System SHALL display simple error messages with suggested actions

### Requirement 11: Dashboard and Analytics

**User Story:** As a farmer, I want to see a dashboard with my sales summary, active listings, and messages, so that I can monitor my business performance at a glance.

#### Acceptance Criteria

1. WHEN a farmer opens the dashboard THEN THE Dashboard_System SHALL display total listings, active conversations, pending transactions, and total earnings
2. WHEN a buyer opens the dashboard THEN THE Dashboard_System SHALL display saved searches, recent purchases, and active conversations
3. WHEN dashboard data is displayed THEN THE Dashboard_System SHALL show trends (earnings this month vs last month)
4. WHEN a farmer views analytics THEN THE Dashboard_System SHALL display listing views, message response rate, and average sale price
5. WHEN dashboard loads THEN THE Dashboard_System SHALL fetch data from Firestore with offline caching
6. WHEN a user taps a dashboard metric THEN THE Dashboard_System SHALL navigate to the detailed view (e.g., tap earnings → transaction history)

### Requirement 12: Notifications

**User Story:** As a user, I want to receive notifications for important events, so that I can respond quickly to messages, purchases, and payment updates.

#### Acceptance Criteria

1. WHEN a new message arrives THEN THE Notification_System SHALL send a push notification with sender name and message preview
2. WHEN a buyer initiates a purchase THEN THE Notification_System SHALL notify the farmer immediately
3. WHEN payment status changes THEN THE Notification_System SHALL notify both buyer and farmer with the new status
4. WHEN a listing receives interest THEN THE Notification_System SHALL notify the farmer of listing views
5. WHEN verification status changes THEN THE Notification_System SHALL notify the user
6. WHEN the app is in foreground THEN THE Notification_System SHALL display in-app notifications instead of push notifications
7. WHERE notification preferences are set THEN THE Notification_System SHALL respect user preferences for notification types

### Requirement 13: Data Security and Privacy

**User Story:** As a user, I want my personal and financial data to be secure, so that I can trust the platform with sensitive information.

#### Acceptance Criteria

1. WHEN user data is stored THEN THE Security_System SHALL use Firebase Authentication for identity management
2. WHEN data is transmitted THEN THE Security_System SHALL use HTTPS/TLS encryption for all network requests
3. WHEN Firestore rules are configured THEN THE Security_System SHALL enforce that users can only read/write their own data
4. WHEN payment data is processed THEN THE Security_System SHALL not store sensitive payment credentials in the app
5. WHEN a user deletes their account THEN THE Security_System SHALL remove all personal data from Firestore within 30 days
6. WHEN authentication tokens expire THEN THE Security_System SHALL prompt users to re-authenticate
7. WHERE location data is collected THEN THE Security_System SHALL request explicit user permission

### Requirement 14: Performance and Scalability

**User Story:** As a user with a low-end Android device, I want the app to load quickly and run smoothly, so that I can complete tasks efficiently despite hardware limitations.

#### Acceptance Criteria

1. WHEN the app launches THEN THE Performance_System SHALL display the main screen within 3 seconds on low-end devices
2. WHEN images are loaded THEN THE Performance_System SHALL use lazy loading and caching to minimize data usage
3. WHEN lists are displayed THEN THE Performance_System SHALL implement pagination with 20 items per page
4. WHEN the app runs THEN THE Performance_System SHALL maintain 60fps UI rendering on devices with 2GB RAM
5. WHEN data is synced THEN THE Performance_System SHALL batch Firestore operations to minimize read/write costs
6. WHEN the app is backgrounded THEN THE Performance_System SHALL release memory and pause non-critical operations

### Requirement 15: Regulatory Compliance

**User Story:** As a platform operator, I want to ensure compliance with coffee trading regulations, so that farmers and buyers can trade legally and maintain traceability for export.

#### Acceptance Criteria

1. WHEN a listing is created THEN THE Compliance_System SHALL record traceability data (farm location, harvest date, farmer ID)
2. WHEN a transaction completes THEN THE Compliance_System SHALL generate a transaction record with all required regulatory fields
3. WHEN export documentation is needed THEN THE Compliance_System SHALL provide exportable transaction history in PDF format
4. WHEN a farmer registers THEN THE Compliance_System SHALL collect farm registration numbers where required by local regulations
5. WHEN transaction records are stored THEN THE Compliance_System SHALL retain them for a minimum of 5 years for audit purposes


---

## Academic and Quality Assurance Requirements

These requirements ensure the project meets academic standards and grading criteria for the Mobile Application Development course.

### Requirement 16: Code Quality and Architecture

**User Story:** As a development team, we need to follow professional coding standards and clean architecture principles, so that our code is maintainable, testable, and meets academic evaluation criteria.

#### Acceptance Criteria

16.1. WHEN the codebase is analyzed THEN `flutter analyze` SHALL return zero issues (no warnings or errors)
16.2. WHEN the project structure is reviewed THEN THE code SHALL be organized into presentation/, domain/, and data/ layers following clean architecture
16.3. WHEN state management is implemented THEN THE application SHALL use Provider (or equivalent advanced state management) and avoid setState() in production code except for local UI state
16.4. WHEN variables and functions are named THEN THEY SHALL use descriptive names following Dart naming conventions (camelCase for variables, PascalCase for classes)
16.5. WHEN complex logic is implemented THEN THE code SHALL include comments explaining the logic
16.6. WHEN code is written THEN functions SHALL be extracted for reusability rather than duplicating code

### Requirement 17: Testing and Quality Assurance

**User Story:** As a development team, we need comprehensive testing to ensure code quality and meet academic requirements.

#### Acceptance Criteria

17.1. WHEN widget testing is implemented THEN THE test suite SHALL include widget tests for at least 3 key screens (Login, Listing Form, Search)
17.2. WHEN unit testing is implemented THEN THE test suite SHALL include at least 3 unit tests covering model serialization, validators, and service methods
17.3. WHEN test coverage is measured THEN THE coverage SHALL be ≥ 70% for services and models
17.4. WHEN tests are run THEN ALL tests SHALL pass before submission
17.5. WHEN test results are documented THEN screenshots of passing tests and coverage reports SHALL be included in the project report

### Requirement 18: Database Design and Documentation

**User Story:** As a development team, we need to design the database structure before implementation and ensure it matches our implementation exactly.

#### Acceptance Criteria

18.1. WHEN database design begins THEN AN Entity-Relationship Diagram (ERD) SHALL be created showing all collections, fields, relationships, primary keys, and foreign keys
18.2. WHEN Firestore is implemented THEN THE collections and field names SHALL match the ERD exactly (no deviations)
18.3. WHEN security is implemented THEN Firebase security rules SHALL limit data access to authorized users only (owners, participants)
18.4. WHEN indexes are needed THEN composite indexes SHALL be defined in firestore.indexes.json
18.5. WHEN the database is documented THEN THE project report SHALL include the ERD and explain the security rules

### Requirement 19: User Preferences and Settings

**User Story:** As a user, I want to customize my app experience with preferences that persist across app sessions.

#### Acceptance Criteria

19.1. WHEN theme preference is set THEN THE application SHALL save the user's choice (light/dark mode) using SharedPreferences
19.2. WHEN language preference is set THEN THE application SHALL save the user's choice (English/Kinyarwanda/Swahili) using SharedPreferences
19.3. WHEN notification preference is set THEN THE application SHALL save the user's choice (enabled/disabled) using SharedPreferences
19.4. WHEN the app is restarted THEN ALL preferences SHALL be restored from SharedPreferences
19.5. WHEN preferences are changed THEN THE UI SHALL update immediately to reflect the new settings

### Requirement 20: Responsive Design and Accessibility

**User Story:** As a user with different devices, I want the app to work correctly on various screen sizes and orientations.

#### Acceptance Criteria

20.1. WHEN the app runs on a small phone (≤ 5.5″) THEN ALL screens SHALL display correctly without overflow
20.2. WHEN the app runs on a large phone (≥ 6.7″) THEN ALL screens SHALL display correctly with appropriate spacing
20.3. WHEN the device is rotated to landscape THEN NO pixel overflow errors SHALL occur on any screen
20.4. WHEN buttons are rendered THEN THEY SHALL meet Material Design minimum tap target size (48x48dp)
20.5. WHEN colors are used THEN THEY SHALL meet WCAG AA contrast ratio requirements (4.5:1 minimum)
20.6. WHEN the app is tested THEN IT SHALL work correctly on both portrait and landscape orientations

### Requirement 21: Version Control and Collaboration

**User Story:** As a development team, we need to collaborate effectively using Git and ensure equal contributions from all members.

#### Acceptance Criteria

21.1. WHEN code is developed THEN ALL team members SHALL contribute at least 15% of total commits
21.2. WHEN features are developed THEN feature branches SHALL be created for each task
21.3. WHEN code is ready for review THEN pull requests SHALL be created and reviewed by another team member
21.4. WHEN commits are made THEN commit messages SHALL be descriptive and meaningful
21.5. WHEN development progresses THEN commits SHALL be spread over time (not concentrated on final days)
21.6. WHEN the project is submitted THEN THE contribution table in the report SHALL match Git statistics

### Requirement 22: Documentation and Reporting

**User Story:** As a development team, we need to document our work professionally to meet academic submission requirements.

#### Acceptance Criteria

22.1. WHEN the README is written THEN IT SHALL include setup instructions, screenshots, and Firebase configuration steps
22.2. WHEN the project report is written THEN IT SHALL follow the provided template with Times New Roman font (12pt body, 14pt headings)
22.3. WHEN non-original content is used THEN IT SHALL be cited with in-text citations corresponding to references
22.4. WHEN AI assistance is used THEN IT SHALL be disclosed in the methodology section and be < 40% of content
22.5. WHEN the report is completed THEN IT SHALL include: ERD, implemented functionalities, testing results, known limitations, and future work
22.6. WHEN the report is saved THEN IT SHALL be named Group40_Final_Project_Submission.pdf

### Requirement 23: Demo Video

**User Story:** As a development team, we need to create a professional demo video showcasing all app functionalities.

#### Acceptance Criteria

23.1. WHEN the video is recorded THEN IT SHALL be 10-15 minutes long
23.2. WHEN the video is recorded THEN IT SHALL be a single continuous recording on a physical device (not emulator)
23.3. WHEN the video is recorded THEN IT SHALL show these 7 actions in order:
   - Cold-start launch from phone home screen
   - Register → logout → login authentication flow
   - Visit every screen and rotate to landscape once
   - Create → read → update → delete operations with Firebase Console visible
   - State update affecting two widgets simultaneously
   - Change SharedPreferences setting, restart app, show persistence
   - Force validation error and display polite error message
23.4. WHEN the video is recorded THEN EVERY team member SHALL speak and demonstrate a feature
23.5. WHEN the video is recorded THEN IT SHALL have ≥ 1080p quality and clear audio
23.6. WHEN the video is recorded THEN IT SHALL NOT include slide decks or team member introductions

