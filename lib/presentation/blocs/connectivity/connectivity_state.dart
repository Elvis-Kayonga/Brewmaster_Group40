// Feature: brewmaster-offline-sync
// ConnectivityBloc states.
//
// Requirements: 22.3
// Developer: Developer 3 (Ryan)

part of 'connectivity_bloc.dart';

abstract class ConnectivityState extends Equatable {
  const ConnectivityState();

  @override
  List<Object?> get props => [];
}

class ConnectivityInitial extends ConnectivityState {
  const ConnectivityInitial();
}

class ConnectivityOnline extends ConnectivityState {
  const ConnectivityOnline();
}

class ConnectivityOffline extends ConnectivityState {
  const ConnectivityOffline();
}

class ConnectivityUnknown extends ConnectivityState {
  const ConnectivityUnknown();
}
