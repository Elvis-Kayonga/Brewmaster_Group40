

part of 'voice_bloc.dart';

abstract class VoiceAssistantState extends Equatable {
  const VoiceAssistantState();

  @override
  List<Object?> get props => [];
}


class VoiceAssistantIdle extends VoiceAssistantState {
  const VoiceAssistantIdle();
}


class VoiceAssistantActive extends VoiceAssistantState {
  final bool isListening;
  final String transcript;
  final String response;

  const VoiceAssistantActive({
    required this.isListening,
    required this.transcript,
    required this.response,
  });

  VoiceAssistantActive copyWith({
    bool? isListening,
    String? transcript,
    String? response,
  }) {
    return VoiceAssistantActive(
      isListening: isListening ?? this.isListening,
      transcript: transcript ?? this.transcript,
      response: response ?? this.response,
    );
  }

  @override
  List<Object?> get props => [isListening, transcript, response];
}


class VoiceAssistantError extends VoiceAssistantState {
  final String message;
  const VoiceAssistantError({required this.message});

  @override
  List<Object?> get props => [message];
}
