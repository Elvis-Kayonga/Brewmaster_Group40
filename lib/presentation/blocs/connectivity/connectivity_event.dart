// Feature: brewmaster-offline-sync
// ConnectivityBloc events.
//
// Requirements: 22.3
// Developer: Developer 3 (Ryan)

part of 'connectivity_bloc.dart';

abstract class ConnectivityEvent extends Equatable {
  const ConnectivityEvent();

  @override
  List<Object?> get props => [];
}

/// Public event — request the current connectivity status.
class ConnectivityCheckRequested extends ConnectivityEvent {
  const ConnectivityCheckRequested();
}

/// Internal event — emitted when the connectivity stream changes.
class _ConnectivityStatusChanged extends ConnectivityEvent {
  final bool isOnline;

  const _ConnectivityStatusChanged(this.isOnline);

  @override
  List<Object?> get props => [isOnline];
}
