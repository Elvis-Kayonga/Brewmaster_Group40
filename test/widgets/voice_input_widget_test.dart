import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brewmaster/presentation/widgets/common/voice_input_widget.dart';
import 'package:brewmaster/config/localization/app_localizations.dart';

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: const [AppLocalizations.delegate],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

/// A fake speech service that is always available and controllable.
class _FakeSpeechService implements SpeechService {
  bool _listening = false;
  bool _available = true;
  void Function(String text)? _onResult;

  void setAvailable(bool v) => _available = v;

  void simulateResult(String text) => _onResult?.call(text);

  @override
  bool get isAvailable => _available;

  @override
  bool get isListening => _listening;

  @override
  Future<bool> initialize() async => _available;

  @override
  Future<void> startListening({required void Function(String text) onResult}) async {
    _listening = true;
    _onResult = onResult;
  }

  @override
  Future<void> stopListening() async {
    _listening = false;
  }
}

void main() {
  group('VoiceInputWidget - unavailable service', () {
    testWidgets('renders mic_none icon when unavailable', (tester) async {
      final service = _FakeSpeechService()..setAvailable(false);
      await tester.pumpWidget(_wrap(VoiceInputWidget(
        onResult: (_) {},
        speechService: service,
      )));
      await tester.pump();
      expect(find.byIcon(Icons.mic_none), findsOneWidget);
    });

    testWidgets('does not call onResult when unavailable', (tester) async {
      final service = _FakeSpeechService()..setAvailable(false);
      String? result;
      await tester.pumpWidget(_wrap(VoiceInputWidget(
        onResult: (t) => result = t,
        speechService: service,
      )));
      await tester.pump();
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pump();
      expect(result, isNull);
    });
  });

  group('VoiceInputWidget - available service', () {
    testWidgets('renders mic_none icon when idle', (tester) async {
      final service = _FakeSpeechService();
      await tester.pumpWidget(_wrap(VoiceInputWidget(
        onResult: (_) {},
        speechService: service,
      )));
      await tester.pump();
      expect(find.byIcon(Icons.mic_none), findsOneWidget);
    });

    testWidgets('renders with custom size', (tester) async {
      final service = _FakeSpeechService();
      await tester.pumpWidget(_wrap(VoiceInputWidget(
        onResult: (_) {},
        speechService: service,
        size: 80.0,
      )));
      await tester.pump();
      expect(find.byType(VoiceInputWidget), findsOneWidget);
    });

    testWidgets('switches to mic icon when tapped (listening)', (tester) async {
      final service = _FakeSpeechService();
      await tester.pumpWidget(_wrap(VoiceInputWidget(
        onResult: (_) {},
        speechService: service,
      )));
      await tester.pump();
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pump();
      expect(find.byIcon(Icons.mic), findsOneWidget);
    });

    testWidgets('returns to idle when tapped again', (tester) async {
      final service = _FakeSpeechService();
      await tester.pumpWidget(_wrap(VoiceInputWidget(
        onResult: (_) {},
        speechService: service,
      )));
      await tester.pump();
      // Start listening
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pump();
      // Stop listening
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pump();
      expect(find.byIcon(Icons.mic_none), findsOneWidget);
    });

    testWidgets('calls onResult when service emits result', (tester) async {
      final service = _FakeSpeechService();
      String? captured;
      await tester.pumpWidget(_wrap(VoiceInputWidget(
        onResult: (t) => captured = t,
        speechService: service,
      )));
      await tester.pump();
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pump();
      service.simulateResult('Hello world');
      await tester.pump();
      expect(captured, equals('Hello world'));
    });
  });

  group('NoOpSpeechService', () {
    test('isAvailable is false', () {
      const service = NoOpSpeechService();
      expect(service.isAvailable, isFalse);
    });

    test('isListening is false', () {
      const service = NoOpSpeechService();
      expect(service.isListening, isFalse);
    });

    test('initialize returns false', () async {
      const service = NoOpSpeechService();
      final result = await service.initialize();
      expect(result, isFalse);
    });

    test('startListening completes without error', () async {
      const service = NoOpSpeechService();
      await service.startListening(onResult: (_) {});
    });

    test('stopListening completes without error', () async {
      const service = NoOpSpeechService();
      await service.stopListening();
    });
  });
}
