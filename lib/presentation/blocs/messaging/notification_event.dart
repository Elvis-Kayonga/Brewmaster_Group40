part of 'notification_bloc.dart';

abstract class NotificationEvent extends Equatable {
  const NotificationEvent();
  @override
  List<Object?> get props => [];
}

class NotificationPermissionRequested extends NotificationEvent {
  const NotificationPermissionRequested();
}

class NotificationReceived extends NotificationEvent {
  final Map<String, dynamic> payload;
  const NotificationReceived(this.payload);
  @override
  List<Object?> get props => [payload];
}

class NotificationPreferencesLoadRequested extends NotificationEvent {
  const NotificationPreferencesLoadRequested();
}

class NotificationPreferencesUpdateRequested extends NotificationEvent {
  final Map<String, bool> preferences;
  const NotificationPreferencesUpdateRequested(this.preferences);
  @override
  List<Object?> get props => [preferences];
}

/// Start watching Firestore notifications for [userId].
class NotificationsWatchRequested extends NotificationEvent {
  final String userId;
  const NotificationsWatchRequested(this.userId);
  @override
  List<Object?> get props => [userId];
}

/// Mark a single notification as read.
class NotificationMarkAsReadRequested extends NotificationEvent {
  final String notificationId;
  final String userId;
  const NotificationMarkAsReadRequested(this.notificationId, this.userId);
  @override
  List<Object?> get props => [notificationId, userId];
}

/// Mark all notifications as read.
class NotificationMarkAllReadRequested extends NotificationEvent {
  final String userId;
  const NotificationMarkAllReadRequested(this.userId);
  @override
  List<Object?> get props => [userId];
}

/// Internal: Firestore stream pushed an updated list.
class _NotificationsUpdated extends NotificationEvent {
  final List<AppNotification> notifications;
  const _NotificationsUpdated(this.notifications);
  @override
  List<Object?> get props => [notifications];
}
