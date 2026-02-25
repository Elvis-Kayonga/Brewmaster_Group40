# Design Document: BrewMaster Coffee Marketplace

## Overview

BrewMaster is a Flutter-based mobile application that connects smallholder coffee farmers directly with specialty buyers. The system eliminates intermediaries, providing price transparency, secure payments, and quality verification while supporting offline-first operations for users with intermittent connectivity.

### Key Design Principles

1. **Offline-First Architecture**: All critical operations must work without internet connectivity using Firestore offline persistence
2. **Clean Architecture**: Separation of concerns using Models → Services → Providers → UI layers
3. **Accessibility**: Icon-driven navigation, voice input support, and simple workflows for low-literacy users
4. **Performance**: Optimized for low-end Android devices with minimal data usage
5. **Security**: Firebase Authentication, Firestore security rules, and encrypted communications
6. **Scalability**: Designed to support parallel development by 6 developers with minimal conflicts

### Technology Stack

- **Frontend**: Flutter (Dart) for cross-platform mobile development
- **Backend**: Firebase (Firestore, Authentication, Storage, Cloud Functions)
- **State Management**: Provider pattern for reactive state updates
- **Offline Support**: Firestore offline persistence with automatic synchronization
- **Payment Integration**: M-Pesa and MTN Mobile Money APIs
- **Push Notifications**: Firebase Cloud Messaging (FCM)
- **Image Processing**: Flutter image compression and caching

## Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        UI Layer (Screens)                    │
│  Dashboard | Listings | Search | Messages | Profile | Auth  │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                    State Management (Providers)              │
│   AuthProvider | ListingProvider | MessageProvider | etc.   │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                      Service Layer                           │
│  AuthService | ListingService | PaymentService | etc.       │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                      Data Layer (Models)                     │
│    User | Listing | Message | Transaction | etc.            │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                    Firebase Backend                          │
│  Firestore | Authentication | Storage | Cloud Functions     │
└─────────────────────────────────────────────────────────────┘
```

## Project Structure

### Folder Organization

The project follows clean architecture principles with clear separation of concerns. All code must be organized into the following folder structure:

```
lib/
├── presentation/          # UI Layer - All visual components
│   ├── screens/          # Full-screen pages
│   │   ├── auth/         # Login, signup, profile setup
│   │   ├── listings/     # Listing form, detail, my listings
│   │   ├── search/       # Search and filter screens
│   │   ├── messaging/    # Conversations, chat screens
│   │   ├── payments/     # Payment, transaction screens
│   │   ├── dashboard/    # Dashboard screens
│   │   └── profile/      # Profile, verification screens
│   └── widgets/          # Reusable UI components
│       ├── common/       # Buttons, text fields, dialogs
│       ├── listing/      # Listing cards, badges
│       ├── message/      # Message bubbles, conversation cards
│       └── dashboard/    # Dashboard widgets, charts
│
├── domain/               # Business Logic Layer
│   ├── models/          # Data models (User, Listing, Message, etc.)
│   │   ├── user_profile.dart
│   │   ├── coffee_listing.dart
│   │   ├── message.dart
│   │   ├── conversation.dart
│   │   ├── escrow_transaction.dart
│   │   ├── market_price.dart
│   │   └── enums.dart   # All enums (UserRole, ListingStatus, etc.)
│   └── validators/      # Input validation logic
│       ├── user_profile_validator.dart
│       ├── coffee_listing_validator.dart
│       └── form_validators.dart
│
├── data/                # Data Layer - External interactions
│   ├── services/        # Business logic and Firebase interactions
│   │   ├── auth_service.dart
│   │   ├── user_service.dart
│   │   ├── listing_service.dart
│   │   ├── message_service.dart
│   │   ├── payment_service.dart
│   │   ├── market_price_service.dart
│   │   ├── verification_service.dart
│   │   ├── notification_service.dart
│   │   ├── dashboard_service.dart
│   │   └── offline_sync_service.dart
│   ├── providers/       # State management (Provider pattern)
│   │   ├── auth_provider.dart
│   │   ├── user_provider.dart
│   │   ├── listing_provider.dart
│   │   ├── message_provider.dart
│   │   ├── payment_provider.dart
│   │   ├── market_price_provider.dart
│   │   ├── dashboard_provider.dart
│   │   └── connectivity_provider.dart
│   └── repositories/    # Optional: Data access abstraction
│       └── (if needed for complex data operations)
│
├── config/              # App-wide configuration
│   ├── theme.dart       # AppTheme class with colors, text styles, spacing
│   ├── constants.dart   # App constants (API keys, limits, defaults)
│   ├── routes.dart      # Named routes for navigation
│   └── localization/    # Translation files (en, rw, sw)
│
├── utils/               # Helper utilities
│   ├── image_utils.dart      # Image compression, caching
│   ├── date_utils.dart       # Date formatting
│   ├── validation_utils.dart # Common validation helpers
│   └── error_handler.dart    # Error handling utilities
│
├── firebase_options.dart     # Firebase configuration (auto-generated)
└── main.dart                 # App entry point
```

### File Naming Conventions

**Dart Files:**
- Use `snake_case` for file names: `coffee_listing.dart`, `auth_service.dart`
- Match file name to primary class name: `UserProfile` class → `user_profile.dart`

**Classes:**
- Use `PascalCase` for class names: `CoffeeListing`, `AuthService`, `ListingProvider`
- Suffix providers with `Provider`: `AuthProvider`, `ListingProvider`
- Suffix services with `Service`: `AuthService`, `MessageService`
- Suffix validators with `Validator`: `UserProfileValidator`

**Variables and Functions:**
- Use `camelCase` for variables and functions: `userId`, `createListing()`, `isVerified`
- Use descriptive names: `askingPricePerKg` not `price`, `farmerId` not `id`

**Constants:**
- Use `lowerCamelCase` for constants: `maxImageSize`, `defaultPageSize`
- Group related constants in classes: `AppConstants.maxImageSize`

### Import Organization

Organize imports in this order:
1. Dart SDK imports (`dart:...`)
2. Flutter imports (`package:flutter/...`)
3. Third-party package imports (`package:provider/...`, `package:firebase_core/...`)
4. Project imports (`package:brewmaster/...`)

Example:
```dart
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:brewmaster/domain/models/user_profile.dart';
import 'package:brewmaster/data/services/auth_service.dart';
import 'package:brewmaster/config/theme.dart';
```

### Layer Communication Rules

**Critical Rules:**
1. **Presentation → Domain**: Screens and widgets can import models and validators
2. **Presentation → Data**: Screens use providers (via Provider.of or Consumer), never call services directly
3. **Data (Providers) → Data (Services)**: Providers call services to perform operations
4. **Data (Services) → Domain**: Services use models for data structures
5. **Domain → Nothing**: Models and validators should not import from other layers (pure Dart)

**Forbidden:**
- ❌ Screens calling services directly (bypass providers)
- ❌ Services importing widgets or screens
- ❌ Models importing Firebase or Flutter packages
- ❌ Putting business logic in widgets

**Example Correct Flow:**
```
LoginScreen (presentation)
    ↓ uses Consumer<AuthProvider>
AuthProvider (data/providers)
    ↓ calls signIn()
AuthService (data/services)
    ↓ uses UserProfile model
UserProfile (domain/models)
```

### Phase 0 Structure Setup

Before any feature development begins, Developer 1 and Developer 6 must create this complete folder structure:

```bash
# Create all folders
mkdir -p lib/presentation/screens/{auth,listings,search,messaging,payments,dashboard,profile}
mkdir -p lib/presentation/widgets/{common,listing,message,dashboard}
mkdir -p lib/domain/{models,validators}
mkdir -p lib/data/{services,providers,repositories}
mkdir -p lib/config/localization
mkdir -p lib/utils
mkdir -p test/{unit,properties,widgets}
mkdir -p integration_test
```

This ensures all developers can immediately place their files in the correct locations without conflicts.

### Layer Responsibilities

**UI Layer (Screens & Widgets)**
- Render user interface components
- Handle user interactions and gestures
- Display data from providers
- Navigate between screens
- Show loading states and errors

**State Management Layer (Providers)**
- Manage application state using Provider pattern
- Notify UI of state changes
- Coordinate between services
- Handle loading and error states
- Cache data for offline access

**Service Layer**
- Encapsulate business logic
- Interact with Firebase services
- Handle data transformations
- Manage offline queue operations
- Implement retry logic for failed operations

**Data Layer (Models)**
- Define data structures
- Implement validation logic
- Provide serialization/deserialization (toJson/fromJson)
- Enforce data integrity constraints

### Offline-First Strategy

1. **Firestore Offline Persistence**: Enable persistent cache on app initialization
2. **Write Queue**: Queue all write operations when offline, sync when online
3. **Optimistic Updates**: Update UI immediately, sync in background
4. **Conflict Resolution**: Last-write-wins with server timestamp
5. **Sync Indicator**: Display connectivity status and last sync time
6. **Image Upload Queue**: Compress and queue images for background upload

## Components and Interfaces

### 1. Authentication System

**Components:**
- `AuthService`: Handles Firebase Authentication operations
- `AuthProvider`: Manages authentication state
- `LoginScreen`: Email/Google login interface
- `SignupScreen`: User registration with role selection
- `ProfileSetupScreen`: Post-registration profile completion

**Key Interfaces:**

```dart
class AuthService {
  Future<User?> signUpWithEmail(String email, String password, UserRole role);
  Future<User?> signInWithEmail(String email, String password);
  Future<User?> signInWithGoogle();
  Future<void> signOut();
  Stream<User?> get authStateChanges;
  Future<void> sendPasswordResetEmail(String email);
}

class AuthProvider extends ChangeNotifier {
  User? currentUser;
  bool isLoading;
  String? errorMessage;
  
  Future<void> signUp(String email, String password, UserRole role);
  Future<void> signIn(String email, String password);
  Future<void> signInWithGoogle();
  Future<void> signOut();
}
```

### 2. User Profile System

**Components:**
- `UserService`: CRUD operations for user profiles
- `UserProvider`: Manages user profile state
- `ProfileScreen`: Display and edit user profile
- `VerificationScreen`: Submit verification documents

**Key Interfaces:**

```dart
class UserService {
  Future<UserProfile> getUserProfile(String userId);
  Future<void> createUserProfile(UserProfile profile);
  Future<void> updateUserProfile(String userId, Map<String, dynamic> updates);
  Future<void> uploadVerificationDocuments(String userId, List<File> documents);
  Stream<UserProfile> watchUserProfile(String userId);
}

class UserProfile {
  String id;
  String email;
  String phoneNumber;
  UserRole role; // farmer or buyer
  String displayName;
  String? photoUrl;
  bool isVerified;
  DateTime createdAt;
  DateTime updatedAt;
  
  // Farmer-specific fields
  double? farmSize;
  String? farmLocation;
  List<String>? coffeeVarieties;
  
  // Buyer-specific fields
  String? businessName;
  String? businessType;
  double? monthlyVolume;
  
  Map<String, dynamic> toJson();
  factory UserProfile.fromJson(Map<String, dynamic> json);
}
```

### 3. Coffee Listing System

**Components:**
- `ListingService`: CRUD operations for coffee listings
- `ListingProvider`: Manages listing state and search
- `ListingFormScreen`: Create/edit coffee listings
- `ListingDetailScreen`: View detailed listing information
- `MyListingsScreen`: View farmer's own listings

**Key Interfaces:**

```dart
class ListingService {
  Future<String> createListing(CoffeeListing listing);
  Future<void> updateListing(String listingId, Map<String, dynamic> updates);
  Future<void> deleteListing(String listingId);
  Future<CoffeeListing> getListing(String listingId);
  Future<List<CoffeeListing>> getListingsByFarmer(String farmerId);
  Future<List<CoffeeListing>> searchListings(SearchFilters filters);
  Future<List<String>> uploadListingImages(String listingId, List<File> images);
  Stream<List<CoffeeListing>> watchActiveListings();
}

class CoffeeListing {
  String id;
  String farmerId;
  String farmerName;
  String coffeeVariety;
  double quantityKg;
  double altitude;
  ProcessingMethod processingMethod;
  DateTime harvestDate;
  double askingPricePerKg;
  List<String> imageUrls;
  double? cuppingScore;
  String? flavorNotes;
  ListingStatus status; // active, sold, draft
  int viewCount;
  DateTime createdAt;
  DateTime updatedAt;
  
  Map<String, dynamic> toJson();
  factory CoffeeListing.fromJson(Map<String, dynamic> json);
  bool validate();
}

class SearchFilters {
  List<String>? varieties;
  ProcessingMethod? processingMethod;
  double? minAltitude;
  double? maxAltitude;
  double? minPrice;
  double? maxPrice;
  String? location;
  double? minCuppingScore;
  bool? verifiedOnly;
  SortOption sortBy; // price, altitude, date, quantity
}
```

### 4. Market Price System

**Components:**
- `MarketPriceService`: Fetch and cache market price data
- `MarketPriceProvider`: Manages price state
- `MarketPricesScreen`: Display current market prices
- `PriceGuidanceWidget`: Inline price suggestions

**Key Interfaces:**

```dart
class MarketPriceService {
  Future<List<MarketPrice>> getMarketPrices();
  Future<MarketPrice> getPriceForVariety(String variety, QualityGrade grade);
  Future<void> syncMarketPrices();
  DateTime getLastSyncTime();
}

class MarketPrice {
  String variety;
  QualityGrade grade;
  double lowPrice;
  double avgPrice;
  double highPrice;
  String currency;
  DateTime updatedAt;
  
  Map<String, dynamic> toJson();
  factory MarketPrice.fromJson(Map<String, dynamic> json);
}
```

### 5. Messaging System

**Components:**
- `MessageService`: Send/receive messages via Firestore
- `MessageProvider`: Manages conversation state
- `ConversationsScreen`: List all conversations
- `ChatScreen`: Individual conversation view

**Key Interfaces:**

```dart
class MessageService {
  Future<String> createConversation(String userId1, String userId2, String? listingId);
  Future<void> sendMessage(String conversationId, Message message);
  Future<List<Message>> getMessages(String conversationId, {int limit = 50});
  Future<List<Conversation>> getUserConversations(String userId);
  Future<void> markMessagesAsRead(String conversationId, String userId);
  Stream<List<Message>> watchMessages(String conversationId);
  Stream<List<Conversation>> watchConversations(String userId);
}

class Message {
  String id;
  String conversationId;
  String senderId;
  String senderName;
  String content;
  MessageType type; // text, listing_reference, system
  String? listingId;
  bool isRead;
  DateTime createdAt;
  
  Map<String, dynamic> toJson();
  factory Message.fromJson(Map<String, dynamic> json);
}

class Conversation {
  String id;
  List<String> participantIds;
  Map<String, String> participantNames;
  String? listingId;
  Message? lastMessage;
  Map<String, int> unreadCounts;
  DateTime createdAt;
  DateTime updatedAt;
  
  Map<String, dynamic> toJson();
  factory Conversation.fromJson(Map<String, dynamic> json);
}
```

### 6. Payment and Escrow System

**Components:**
- `PaymentService`: Handle escrow transactions and mobile money integration
- `PaymentProvider`: Manages payment state
- `PaymentScreen`: Initiate and track payments
- `TransactionHistoryScreen`: View past transactions

**Key Interfaces:**

```dart
class PaymentService {
  Future<String> createEscrowTransaction(EscrowTransaction transaction);
  Future<void> initiatePayment(String transactionId, PaymentMethod method);
  Future<void> confirmDelivery(String transactionId, String userId);
  Future<void> confirmReceipt(String transactionId, String userId);
  Future<void> releaseFunds(String transactionId);
  Future<void> disputeTransaction(String transactionId, String reason);
  Future<List<EscrowTransaction>> getUserTransactions(String userId);
  Stream<EscrowTransaction> watchTransaction(String transactionId);
}

class EscrowTransaction {
  String id;
  String buyerId;
  String farmerId;
  String listingId;
  double amount;
  String currency;
  TransactionStatus status; // pending, funds_held, delivered, completed, disputed
  PaymentMethod paymentMethod;
  String? paymentReference;
  DateTime? deliveryConfirmedAt;
  DateTime? receiptConfirmedAt;
  DateTime? completedAt;
  DateTime createdAt;
  DateTime updatedAt;
  
  Map<String, dynamic> toJson();
  factory EscrowTransaction.fromJson(Map<String, dynamic> json);
}

enum TransactionStatus {
  pending,
  funds_held,
  delivered,
  completed,
  disputed,
  cancelled
}

enum PaymentMethod {
  mpesa,
  mtn_mobile_money
}
```

### 7. Verification System

**Components:**
- `VerificationService`: Handle verification requests and status
- `VerificationProvider`: Manages verification state
- `VerificationRequestScreen`: Submit verification documents

**Key Interfaces:**

```dart
class VerificationService {
  Future<void> requestVerification(String userId, List<File> documents);
  Future<VerificationStatus> getVerificationStatus(String userId);
  Future<void> updateVerificationStatus(String userId, VerificationStatus status);
  Stream<VerificationStatus> watchVerificationStatus(String userId);
}

class VerificationStatus {
  String userId;
  VerificationState state; // unverified, pending, verified, rejected
  List<String> documentUrls;
  String? rejectionReason;
  DateTime? verifiedAt;
  DateTime updatedAt;
  
  Map<String, dynamic> toJson();
  factory VerificationStatus.fromJson(Map<String, dynamic> json);
}
```

### 8. Notification System

**Components:**
- `NotificationService`: Handle FCM and local notifications
- `NotificationProvider`: Manages notification state

**Key Interfaces:**

```dart
class NotificationService {
  Future<void> initialize();
  Future<String?> getFCMToken();
  Future<void> subscribeToTopic(String topic);
  Future<void> unsubscribeFromTopic(String topic);
  Future<void> sendNotification(String userId, NotificationPayload payload);
  Stream<NotificationPayload> get onNotificationReceived;
}

class NotificationPayload {
  String title;
  String body;
  NotificationType type;
  Map<String, dynamic> data;
  DateTime createdAt;
}

enum NotificationType {
  new_message,
  purchase_initiated,
  payment_received,
  delivery_confirmed,
  verification_updated,
  listing_interest
}
```

### 9. Dashboard System

**Components:**
- `DashboardService`: Aggregate dashboard metrics
- `DashboardProvider`: Manages dashboard state
- `DashboardScreen`: Display metrics and quick actions

**Key Interfaces:**

```dart
class DashboardService {
  Future<FarmerDashboard> getFarmerDashboard(String farmerId);
  Future<BuyerDashboard> getBuyerDashboard(String buyerId);
}

class FarmerDashboard {
  int totalListings;
  int activeListings;
  int soldListings;
  double totalEarnings;
  double earningsThisMonth;
  int activeConversations;
  int pendingTransactions;
  double averageSalePrice;
  int totalViews;
  
  Map<String, dynamic> toJson();
  factory FarmerDashboard.fromJson(Map<String, dynamic> json);
}

class BuyerDashboard {
  int savedSearches;
  int recentPurchases;
  int activeConversations;
  double totalSpent;
  double spentThisMonth;
  List<CoffeeListing> recommendedListings;
  
  Map<String, dynamic> toJson();
  factory BuyerDashboard.fromJson(Map<String, dynamic> json);
}
```

### 10. Offline Sync System

**Components:**
- `OfflineSyncService`: Manage offline queue and synchronization
- `ConnectivityProvider`: Monitor network connectivity

**Key Interfaces:**

```dart
class OfflineSyncService {
  Future<void> initialize();
  Future<void> queueOperation(OfflineOperation operation);
  Future<void> syncPendingOperations();
  Future<List<OfflineOperation>> getPendingOperations();
  Stream<SyncStatus> get syncStatusStream;
}

class OfflineOperation {
  String id;
  OperationType type; // create, update, delete
  String collection;
  Map<String, dynamic> data;
  DateTime queuedAt;
  int retryCount;
  
  Map<String, dynamic> toJson();
  factory OfflineOperation.fromJson(Map<String, dynamic> json);
}

class ConnectivityProvider extends ChangeNotifier {
  bool isOnline;
  DateTime? lastSyncTime;
  int pendingOperations;
  
  Future<void> checkConnectivity();
  Future<void> forceSyncNow();
}
```

## Data Models

### Firestore Collections Structure

```
users/
  {userId}/
    - email: string
    - phoneNumber: string
    - role: string (farmer | buyer)
    - displayName: string
    - photoUrl: string?
    - isVerified: boolean
    - farmSize: number? (farmers only)
    - farmLocation: string? (farmers only)
    - coffeeVarieties: array<string>? (farmers only)
    - businessName: string? (buyers only)
    - businessType: string? (buyers only)
    - monthlyVolume: number? (buyers only)
    - createdAt: timestamp
    - updatedAt: timestamp
    - fcmToken: string?

listings/
  {listingId}/
    - farmerId: string
    - farmerName: string
    - coffeeVariety: string
    - quantityKg: number
    - altitude: number
    - processingMethod: string
    - harvestDate: timestamp
    - askingPricePerKg: number
    - imageUrls: array<string>
    - cuppingScore: number?
    - flavorNotes: string?
    - status: string (active | sold | draft)
    - viewCount: number
    - createdAt: timestamp
    - updatedAt: timestamp

conversations/
  {conversationId}/
    - participantIds: array<string>
    - participantNames: map<string, string>
    - listingId: string?
    - lastMessageContent: string?
    - lastMessageAt: timestamp?
    - unreadCounts: map<string, number>
    - createdAt: timestamp
    - updatedAt: timestamp
    
    messages/
      {messageId}/
        - senderId: string
        - senderName: string
        - content: string
        - type: string (text | listing_reference | system)
        - listingId: string?
        - isRead: boolean
        - createdAt: timestamp

transactions/
  {transactionId}/
    - buyerId: string
    - farmerId: string
    - listingId: string
    - amount: number
    - currency: string
    - status: string
    - paymentMethod: string
    - paymentReference: string?
    - deliveryConfirmedAt: timestamp?
    - receiptConfirmedAt: timestamp?
    - completedAt: timestamp?
    - createdAt: timestamp
    - updatedAt: timestamp

marketPrices/
  {priceId}/
    - variety: string
    - grade: string
    - lowPrice: number
    - avgPrice: number
    - highPrice: number
    - currency: string
    - updatedAt: timestamp

verifications/
  {userId}/
    - state: string (unverified | pending | verified | rejected)
    - documentUrls: array<string>
    - rejectionReason: string?
    - verifiedAt: timestamp?
    - updatedAt: timestamp

notifications/
  {notificationId}/
    - userId: string
    - title: string
    - body: string
    - type: string
    - data: map
    - isRead: boolean
    - createdAt: timestamp
```

### Firestore Indexes

Required composite indexes for efficient queries:

```json
{
  "indexes": [
    {
      "collectionGroup": "listings",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "coffeeVariety", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "listings",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "altitude", "order": "ASCENDING" },
        { "fieldPath": "askingPricePerKg", "order": "ASCENDING" }
      ]
    },
    {
      "collectionGroup": "listings",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "farmerId", "order": "ASCENDING" },
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "conversations",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "participantIds", "arrayConfig": "CONTAINS" },
        { "fieldPath": "updatedAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "transactions",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "farmerId", "order": "ASCENDING" },
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "transactions",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "buyerId", "order": "ASCENDING" },
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    }
  ]
}
```

### Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }
    
    function isParticipant(participantIds) {
      return isAuthenticated() && request.auth.uid in participantIds;
    }
    
    // Users collection
    match /users/{userId} {
      allow read: if isAuthenticated();
      allow create: if isOwner(userId);
      allow update: if isOwner(userId);
      allow delete: if isOwner(userId);
    }
    
    // Listings collection
    match /listings/{listingId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated() && request.resource.data.farmerId == request.auth.uid;
      allow update: if isAuthenticated() && resource.data.farmerId == request.auth.uid;
      allow delete: if isAuthenticated() && resource.data.farmerId == request.auth.uid;
    }
    
    // Conversations collection
    match /conversations/{conversationId} {
      allow read: if isAuthenticated() && request.auth.uid in resource.data.participantIds;
      allow create: if isAuthenticated() && request.auth.uid in request.resource.data.participantIds;
      allow update: if isAuthenticated() && request.auth.uid in resource.data.participantIds;
      
      match /messages/{messageId} {
        allow read: if isAuthenticated() && request.auth.uid in get(/databases/$(database)/documents/conversations/$(conversationId)).data.participantIds;
        allow create: if isAuthenticated() && request.auth.uid in get(/databases/$(database)/documents/conversations/$(conversationId)).data.participantIds;
      }
    }
    
    // Transactions collection
    match /transactions/{transactionId} {
      allow read: if isAuthenticated() && (
        request.auth.uid == resource.data.buyerId ||
        request.auth.uid == resource.data.farmerId
      );
      allow create: if isAuthenticated();
      allow update: if isAuthenticated() && (
        request.auth.uid == resource.data.buyerId ||
        request.auth.uid == resource.data.farmerId
      );
    }
    
    // Market prices (read-only for users)
    match /marketPrices/{priceId} {
      allow read: if isAuthenticated();
    }
    
    // Verifications
    match /verifications/{userId} {
      allow read: if isOwner(userId);
      allow create: if isOwner(userId);
      allow update: if isOwner(userId);
    }
    
    // Notifications
    match /notifications/{notificationId} {
      allow read: if isAuthenticated() && resource.data.userId == request.auth.uid;
      allow update: if isAuthenticated() && resource.data.userId == request.auth.uid;
    }
  }
}
```

### Data Validation

Each model includes validation methods to ensure data integrity:

```dart
class CoffeeListingValidator {
  static bool validate(CoffeeListing listing) {
    if (listing.coffeeVariety.isEmpty) return false;
    if (listing.quantityKg <= 0) return false;
    if (listing.altitude < 1000 || listing.altitude > 2500) return false;
    if (listing.askingPricePerKg <= 0) return false;
    if (listing.cuppingScore != null && 
        (listing.cuppingScore! < 0 || listing.cuppingScore! > 100)) return false;
    return true;
  }
}

class UserProfileValidator {
  static bool validate(UserProfile profile) {
    if (profile.email.isEmpty && profile.phoneNumber.isEmpty) return false;
    if (profile.displayName.isEmpty) return false;
    if (profile.role == UserRole.farmer && profile.farmSize != null && profile.farmSize! <= 0) return false;
    return true;
  }
}
```


## Correctness Properties

A property is a characteristic or behavior that should hold true across all valid executions of a system—essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.

### Property 1: Authentication Method Support

*For any* user registration attempt, the system should successfully create an account using either email/password or Google sign-in authentication methods.

**Validates: Requirements 1.2**

### Property 2: Profile Data Persistence Round-Trip

*For any* user profile (farmer or buyer), saving the profile then retrieving it should produce an equivalent profile with all required fields intact.

**Validates: Requirements 1.3, 1.4, 1.6**

### Property 3: Session State Persistence

*For any* authenticated user, logging in then restarting the app should maintain the authentication session without requiring re-login.

**Validates: Requirements 1.7**

### Property 4: Profile Update Synchronization

*For any* profile update operation, the changes should be persisted to Firestore and retrievable in subsequent queries.

**Validates: Requirements 1.8**

### Property 5: Listing Field Completeness

*For any* coffee listing created by a farmer, the listing should contain all required fields: coffee variety, quantity, altitude, processing method, harvest date, asking price, and unique identifier with timestamp.

**Validates: Requirements 2.1, 2.6, 8.1, 15.1**

### Property 6: Image Upload Limit Enforcement

*For any* listing, attempting to add more than 5 images should be rejected, and the listing should contain at most 5 image URLs.

**Validates: Requirements 2.2**

### Property 7: Market Price Display on Listing Creation

*For any* listing being created, when a coffee variety is selected, the system should fetch and display the corresponding market price data for that variety.

**Validates: Requirements 2.3, 3.3**

### Property 8: Cupping Score Validation

*For any* cupping score value, the system should only accept scores between 0 and 100 (inclusive), rejecting any values outside this range.

**Validates: Requirements 2.4**

### Property 9: Offline Listing Queue

*For any* listing created while offline, the listing should be queued locally and successfully synced to Firestore when connectivity returns.

**Validates: Requirements 2.5, 9.2, 9.3**

### Property 10: Listing Status Filtering

*For any* farmer viewing their listings, the system should correctly filter and display listings by status (active, sold, draft) with appropriate status indicators.

**Validates: Requirements 2.7**

### Property 11: Listing Update Round-Trip

*For any* listing edit operation, updating a listing then retrieving it should reflect the changes made.

**Validates: Requirements 2.8**

### Property 12: Market Price Data Structure

*For any* market price record, it should contain variety, grade, low price, average price, high price, currency, and timestamp fields.

**Validates: Requirements 3.2**

### Property 13: Offline Market Price Caching

*For any* market price query when offline, the system should return cached price data with the last sync timestamp.

**Validates: Requirements 3.5**

### Property 14: Price Deviation Warning

*For any* listing where the asking price deviates more than 20% from the market average price, the system should display a warning indicator.

**Validates: Requirements 3.6**

### Property 15: Search Filter Application

*For any* search with filters applied (variety, processing method, altitude range, location, price range), all returned listings should match the specified filter criteria.

**Validates: Requirements 4.2**

### Property 16: Text Search Field Matching

*For any* text search query, the system should return listings where the query matches the coffee variety, location, or farmer name fields.

**Validates: Requirements 4.3**

### Property 17: Search Result Completeness

*For any* search result listing, it should contain all key attributes: variety, quantity, price, location, verification badge, and all detail fields (specifications, photos, farmer profile).

**Validates: Requirements 4.4, 4.6**

### Property 18: Search Result Sorting

*For any* search with a sort option (price, quantity, altitude, date), the returned listings should be ordered correctly according to the selected sort field.

**Validates: Requirements 4.5**

### Property 19: Quality Score Filtering

*For any* search filtered by minimum cupping score, all returned listings should have cupping scores greater than or equal to the specified threshold.

**Validates: Requirements 4.7, 8.6**

### Property 20: Offline Search Data Freshness

*For any* search performed offline, the system should search cached listings and display the last sync timestamp to indicate data freshness.

**Validates: Requirements 4.8**

### Property 21: Message Delivery

*For any* message sent in a conversation, the message should appear in the conversation's message history for all participants.

**Validates: Requirements 5.2**

### Property 22: Offline Message Queue

*For any* message sent while offline, the message should be queued locally and delivered to Firestore when connectivity returns.

**Validates: Requirements 5.3**

### Property 23: Unread Message Count Accuracy

*For any* user's conversation list, the unread message count for each conversation should accurately reflect the number of messages not yet marked as read by that user.

**Validates: Requirements 5.5**

### Property 24: Message Read Status Update

*For any* conversation opened by a user, all messages in that conversation should be marked as read for that user.

**Validates: Requirements 5.6**

### Property 25: Listing Reference in Messages

*For any* message containing a listing ID, the message should include a preview with the listing's key details (variety, price, quantity).

**Validates: Requirements 5.8**

### Property 26: Escrow Transaction Creation

*For any* purchase initiated by a buyer, the system should create an escrow transaction containing buyer ID, farmer ID, listing ID, amount, and currency.

**Validates: Requirements 6.1, 15.2**

### Property 27: Payment Status Transition

*For any* escrow transaction, when buyer payment is received, the transaction status should update to "funds_held" and both parties should be notified.

**Validates: Requirements 6.3**

### Property 28: Two-Step Confirmation Requirement

*For any* escrow transaction, farmer delivery confirmation alone should not release funds; buyer receipt confirmation must also be provided before funds are released.

**Validates: Requirements 6.4**

### Property 29: Fund Release Trigger

*For any* escrow transaction where both farmer confirms delivery and buyer confirms receipt, the system should trigger fund transfer to the farmer's account.

**Validates: Requirements 6.5**

### Property 30: Dispute Handling

*For any* escrow transaction where a dispute is raised, the transaction status should change to "disputed", funds should remain held, and the transaction should be flagged for review.

**Validates: Requirements 6.6**

### Property 31: Transaction History Recording

*For any* completed transaction, the system should record a complete history including all status changes with timestamps.

**Validates: Requirements 6.7**

### Property 32: Payment Retry Logic

*For any* failed payment attempt, the system should retry up to 3 times before marking the payment as failed and notifying the user.

**Validates: Requirements 6.8**

### Property 33: Verification Status Display

*For any* user profile, the verification status field should be one of: unverified, pending, verified, or rejected.

**Validates: Requirements 7.1**

### Property 34: Verification Document Collection

*For any* verification request, the system should store the submitted documents and update the verification status to "pending".

**Validates: Requirements 7.2, 7.3**

### Property 35: Verification Badge Propagation

*For any* farmer profile that is verified, the verification badge should appear on both the profile and all listings created by that farmer.

**Validates: Requirements 7.4**

### Property 36: Verified Farmer Prioritization

*For any* search results, listings from verified farmers should appear before listings from unverified farmers when other factors are equal.

**Validates: Requirements 7.5**

### Property 37: Trusted Buyer Badge Award

*For any* buyer who completes 5 or more successful transactions, the system should award a "Trusted Buyer" badge to their profile.

**Validates: Requirements 7.6**

### Property 38: Quality Data Completeness

*For any* listing with a cupping score, the listing should also include flavor notes and defect counts.

**Validates: Requirements 8.3**

### Property 39: Altitude Validation

*For any* listing, the altitude value should be between 1000 and 2500 meters; values outside this range should be rejected.

**Validates: Requirements 8.4**

### Property 40: Offline Write Queue

*For any* write operation (listing creation, message send, profile update) performed offline, the operation should be queued and automatically synced when connectivity returns.

**Validates: Requirements 9.2, 9.3**

### Property 41: Conflict Resolution Strategy

*For any* data conflict between local and server versions, the system should use last-write-wins based on timestamp comparison, keeping the most recent version.

**Validates: Requirements 9.4**

### Property 42: Sync Timestamp Display

*For any* cached data displayed offline, the system should show the timestamp of the last successful synchronization.

**Validates: Requirements 9.6**

### Property 43: Image Compression and Queue

*For any* image uploaded while offline, the system should compress the image to reduce size and queue it for background upload when connectivity returns.

**Validates: Requirements 9.7**

### Property 44: Language Localization

*For any* supported language (English, Kinyarwanda, Swahili), switching to that language should update all UI text to the selected language.

**Validates: Requirements 10.6**

### Property 45: Error Message Completeness

*For any* error that occurs, the system should display an error message that includes both a description of the error and a suggested action.

**Validates: Requirements 10.7**

### Property 46: Dashboard Metric Calculation

*For any* user dashboard (farmer or buyer), the displayed metrics should accurately reflect aggregated data from the user's listings, transactions, and conversations.

**Validates: Requirements 11.1, 11.2, 11.4**

### Property 47: Dashboard Trend Calculation

*For any* dashboard displaying trends, the trend comparison (e.g., earnings this month vs last month) should be calculated correctly based on transaction dates.

**Validates: Requirements 11.3**

### Property 48: Dashboard Offline Caching

*For any* dashboard data fetch, the data should be cached locally and available for display when offline.

**Validates: Requirements 11.5**

### Property 49: Notification Preference Filtering

*For any* user with notification preferences set, only notifications matching the enabled preference types should be delivered to that user.

**Validates: Requirements 12.7**

### Property 50: Firestore Security Rule Enforcement

*For any* Firestore read or write operation, users should only be able to access documents they own or are participants in (e.g., their own profile, conversations they're part of).

**Validates: Requirements 13.3**

### Property 51: Payment Data Exclusion

*For any* payment transaction object stored in the app or Firestore, it should not contain sensitive payment credentials (card numbers, PINs, passwords).

**Validates: Requirements 13.4**

### Property 52: Account Deletion Data Removal

*For any* user account deletion request, all personal data associated with that user should be removed from Firestore.

**Validates: Requirements 13.5**

### Property 53: Image Caching

*For any* image loaded from a URL, after the first load, subsequent loads should use the cached version rather than re-downloading.

**Validates: Requirements 14.2**

### Property 54: List Pagination

*For any* list query (listings, messages, transactions), the system should return results in pages of 20 items to optimize performance.

**Validates: Requirements 14.3**

### Property 55: Firestore Operation Batching

*For any* set of multiple Firestore write operations performed together, the system should batch them into a single batch write to minimize costs.

**Validates: Requirements 14.5**

### Property 56: Compliance Data Completeness

*For any* listing or transaction record, it should contain all required traceability and regulatory fields (farm location, harvest date, farmer ID, registration numbers).

**Validates: Requirements 15.1, 15.2, 15.4**

### Property 57: Transaction Export Format

*For any* transaction history export request, the system should generate a valid PDF document containing all transaction records with required regulatory fields.

**Validates: Requirements 15.3**

## Error Handling

### Error Categories

1. **Network Errors**: Connection timeouts, no internet, server unavailable
2. **Authentication Errors**: Invalid credentials, expired tokens, unauthorized access
3. **Validation Errors**: Invalid input data, missing required fields, out-of-range values
4. **Payment Errors**: Payment failed, insufficient funds, API errors
5. **Storage Errors**: Upload failed, quota exceeded, file too large
6. **Conflict Errors**: Data conflicts during sync, concurrent modifications

### Error Handling Strategy

**Network Errors:**
- Queue operations for retry when offline
- Display connectivity indicator
- Show cached data with timestamp
- Automatic retry with exponential backoff

**Authentication Errors:**
- Clear invalid tokens
- Redirect to login screen
- Display user-friendly error messages
- Preserve user's intended action for post-login

**Validation Errors:**
- Validate input on client side before submission
- Display inline error messages with specific field issues
- Provide suggestions for correction
- Prevent form submission until valid

**Payment Errors:**
- Retry failed payments up to 3 times
- Display specific error reason from payment provider
- Provide alternative payment methods
- Maintain transaction in "pending" state for manual resolution

**Storage Errors:**
- Compress images before upload
- Display upload progress
- Retry failed uploads
- Provide clear error messages with file size limits

**Conflict Errors:**
- Use last-write-wins with timestamp
- Log conflicts for debugging
- Notify user if their changes were overwritten
- Provide option to view conflict details

### Error Message Format

All error messages should follow this structure:
```dart
class AppError {
  String code;           // Machine-readable error code
  String message;        // User-friendly description
  String? suggestion;    // Suggested action to resolve
  ErrorSeverity severity; // info, warning, error, critical
}
```

### Logging and Monitoring

- Log all errors with context (user ID, operation, timestamp)
- Track error rates by category
- Monitor offline queue size
- Alert on critical errors (payment failures, data loss)
- Preserve user privacy in logs (no PII)

## Testing Strategy

### Dual Testing Approach

The BrewMaster application requires both unit testing and property-based testing to ensure comprehensive coverage:

**Unit Tests**: Verify specific examples, edge cases, and error conditions
- Test specific user flows (registration, listing creation, message sending)
- Test edge cases (empty inputs, boundary values, null handling)
- Test error conditions (network failures, invalid data, unauthorized access)
- Test integration points between components
- Focus on concrete scenarios that demonstrate correct behavior

**Property Tests**: Verify universal properties across all inputs
- Test properties that should hold for all valid inputs
- Use randomized input generation to cover wide range of scenarios
- Validate data integrity properties (round-trips, invariants)
- Test business rules that apply universally
- Each property test should run minimum 100 iterations

Both approaches are complementary and necessary:
- Unit tests catch specific bugs and validate concrete examples
- Property tests verify general correctness across all inputs
- Together they provide comprehensive coverage

### Property-Based Testing Configuration

**Testing Library**: Use `faker` package for Flutter to generate random test data

**Test Configuration**:
- Minimum 100 iterations per property test
- Each test must reference its design document property
- Tag format: `// Feature: brewmaster-marketplace, Property {number}: {property_text}`

**Example Property Test Structure**:
```dart
import 'package:test/test.dart';
import 'package:faker/faker.dart';

// Feature: brewmaster-marketplace, Property 2: Profile Data Persistence Round-Trip
test('profile round-trip preserves all fields', () {
  final faker = Faker();
  
  for (int i = 0; i < 100; i++) {
    // Generate random profile
    final profile = UserProfile(
      id: faker.guid.guid(),
      email: faker.internet.email(),
      displayName: faker.person.name(),
      role: faker.randomGenerator.boolean() ? UserRole.farmer : UserRole.buyer,
      // ... other fields
    );
    
    // Save and retrieve
    final json = profile.toJson();
    final retrieved = UserProfile.fromJson(json);
    
    // Verify equivalence
    expect(retrieved.id, equals(profile.id));
    expect(retrieved.email, equals(profile.email));
    // ... verify all fields
  }
});
```

### Test Organization

**Unit Tests** (`test/unit/`):
- `auth_test.dart`: Authentication flows
- `profile_test.dart`: Profile management
- `listing_test.dart`: Listing CRUD operations
- `messaging_test.dart`: Message sending and receiving
- `payment_test.dart`: Payment and escrow flows
- `search_test.dart`: Search and filtering
- `offline_test.dart`: Offline queue and sync

**Property Tests** (`test/properties/`):
- `profile_properties_test.dart`: Properties 2, 3, 4
- `listing_properties_test.dart`: Properties 5-11
- `market_price_properties_test.dart`: Properties 12-14
- `search_properties_test.dart`: Properties 15-20
- `messaging_properties_test.dart`: Properties 21-25
- `payment_properties_test.dart`: Properties 26-32
- `verification_properties_test.dart`: Properties 33-37
- `offline_properties_test.dart`: Properties 40-43
- `dashboard_properties_test.dart`: Properties 46-48

**Widget Tests** (`test/widgets/`):
- Test UI components in isolation
- Verify widget rendering and interactions
- Test form validation and user input
- Test navigation flows

**Integration Tests** (`integration_test/`):
- Test complete user flows end-to-end
- Test Firebase integration
- Test offline-to-online transitions
- Test payment integration (with mocked APIs)

### Test Data Generation

Use `faker` package to generate realistic test data:

```dart
class TestDataGenerator {
  static CoffeeListing generateListing() {
    final faker = Faker();
    return CoffeeListing(
      id: faker.guid.guid(),
      farmerId: faker.guid.guid(),
      farmerName: faker.person.name(),
      coffeeVariety: faker.randomGenerator.element(['Bourbon', 'Typica', 'SL28', 'Geisha']),
      quantityKg: faker.randomGenerator.decimal(min: 50, scale: 500),
      altitude: faker.randomGenerator.integer(2500, min: 1000),
      processingMethod: faker.randomGenerator.element([
        ProcessingMethod.washed,
        ProcessingMethod.natural,
        ProcessingMethod.honey
      ]),
      harvestDate: faker.date.dateTime(minYear: 2023, maxYear: 2024),
      askingPricePerKg: faker.randomGenerator.decimal(min: 5, scale: 20),
      status: ListingStatus.active,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
  
  static UserProfile generateFarmerProfile() {
    final faker = Faker();
    return UserProfile(
      id: faker.guid.guid(),
      email: faker.internet.email(),
      phoneNumber: faker.phoneNumber.us(),
      role: UserRole.farmer,
      displayName: faker.person.name(),
      farmSize: faker.randomGenerator.decimal(min: 0.5, scale: 5),
      farmLocation: faker.address.city(),
      coffeeVarieties: List.generate(
        faker.randomGenerator.integer(3, min: 1),
        (_) => faker.randomGenerator.element(['Bourbon', 'Typica', 'SL28'])
      ),
      isVerified: faker.randomGenerator.boolean(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}
```

### Continuous Integration

- Run all tests on every commit
- Require tests to pass before merging
- Track test coverage (target: 80%+ for services and models)
- Run property tests with increased iterations (500+) in CI
- Generate test reports and coverage metrics

### Testing Parallel Development

To support 6 developers working in parallel:

1. **Mock Firebase Services**: Create mock implementations for local testing
2. **Test Isolation**: Each test should be independent and not rely on shared state
3. **Seed Data**: Use consistent seed values for reproducible tests
4. **Test Naming**: Use descriptive names that reference requirements
5. **Fast Feedback**: Unit and property tests should run quickly (<5 minutes total)

### Manual Testing Checklist

While automated tests cover most functionality, manual testing is required for:

- Voice input functionality (device-specific)
- Push notification delivery and display
- Payment integration with real mobile money accounts (in staging)
- UI/UX on different device sizes and Android versions
- Offline-to-online transitions in real network conditions
- Accessibility features (screen readers, color contrast)
- Localization accuracy (translation quality)
- Performance on low-end devices (2GB RAM, older processors)

## Implementation Notes

### Development Team Structure

**Developer 1: Firebase Setup + Authentication + User Profiles**
- Set up Firebase project and configure Flutter app
- Implement AuthService and AuthProvider
- Build login, signup, and profile screens
- Configure Firestore security rules
- Implement offline persistence setup

**Developer 2: Coffee Listings + Search/Filter**
- Implement ListingService and ListingProvider
- Build listing creation and editing screens
- Implement search and filter functionality
- Create listing detail view
- Implement image upload and compression

**Developer 3: Messaging System + Notifications**
- Implement MessageService and MessageProvider
- Build conversations list and chat screens
- Set up Firebase Cloud Messaging
- Implement notification handling
- Create message queue for offline support

**Developer 4: Payment Integration + Escrow System**
- Implement PaymentService and PaymentProvider
- Integrate M-Pesa and MTN Mobile Money APIs
- Build payment and transaction screens
- Implement escrow state machine
- Handle payment errors and retries

**Developer 5: Dashboard + Market Prices + Analytics**
- Implement DashboardService and MarketPriceService
- Build dashboard screens for farmers and buyers
- Implement analytics calculations
- Create market price display
- Build transaction history views

**Developer 6: UI/UX + Navigation + Testing + Integration**
- Design and implement app theme and navigation
- Create reusable UI components and widgets
- Implement voice input integration
- Build connectivity indicator
- Write integration tests and coordinate testing
- Wire all components together

### Development Phases

**Phase 1: Foundation (Week 1)**
- Firebase setup and configuration
- Authentication system
- Basic navigation structure
- User profile management
- Offline persistence setup

**Phase 2: Core Features (Week 2-3)**
- Coffee listing management
- Search and filtering
- Messaging system
- Market price display
- Dashboard implementation

**Phase 3: Payments (Week 4)**
- Escrow system
- Mobile money integration
- Transaction management
- Payment error handling

**Phase 4: Polish (Week 5)**
- Verification system
- Notifications
- Voice input
- Localization
- Performance optimization

**Phase 5: Testing & Launch (Week 6)**
- Comprehensive testing
- Bug fixes
- Documentation
- Deployment preparation

### Key Technical Decisions

1. **State Management**: Provider pattern chosen for simplicity and team familiarity
2. **Offline Strategy**: Firestore offline persistence + custom queue for complex operations
3. **Image Storage**: Firebase Storage with client-side compression
4. **Payment Integration**: Direct API integration with M-Pesa/MTN (not Firebase Extensions)
5. **Testing**: Faker package for property-based testing with 100+ iterations
6. **Navigation**: Named routes with arguments for deep linking support
7. **Localization**: Flutter intl package with JSON translation files

### Performance Considerations

- Lazy load images with caching
- Paginate all lists (20 items per page)
- Batch Firestore operations
- Compress images before upload (max 800x800, 80% quality)
- Use Firestore indexes for complex queries
- Minimize widget rebuilds with const constructors
- Profile app performance on low-end devices

### Security Considerations

- Never store payment credentials locally
- Use Firestore security rules to enforce access control
- Validate all input on client and server
- Use HTTPS for all network requests
- Implement rate limiting for sensitive operations
- Log security events for monitoring
- Request minimal permissions from users


---

## Testing Strategy

### Academic Testing Requirements

To meet course requirements and ensure code quality, the following testing strategy will be implemented:

#### Widget Testing
Widget tests verify that UI components render correctly and respond to user interactions.

**Required Widget Tests:**
1. **LoginScreen Test**: Verify email/password fields render, validation works, and login button triggers authentication
2. **ListingFormScreen Test**: Verify all form fields render, image picker works, and form validation prevents invalid submissions
3. **SearchScreen Test**: Verify listing cards render, filters work, and search functionality updates results

#### Unit Testing
Unit tests verify that individual functions and methods work correctly in isolation.

**Required Unit Tests (minimum 3):**
1. **Model Serialization Tests**:
   - Test UserProfile toJson() and fromJson() methods
   - Test CoffeeListing toJson() and fromJson() methods
   - Verify all fields are correctly serialized and deserialized

2. **Validator Tests**:
   - Test UserProfileValidator with valid and invalid data
   - Test CoffeeListingValidator with valid and invalid data
   - Verify validation rules are enforced correctly

3. **Service Method Tests**:
   - Test AuthService signUpWithEmail() with mock Firebase
   - Test ListingService createListing() with mock Firestore
   - Test MessageService sendMessage() with mock Firestore

#### Test Coverage Target
- **Minimum Coverage**: 70% for services and models
- **How to Measure**: Run `flutter test --coverage` and generate HTML report
- **Documentation**: Include coverage screenshots in project report

#### Testing Tools
- **flutter_test**: Built-in Flutter testing framework
- **mockito**: For mocking Firebase and Firestore services
- **faker**: For generating test data
- **test_coverage**: For measuring code coverage

#### Testing Workflow
1. Write tests alongside feature implementation (not after)
2. Run tests locally before committing: `flutter test`
3. Fix any failing tests immediately
4. Generate coverage report before submission
5. Include test screenshots in project report

---

## Academic Compliance Checklist

### Code Quality Requirements
- [ ] Code organized into presentation/, domain/, and data/ folders
- [ ] Provider used for all state management (no setState in production code)
- [ ] `flutter analyze` returns 0 issues
- [ ] All variables and functions have descriptive names
- [ ] Complex logic includes explanatory comments
- [ ] Code is formatted with `dart format`

### Testing Requirements
- [ ] Widget tests for LoginScreen, ListingFormScreen, SearchScreen
- [ ] At least 3 unit tests (models, validators, services)
- [ ] Test coverage ≥ 70% for services and models
- [ ] All tests pass
- [ ] Coverage screenshots included in report

### Database Requirements
- [ ] ERD created before Firestore implementation
- [ ] ERD matches Firestore collections exactly (same field names)
- [ ] Security rules limit access to authorized users
- [ ] Composite indexes defined in firestore.indexes.json
- [ ] ERD and security rules documented in report

### User Preferences Requirements
- [ ] Theme preference (light/dark) using SharedPreferences
- [ ] Language preference (English/Kinyarwanda/Swahili) using SharedPreferences
- [ ] Notification preference (enabled/disabled) using SharedPreferences
- [ ] All preferences persist after app restart

### Responsive Design Requirements
- [ ] Works correctly on ≤ 5.5″ screens
- [ ] Works correctly on ≥ 6.7″ screens
- [ ] No pixel overflow in landscape orientation
- [ ] Buttons meet Material Design tap target size (48x48dp)
- [ ] Colors meet WCAG AA contrast ratio (4.5:1)

### Git Collaboration Requirements
- [ ] All team members contribute ≥ 15% of commits
- [ ] Commits spread over time (not last-minute)
- [ ] Feature branches used for development
- [ ] Pull requests created and reviewed
- [ ] Contribution table matches Git statistics

### Documentation Requirements
- [ ] README includes setup instructions and screenshots
- [ ] Report follows template (Times New Roman, 12pt/14pt)
- [ ] All non-original content cited
- [ ] AI usage disclosed (< 40%)
- [ ] Report includes ERD, functionalities, testing, limitations
- [ ] Report saved as Group40_Final_Project_Submission.pdf

### Demo Video Requirements
- [ ] 10-15 minutes long
- [ ] Single continuous recording on physical device
- [ ] Shows all 7 required actions:
  1. Cold-start launch
  2. Register → logout → login
  3. Visit all screens, rotate once
  4. CRUD with Firebase Console visible
  5. State update affecting two widgets
  6. SharedPreferences persistence test
  7. Validation error with polite message
- [ ] Every team member speaks and demonstrates
- [ ] ≥ 1080p quality with clear audio
- [ ] No slide decks or team introductions

