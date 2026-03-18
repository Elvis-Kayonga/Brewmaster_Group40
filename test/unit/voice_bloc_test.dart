// test/unit/voice_bloc_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:brewmaster/presentation/blocs/voice/voice_bloc.dart';

void main() {
  group('VoiceAssistantBloc — initial state', () {
    test('starts in VoiceAssistantIdle', () {
      final bloc = VoiceAssistantBloc();
      expect(bloc.state, isA<VoiceAssistantIdle>());
      bloc.close();
    });
  });

  group('VoiceAssistantBloc — VoiceSessionStartRequested', () {
    test('idle → active with empty transcript and response', () async {
      final bloc = VoiceAssistantBloc();

      bloc.add(const VoiceSessionStartRequested());
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state, isA<VoiceAssistantActive>());
      final active = bloc.state as VoiceAssistantActive;
      expect(active.isListening, isFalse);
      expect(active.transcript, isEmpty);
      expect(active.response, isEmpty);
      bloc.close();
    });
  });

  group('VoiceAssistantBloc — VoiceListenToggled', () {
    test('toggles isListening from false to true', () async {
      final bloc = VoiceAssistantBloc();
      bloc.add(const VoiceSessionStartRequested());
      await Future<void>.delayed(Duration.zero);

      bloc.add(const VoiceListenToggled());
      await Future<void>.delayed(Duration.zero);

      final active = bloc.state as VoiceAssistantActive;
      expect(active.isListening, isTrue);
      bloc.close();
    });

    test('toggles isListening from true back to false', () async {
      final bloc = VoiceAssistantBloc();
      bloc.add(const VoiceSessionStartRequested());
      await Future<void>.delayed(Duration.zero);

      bloc.add(const VoiceListenToggled()); // → true
      await Future<void>.delayed(Duration.zero);
      bloc.add(const VoiceListenToggled()); // → false
      await Future<void>.delayed(Duration.zero);

      final active = bloc.state as VoiceAssistantActive;
      expect(active.isListening, isFalse);
      bloc.close();
    });

    test('does nothing when state is not active', () async {
      final bloc = VoiceAssistantBloc();
      // still idle
      bloc.add(const VoiceListenToggled());
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state, isA<VoiceAssistantIdle>());
      bloc.close();
    });
  });

  group('VoiceAssistantBloc — VoiceTranscriptReceived', () {
    test('stores transcript and stops listening', () async {
      final bloc = VoiceAssistantBloc();
      bloc.add(const VoiceSessionStartRequested());
      await Future<void>.delayed(Duration.zero);
      bloc.add(const VoiceListenToggled()); // start listening
      await Future<void>.delayed(Duration.zero);

      bloc.add(const VoiceTranscriptReceived('What is the best altitude?'));
      await Future<void>.delayed(Duration.zero);

      final active = bloc.state as VoiceAssistantActive;
      expect(active.transcript, 'What is the best altitude?');
      expect(active.isListening, isFalse);
      bloc.close();
    });

    test('does nothing when state is not active', () async {
      final bloc = VoiceAssistantBloc();
      bloc.add(const VoiceTranscriptReceived('hello'));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state, isA<VoiceAssistantIdle>());
      bloc.close();
    });
  });

  group('VoiceAssistantBloc — VoiceResponseReceived', () {
    test('stores AI response without clearing transcript', () async {
      final bloc = VoiceAssistantBloc();
      bloc.add(const VoiceSessionStartRequested());
      await Future<void>.delayed(Duration.zero);
      bloc.add(const VoiceTranscriptReceived('Tell me about washed process'));
      await Future<void>.delayed(Duration.zero);

      bloc.add(const VoiceResponseReceived('Washed process removes the fruit...'));
      await Future<void>.delayed(Duration.zero);

      final active = bloc.state as VoiceAssistantActive;
      expect(active.response, 'Washed process removes the fruit...');
      expect(active.transcript, 'Tell me about washed process');
      bloc.close();
    });

    test('does nothing when state is not active', () async {
      final bloc = VoiceAssistantBloc();
      bloc.add(const VoiceResponseReceived('some response'));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state, isA<VoiceAssistantIdle>());
      bloc.close();
    });
  });

  group('VoiceAssistantBloc — VoiceSessionEnded', () {
    test('active → idle', () async {
      final bloc = VoiceAssistantBloc();
      bloc.add(const VoiceSessionStartRequested());
      await Future<void>.delayed(Duration.zero);

      bloc.add(const VoiceSessionEnded());
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state, isA<VoiceAssistantIdle>());
      bloc.close();
    });
  });

  group('VoiceAssistantBloc — VoiceErrorOccurred', () {
    test('emits VoiceAssistantError with message', () async {
      final bloc = VoiceAssistantBloc();
      bloc.add(const VoiceErrorOccurred('Microphone unavailable'));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state, isA<VoiceAssistantError>());
      final error = bloc.state as VoiceAssistantError;
      expect(error.message, 'Microphone unavailable');
      bloc.close();
    });
  });

  group('VoiceAssistantState — equality', () {
    test('two VoiceAssistantIdle instances are equal', () {
      expect(const VoiceAssistantIdle(), equals(const VoiceAssistantIdle()));
    });

    test('VoiceAssistantActive equality based on props', () {
      const a = VoiceAssistantActive(
        isListening: false,
        transcript: 'hello',
        response: 'world',
      );
      const b = VoiceAssistantActive(
        isListening: false,
        transcript: 'hello',
        response: 'world',
      );
      expect(a, equals(b));
    });

    test('VoiceAssistantActive copyWith only changes specified field', () {
      const original = VoiceAssistantActive(
        isListening: false,
        transcript: 'abc',
        response: '',
      );
      final updated = original.copyWith(isListening: true);

      expect(updated.isListening, isTrue);
      expect(updated.transcript, 'abc');
      expect(updated.response, '');
    });

    test('VoiceAssistantError equality based on message', () {
      expect(
        const VoiceAssistantError(message: 'err'),
        equals(const VoiceAssistantError(message: 'err')),
      );
    });
  });

  group('VoiceAssistantBloc — full session flow', () {
    test('idle → active → transcript → response → idle', () async {
      final bloc = VoiceAssistantBloc();

      expect(bloc.state, isA<VoiceAssistantIdle>());

      bloc.add(const VoiceSessionStartRequested());
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state, isA<VoiceAssistantActive>());

      bloc.add(const VoiceTranscriptReceived('Best brewing temp?'));
      await Future<void>.delayed(Duration.zero);
      expect((bloc.state as VoiceAssistantActive).transcript,
          'Best brewing temp?');

      bloc.add(const VoiceResponseReceived('93°C is optimal.'));
      await Future<void>.delayed(Duration.zero);
      expect((bloc.state as VoiceAssistantActive).response, '93°C is optimal.');

      bloc.add(const VoiceSessionEnded());
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state, isA<VoiceAssistantIdle>());

      bloc.close();
    });
  });
}
