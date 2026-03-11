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
