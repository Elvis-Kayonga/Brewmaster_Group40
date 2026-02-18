# Payment System Documentation

## Overview
The BrewMaster payment system implements a secure escrow-based payment mechanism for transactions between coffee buyers and farmers. The system supports M-Pesa and MTN Mobile Money payment methods with comprehensive transaction lifecycle management.

## Architecture

### Domain Layer

#### Transaction Model (`lib/domain/models/transaction.dart`)
Represents an escrow transaction with the following key properties:
- **Transaction States**: pending → fundsHeld → delivered → completed
- **Retry Mechanism**: Up to 3 automatic retry attempts for failed payments
- **Status History**: Complete audit trail of all status transitions
- **Payment Methods**: M-Pesa and MTN Mobile Money support

**Key Features:**
- Firestore serialization/deserialization
- Status validation logic
- Fund release eligibility checks
- Immutable transaction records with copyWith pattern

#### PaymentService (`lib/domain/services/payment_service.dart`)
Core business logic for payment processing:

**Methods:**
- `createTransaction()` - Creates new escrow transaction
- `processPayment()` - Processes buyer payment with retry logic (90% success rate simulation)
- `confirmDelivery()` - Farmer confirms coffee delivery
- `confirmReceiptAndReleaseFunds()` - Buyer confirms receipt, releases funds to farmer
- `raiseDispute()` - Initiates dispute resolution process
- `cancelTransaction()` - Cancels pending transactions
- `getUserTransactions()` - Real-time transaction stream for user
- `getUserStatistics()` - Calculates earnings and transaction counts

**Security Features:**
- Transaction state validation
- Atomic Firestore operations
- Retry logic with exponential backoff
- Fund release verification

#### PaymentValidator (`lib/domain/validators/payment_validator.dart`)
Input validation and data sanitization:

**Validators:**
- `validateAmount()` - Ensures amount is positive, max 2 decimals, within limits ($1-$1M)
- `validatePhoneNumber()` - Validates M-Pesa/MTN phone formats
- `validatePaymentPin()` - 4-digit PIN validation, rejects weak PINs (0000, 1234, etc.)
- `validateDisputeReason()` - 10-500 character requirement
- `sanitizePaymentData()` - Removes sensitive fields, masks phone numbers

### Presentation Layer

#### PaymentProvider (`lib/presentation/providers/payment_provider.dart`)
State management using Provider pattern:

**State Management:**
- Loading states for async operations
- Error handling with user-friendly messages
- Real-time transaction updates
- Statistics caching

**Public Methods:**
- `createTransaction()` - Initiates payment flow
- `processPayment()` - Handles payment processing
- `confirmDelivery()` - Delivery confirmation
- `confirmReceiptAndReleaseFunds()` - Final release
- `raiseDispute()` - Dispute handling
- `subscribeToUserTransactions()` - Live transaction updates
- `loadUserStatistics()` - Load user earnings/stats

## User Interface

### 1. PaymentScreen (`lib/presentation/screens/payment_screen.dart`)

**Purpose:** Initiate a payment transaction for a coffee purchase

**Features:**
- Payment method selection (M-Pesa / MTN Mobile Money)
- Phone number input with format validation
- Secure PIN entry
- Payment summary with amount breakdown
- Terms and conditions agreement
- Real-time validation feedback

**User Flow:**
1. User selects payment method
2. Enters mobile money phone number
3. Enters 4-digit payment PIN
4. Reviews payment summary
5. Accepts terms and conditions
6. Clicks "Process Payment"
7. Payment processed with automatic retry if needed
8. Success: Funds held in escrow, user redirected

**Validations:**
- Valid phone number format for selected method
- 4-digit PIN (rejects weak PINs)
- Amount within acceptable range
- Terms agreement required

### 2. TransactionDetailScreen (`lib/presentation/screens/transaction_detail_screen.dart`)

**Purpose:** View detailed information about a specific transaction and take actions

**Features:**
- Transaction status badge with live updates
- Complete transaction information (ID, amount, payment method, dates)
- Status timeline showing all transitions
- Context-aware action buttons
- Dispute submission form

**User Actions:**

**For Farmers:**
- **Confirm Delivery** (when status = fundsHeld)
  - Marks coffee as delivered
  - Transitions to "delivered" status
  - Notifies buyer

**For Buyers:**
- **Confirm Receipt & Release Funds** (when status = delivered)
  - Confirms coffee received in good condition
  - Releases escrowed funds to farmer
  - Completes transaction

**For Both:**
- **Raise Dispute** (before completion)
  - Submit detailed dispute reason (10-500 chars)
  - Flags transaction for manual review
  - Holds funds until resolution

**Information Displayed:**
- Transaction ID
- Amount with currency formatting
- Payment method icon and label
- Creation date and time
- Status history with timestamps
- Retry attempts (if any)
- Dispute reason (if disputed)

### 3. TransactionHistoryScreen (`lib/presentation/screens/transaction_history_screen.dart`)

**Purpose:** View all transactions with filtering and statistics

**Features:**
- Statistics summary card
  - Total earnings
  - Completed transaction count
  - Pending transaction count
- Tabbed interface for filtering:
  - **All** - Shows all transactions
  - **Active** - Pending, fundsHeld, delivered
  - **Completed** - Successfully completed
  - **Disputed** - Under dispute
- Transaction cards with:
  - Amount prominently displayed
  - Status badge
  - Direction indicator (sent/received)
  - Payment method icon
  - Date and time
  - Retry indicators
  - Dispute flags
- Tap to view transaction details
- Empty states for each filter

**Transaction Card Information:**
- Amount: $XXX.XX format
- Status: Visual badge (color-coded)
- Direction: ↑ Payment Sent (buyer) / ↓ Payment Received (farmer)
- Date: "MMM DD, YYYY HH:MM" format
- Payment Method: Icon + label
- Special Indicators:
  - 🔄 Retry count (if retried)
  - 🚩 Dispute flag (if disputed)

## Transaction Lifecycle

```
1. PENDING
   ↓ (buyer pays)
2. FUNDS_HELD (escrow)
   ↓ (farmer confirms delivery)
3. DELIVERED
   ↓ (buyer confirms receipt)
4. COMPLETED
```

**Alternative Paths:**
- **PENDING** → Cancel (only from pending)
- **ANY** → DISPUTED (before completion)
- **PENDING** → CANCELLED (after 3 failed retries)

## Payment Flow

### Buyer Perspective
1. Browse coffee listings
2. Select listing and click "Purchase"
3. Redirected to PaymentScreen
4. Select payment method (M-Pesa/MTN)
5. Enter phone number and PIN
6. Accept terms and conditions
7. Click "Process Payment"
8. Payment processed (with automatic retry if needed)
9. Funds held in escrow (status: FUNDS_HELD)
10. Wait for farmer delivery confirmation
11. Receive delivery notification (status: DELIVERED)
12. Inspect coffee delivery
13. Confirm receipt on TransactionDetailScreen
14. Funds released to farmer (status: COMPLETED)

### Farmer Perspective
1. Receive purchase notification
2. View transaction in TransactionHistoryScreen (status: PENDING)
3. Wait for payment processing
4. Receive payment confirmation (status: FUNDS_HELD)
5. Prepare and deliver coffee
6. Confirm delivery on TransactionDetailScreen
7. Wait for buyer confirmation (status: DELIVERED)
8. Receive funds when buyer confirms (status: COMPLETED)
9. View earnings in statistics

## Security Measures

1. **Payment Data Validation**
   - Amount limits and format validation
   - Phone number format verification
   - PIN strength requirements

2. **Data Sanitization**
   - Sensitive fields removed from logs
   - Phone numbers masked (****1234)
   - No storage of PINs or passwords

3. **Transaction Integrity**
   - Atomic Firestore operations
   - Status validation before transitions
   - Retry limit enforcement (max 3)
   - Timestamp verification

4. **Escrow Protection**
   - Funds held until both parties confirm
   - Dispute mechanism for issues
   - Manual review for disputed transactions

## Testing

### Property Tests (`test/`)
Comprehensive test coverage includes:

1. **payment_service_test.dart** (15 test groups)
   - Transaction creation uniqueness
   - Status transition validation
   - Fund release conditions
   - Dispute workflows
   - Retry logic
   - Data serialization integrity

2. **payment_validator_test.dart** (9 test groups)
   - Amount validation properties
   - Phone number format validation
   - PIN security validation
   - Data sanitization verification

3. **transaction_history_screen_test.dart** (14 test groups)
   - UI rendering and filtering
   - Transaction ordering
   - Statistics accuracy
   - Status badge mapping

**Test Statistics:**
- 150+ test cases
- Property-based testing approach
- Zero errors, clean analyzer output

## Error Handling

### User-Facing Errors
1. **Payment Failed**
   - Message: "Payment failed after X retries"
   - Action: Prompt user to try again or contact support

2. **Invalid Phone Number**
   - Message: "Invalid M-Pesa/MTN number format"
   - Action: Show format example

3. **Weak PIN**
   - Message: "PIN is too weak"
   - Action: Request stronger PIN

4. **Invalid Transaction State**
   - Message: "Cannot perform this action in current state"
   - Action: Show current status and valid actions

### Developer Errors
- Logged via PaymentProvider error state
- Captured in Firestore transaction logs
- Includes stack traces for debugging

## Future Enhancements

1. **Real Payment Integration**
   - Replace dummy simulation with actual M-Pesa/MTN API
   - Implement webhook handlers for payment callbacks
   - Add payment gateway SDKs

2. **Extended Features**
   - Partial refunds
   - Split payments
   - Scheduled/recurring payments
   - Multi-currency support

3. **Advanced Security**
   - Two-factor authentication
   - Biometric verification
   - Transaction limits per user
   - Fraud detection algorithms

4. **Analytics**
   - Payment success rates
   - Average transaction times
   - Dispute resolution metrics
   - Revenue tracking

## Dependencies

```yaml
dependencies:
  firebase_core: ^2.24.2
  cloud_firestore: ^4.14.0
  provider: ^6.1.1
  intl: ^0.19.0

dev_dependencies:
  fake_cloud_firestore: ^2.5.0
  flutter_test: sdk: flutter
```

## Configuration

No additional configuration required. The payment system uses:
- Firebase Firestore for data persistence
- Provider for state management
- Dummy data simulation for testing without actual payment gateways

## API Reference

### PaymentService

```dart
// Create transaction
Future<Transaction> createTransaction({
  required String buyerId,
  required String farmerId,
  required String listingId,
  required double amount,
  required PaymentMethod paymentMethod,
})

// Process payment (with retry)
Future<Transaction> processPayment(String transactionId)

// Confirm delivery
Future<Transaction> confirmDelivery(String transactionId)

// Release funds
Future<Transaction> confirmReceiptAndReleaseFunds(String transactionId)

// Raise dispute
Future<Transaction> raiseDispute(String transactionId, String reason)

// Get user transactions
Stream<List<Transaction>> getUserTransactions(String userId)

// Get user statistics
Future<Map<String, dynamic>> getUserStatistics(String userId)
```

### PaymentProvider

```dart
// Create and process transaction
Future<Transaction?> createTransaction(...)
Future<bool> processPayment(String transactionId)
Future<bool> confirmDelivery(String transactionId)
Future<bool> confirmReceiptAndReleaseFunds(String transactionId)
Future<bool> raiseDispute(String transactionId, String reason)

// Subscribe to updates
void subscribeToUserTransactions(String userId)
Future<void> loadUserStatistics(String userId)

// Filtered access
List<Transaction> getTransactionsByStatus(TransactionStatus status)
int get pendingTransactionsCount
int get completedTransactionsCount
double get totalEarnings
```

## Support

For issues or questions:
1. Check test files for usage examples
2. Review property tests for expected behavior
3. Consult Firestore logs for transaction history
4. Contact development team for payment gateway integration

---

**Version:** 1.0.0  
**Last Updated:** February 18, 2026  
**Developer:** Developer 4  
**Status:** ✅ Implementation Complete
