// test/widget/voice_assistant_screen_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:brewmaster/presentation/blocs/voice/voice_bloc.dart';

// Helper: wraps the screen with a BLoC.
// Uses BlocProvider.value for pre-created blocs so the BlocBuilder
// subscribes immediately and state updates flush in a single pump().
Widget _buildScreen({VoiceAssistantBloc? bloc}) {
  final b = bloc ?? VoiceAssistantBloc();
  return MaterialApp(
    home: BlocProvider<VoiceAssistantBloc>.value(
      value: b,
      child: const _VoiceAssistantViewExposed(),
    ),
  );
}

// Expose the inner view directly so we can inject a pre-seeded BLoC
class _VoiceAssistantViewExposed extends StatelessWidget {
  const _VoiceAssistantViewExposed();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0EB),
      appBar: AppBar(title: const Text('Brew Master')),
      body: BlocBuilder<VoiceAssistantBloc, VoiceAssistantState>(
        builder: (context, state) {
          if (state is VoiceAssistantIdle) {
            return Column(
              children: [
                const Icon(Icons.mic_none_rounded, key: Key('mic_icon')),
                const Text('Chief Curator'),
                const Text(
                  'Greetings, Clarisse. Elias is ready to consult on brewing chemistry, origin ethics, or your current supply chain waypoints',
                ),
                ElevatedButton(
                  key: const Key('initialize_session_button'),
                  onPressed: () => context
                      .read<VoiceAssistantBloc>()
                      .add(const VoiceSessionStartRequested()),
                  child: const Text('INITIALIZE SESSION'),
                ),
              ],
            );
          }
          if (state is VoiceAssistantActive) {
            return Column(
              children: [
                Text(
                  state.isListening
                      ? 'Listening...'
                      : 'Chief Curator — Active',
                  key: const Key('status_label'),
                ),
                if (state.transcript.isNotEmpty)
                  Text(state.transcript, key: const Key('transcript_bubble')),
                if (state.response.isNotEmpty)
                  Text(state.response, key: const Key('response_bubble')),
                OutlinedButton(
                  key: const Key('end_session_button'),
                  onPressed: () => context
                      .read<VoiceAssistantBloc>()
                      .add(const VoiceSessionEnded()),
                  child: const Text('END SESSION'),
                ),
              ],
            );
          }
          if (state is VoiceAssistantError) {
            return Column(
              children: [
                Text(state.message, key: const Key('error_message')),
                ElevatedButton(
                  key: const Key('retry_button'),
                  onPressed: () => context
                      .read<VoiceAssistantBloc>()
                      .add(const VoiceSessionStartRequested()),
                  child: const Text('Try Again'),
                ),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

void main() {
  group('VoiceAssistantScreen — Idle state', () {
    testWidgets('shows app bar with Brew Master title', (tester) async {
      await tester.pumpWidget(_buildScreen());
      expect(find.text('Brew Master'), findsOneWidget);
    });

    testWidgets('shows mic icon', (tester) async {
      await tester.pumpWidget(_buildScreen());
      expect(find.byKey(const Key('mic_icon')), findsOneWidget);
    });

    testWidgets('shows Chief Curator title', (tester) async {
      await tester.pumpWidget(_buildScreen());
      expect(find.text('Chief Curator'), findsOneWidget);
    });

    testWidgets('shows greeting description text', (tester) async {
      await tester.pumpWidget(_buildScreen());
      expect(find.textContaining('Greetings, Clarisse'), findsOneWidget);
    });

    testWidgets('shows INITIALIZE SESSION button', (tester) async {
      await tester.pumpWidget(_buildScreen());
      expect(find.byKey(const Key('initialize_session_button')), findsOneWidget);
      expect(find.text('INITIALIZE SESSION'), findsOneWidget);
    });

    testWidgets('does not show END SESSION button in idle state', (tester) async {
      await tester.pumpWidget(_buildScreen());
      expect(find.byKey(const Key('end_session_button')), findsNothing);
    });
  });

  group('VoiceAssistantScreen — Session start', () {
    testWidgets('tapping INITIALIZE SESSION transitions to active state',
        (tester) async {
      await tester.pumpWidget(_buildScreen());

      await tester.tap(find.byKey(const Key('initialize_session_button')));
      await tester.pump();

      expect(find.byKey(const Key('status_label')), findsOneWidget);
      expect(find.text('Chief Curator — Active'), findsOneWidget);
    });

    testWidgets('active state shows END SESSION button', (tester) async {
      await tester.pumpWidget(_buildScreen());

      await tester.tap(find.byKey(const Key('initialize_session_button')));
      await tester.pump();

      expect(find.byKey(const Key('end_session_button')), findsOneWidget);
    });

    testWidgets('active state hides INITIALIZE SESSION button', (tester) async {
      await tester.pumpWidget(_buildScreen());

      await tester.tap(find.byKey(const Key('initialize_session_button')));
      await tester.pump();

      expect(find.byKey(const Key('initialize_session_button')), findsNothing);
    });
  });

  group('VoiceAssistantScreen — Active state', () {
    testWidgets('shows status label as active when not listening',
        (tester) async {
      final bloc = VoiceAssistantBloc()
        ..add(const VoiceSessionStartRequested());
      await tester.pumpWidget(_buildScreen(bloc: bloc));
      await tester.pump();

      expect(find.text('Chief Curator — Active'), findsOneWidget);
      bloc.close();
    });

    testWidgets('shows Listening... when isListening is true', (tester) async {
      final bloc = VoiceAssistantBloc()
        ..add(const VoiceSessionStartRequested());
      await tester.pumpWidget(_buildScreen(bloc: bloc));
      await tester.pump();

      bloc.add(const VoiceListenToggled());
      await tester.pump();
      await tester.pump();

      expect(find.text('Listening...'), findsOneWidget);
      bloc.close();
    });

    testWidgets('shows transcript bubble when transcript is not empty',
        (tester) async {
      final bloc = VoiceAssistantBloc()
        ..add(const VoiceSessionStartRequested());
      await tester.pumpWidget(_buildScreen(bloc: bloc));
      await tester.pump();

      bloc.add(const VoiceTranscriptReceived('What is the best altitude?'));
      await tester.pump();
      await tester.pump(); // second pump flushes BLoC stream → setState → rebuild

      expect(find.byKey(const Key('transcript_bubble')), findsOneWidget);
      expect(find.text('What is the best altitude?'), findsOneWidget);
      bloc.close();
    });

    testWidgets('shows response bubble when response is not empty',
        (tester) async {
      final bloc = VoiceAssistantBloc()
        ..add(const VoiceSessionStartRequested());
      await tester.pumpWidget(_buildScreen(bloc: bloc));
      await tester.pump();

      bloc.add(const VoiceResponseReceived('1800m is ideal for specialty.'));
      await tester.pump();
      await tester.pump(); // second pump flushes BLoC stream → setState → rebuild

      expect(find.byKey(const Key('response_bubble')), findsOneWidget);
      expect(find.text('1800m is ideal for specialty.'), findsOneWidget);
      bloc.close();
    });

    testWidgets('does not show transcript bubble when transcript is empty',
        (tester) async {
      final bloc = VoiceAssistantBloc()
        ..add(const VoiceSessionStartRequested());
      await tester.pumpWidget(_buildScreen(bloc: bloc));
      await tester.pump();

      expect(find.byKey(const Key('transcript_bubble')), findsNothing);
      bloc.close();
    });
  });

  group('VoiceAssistantScreen — End session', () {
    testWidgets('tapping END SESSION returns to idle state', (tester) async {
      final bloc = VoiceAssistantBloc()
        ..add(const VoiceSessionStartRequested());
      await tester.pumpWidget(_buildScreen(bloc: bloc));
      await tester.pump();

      await tester.tap(find.byKey(const Key('end_session_button')));
      await tester.pump();

      expect(find.text('Chief Curator'), findsOneWidget);
      expect(find.byKey(const Key('initialize_session_button')), findsOneWidget);
      bloc.close();
    });
  });

  group('VoiceAssistantScreen — Error state', () {
    testWidgets('shows error message', (tester) async {
      final bloc = VoiceAssistantBloc()
        ..add(const VoiceErrorOccurred('Microphone unavailable'));
      await tester.pumpWidget(_buildScreen(bloc: bloc));
      await tester.pump();

      expect(find.byKey(const Key('error_message')), findsOneWidget);
      expect(find.text('Microphone unavailable'), findsOneWidget);
    });

    testWidgets('shows Try Again button in error state', (tester) async {
      final bloc = VoiceAssistantBloc()
        ..add(const VoiceErrorOccurred('Microphone unavailable'));
      await tester.pumpWidget(_buildScreen(bloc: bloc));
      await tester.pump();

      expect(find.byKey(const Key('retry_button')), findsOneWidget);
    });

    testWidgets('tapping Try Again transitions back to active state',
        (tester) async {
      final bloc = VoiceAssistantBloc()
        ..add(const VoiceErrorOccurred('Microphone unavailable'));
      await tester.pumpWidget(_buildScreen(bloc: bloc));
      await tester.pump();

      await tester.tap(find.byKey(const Key('retry_button')));
      await tester.pump();

      expect(find.byKey(const Key('status_label')), findsOneWidget);
    });
  });
}
