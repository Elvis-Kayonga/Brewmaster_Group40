# BrewMaster Entity-Relationship Diagram (ERD)

## Overview

This document describes the Firestore database structure for the BrewMaster Coffee Marketplace application. All field names, types, and relationships are documented here and MUST match the actual Firestore implementation exactly.

## Collections

### 1. users

**Primary Key**: `id` (String - Firebase Auth UID)

**Description**: Stores user profiles for both farmers and buyers

| Field Name | Type | Required | Description |
|------------|------|----------|-------------|
| id | String | Yes | User ID (Firebase Auth UID) |
| email | String | Yes | User email address |
| phoneNumber | String | Yes | User phone number |
| role | String | Yes | User role: "farmer" or "buyer" |
| displayName | String | Yes | User's display name |
| photoUrl | String | No | URL to profile photo |
| isVerified | Boolean | Yes | Verification status (true/false) |
| createdAt | Timestamp | Yes | Account creation timestamp |
| updatedAt | Timestamp | Yes | Last update timestamp |
| farmSize | Number | No | Farm size in hectares (farmers only) |
| farmLocation | String | No | Farm location (farmers only) |
| coffeeVarieties | Array<String> | No | Coffee varieties grown (farmers only) |
| farmRegistrationNumber | String | No | Farm registration number (farmers only) |
| businessName | String | No | Business name (buyers only) |
| businessType | String | No | Type of business (buyers only) |
| monthlyVolume | Number | No | Monthly purchase volume in kg (buyers only) |
| fcmToken | String | No | Firebase Cloud Messaging token |
| verificationStatus | String | Yes | Verification status: "unverified", "pending", "verified", "rejected" |

**Relationships**:
- One user can have many listings (1:N with listings)
- One user can have many conversations (1:N with conversations)
- One user can have many transactions (1:N with transactions)
- One user can have one verification record (1:1 with verifications)

---

### 2. listings

**Primary Key**: `id` (String - Auto-generated)

**Description**: Coffee listings created by farmers

| Field Name | Type | Required | Description |
|------------|------|----------|-------------|
| id | String | Yes | Listing ID (auto-generated) |
| farmerId | String | Yes | Foreign key to users.id |
| farmerName | String | Yes | Farmer's display name (denormalized) |
| coffeeVariety | String | Yes | Coffee variety name |
| quantityKg | Number | Yes | Quantity in kilograms |
| altitude | Number | Yes | Altitude in meters (1000-2500) |
| processingMethod | String | Yes | Processing method: "washed", "natural", "honey" |
| harvestDate | Timestamp | Yes | Harvest date |
| askingPricePerKg | Number | Yes | Asking price per kilogram |
| imageUrls | Array<String> | Yes | Array of image URLs (max 5) |
| cuppingScore | Number | No | Cupping score (0-100) |
| flavorNotes | String | No | Flavor notes description |
| status | String | Yes | Listing status: "draft", "active", "sold", "expired" |
| viewCount | Number | Yes | Number of views (default 0) |
| createdAt | Timestamp | Yes | Creation timestamp |
| updatedAt | Timestamp | Yes | Last update timestamp |

**Relationships**:
- Many listings belong to one user (N:1 with users via farmerId)
- One listing can have many messages referencing it (1:N with messages)
- One listing can have one transaction (1:1 with transactions)

**Indexes**:
- Composite: (status, coffeeVariety, createdAt DESC)
- Composite: (status, altitude, askingPricePerKg)
- Composite: (farmerId, status, createdAt DESC)

---

### 3. conversations

**Primary Key**: `id` (String - Auto-generated)

**Description**: Conversation threads between users

| Field Name | Type | Required | Description |
|------------|------|----------|-------------|
| id | String | Yes | Conversation ID (auto-generated) |
| participantIds | Array<String> | Yes | Array of user IDs (2 participants) |
| participantNames | Map<String, String> | Yes | Map of userId -> displayName |
| listingId | String | No | Related listing ID (if conversation started from listing) |
| lastMessageContent | String | No | Content of last message |
| lastMessageAt | Timestamp | No | Timestamp of last message |
| unreadCounts | Map<String, Number> | Yes | Map of userId -> unread count |
| createdAt | Timestamp | Yes | Creation timestamp |
| updatedAt | Timestamp | Yes | Last update timestamp |

**Relationships**:
- Many conversations belong to many users (N:M via participantIds array)
- One conversation can reference one listing (N:1 with listings via listingId)
- One conversation has many messages (1:N with messages subcollection)

**Indexes**:
- Composite: (participantIds ARRAY_CONTAINS, updatedAt DESC)

---

### 4. conversations/{conversationId}/messages (Subcollection)

**Primary Key**: `id` (String - Auto-generated)

**Description**: Messages within a conversation

| Field Name | Type | Required | Description |
|------------|------|----------|-------------|
| id | String | Yes | Message ID (auto-generated) |
| senderId | String | Yes | Foreign key to users.id |
| senderName | String | Yes | Sender's display name (denormalized) |
| content | String | Yes | Message content |
| type | String | Yes | Message type: "text", "listingReference", "system" |
| listingId | String | No | Referenced listing ID (if type is listingReference) |
| isRead | Boolean | Yes | Read status (default false) |
| createdAt | Timestamp | Yes | Creation timestamp |

**Relationships**:
- Many messages belong to one conversation (N:1 with conversations)
- Many messages belong to one user (N:1 with users via senderId)
- One message can reference one listing (N:1 with listings via listingId)

---

### 5. transactions

**Primary Key**: `id` (String - Auto-generated)

**Description**: Escrow transactions for coffee purchases

| Field Name | Type | Required | Description |
|------------|------|----------|-------------|
| id | String | Yes | Transaction ID (auto-generated) |
| buyerId | String | Yes | Foreign key to users.id |
| farmerId | String | Yes | Foreign key to users.id |
| listingId | String | Yes | Foreign key to listings.id |
| amount | Number | Yes | Transaction amount |
| currency | String | Yes | Currency code (e.g., "USD", "KES") |
| status | String | Yes | Status: "pending", "fundsHeld", "delivered", "completed", "disputed", "cancelled" |
| paymentMethod | String | Yes | Payment method: "mpesa", "mtnMobileMoney" |
| paymentReference | String | No | Payment reference from provider |
| deliveryConfirmedAt | Timestamp | No | Delivery confirmation timestamp |
| receiptConfirmedAt | Timestamp | No | Receipt confirmation timestamp |
| completedAt | Timestamp | No | Completion timestamp |
| disputeReason | String | No | Reason for dispute (if status is disputed) |
| createdAt | Timestamp | Yes | Creation timestamp |
| updatedAt | Timestamp | Yes | Last update timestamp |

**Relationships**:
- Many transactions belong to one buyer (N:1 with users via buyerId)
- Many transactions belong to one farmer (N:1 with users via farmerId)
- Many transactions belong to one listing (N:1 with listings via listingId)

**Indexes**:
- Composite: (farmerId, status, createdAt DESC)
- Composite: (buyerId, status, createdAt DESC)

---

### 6. marketPrices

**Primary Key**: `id` (String - Auto-generated)

**Description**: Market price data for coffee varieties

| Field Name | Type | Required | Description |
|------------|------|----------|-------------|
| id | String | Yes | Price record ID (auto-generated) |
| variety | String | Yes | Coffee variety name |
| grade | String | Yes | Quality grade: "specialty", "premium", "standard" |
| lowPrice | Number | Yes | Low price per kg |
| avgPrice | Number | Yes | Average price per kg |
| highPrice | Number | Yes | High price per kg |
| currency | String | Yes | Currency code |
| updatedAt | Timestamp | Yes | Last update timestamp |

**Relationships**:
- None (reference data)

---

### 7. verifications

**Primary Key**: `userId` (String - Foreign key to users.id)

**Description**: Verification status and documents for users

| Field Name | Type | Required | Description |
|------------|------|----------|-------------|
| userId | String | Yes | Foreign key to users.id |
| state | String | Yes | Verification state: "unverified", "pending", "verified", "rejected" |
| documentUrls | Array<String> | Yes | Array of document URLs |
| rejectionReason | String | No | Reason for rejection (if state is rejected) |
| verifiedAt | Timestamp | No | Verification timestamp |
| updatedAt | Timestamp | Yes | Last update timestamp |

**Relationships**:
- One verification belongs to one user (1:1 with users via userId)

---

### 8. notifications

**Primary Key**: `id` (String - Auto-generated)

**Description**: Push notifications for users

| Field Name | Type | Required | Description |
|------------|------|----------|-------------|
| id | String | Yes | Notification ID (auto-generated) |
| userId | String | Yes | Foreign key to users.id |
| title | String | Yes | Notification title |
| body | String | Yes | Notification body |
| type | String | Yes | Notification type: "newMessage", "purchaseInitiated", "paymentReceived", "deliveryConfirmed", "verificationUpdated", "listingInterest" |
| data | Map | Yes | Additional data payload |
| isRead | Boolean | Yes | Read status (default false) |
| createdAt | Timestamp | Yes | Creation timestamp |

**Relationships**:
- Many notifications belong to one user (N:1 with users via userId)

---

## Relationship Summary

### One-to-Many (1:N)
- users → listings (via farmerId)
- users → conversations (via participantIds array)
- users → transactions (via buyerId and farmerId)
- users → notifications (via userId)
- conversations → messages (subcollection)
- listings → messages (via listingId reference)

### One-to-One (1:1)
- users ↔ verifications (via userId)
- listings ↔ transactions (via listingId)

### Many-to-Many (N:M)
- users ↔ conversations (via participantIds array)

---

## Data Types Reference

| Firestore Type | Dart Type | Description |
|----------------|-----------|-------------|
| String | String | Text data |
| Number | int, double | Numeric data |
| Boolean | bool | True/false values |
| Timestamp | DateTime | Date and time |
| Array | List | Ordered list of values |
| Map | Map<String, dynamic> | Key-value pairs |

---

## Security Rules Summary

- **users**: Users can read all profiles, but only create/update/delete their own
- **listings**: All authenticated users can read, only listing owner can create/update/delete
- **conversations**: Only participants can read/write
- **messages**: Only conversation participants can read/write
- **transactions**: Only buyer and farmer involved can read/write
- **marketPrices**: Read-only for all authenticated users
- **verifications**: Only the user can read/write their own verification
- **notifications**: Only the user can read/update their own notifications

---

## Notes

1. All timestamps use Firestore Timestamp type
2. All IDs are auto-generated by Firestore except where noted
3. Foreign keys are stored as String references to document IDs
4. Arrays are used for one-to-many relationships where appropriate
5. Denormalized data (e.g., farmerName, senderName) is used to reduce reads
6. Composite indexes are required for complex queries (defined in firestore.indexes.json)

---

## Validation Rules

- **altitude**: Must be between 1000 and 2500 meters
- **cuppingScore**: Must be between 0 and 100
- **imageUrls**: Maximum 5 images per listing
- **participantIds**: Exactly 2 participants per conversation
- **email**: Must be valid email format
- **phoneNumber**: Must be valid phone format
- **farmSize**: Must be greater than 0 and less than 1000 hectares

---

**Last Updated**: Phase 0 - Foundation
**Status**: Ready for Implementation
**Approved By**: All Developers (pending Task 0.4.2 review)
