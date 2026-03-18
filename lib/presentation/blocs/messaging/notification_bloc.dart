import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/models/notification.dart';
import '../../../domain/repositories/notification_repository.dart';

part 'notification_event.dart';
part 'notification_state.dart';

/// BLoC for push notification permission and preferences.
///
/// Events: [NotificationPermissionRequested], [NotificationReceived],
///         [NotificationPreferencesUpdateRequested], [NotificationPreferencesLoadRequested]
/// Requirements: 5.4, 12.1, 12.2, 12.3, 12.6, 12.7
/// Developer: Developer 3
class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final NotificationRepository _repository;
  StreamSubscription<Map<String, dynamic>>? _notificationSub;
  StreamSubscription<List<AppNotification>>? _firestoreSub;

  NotificationBloc({required NotificationRepository repository})
      : _repository = repository,
        super(const NotificationInitial()) {
    on<NotificationPermissionRequested>(_onRequestPermission);
    on<NotificationReceived>(_onReceived);
    on<NotificationPreferencesLoadRequested>(_onLoadPreferences);
    on<NotificationPreferencesUpdateRequested>(_onUpdatePreferences);
    on<NotificationsWatchRequested>(_onWatchNotifications);
    on<_NotificationsUpdated>(_onNotificationsUpdated);
    on<NotificationMarkAsReadRequested>(_onMarkAsRead);
    on<NotificationMarkAllReadRequested>(_onMarkAllRead);
  }

  Future<void> _onRequestPermission(
    NotificationPermissionRequested event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      final granted = await _repository.requestPermission();
      final token = await _repository.getToken();

      if (granted) {
        emit(NotificationGranted(token: token));
        // Start listening to foreground notifications
        await _notificationSub?.cancel();
        _notificationSub = _repository.watchNotifications().listen(
          (payload) => add(NotificationReceived(payload)),
        );
      } else {
        emit(const NotificationDenied());
      }
    } catch (e) {
      emit(NotificationFailure(e.toString()));
    }
  }

  void _onReceived(
    NotificationReceived event,
    Emitter<NotificationState> emit,
  ) {
    emit(NotificationArrived(event.payload));
  }

  Future<void> _onLoadPreferences(
    NotificationPreferencesLoadRequested event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      final prefs = await _repository.getPreferences();
      emit(NotificationPreferencesLoaded(prefs));
    } catch (e) {
      emit(NotificationFailure(e.toString()));
    }
  }

  Future<void> _onUpdatePreferences(
    NotificationPreferencesUpdateRequested event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      await _repository.updatePreferences(event.preferences);
      emit(NotificationPreferencesLoaded(event.preferences));
    } catch (e) {
      emit(NotificationFailure(e.toString()));
    }
  }

  Future<void> _onWatchNotifications(
    NotificationsWatchRequested event,
    Emitter<NotificationState> emit,
  ) async {
    await _firestoreSub?.cancel();
    _firestoreSub = _repository.watchUserNotifications(event.userId).listen(
      (notifications) => add(_NotificationsUpdated(notifications)),
      onError: (_) {},
    );
  }

  void _onNotificationsUpdated(
    _NotificationsUpdated event,
    Emitter<NotificationState> emit,
  ) {
    final unread = event.notifications.where((n) => !n.isRead).length;
    emit(NotificationsLoaded(
      notifications: event.notifications,
      unreadCount: unread,
    ));
  }

  Future<void> _onMarkAsRead(
    NotificationMarkAsReadRequested event,
    Emitter<NotificationState> emit,
  ) async {
    await _repository.markAsRead(event.notificationId, event.userId);
  }

  Future<void> _onMarkAllRead(
    NotificationMarkAllReadRequested event,
    Emitter<NotificationState> emit,
  ) async {
    await _repository.markAllAsRead(event.userId);
  }

  @override
  Future<void> close() {
    _notificationSub?.cancel();
    _firestoreSub?.cancel();
    return super.close();
  }
}
