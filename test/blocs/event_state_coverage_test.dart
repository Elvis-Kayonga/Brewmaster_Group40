// Unit tests that instantiate event/state classes to improve coverage.
// These are pure data class tests — no Firebase, no widgets.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:brewmaster/domain/models/coffee_listing.dart';
import 'package:brewmaster/domain/models/enums.dart' hide NotificationType, MessageType;
import 'package:brewmaster/domain/models/escrow_transaction.dart' as models;
import 'package:brewmaster/domain/models/message.dart' show MessageType;
import 'package:brewmaster/domain/models/notification.dart';
import 'package:brewmaster/domain/models/search_filters.dart';
import 'package:brewmaster/presentation/blocs/auth/auth_bloc.dart';
import 'package:brewmaster/presentation/blocs/listing/listing_bloc.dart';
import 'package:brewmaster/presentation/blocs/listing_detail/listing_detail_bloc.dart';
import 'package:brewmaster/presentation/blocs/messaging/messaging_bloc.dart';
import 'package:brewmaster/presentation/blocs/messaging/notification_bloc.dart';
import 'package:brewmaster/presentation/blocs/payment/payment_bloc.dart';

// ── Fixtures ──────────────────────────────────────────────────────────────────

CoffeeListing _listing() => CoffeeListing(
      listingId: 'l1',
      farmerId: 'f1',
      variety: 'Bourbon',
      quantity: 50,
      pricePerKg: 10,
      processingMethod: ProcessingMethod.washed,
      altitude: 1500,
      harvestDate: DateTime(2024),
      qualityScore: 85,
      description: 'desc',
      images: const [],
      location: '',
      status: ListingStatus.active,
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    );

models.Transaction _tx() => models.Transaction(
      id: 'tx1',
      buyerId: 'b1',
      farmerId: 'f1',
      listingId: 'l1',
      amount: 100,
      currency: 'USD',
      status: TransactionStatus.pending,
      paymentMethod: PaymentMethod.mpesa,
      createdAt: DateTime(2024),
    );

AppNotification _notif() => AppNotification(
      id: 'n1',
      userId: 'u1',
      title: 'Test',
      body: 'Body',
      type: NotificationType.newMessage,
      data: const {},
      isRead: false,
      createdAt: DateTime(2024),
    );

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  // ── PaymentEvent ────────────────────────────────────────────────────────────
  group('PaymentEvent', () {
    test('PaymentInitiateRequested props', () {
      const e = PaymentInitiateRequested(
        buyerId: 'b1',
        farmerId: 'f1',
        listingId: 'l1',
        amount: 100.0,
        currency: 'KES',
        paymentMethod: PaymentMethod.mpesa,
      );
      expect(e.buyerId, 'b1');
      expect(e.currency, 'KES');
      expect(e.props, contains('b1'));
    });

    test('PaymentInitiateRequested default currency', () {
      const e = PaymentInitiateRequested(
        buyerId: 'b', farmerId: 'f', listingId: 'l',
        amount: 50, paymentMethod: PaymentMethod.mtnMobileMoney,
      );
      expect(e.currency, 'USD');
    });

    test('PaymentProcessRequested props', () {
      const e = PaymentProcessRequested('tx1');
      expect(e.transactionId, 'tx1');
      expect(e.props, contains('tx1'));
    });

    test('PaymentDeliveryConfirmed props', () {
      const e = PaymentDeliveryConfirmed('tx2');
      expect(e.transactionId, 'tx2');
    });

    test('PaymentReceiptConfirmed props', () {
      const e = PaymentReceiptConfirmed('tx3');
      expect(e.transactionId, 'tx3');
    });

    test('PaymentDisputeRaised props', () {
      const e = PaymentDisputeRaised(transactionId: 'tx4', reason: 'Bad');
      expect(e.reason, 'Bad');
      expect(e.props, contains('Bad'));
    });

    test('PaymentCancelRequested props', () {
      const e = PaymentCancelRequested('tx5');
      expect(e.props, contains('tx5'));
    });

    test('PaymentTransactionsSubscribed props', () {
      const e = PaymentTransactionsSubscribed('u1');
      expect(e.props, contains('u1'));
    });

    test('PaymentStatisticsRequested props', () {
      const e = PaymentStatisticsRequested('u2');
      expect(e.props, contains('u2'));
    });

    test('PaymentTransactionLoadRequested props', () {
      const e = PaymentTransactionLoadRequested('tx6');
      expect(e.props, contains('tx6'));
    });

    test('PaymentHistoryRequested props', () {
      const e = PaymentHistoryRequested('u3');
      expect(e.props, contains('u3'));
    });
  });

  // ── PaymentState ────────────────────────────────────────────────────────────
  group('PaymentState', () {
    test('PaymentInitial props empty', () {
      const s = PaymentInitial();
      expect(s.props, isEmpty);
    });

    test('PaymentTransactionCreated props', () {
      final s = PaymentTransactionCreated(_tx());
      expect(s.transaction.id, 'tx1');
      expect(s.props, isNotEmpty);
    });

    test('PaymentProcessed props', () {
      final s = PaymentProcessed(_tx());
      expect(s.transaction.amount, 100);
    });

    test('PaymentTransactionsLoaded props', () {
      final s = PaymentTransactionsLoaded([_tx()]);
      expect(s.transactions, hasLength(1));
    });

    test('PaymentStatisticsLoaded props', () {
      final s = PaymentStatisticsLoaded({'total': 500.0});
      expect(s.statistics['total'], 500.0);
    });

    test('PaymentActionSuccess props', () {
      final s = PaymentActionSuccess(_tx());
      expect(s.props, isNotEmpty);
    });

    test('PaymentTransactionLoaded props', () {
      final s = PaymentTransactionLoaded(_tx());
      expect(s.transaction.id, 'tx1');
    });

    test('PaymentHistoryLoaded copyWith', () {
      final s = PaymentHistoryLoaded(transactions: [_tx()], statistics: {'a': 1});
      final s2 = s.copyWith(statistics: {'b': 2});
      expect(s2.transactions, hasLength(1));
      expect(s2.statistics?['b'], 2);
    });

    test('PaymentHistoryLoaded props', () {
      final s = PaymentHistoryLoaded(transactions: [_tx()]);
      expect(s.statistics, isNull);
      expect(s.props, isNotEmpty);
    });
  });

  // ── AuthEvent ───────────────────────────────────────────────────────────────
  group('AuthEvent', () {
    test('AuthCheckRequested props empty', () {
      const e = AuthCheckRequested();
      expect(e.props, isEmpty);
    });

    test('AuthSignInRequested props', () {
      const e = AuthSignInRequested(email: 'a@b.com', password: 'pw');
      expect(e.email, 'a@b.com');
      expect(e.props, contains('pw'));
    });

    test('AuthRegisterRequested props', () {
      const e = AuthRegisterRequested(
        email: 'a@b.com', password: 'pw',
        displayName: 'Alice', role: UserRole.farmer,
      );
      expect(e.displayName, 'Alice');
      expect(e.props, hasLength(4));
    });

    test('AuthGoogleSignInRequested props empty', () {
      const e = AuthGoogleSignInRequested();
      expect(e.props, isEmpty);
    });

    test('AuthVerificationEmailRequested props empty', () {
      const e = AuthVerificationEmailRequested();
      expect(e.props, isEmpty);
    });

    test('AuthSignOutRequested props empty', () {
      const e = AuthSignOutRequested();
      expect(e.props, isEmpty);
    });

    test('AuthPasswordResetRequested props', () {
      const e = AuthPasswordResetRequested('user@test.com');
      expect(e.email, 'user@test.com');
      expect(e.props, contains('user@test.com'));
    });
  });

  // ── MessagingEvent ──────────────────────────────────────────────────────────
  group('MessagingEvent', () {
    test('ConversationsLoadRequested props empty', () {
      const e = ConversationsLoadRequested();
      expect(e.props, isEmpty);
    });

    test('MessagesLoadRequested props', () {
      const e = MessagesLoadRequested('conv1');
      expect(e.conversationId, 'conv1');
      expect(e.props, contains('conv1'));
    });

    test('MessageSendRequested props', () {
      const e = MessageSendRequested(
        conversationId: 'c1', receiverId: 'u2', content: 'Hi',
      );
      expect(e.content, 'Hi');
      expect(e.messageType, MessageType.text);
      expect(e.listingId, isNull);
    });

    test('MessageSendRequested with listing', () {
      const e = MessageSendRequested(
        conversationId: 'c1', receiverId: 'u2', content: 'Hi',
        listingId: 'l1', messageType: MessageType.listingReference,
      );
      expect(e.listingId, 'l1');
      expect(e.props, contains('l1'));
    });

    test('StartConversationRequested props', () {
      const e = StartConversationRequested('u3');
      expect(e.otherUserId, 'u3');
    });

    test('MessagesMarkReadRequested props', () {
      const e = MessagesMarkReadRequested('conv2');
      expect(e.props, contains('conv2'));
    });
  });

  // ── NotificationEvent ───────────────────────────────────────────────────────
  group('NotificationEvent', () {
    test('NotificationPermissionRequested props empty', () {
      const e = NotificationPermissionRequested();
      expect(e.props, isEmpty);
    });

    test('NotificationReceived props', () {
      const e = NotificationReceived({'type': 'message'});
      expect(e.payload['type'], 'message');
      expect(e.props, isNotEmpty);
    });

    test('NotificationPreferencesLoadRequested props empty', () {
      const e = NotificationPreferencesLoadRequested();
      expect(e.props, isEmpty);
    });

    test('NotificationPreferencesUpdateRequested props', () {
      const e = NotificationPreferencesUpdateRequested({'messages': true});
      expect(e.preferences['messages'], true);
    });

    test('NotificationsWatchRequested props', () {
      const e = NotificationsWatchRequested('u1');
      expect(e.userId, 'u1');
      expect(e.props, contains('u1'));
    });

    test('NotificationMarkAsReadRequested props', () {
      const e = NotificationMarkAsReadRequested('n1', 'u1');
      expect(e.notificationId, 'n1');
      expect(e.userId, 'u1');
      expect(e.props, hasLength(2));
    });

    test('NotificationMarkAllReadRequested props', () {
      const e = NotificationMarkAllReadRequested('u2');
      expect(e.props, contains('u2'));
    });
  });

  // ── NotificationState ───────────────────────────────────────────────────────
  group('NotificationState', () {
    test('NotificationInitial props empty', () {
      const s = NotificationInitial();
      expect(s.props, isEmpty);
    });

    test('NotificationGranted with token', () {
      const s = NotificationGranted(token: 'tok123');
      expect(s.token, 'tok123');
      expect(s.props, contains('tok123'));
    });

    test('NotificationGranted without token', () {
      const s = NotificationGranted();
      expect(s.token, isNull);
    });

    test('NotificationDenied props empty', () {
      const s = NotificationDenied();
      expect(s.props, isEmpty);
    });

    test('NotificationArrived props', () {
      const s = NotificationArrived({'key': 'val'});
      expect(s.payload['key'], 'val');
    });

    test('NotificationPreferencesLoaded props', () {
      const s = NotificationPreferencesLoaded({'msgs': false});
      expect(s.preferences['msgs'], false);
    });

    test('NotificationsLoaded props', () {
      final s = NotificationsLoaded(notifications: [_notif()], unreadCount: 1);
      expect(s.unreadCount, 1);
      expect(s.notifications, hasLength(1));
      expect(s.props, hasLength(2));
    });

    test('NotificationFailure props', () {
      const s = NotificationFailure('oops');
      expect(s.message, 'oops');
      expect(s.props, contains('oops'));
    });
  });

  // ── ListingEvent ────────────────────────────────────────────────────────────
  group('ListingEvent', () {
    test('ActiveListingsLoadRequested props empty', () {
      const e = ActiveListingsLoadRequested();
      expect(e.props, isEmpty);
    });

    test('FarmerListingsLoadRequested props', () {
      const e = FarmerListingsLoadRequested('f1');
      expect(e.farmerId, 'f1');
      expect(e.props, contains('f1'));
    });

    test('ListingDetailLoadRequested props', () {
      const e = ListingDetailLoadRequested('l1');
      expect(e.listingId, 'l1');
    });

    test('ListingCreateRequested props', () {
      final e = ListingCreateRequested(listing: _listing());
      expect(e.listing.variety, 'Bourbon');
      expect(e.images, isNull);
    });

    test('ListingCreateRequested with images', () {
      final e = ListingCreateRequested(listing: _listing(), images: [File('/tmp/a.jpg')]);
      expect(e.images, hasLength(1));
    });

    test('ListingUpdateRequested props', () {
      final e = ListingUpdateRequested(listing: _listing());
      expect(e.listing.listingId, 'l1');
      expect(e.newImages, isNull);
    });

    test('ListingDeleteRequested props', () {
      const e = ListingDeleteRequested('l2');
      expect(e.listingId, 'l2');
      expect(e.props, contains('l2'));
    });

    test('ListingsSearchRequested props', () {
      final e = ListingsSearchRequested(SearchFilters(query: 'Arabica'));
      expect(e.filters.query, 'Arabica');
      expect(e.props, isNotEmpty);
    });
  });

  // ── ListingState ────────────────────────────────────────────────────────────
  group('ListingState', () {
    test('ListingInitial props empty', () {
      const s = ListingInitial();
      expect(s.props, isEmpty);
    });

    test('ListingLoading props empty', () {
      const s = ListingLoading();
      expect(s.props, isEmpty);
    });

    test('ActiveListingsLoaded props', () {
      final s = ActiveListingsLoaded([_listing()]);
      expect(s.listings, hasLength(1));
      expect(s.props, isNotEmpty);
    });

    test('FarmerListingsLoaded props', () {
      final s = FarmerListingsLoaded([_listing(), _listing()]);
      expect(s.listings, hasLength(2));
    });

    test('ListingDetailLoaded props', () {
      final s = ListingDetailLoaded(_listing());
      expect(s.listing.variety, 'Bourbon');
    });

    test('ListingDetailFailure props', () {
      const s = ListingDetailFailure('oops');
      expect(s.message, 'oops');
    });

    test('ListingActionSuccess props', () {
      const s = ListingActionSuccess('Created!');
      expect(s.message, 'Created!');
      expect(s.props, contains('Created!'));
    });

    test('ListingFailure props', () {
      const s = ListingFailure('Network error');
      expect(s.message, 'Network error');
    });
  });
}
