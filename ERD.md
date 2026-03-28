# BrewMaster Entity-Relationship Diagram (ERD)

## Visual Diagram

```mermaid
erDiagram
    users ||--o{ listings : "creates"
    users ||--o{ transactions : "buys/sells"
    users ||--o{ notifications : "receives"
    users ||--|| verifications : "has"
    users }o--o{ conversations : "participates"
    users ||--o| userPreferences : "configures"
    users ||--o{ savedLots : "saves"
    savedLots }o--|| listings : "references"
    
    listings ||--o| transactions : "sold via"
    listings ||--o{ messages : "referenced in"
    
    conversations ||--|{ messages : "contains"
    
    users {
        string id PK "Firebase Auth UID"
        string email
        string phoneNumber
        string role "farmer|buyer"
        string displayName
        string photoUrl
        string country "ISO country code e.g. KE UG TZ"
        boolean isVerified
        timestamp createdAt
        timestamp updatedAt
        number farmSize "farmers only"
        string farmLocation "farmers only"
        array coffeeVarieties "farmers only"
        string farmRegistrationNumber "farmers only"
        string businessName "buyers only"
        string businessType "buyers only"
        number monthlyVolume "buyers only"
        string fcmToken
        string verificationStatus "unverified|pending|verified|rejected"
        array savedListings "listingIds saved by this user (buyer)"
    }
    
    listings {
        string id PK
        string farmerId FK
        string farmerName "denormalized"
        string coffeeVariety
        number quantityKg
        number altitude "1000-2500m"
        string processingMethod "washed|natural|honey"
        timestamp harvestDate
        number askingPricePerKg
        array imageUrls "max 5"
        number cuppingScore "0-100"
        string flavorNotes
        string location "farm/region location"
        string locationAddress "human-readable address shown on cards"
        string status "draft|active|sold|expired"
        string batchNumber "traceability"
        array certifications "e.g. Organic FairTrade"
        number viewCount "written by app; reserved for future analytics"
        timestamp createdAt
        timestamp updatedAt
    }
    
    conversations {
        string id PK
        array participantIds "2 users"
        map participantNames "userId to displayName"
        map participantPhotoUrls "userId to photoUrl - denormalized for avatars"
        string listingId FK
        map lastMessage "embedded Message object"
        string lastMessageContent "denormalized for quick reads"
        timestamp lastMessageAt "denormalized for quick reads"
        number unreadCount "unread count for current user"
        timestamp createdAt
        timestamp updatedAt
    }
    
    messages {
        string messageId PK
        string conversationId FK
        string senderId FK
        string senderName "denormalized"
        string receiverId FK
        string content
        string type "text|listingReference"
        string listingId FK
        boolean isRead
        timestamp createdAt
    }
    
    transactions {
        string id PK
        string buyerId FK
        string farmerId FK
        string listingId FK
        number amount
        string currency "USD canonical - Flutterwave charges buyer in local currency"
        string status "pending|fundsHeld|delivered|completed|disputed|cancelled"
        string paymentMethod "flutterwave"
        string paymentReference "Flutterwave txId e.g. FLW-XXXXXXXX"
        timestamp fundsHeldAt
        timestamp deliveredAt
        timestamp completedAt
        string disputeReason
        number retryCount
        string failureReason
        map statusHistory
        string receiptNumber "compliance traceability"
        map traceabilityData "certificationIds exportRef etc"
        timestamp createdAt
        timestamp updatedAt
    }
    
    verifications {
        string userId PK_FK
        string state "unverified|pending|verified|rejected"
        array documentUrls
        string rejectionReason
        timestamp verifiedAt
        timestamp updatedAt
    }
    
    notifications {
        string id PK
        string userId FK
        string title
        string body
        string type "newMessage|purchaseInitiated|paymentReceived|deliveryConfirmed|verificationUpdated|listingInterest"
        map data
        boolean isRead
        timestamp createdAt
    }
    
    marketPrices {
        string id PK
        string variety
        string grade "specialty|premium|standard"
        number lowPrice
        number avgPrice
        number highPrice
        string currency
        timestamp updatedAt
    }
```

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
| country | String | No | ISO country code e.g. "KE", "UG", "TZ" — drives currency display |
| isVerified | Boolean | Yes | Email verification status (true/false) |
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
| verificationStatus | String | Yes | KYC status: "unverified", "pending", "verified", "rejected" |

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
| id | String | Yes | Listing ID (auto-generated, stored as `listingId` in doc) |
| farmerId | String | Yes | Foreign key to users.id |
| farmerName | String | No | Farmer's display name (denormalized for quick reads) |
| coffeeVariety | String | Yes | Coffee variety name |
| quantityKg | Number | Yes | Quantity in kilograms |
| altitude | Number | Yes | Altitude in meters (1000-2500) |
| processingMethod | String | Yes | Processing method: "washed", "natural", "honey" |
| harvestDate | Timestamp | Yes | Harvest date |
| askingPricePerKg | Number | Yes | Asking price per kilogram |
| imageUrls | Array<String> | Yes | Array of image URLs (max 5) |
| cuppingScore | Number | No | Cupping score (0-100) |
| flavorNotes | String | No | Flavor notes / tasting description |
| location | String | No | Coordinate string for map pins ("lat,lng") |
| locationAddress | String | No | Human-readable address shown on listing cards (e.g. "Kigali, Rwanda") |
| status | String | Yes | Listing status: "draft", "active", "sold", "expired" |
| batchNumber | String | No | Traceability batch identifier |
| certifications | Array(String) | No | e.g. "Organic", "Fair Trade" |
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
| conversationId | String | Yes | Conversation ID (auto-generated) |
| participantIds | Array(String) | Yes | Array of user IDs (2 participants) |
| participantNames | Map(String,String) | Yes | Map of userId → displayName (denormalized) |
| participantPhotoUrls | Map(String,String) | No | Map of userId → photoUrl (denormalized for avatars) |
| listingId | String | No | Related listing ID (if conversation started from a listing) |
| lastMessage | Map | No | Embedded last Message object for quick display |
| lastMessageContent | String | No | Denormalized content of last message |
| lastMessageAt | Timestamp | No | Denormalized timestamp of last message |
| unreadCount | Number | Yes | Unread message count for the current user (default 0) |
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
| messageId | String | Yes | Message ID (auto-generated) |
| conversationId | String | Yes | Foreign key to conversations.id |
| senderId | String | Yes | Foreign key to users.id |
| senderName | String | No | Sender's display name (denormalized) |
| receiverId | String | Yes | Foreign key to users.id |
| content | String | Yes | Message content |
| type | String | Yes | Message type: "text", "listingReference" |
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
| amount | Number | Yes | Transaction amount in USD (canonical storage currency) |
| currency | String | Yes | Always `"USD"` — Flutterwave converts to buyer's local currency (KES/RWF/UGX/TZS/ETB/BIF) at checkout using live rates |
| status | String | Yes | Status: "pending", "fundsHeld", "delivered", "completed", "disputed", "cancelled" |
| paymentMethod | String | Yes | Always `"flutterwave"` — Flutterwave handles card, MPesa (KE), mobile money (RW/UG/TZ), and USSD per buyer country |
| paymentReference | String | No | Flutterwave transaction ID returned by the checkout SDK (e.g. `FLW-XXXXXXXX`) |
| fundsHeldAt | Timestamp | No | Timestamp when funds were held in escrow |
| deliveredAt | Timestamp | No | Timestamp when delivery was confirmed |
| completedAt | Timestamp | No | Timestamp when transaction was completed |
| disputeReason | String | No | Reason for dispute (if status is disputed) |
| retryCount | Number | Yes | Number of payment retry attempts (default 0) |
| failureReason | String | No | Reason for payment failure |
| statusHistory | Map(String,Timestamp) | Yes | Complete audit trail of status transitions |
| receiptNumber | String | No | Compliance/traceability receipt identifier |
| traceabilityData | Map(String,String) | No | Extra traceability fields e.g. certificationIds, exportRef |
| createdAt | Timestamp | Yes | Creation timestamp |
| updatedAt | Timestamp | No | Last status-change timestamp |

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

### 9. users/{userId}/savedLots (Subcollection)

**Primary Key**: `listingId` (String — document ID matches the saved listing's ID)

**Description**: Buyer's wishlist. Each document is a denormalised snapshot of a listing saved by the buyer. Stored as a subcollection so queries stay scoped to the authenticated user. Currently held in-memory (session only); this schema documents the intended Firestore structure for future persistence.

| Field Name | Type | Required | Description |
|------------|------|----------|-------------|
| listingId | String | Yes | Document ID — foreign key to listings.id |
| farmerId | String | Yes | Denormalized foreign key to users.id |
| farmerName | String | No | Denormalized farmer display name |
| variety | String | Yes | Coffee variety name (denormalized) |
| pricePerKg | Number | Yes | Price per kg at time of saving (denormalized) |
| availableQuantity | Number | Yes | Quantity in kg available at time of saving (denormalized) |
| location | String | Yes | Farm/region location (denormalized) |
| imageUrl | String | No | First image URL (denormalized) |
| savedAt | Timestamp | Yes | When the buyer saved this lot |

**Relationships**:
- Many savedLots belong to one user (subcollection under users/{userId})
- Each savedLot references one listing (N:1 with listings via listingId)

---

### 10. users/{userId}/preferences (Subcollection — single doc: `notifications`)

**Primary Key**: `notifications` (fixed document ID)

**Description**: Per-user notification preference settings. Stored as a subcollection so the main users doc stays lean.

| Field Name | Type | Required | Description |
|------------|------|----------|-------------|
| messagesEnabled | Boolean | Yes | Receive new message notifications (default true) |
| listingsEnabled | Boolean | Yes | Receive listing interest notifications (default true) |
| paymentsEnabled | Boolean | Yes | Receive payment/escrow notifications (default true) |
| promotionsEnabled | Boolean | Yes | Receive promotional notifications (default false) |
| updatedAt | Timestamp | Yes | Last update timestamp |

**Relationships**:
- One-to-one with users (subcollection keyed by fixed doc ID `notifications`)

---

## Relationship Summary

### One-to-Many (1:N)
- users → listings (via farmerId)
- users → conversations (via participantIds array)
- users → transactions (via buyerId and farmerId)
- users → notifications (via userId)
- users → savedLots (subcollection under users/{userId}/savedLots)
- conversations → messages (subcollection)
- listings → messages (via listingId reference)
- listings → savedLots (a listing can be saved by many buyers)

### One-to-One (1:1)
- users ↔ verifications (via userId)
- listings ↔ transactions (via listingId)

### Many-to-Many (N:M)
- users ↔ conversations (via participantIds array)
- users ↔ listings (buyers save many listings; a listing can be saved by many buyers — via savedLots subcollection)

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
- **messages**: Participants can read and create; participants can update only the `isRead` field
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

**Last Updated**: 2026-03-28
**Status**: In Sync with Implementation
**Changes in this update**:

- `listings`: removed `viewCount` (dead field — never read by UI); added `locationAddress` (human-readable address for cards, separate from `location` which stores "lat,lng" for map pins)
- `conversations`: added `participantPhotoUrls` map (userId → photoUrl, denormalized for avatar display); backfilled on existing docs via `migrateParticipantPhotoUrls()` at first authenticated load
- `messages`: security rule updated — participants can now `update` the `isRead` field; composite index added on (receiverId ASC, isRead ASC) for mark-read queries
- Farmer dashboard metric `views` (always 0, sourced from unwritten `viewCount`) replaced with `savedCount` — counts how many buyers have saved any of the farmer's listings (cross-user query on `savedListings` arrays)
- `users`: added `savedListings` array — buyer's saved listing IDs written via `FieldValue.arrayUnion`/`arrayRemove` on every save/unsave action; was previously in-memory only
- `transactions`: corrected `paymentMethod` — always `"flutterwave"` (not `"mpesa"` or `"mtnMobileMoney"`); Flutterwave is the single payment gateway and handles regional sub-methods (card, MPesa, mobile money, USSD) internally based on buyer country; corrected `currency` — always `"USD"` canonical; Flutterwave converts to local currency at checkout
