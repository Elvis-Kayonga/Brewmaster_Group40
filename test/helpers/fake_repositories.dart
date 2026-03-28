// Shared fake repository implementations used across screen tests.
// Using hand-rolled fakes (no mocktail/mockito) — only flutter_test available.

import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:brewmaster/domain/models/coffee_listing.dart';
import 'package:brewmaster/domain/models/conversation.dart';
import 'package:brewmaster/domain/models/enums.dart' hide MessageType;
import 'package:brewmaster/domain/models/escrow_transaction.dart' as models;
import 'package:brewmaster/domain/models/message.dart';
import 'package:brewmaster/domain/models/notification.dart';
import 'package:brewmaster/domain/models/paginated_result.dart';
import 'package:brewmaster/domain/models/search_filters.dart';
import 'package:brewmaster/domain/models/user_profile.dart';
import 'package:brewmaster/domain/models/verification_request.dart';
import 'package:brewmaster/domain/models/offline_sync_operation.dart';
import 'package:brewmaster/domain/repositories/auth_repository.dart';
import 'package:brewmaster/domain/repositories/listing_repository.dart';
import 'package:brewmaster/domain/repositories/message_repository.dart';
import 'package:brewmaster/domain/repositories/notification_repository.dart';
import 'package:brewmaster/domain/repositories/offline_sync_repository.dart';
import 'package:brewmaster/domain/repositories/payment_repository.dart';
import 'package:brewmaster/domain/repositories/user_repository.dart';
import 'package:brewmaster/domain/repositories/verification_repository.dart';

// ── AuthRepository ────────────────────────────────────────────────────────────

class FakeAuthRepository implements AuthRepository {
  @override
  fb.User? get currentUser => null;
  @override
  Stream<fb.User?> get authStateChanges => const Stream.empty();
  @override
  Future<fb.User?> register(String email, String password) async => null;
  @override
  Future<fb.User?> signIn(String email, String password) async => null;
  @override
  Future<fb.User?> signInWithGoogle() async => null;
  @override
  Future<void> signOut() async {}
  @override
  Future<void> sendPasswordResetEmail(String email) async {}
  @override
  Future<bool> sendEmailVerification() async => false;
  @override
  Future<bool> isEmailVerified() async => false;
}

// ── UserRepository ────────────────────────────────────────────────────────────

class FakeUserRepository implements UserRepository {
  UserProfile? profile;
  Exception? error;
  final _ctrl = StreamController<UserProfile?>.broadcast();

  FakeUserRepository({this.profile});

  void push(UserProfile? p) => _ctrl.add(p);
  void dispose() => _ctrl.close();

  @override
  Future<UserProfile?> getUserProfile(String userId) async {
    if (error != null) throw error!;
    return profile;
  }

  @override
  Future<UserProfile?> getUserProfileByEmail(String email) async => profile;

  @override
  Future<void> createUserProfile(UserProfile p) async {
    if (error != null) throw error!;
  }

  @override
  Future<void> updateUserProfile(String userId, Map<String, dynamic> updates) async {
    if (error != null) throw error!;
  }

  @override
  Stream<UserProfile?> watchUserProfile(String userId) =>
      profile != null ? Stream.value(profile) : const Stream.empty();

  @override
  Future<void> saveListing(String userId, String listingId) async {}

  @override
  Future<void> unsaveListing(String userId, String listingId) async {}

  @override
  Future<List<String>> getSavedListings(String userId) async => [];
}

// ── VerificationRepository ────────────────────────────────────────────────────

class FakeVerificationRepository implements VerificationRepository {
  VerificationStatus _status = VerificationStatus.unverified;
  VerificationRequest? _request;
  Exception? error;

  void setStatus(VerificationStatus s) => _status = s;
  void setRequest(VerificationRequest r) => _request = r;

  @override
  Future<void> submitVerificationRequest(String userId, List<File> documents) async {
    if (error != null) throw error!;
  }

  @override
  Future<String> uploadDocument(String userId, File document) async {
    if (error != null) throw error!;
    return 'https://fake-url.com/doc.jpg';
  }

  @override
  Future<VerificationRequest?> getVerificationStatus(String userId) async {
    if (error != null) throw error!;
    return _request;
  }

  @override
  Stream<VerificationStatus> watchVerificationStatus(String userId) =>
      Stream.value(_status);

  @override
  Future<void> syncStatusToUserProfile(String userId, VerificationStatus status) async {}
}

// ── NotificationRepository ────────────────────────────────────────────────────

class FakeNotificationRepository implements NotificationRepository {
  List<AppNotification> notifications = [];
  Map<String, bool> preferences = {};

  @override
  Future<bool> requestPermission() async => false;
  @override
  Future<String?> getToken() async => null;
  @override
  Stream<Map<String, dynamic>> watchNotifications() => Stream.value({});
  @override
  Future<void> updatePreferences(Map<String, bool> prefs) async {
    preferences = prefs;
  }
  @override
  Future<Map<String, bool>> getPreferences() async => preferences;
  @override
  Future<void> saveNotification(AppNotification notification) async {}
  @override
  Stream<List<AppNotification>> watchUserNotifications(String userId) =>
      Stream.value(notifications);
  @override
  Future<void> markAsRead(String notificationId, String userId) async {}
  @override
  Future<void> markAllAsRead(String userId) async {}
  @override
  Future<int> getUnreadCount(String userId) async =>
      notifications.where((n) => !n.isRead).length;
}

// ── MessageRepository ─────────────────────────────────────────────────────────

class FakeMessageRepository implements MessageRepository {
  @override
  Future<Message> sendMessage({
    required String conversationId,
    required String receiverId,
    required String content,
    MessageType messageType = MessageType.text,
    String? listingId,
  }) async =>
      throw UnimplementedError();

  @override
  Stream<List<Conversation>> watchConversations() => Stream.value([]);

  @override
  Stream<List<Message>> watchMessages(String conversationId) =>
      Stream.value([]);

  @override
  Future<void> markConversationAsRead(String conversationId) async {}

  @override
  Future<Conversation> getOrCreateConversation(String otherUserId) async =>
      throw UnimplementedError();

  @override
  Future<int> getTotalUnreadCount() async => 0;

  @override
  Future<PaginatedResult<Message>> getMessagePage({
    required String conversationId,
    int pageSize = 30,
    Object? startAfter,
  }) async =>
      const PaginatedResult(items: [], hasMore: false);

  @override
  Future<void> migrateParticipantPhotoUrls() async {}
}

// ── PaymentRepository ─────────────────────────────────────────────────────────

class FakePaymentRepository implements PaymentRepository {
  List<models.Transaction> transactions = [];
  Map<String, dynamic> statistics = {};
  models.Transaction? transaction;
  Exception? error;

  @override
  Future<models.Transaction> createTransaction({
    required String buyerId,
    required String farmerId,
    required String listingId,
    required double amount,
    String currency = 'USD',
    required PaymentMethod paymentMethod,
    String? paymentReference,
  }) async {
    if (error != null) throw error!;
    return transaction!;
  }

  @override
  Future<models.Transaction> processPayment(String transactionId) async {
    if (error != null) throw error!;
    return transaction!;
  }

  @override
  Future<models.Transaction> confirmDelivery(String transactionId) async {
    if (error != null) throw error!;
    return transaction!;
  }

  @override
  Future<models.Transaction> confirmReceiptAndReleaseFunds(String transactionId) async {
    if (error != null) throw error!;
    return transaction!;
  }

  @override
  Future<models.Transaction> raiseDispute(String transactionId, String reason) async {
    if (error != null) throw error!;
    return transaction!;
  }

  @override
  Future<models.Transaction> cancelTransaction(String transactionId) async {
    if (error != null) throw error!;
    return transaction!;
  }

  @override
  Future<models.Transaction?> getTransaction(String transactionId) async {
    if (error != null) throw error!;
    return transaction;
  }

  @override
  Stream<List<models.Transaction>> getUserTransactions(String userId) =>
      Stream.value(transactions);

  @override
  Stream<List<models.Transaction>> getListingTransactions(String listingId) =>
      Stream.value(transactions);

  @override
  Future<Map<String, dynamic>> getUserStatistics(String userId) async => statistics;

  @override
  Future<PaginatedResult<models.Transaction>> getTransactionPage({
    required String userId,
    int pageSize = 20,
    Object? startAfter,
  }) async =>
      const PaginatedResult(items: [], hasMore: false);
}

// ── OfflineSyncRepository ─────────────────────────────────────────────────────

class FakeOfflineSyncRepository implements OfflineSyncRepository {
  @override
  Stream<bool> watchConnectivity() => Stream.value(true);
  @override
  Future<void> enqueueOperation(OfflineSyncOperation operation) async {}
  @override
  Future<int> processPendingQueue() async => 0;
  @override
  Future<void> clearQueue() async {}
  @override
  Future<List<OfflineSyncOperation>> getPendingOperations() async => [];
}

// ── ListingRepository ─────────────────────────────────────────────────────────

class FakeListingRepository implements ListingRepository {
  List<CoffeeListing> listings = [];
  CoffeeListing? listing;
  Exception? error;

  @override
  Future<String> createListing(CoffeeListing l, {List<File>? images}) async {
    if (error != null) throw error!;
    return l.listingId;
  }

  @override
  Future<void> updateListing(CoffeeListing l, {List<File>? newImages}) async {
    if (error != null) throw error!;
  }

  @override
  Future<void> deleteListing(String listingId) async {
    if (error != null) throw error!;
  }

  @override
  Future<CoffeeListing?> getListing(String listingId) async {
    if (error != null) throw error!;
    return listing;
  }

  @override
  Stream<List<CoffeeListing>> watchFarmerListings(String farmerId) =>
      Stream.value(listings);

  @override
  Stream<List<CoffeeListing>> watchActiveListings() => Stream.value(listings);

  @override
  Future<List<CoffeeListing>> searchListings(SearchFilters filters) async => listings;

  @override
  Future<PaginatedResult<CoffeeListing>> getListingPage({
    int pageSize = 20,
    Object? startAfter,
  }) async =>
      const PaginatedResult(items: [], hasMore: false);
}

// ── Common fixture helpers ────────────────────────────────────────────────────

UserProfile makeProfile({
  String id = 'u1',
  String email = 'test@test.com',
  UserRole role = UserRole.farmer,
  bool isVerified = true,
  VerificationStatus verificationStatus = VerificationStatus.unverified,
  String displayName = 'Test User',
}) =>
    UserProfile(
      id: id,
      email: email,
      phoneNumber: '+1234567890',
      role: role,
      displayName: displayName,
      isVerified: isVerified,
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
      verificationStatus: verificationStatus,
      farmSize: 5.0,
      farmLocation: 'Kigali',
      coffeeVarieties: ['Arabica'],
      businessName: 'CoffeeCo',
      businessType: 'Roaster',
      monthlyVolume: 100.0,
    );
