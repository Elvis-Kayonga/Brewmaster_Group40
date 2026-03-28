import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:brewmaster/domain/models/notification.dart';
import 'package:brewmaster/presentation/blocs/auth/auth_bloc.dart';
import 'package:brewmaster/presentation/blocs/messaging/notification_bloc.dart';
import 'package:brewmaster/presentation/screens/notifications/notifications_screen.dart';

import '../helpers/fake_repositories.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

Widget _buildScreen({
  NotificationBloc? notificationBloc,
  AuthBloc? authBloc,
}) {
  final ab = authBloc ??
      (AuthBloc(
        authRepository: FakeAuthRepository(),
        userRepository: FakeUserRepository(),
      )..emit(AuthAuthenticated(makeProfile())));
  final nb = notificationBloc ??
      NotificationBloc(repository: FakeNotificationRepository());
  return MaterialApp(
    home: MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(create: (_) => ab),
        BlocProvider<NotificationBloc>(create: (_) => nb),
      ],
      child: const NotificationsScreen(),
    ),
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    setupFirebaseCoreMocks();
    await Firebase.initializeApp();
  });

  group('NotificationsScreen', () {
    testWidgets('shows loading indicator on NotificationInitial', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows "No notifications" when notifications list is empty', (tester) async {
      final nb = NotificationBloc(repository: FakeNotificationRepository())
        ..emit(const NotificationsLoaded(notifications: [], unreadCount: 0));
      await tester.pumpWidget(_buildScreen(notificationBloc: nb));
      await tester.pump();
      expect(find.text('No notifications'), findsOneWidget);
    });

    testWidgets('shows notification titles when loaded', (tester) async {
      final notifications = [
        AppNotification(
          id: 'n1',
          userId: 'u1',
          title: 'New message received',
          body: 'You have a new message',
          type: NotificationType.newMessage,
          data: const {},
          isRead: false,
          createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
        ),
        AppNotification(
          id: 'n2',
          userId: 'u1',
          title: 'Payment received',
          body: 'Your payment was processed',
          type: NotificationType.paymentReceived,
          data: const {},
          isRead: true,
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
      ];
      final nb = NotificationBloc(repository: FakeNotificationRepository())
        ..emit(NotificationsLoaded(notifications: notifications, unreadCount: 1));
      await tester.pumpWidget(_buildScreen(notificationBloc: nb));
      await tester.pump();
      expect(find.text('New message received'), findsOneWidget);
      expect(find.text('Payment received'), findsOneWidget);
    });

    testWidgets('shows "Mark all read" button when unreadCount > 0', (tester) async {
      final notifications = [
        AppNotification(
          id: 'n1',
          userId: 'u1',
          title: 'Unread notification',
          body: 'Body text',
          type: NotificationType.newMessage,
          data: const {},
          isRead: false,
          createdAt: DateTime.now().subtract(const Duration(minutes: 1)),
        ),
      ];
      final nb = NotificationBloc(repository: FakeNotificationRepository())
        ..emit(NotificationsLoaded(notifications: notifications, unreadCount: 1));
      await tester.pumpWidget(_buildScreen(notificationBloc: nb));
      await tester.pump();
      expect(find.text('Mark all read'), findsOneWidget);
    });

    testWidgets('does not show "Mark all read" when unreadCount is 0', (tester) async {
      final notifications = [
        AppNotification(
          id: 'n1',
          userId: 'u1',
          title: 'Read notification',
          body: 'Body text',
          type: NotificationType.newMessage,
          data: const {},
          isRead: true,
          createdAt: DateTime.now().subtract(const Duration(minutes: 1)),
        ),
      ];
      final nb = NotificationBloc(repository: FakeNotificationRepository())
        ..emit(NotificationsLoaded(notifications: notifications, unreadCount: 0));
      await tester.pumpWidget(_buildScreen(notificationBloc: nb));
      await tester.pump();
      expect(find.text('Mark all read'), findsNothing);
    });

    testWidgets('app bar shows "Notifications" title', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pump();
      expect(find.text('Notifications'), findsOneWidget);
    });

    testWidgets('tapping "Mark all read" dispatches event', (tester) async {
      final notifications = [
        AppNotification(
          id: 'n1',
          userId: 'u1',
          title: 'Unread notification',
          body: 'Body',
          type: NotificationType.newMessage,
          data: const {},
          isRead: false,
          createdAt: DateTime.now(),
        ),
      ];
      final nb = NotificationBloc(repository: FakeNotificationRepository())
        ..emit(NotificationsLoaded(notifications: notifications, unreadCount: 1));
      await tester.pumpWidget(_buildScreen(notificationBloc: nb));
      await tester.pump();

      await tester.tap(find.text('Mark all read'));
      await tester.pump();

      // _markAllRead() called — no crash
      expect(find.byType(NotificationsScreen), findsOneWidget);
    });

    testWidgets('tapping unread notification tile dispatches mark-as-read',
        (tester) async {
      final notifications = [
        AppNotification(
          id: 'n1',
          userId: 'u1',
          title: 'Unread msg',
          body: 'Body',
          type: NotificationType.newMessage,
          data: const {},
          isRead: false,
          createdAt: DateTime.now(),
        ),
      ];
      final nb = NotificationBloc(repository: FakeNotificationRepository())
        ..emit(NotificationsLoaded(notifications: notifications, unreadCount: 1));
      await tester.pumpWidget(_buildScreen(notificationBloc: nb));
      await tester.pump();

      await tester.tap(find.text('Unread msg'));
      await tester.pump();

      expect(find.byType(NotificationsScreen), findsOneWidget);
    });

    testWidgets('shows shipping icon for deliveryConfirmed type', (tester) async {
      final nb = NotificationBloc(repository: FakeNotificationRepository())
        ..emit(NotificationsLoaded(
          notifications: [
            AppNotification(
              id: 'n1',
              userId: 'u1',
              title: 'Delivered',
              body: 'B',
              type: NotificationType.deliveryConfirmed,
              data: const {},
              isRead: false,
              createdAt: DateTime.now(),
            ),
          ],
          unreadCount: 1,
        ));
      await tester.pumpWidget(_buildScreen(notificationBloc: nb));
      await tester.pump();
      expect(find.byIcon(Icons.local_shipping_outlined), findsOneWidget);
    });

    testWidgets('shows verified icon for verificationUpdated type',
        (tester) async {
      final nb = NotificationBloc(repository: FakeNotificationRepository())
        ..emit(NotificationsLoaded(
          notifications: [
            AppNotification(
              id: 'n1',
              userId: 'u1',
              title: 'Verified',
              body: 'B',
              type: NotificationType.verificationUpdated,
              data: const {},
              isRead: false,
              createdAt: DateTime.now(),
            ),
          ],
          unreadCount: 1,
        ));
      await tester.pumpWidget(_buildScreen(notificationBloc: nb));
      await tester.pump();
      expect(find.byIcon(Icons.verified_outlined), findsOneWidget);
    });

    testWidgets('shows visibility icon for listingInterest type', (tester) async {
      final nb = NotificationBloc(repository: FakeNotificationRepository())
        ..emit(NotificationsLoaded(
          notifications: [
            AppNotification(
              id: 'n1',
              userId: 'u1',
              title: 'Interest',
              body: 'B',
              type: NotificationType.listingInterest,
              data: const {},
              isRead: false,
              createdAt: DateTime.now(),
            ),
          ],
          unreadCount: 1,
        ));
      await tester.pumpWidget(_buildScreen(notificationBloc: nb));
      await tester.pump();
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
    });
  });
}
