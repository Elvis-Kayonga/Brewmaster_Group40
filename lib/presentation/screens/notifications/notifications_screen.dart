import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../config/theme.dart';
import '../../../domain/models/notification.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/messaging/notification_bloc.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/loading_indicator.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String? _userId;

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      _userId = authState.profile.id;
    }
  }

  void _markAllRead() {
    if (_userId != null) {
      context
          .read<NotificationBloc>()
          .add(NotificationMarkAllReadRequested(_userId!));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: AppTheme.primaryDark,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          BlocBuilder<NotificationBloc, NotificationState>(
            builder: (context, state) {
              final hasUnread = state is NotificationsLoaded &&
                  state.unreadCount > 0;
              if (!hasUnread) return const SizedBox.shrink();
              return TextButton(
                onPressed: _markAllRead,
                child: const Text(
                  'Mark all read',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<NotificationBloc, NotificationState>(
        builder: (context, state) {
          if (state is NotificationInitial || state is NotificationGranted) {
            return const LoadingIndicator();
          }

          if (state is! NotificationsLoaded) {
            return const EmptyStateWidget(
              icon: Icons.notifications_none,
              title: 'No notifications',
              description: 'You\'re all caught up!',
            );
          }

          if (state.notifications.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.notifications_none,
              title: 'No notifications',
              description: 'You\'re all caught up!',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: state.notifications.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final n = state.notifications[index];
              return _NotificationTile(
                notification: n,
                onTap: () {
                  if (_userId != null && !n.isRead) {
                    context.read<NotificationBloc>().add(
                        NotificationMarkAsReadRequested(n.id, _userId!));
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback onTap;

  IconData _icon() {
    switch (notification.type) {
      case NotificationType.newMessage:
        return Icons.chat_bubble_outline;
      case NotificationType.purchaseInitiated:
        return Icons.shopping_bag_outlined;
      case NotificationType.paymentReceived:
        return Icons.attach_money;
      case NotificationType.deliveryConfirmed:
        return Icons.local_shipping_outlined;
      case NotificationType.verificationUpdated:
        return Icons.verified_outlined;
      case NotificationType.listingInterest:
        return Icons.visibility_outlined;
    }
  }

  Color _iconColor() {
    switch (notification.type) {
      case NotificationType.newMessage:
        return AppTheme.primaryColor;
      case NotificationType.purchaseInitiated:
        return Colors.orange;
      case NotificationType.paymentReceived:
        return const Color(0xFF388E3C);
      case NotificationType.deliveryConfirmed:
        return Colors.teal;
      case NotificationType.verificationUpdated:
        return Colors.blue;
      case NotificationType.listingInterest:
        return AppTheme.primaryDark;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;

    return InkWell(
      onTap: onTap,
      child: Container(
        color: isUnread
            ? AppTheme.primaryColor.withValues(alpha: 0.06)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _iconColor().withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(_icon(), color: _iconColor(), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isUnread
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: AppTheme.primaryDark,
                          ),
                        ),
                      ),
                      if (isUnread)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    notification.body,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(notification.createdAt),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textHint,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(dt);
  }
}
