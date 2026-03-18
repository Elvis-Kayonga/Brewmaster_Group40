// lib/presentation/screens/voice/voice_assistant_screen.dart
//
// "Chief Curator" AI voice-assistant screen.
// Matches the design: mic avatar card, title, description, INITIALIZE SESSION button.
//
// Requirements: 1.5, 5.7
// Developer: Developer 3

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../config/theme.dart';
import '../../../presentation/widgets/common/voice_input_widget.dart';
import '../../blocs/voice/voice_bloc.dart';

class VoiceAssistantScreen extends StatelessWidget {
  const VoiceAssistantScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => VoiceAssistantBloc(),
      child: const _VoiceAssistantView(),
    );
  }
}

class _VoiceAssistantView extends StatelessWidget {
  const _VoiceAssistantView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Brew Master',
          style: TextStyle(
            color: AppTheme.primaryDark,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_left,
                color: AppTheme.primaryDark, size: 28),
            onPressed: () => Navigator.of(context).maybePop(),
            tooltip: 'Back',
          ),
          Container(
            margin: const EdgeInsets.only(right: 12),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.primaryDark,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 20),
          ),
        ],
      ),
      body: BlocBuilder<VoiceAssistantBloc, VoiceAssistantState>(
        builder: (context, state) {
          if (state is VoiceAssistantIdle) {
            return _IdleBody(
              onInitialize: () => context
                  .read<VoiceAssistantBloc>()
                  .add(const VoiceSessionStartRequested()),
            );
          }
          if (state is VoiceAssistantActive) {
            return _ActiveBody(state: state);
          }
          if (state is VoiceAssistantError) {
            return _ErrorBody(
              message: state.message,
              onRetry: () => context
                  .read<VoiceAssistantBloc>()
                  .add(const VoiceSessionStartRequested()),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}



class _IdleBody extends StatelessWidget {
  final VoidCallback onInitialize;

  const _IdleBody({required this.onInitialize});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const Spacer(flex: 2),
          
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppTheme.inputFillColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.08),
                  blurRadius: 24,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: const Icon(
              Icons.mic_none_rounded,
              size: 52,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 32),
          
          const Text(
            'Chief Curator',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryDark,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Greetings, Clarisse. Elias is ready to consult on brewing chemistry, origin ethics, or your current supply chain waypoints',
            textAlign: TextAlign.center,
            style: AppTheme.body.copyWith(color: AppTheme.textSecondary),
          ),
          const Spacer(flex: 3),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              key: const Key('initialize_session_button'),
              onPressed: onInitialize,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryDark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusPill),
                ),
                elevation: 0,
              ),
              child: const Text(
                'INITIALIZE SESSION',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}



class _ActiveBody extends StatelessWidget {
  final VoiceAssistantActive state;

  const _ActiveBody({required this.state});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const Spacer(flex: 1),
          
          VoiceInputWidget(
            key: const Key('voice_mic_button'),
            size: 100,
            onResult: (text) => context
                .read<VoiceAssistantBloc>()
                .add(VoiceTranscriptReceived(text)),
          ),
          const SizedBox(height: 24),
          
          Text(
            state.isListening ? 'Listening...' : 'Chief Curator — Active',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: state.isListening
                  ? AppTheme.errorColor
                  : AppTheme.primaryDark,
            ),
          ),
          const SizedBox(height: 16),
          
          if (state.transcript.isNotEmpty)
            _ChatBubble(
              text: state.transcript,
              isUser: true,
            ),
          
          if (state.response.isNotEmpty)
            _ChatBubble(
              text: state.response,
              isUser: false,
            ),
          const Spacer(flex: 2),
          
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              key: const Key('end_session_button'),
              onPressed: () => context
                  .read<VoiceAssistantBloc>()
                  .add(const VoiceSessionEnded()),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryDark,
                side: const BorderSide(color: AppTheme.primaryDark, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppTheme.borderRadiusPill),
                ),
              ),
              child: const Text(
                'END SESSION',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}



class _ErrorBody extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBody({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                color: AppTheme.errorColor, size: 48),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTheme.body.copyWith(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              key: const Key('retry_button'),
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryDark,
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}



class _ChatBubble extends StatelessWidget {
  final String text;
  final bool isUser;

  const _ChatBubble({required this.text, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? AppTheme.primaryDark
              : AppTheme.inputFillColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
        ),
        child: Text(
          text,
          style: AppTheme.body.copyWith(
            color: isUser ? Colors.white : AppTheme.textPrimary,
          ),
        ),
      ),
    );
  }
}
