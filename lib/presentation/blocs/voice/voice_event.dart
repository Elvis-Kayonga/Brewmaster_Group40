

part of 'voice_bloc.dart';

abstract class VoiceEvent extends Equatable {
  const VoiceEvent();

  @override
  List<Object?> get props => [];
}


class VoiceSessionStartRequested extends VoiceEvent {
  const VoiceSessionStartRequested();
}


class VoiceListenToggled extends VoiceEvent {
  const VoiceListenToggled();
}


class VoiceTranscriptReceived extends VoiceEvent {
  final String transcript;
  const VoiceTranscriptReceived(this.transcript);

  @override
  List<Object?> get props => [transcript];
}

class VoiceResponseReceived extends VoiceEvent {
  final String response;
  const VoiceResponseReceived(this.response);

  @override
  List<Object?> get props => [response];
}


class VoiceSessionEnded extends VoiceEvent {
  const VoiceSessionEnded();
}


class VoiceErrorOccurred extends VoiceEvent {
  final String message;
  const VoiceErrorOccurred(this.message);

  @override
  List<Object?> get props => [message];
}
