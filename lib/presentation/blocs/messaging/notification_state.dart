part of 'notification_bloc.dart';

abstract class NotificationState extends Equatable {
  const NotificationState();
  @override
  List<Object?> get props => [];
}

class NotificationInitial extends NotificationState {
  const NotificationInitial();
}

class NotificationGranted extends NotificationState {
  final String? token;
  const NotificationGranted({this.token});
  @override
  List<Object?> get props => [token];
}

class NotificationDenied extends NotificationState {
  const NotificationDenied();
}

class NotificationArrived extends NotificationState {
  final Map<String, dynamic> payload;
  const NotificationArrived(this.payload);
  @override
  List<Object?> get props => [payload];
}

class NotificationPreferencesLoaded extends NotificationState {
  final Map<String, bool> preferences;
  const NotificationPreferencesLoaded(this.preferences);
  @override
  List<Object?> get props => [preferences];
}

class NotificationFailure extends NotificationState {
  final String message;
  const NotificationFailure(this.message);
  @override
  List<Object?> get props => [message];
}
