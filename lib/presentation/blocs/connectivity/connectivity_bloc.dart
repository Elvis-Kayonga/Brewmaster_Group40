// Feature: brewmaster-offline-sync
// BLoC that monitors network connectivity and drives UI state accordingly.
//
// Requirements: 22.3
// Developer: Developer 3 (Ryan)

import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/offline_sync_repository.dart';

part 'connectivity_event.dart';
part 'connectivity_state.dart';

class ConnectivityBloc extends Bloc<ConnectivityEvent, ConnectivityState> {
  final OfflineSyncRepository _repository;
  late final StreamSubscription<bool> _connectivitySub;

  ConnectivityBloc({required OfflineSyncRepository repository})
      : _repository = repository,
        super(const ConnectivityInitial()) {
    on<ConnectivityCheckRequested>(_onCheckRequested);
    on<_ConnectivityStatusChanged>(_onStatusChanged);

    _connectivitySub = _repository.watchConnectivity().listen(
      (isOnline) => add(_ConnectivityStatusChanged(isOnline)),
    );
  }

  Future<void> _onCheckRequested(
    ConnectivityCheckRequested event,
    Emitter<ConnectivityState> emit,
  ) async {
    emit(const ConnectivityUnknown());
  }

  void _onStatusChanged(
    _ConnectivityStatusChanged event,
    Emitter<ConnectivityState> emit,
  ) {
    emit(event.isOnline ? const ConnectivityOnline() : const ConnectivityOffline());
  }

  @override
  Future<void> close() {
    _connectivitySub.cancel();
    return super.close();
  }
}
