

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'voice_event.dart';
part 'voice_state.dart';

class VoiceAssistantBloc
    extends Bloc<VoiceEvent, VoiceAssistantState> {
  VoiceAssistantBloc() : super(const VoiceAssistantIdle()) {
    on<VoiceSessionStartRequested>(_onSessionStart);
    on<VoiceListenToggled>(_onListenToggled);
    on<VoiceTranscriptReceived>(_onTranscriptReceived);
    on<VoiceResponseReceived>(_onResponseReceived);
    on<VoiceSessionEnded>(_onSessionEnded);
    on<VoiceErrorOccurred>(_onError);
  }

  void _onSessionStart(
    VoiceSessionStartRequested event,
    Emitter<VoiceAssistantState> emit,
  ) {
    emit(const VoiceAssistantActive(
      isListening: false,
      transcript: '',
      response: '',
    ));
  }

  void _onListenToggled(
    VoiceListenToggled event,
    Emitter<VoiceAssistantState> emit,
  ) {
    if (state is VoiceAssistantActive) {
      final current = state as VoiceAssistantActive;
      emit(current.copyWith(isListening: !current.isListening));
    }
  }

  void _onTranscriptReceived(
    VoiceTranscriptReceived event,
    Emitter<VoiceAssistantState> emit,
  ) {
    if (state is VoiceAssistantActive) {
      final current = state as VoiceAssistantActive;
      emit(current.copyWith(
        isListening: false,
        transcript: event.transcript,
      ));
    }
  }

  void _onResponseReceived(
    VoiceResponseReceived event,
    Emitter<VoiceAssistantState> emit,
  ) {
    if (state is VoiceAssistantActive) {
      final current = state as VoiceAssistantActive;
      emit(current.copyWith(response: event.response));
    }
  }

  void _onSessionEnded(
    VoiceSessionEnded event,
    Emitter<VoiceAssistantState> emit,
  ) {
    emit(const VoiceAssistantIdle());
  }

  void _onError(
    VoiceErrorOccurred event,
    Emitter<VoiceAssistantState> emit,
  ) {
    emit(VoiceAssistantError(message: event.message));
  }
}
