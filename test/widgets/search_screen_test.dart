// test/widgets/search_screen_test.dart

import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:brewmaster/config/localization/app_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brewmaster/domain/models/coffee_listing.dart';
import 'package:brewmaster/domain/models/enums.dart' hide MessageType;
import 'package:brewmaster/domain/models/offline_sync_operation.dart';
import 'package:brewmaster/domain/models/paginated_result.dart';
import 'package:brewmaster/domain/models/search_filters.dart';
import 'package:brewmaster/domain/models/user_profile.dart';
import 'package:brewmaster/domain/models/conversation.dart';
import 'package:brewmaster/domain/models/message.dart';
import 'package:brewmaster/domain/models/paginated_result.dart' as paginated;
import 'package:brewmaster/domain/repositories/auth_repository.dart';
import 'package:brewmaster/domain/repositories/listing_repository.dart';
import 'package:brewmaster/domain/repositories/message_repository.dart';
import 'package:brewmaster/domain/repositories/offline_sync_repository.dart';
import 'package:brewmaster/domain/repositories/user_repository.dart';
import 'package:brewmaster/presentation/blocs/auth/auth_bloc.dart';
import 'package:brewmaster/presentation/blocs/connectivity/connectivity_bloc.dart';
import 'package:brewmaster/presentation/blocs/listing/listing_bloc.dart';
import 'package:brewmaster/presentation/blocs/messaging/messaging_bloc.dart';
import 'package:brewmaster/presentation/blocs/profile/profile_bloc.dart';
import 'package:brewmaster/presentation/screens/search/search_screen.dart';

class _FakeOfflineSyncRepository implements OfflineSyncRepository {
  @override
  Future<void> enqueueOperation(OfflineSyncOperation op) async {}
  @override
  Future<int> processPendingQueue() async => 0;
  @override
  Future<void> clearQueue() async {}
  @override
  Stream<bool> watchConnectivity() => Stream.value(true);
  @override
  Future<List<OfflineSyncOperation>> getPendingOperations() async => [];
}

class _FakeListingRepository implements ListingRepository {
  @override
  Future<String> createListing(CoffeeListing listing,
          {List<File>? images}) async =>
      'fake_id';
  @override
  Future<void> updateListing(CoffeeListing listing,
      {List<File>? newImages}) async {}
  @override
  Future<void> deleteListing(String listingId) async {}
  @override
  Future<CoffeeListing?> getListing(String listingId) async => null;
  @override
  Stream<List<CoffeeListing>> watchFarmerListings(String farmerId) =>
      Stream.value([]);
  @override
  Stream<List<CoffeeListing>> watchActiveListings() => Stream.value([
        CoffeeListing(
          listingId: 'test1',
          farmerId: 'farmer1',
          variety: 'Bourbon',
          quantity: 100,
          pricePerKg: 5.0,
          processingMethod: ProcessingMethod.washed,
          altitude: 1500,
          harvestDate: DateTime(2024, 1, 1),
          qualityScore: 80,
          description: 'Test coffee',
          images: [],
          location: '0,0',
          status: ListingStatus.active,
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        )
      ]);
  @override
  Future<List<CoffeeListing>> searchListings(SearchFilters filters) async =>
      [];
  @override
  Future<PaginatedResult<CoffeeListing>> getListingPage({
    int pageSize = 20,
    Object? startAfter,
  }) async =>
      const PaginatedResult<CoffeeListing>(items: [], hasMore: false);
}

class _FakeAuthRepository implements AuthRepository {
  @override
  Stream<User?> get authStateChanges => const Stream.empty();
  @override
  User? get currentUser => null;
  @override
  Future<User?> register(String email, String password) async => null;
  @override
  Future<User?> signIn(String email, String password) async => null;
  @override
  Future<User?> signInWithGoogle() async => null;
  @override
  Future<void> signOut() async {}
  @override
  Future<void> sendPasswordResetEmail(String email) async {}
  @override
  Future<bool> sendEmailVerification() async => false;
  @override
  Future<bool> isEmailVerified() async => false;
}

class _FakeMessageRepository implements MessageRepository {
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
  Future<paginated.PaginatedResult<Message>> getMessagePage({
    required String conversationId,
    int pageSize = 30,
    Object? startAfter,
  }) async =>
      paginated.PaginatedResult(items: [], cursor: null, hasMore: false);

  @override
  Future<void> migrateParticipantPhotoUrls() async {}
}

class _FakeUserRepository implements UserRepository {
  @override
  Future<UserProfile?> getUserProfile(String userId) async => null;
  @override
  Future<UserProfile?> getUserProfileByEmail(String email) async => null;
  @override
  Future<void> createUserProfile(UserProfile profile) async {}
  @override
  Future<void> updateUserProfile(
      String userId, Map<String, dynamic> updates) async {}
  @override
  Stream<UserProfile?> watchUserProfile(String userId) =>
      Stream.value(null);

  @override
  Future<void> saveListing(String userId, String listingId) async {}

  @override
  Future<void> unsaveListing(String userId, String listingId) async {}

  @override
  Future<List<String>> getSavedListings(String userId) async => [];
}

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => AuthBloc(
              authRepository: _FakeAuthRepository(),
              userRepository: _FakeUserRepository(),
            ),
          ),
          BlocProvider(
            create: (_) => ListingBloc(repository: _FakeListingRepository()),
          ),
          BlocProvider(
            create: (_) => ConnectivityBloc(
                repository: _FakeOfflineSyncRepository()),
          ),
          BlocProvider(create: (_) => ProfileBloc(userRepository: _FakeUserRepository())),
          BlocProvider(create: (_) => MessagingBloc(repository: _FakeMessageRepository())),
        ],
        child: child,
      ),
    );

void main() {
  group('SearchScreen Widget Tests', () {
    testWidgets('renders with filter button', (tester) async {
      await tester.pumpWidget(_wrap(const SearchScreen()));
      await tester.pump();
      expect(find.text('Direct Trade\nShop'), findsOneWidget);
      expect(find.text('ADVANCED FILTERS'), findsOneWidget);
    });

    testWidgets('shows filter options when toggled', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_wrap(const SearchScreen()));
      await tester.pump();
      await tester.tap(find.text('ADVANCED FILTERS'));
      await tester.pumpAndSettle();
      expect(find.text('HIDE FILTERS'), findsOneWidget);
    });

    testWidgets('has clear button inside filter panel', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_wrap(const SearchScreen()));
      await tester.pump();
      await tester.tap(find.text('ADVANCED FILTERS'));
      await tester.pumpAndSettle();
      expect(find.text('CLEAR'), findsOneWidget);
    });

    testWidgets('displays list view', (tester) async {
      await tester.pumpWidget(_wrap(const SearchScreen()));
      await tester.pump();
      await tester.pump();
      expect(find.byType(ListView), findsWidgets);
    });
  });
}
