// Feature: brewmaster-verification
// BLoC for verification request submission and status monitoring.
//
// Requirements: 7.1, 7.2, 7.3
// Developer: Developer 1

import 'dart:async';
import 'dart:io';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/models/enums.dart';
import '../../../domain/models/verification_request.dart';
import '../../../domain/repositories/verification_repository.dart';

part 'verification_event.dart';
part 'verification_state.dart';

class VerificationBloc extends Bloc<VerificationEvent, VerificationState> {
  final VerificationRepository _repository;
  StreamSubscription<VerificationStatus>? _statusSub;
  String? _watchedUserId;

  VerificationBloc({required VerificationRepository repository})
      : _repository = repository,
        super(const VerificationInitial()) {
    on<VerificationStatusLoadRequested>(_onStatusLoadRequested);
    on<VerificationDocumentSubmitted>(_onDocumentSubmitted);
    on<_VerificationStatusChanged>(_onStatusChanged);
  }

  Future<void> _onStatusLoadRequested(
    VerificationStatusLoadRequested event,
    Emitter<VerificationState> emit,
  ) async {
    emit(const VerificationLoading());
    try {
      _watchedUserId = event.userId;
      final request = await _repository.getVerificationStatus(event.userId);
      final status = request?.state ?? VerificationStatus.unverified;
      emit(VerificationStatusLoaded(status: status, request: request));

      // Start watching real-time status updates
      await _statusSub?.cancel();
      _statusSub = _repository.watchVerificationStatus(event.userId).listen(
        (s) => add(_VerificationStatusChanged(s)),
      );
    } catch (e) {
      emit(VerificationFailure(e.toString()));
    }
  }

  Future<void> _onDocumentSubmitted(
    VerificationDocumentSubmitted event,
    Emitter<VerificationState> emit,
  ) async {
    emit(const VerificationLoading());
    try {
      await _repository.submitVerificationRequest(
        event.userId,
        event.documents,
      );
      emit(const VerificationSubmitSuccess());
    } catch (e) {
      emit(VerificationFailure(e.toString()));
    }
  }

  Future<void> _onStatusChanged(
    _VerificationStatusChanged event,
    Emitter<VerificationState> emit,
  ) async {
    final currentRequest = state is VerificationStatusLoaded
        ? (state as VerificationStatusLoaded).request
        : null;
    emit(VerificationStatusLoaded(status: event.status, request: currentRequest));

    // Sync the new status onto users/{userId}.verificationStatus so that
    // AuthBloc reads the correct value when it next calls getUserProfile().
    if (_watchedUserId != null) {
      try {
        await _repository.syncStatusToUserProfile(_watchedUserId!, event.status);
      } catch (_) {}
    }
  }

  @override
  Future<void> close() {
    _statusSub?.cancel();
    return super.close();
  }
}
