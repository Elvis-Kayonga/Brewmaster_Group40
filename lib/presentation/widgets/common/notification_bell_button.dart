import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../config/theme.dart';
import '../../blocs/messaging/notification_bloc.dart';
import '../../screens/notifications/notifications_screen.dart';

/// Bell icon button with an unread-count badge.
/// Drop it into any AppBar actions list.
class NotificationBellButton extends StatelessWidget {
  const NotificationBellButton({super.key});

  Widget _buildBellIcon(int unread) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Icon(Icons.notifications_outlined,
            color: AppTheme.primaryDark, size: 24),
        if (unread > 0)
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                unread > 99 ? '99+' : unread.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final notificationBloc = context.read<NotificationBloc?>();
    if (notificationBloc == null) {
      return IconButton(
        icon: _buildBellIcon(0),
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const NotificationsScreen(),
          ),
        ),
      );
    }

    return BlocBuilder<NotificationBloc, NotificationState>(
      builder: (context, state) {
        final unread =
            state is NotificationsLoaded ? state.unreadCount : 0;

        return IconButton(
          icon: _buildBellIcon(unread),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const NotificationsScreen(),
            ),
          ),
        );
      },
    );
  }
}
