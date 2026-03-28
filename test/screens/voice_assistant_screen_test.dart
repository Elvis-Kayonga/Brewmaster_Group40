// Widget tests for VoiceAssistantScreen
// Coverage: idle state UI, active state after session start, session end.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:brewmaster/config/localization/app_localizations.dart';
import 'package:brewmaster/presentation/blocs/voice/voice_bloc.dart';
import 'package:brewmaster/presentation/screens/voice/voice_assistant_screen.dart';

// ── Helper ─────────────────────────────────────────────────────────────────

Widget _wrap() => MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const VoiceAssistantScreen(),
    );

// ── Tests ──────────────────────────────────────────────────────────────────

void main() {
  group('VoiceAssistantScreen — idle state', () {
    testWidgets('shows "Brew Master" app bar title', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      expect(find.text('Brew Master'), findsOneWidget);
    });

    testWidgets('shows mic icon in idle state', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      expect(find.byIcon(Icons.mic_none_rounded), findsOneWidget);
    });

    testWidgets('shows "Chief Curator" title in idle state', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      expect(find.text('Chief Curator'), findsOneWidget);
    });

    testWidgets('shows "INITIALIZE SESSION" button in idle state',
        (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      expect(find.text('INITIALIZE SESSION'), findsOneWidget);
    });

    testWidgets('shows greeting description text', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      expect(find.textContaining('brewing chemistry'), findsOneWidget);
    });

    testWidgets('shows chevron back icon in app bar', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      expect(find.byIcon(Icons.chevron_left), findsOneWidget);
    });

    testWidgets('shows person icon in app bar', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      expect(find.byIcon(Icons.person), findsOneWidget);
    });
  });

  group('VoiceAssistantScreen — active state (after session start)', () {
    testWidgets('tapping INITIALIZE SESSION shows active state',
        (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      await tester.tap(find.text('INITIALIZE SESSION'));
      await tester.pump();
      expect(find.text('Chief Curator — Active'), findsOneWidget);
    });

    testWidgets('active state shows END SESSION button', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();
      await tester.tap(find.text('INITIALIZE SESSION'));
      await tester.pump();
      expect(find.text('END SESSION'), findsOneWidget);
    });

    testWidgets('END SESSION returns to idle state', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      await tester.tap(find.text('INITIALIZE SESSION'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('END SESSION'), warnIfMissed: false);
      await tester.pump();
      expect(find.text('INITIALIZE SESSION'), findsOneWidget);
    });
  });

  group('VoiceAssistantScreen — error state', () {
    testWidgets('shows error message on VoiceErrorOccurred', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();

      // Dispatch error via the bloc (accessed from within the screen's subtree)
      final bloc = tester.element(find.byType(Scaffold))
          .read<VoiceAssistantBloc>();
      bloc.add(const VoiceErrorOccurred('Connection failed'));
      await tester.pump();

      expect(find.text('Connection failed'), findsOneWidget);
    });

    testWidgets('shows error_outline icon on VoiceErrorOccurred', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();

      final bloc = tester.element(find.byType(Scaffold))
          .read<VoiceAssistantBloc>();
      bloc.add(const VoiceErrorOccurred('Network error'));
      await tester.pump();

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('shows Retry button on error state', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();

      final bloc = tester.element(find.byType(Scaffold))
          .read<VoiceAssistantBloc>();
      bloc.add(const VoiceErrorOccurred('Oops'));
      await tester.pump();

      expect(find.byKey(const Key('retry_button')), findsOneWidget);
    });

    testWidgets('tapping Retry in error state returns to active state',
        (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();

      final bloc = tester.element(find.byType(Scaffold))
          .read<VoiceAssistantBloc>();
      bloc.add(const VoiceErrorOccurred('Oops'));
      await tester.pump();

      await tester.tap(find.byKey(const Key('retry_button')));
      await tester.pump();

      expect(find.text('Chief Curator — Active'), findsOneWidget);
    });
  });

  group('VoiceAssistantScreen — active state with transcript/response', () {
    testWidgets('shows transcript bubble when transcript is non-empty',
        (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();

      // Start session first
      final bloc = tester.element(find.byType(Scaffold))
          .read<VoiceAssistantBloc>();
      bloc.add(const VoiceSessionStartRequested());
      await tester.pump();

      bloc.add(const VoiceTranscriptReceived('Hello Chief Curator'));
      await tester.pump();

      expect(find.text('Hello Chief Curator'), findsOneWidget);
    });

    testWidgets('shows response bubble when response is non-empty',
        (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();

      final bloc = tester.element(find.byType(Scaffold))
          .read<VoiceAssistantBloc>();
      bloc.add(const VoiceSessionStartRequested());
      await tester.pump();

      bloc.add(const VoiceResponseReceived('Here is the brew guide.'));
      await tester.pump();

      expect(find.text('Here is the brew guide.'), findsOneWidget);
    });

    testWidgets('shows "Listening..." when isListening is true', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();

      final bloc = tester.element(find.byType(Scaffold))
          .read<VoiceAssistantBloc>();
      bloc.add(const VoiceSessionStartRequested());
      await tester.pump();

      bloc.add(const VoiceListenToggled());
      await tester.pump();

      expect(find.text('Listening...'), findsOneWidget);
    });
  });
}
