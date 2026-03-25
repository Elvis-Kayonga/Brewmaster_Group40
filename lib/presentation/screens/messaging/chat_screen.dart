import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../../config/theme.dart';
import '../../../domain/models/conversation.dart';
import '../../widgets/common/profile_avatar_button.dart';
import '../../../domain/models/message.dart';
import '../../blocs/messaging/messaging_bloc.dart';
import '../../widgets/common/error_state_widget.dart';
import '../../widgets/common/loading_indicator.dart';

/// Chat screen for a single conversation — direct messaging design.
///
/// Requirements: 5.2, 5.5, 5.6, 5.7, 5.8, 16.1 (Clean Architecture)
/// Developer: Developer 3
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.conversation});

  final Conversation conversation;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isComposing = false;

  @override
  void initState() {
    super.initState();
    context
        .read<MessagingBloc>()
        .add(MessagesLoadRequested(widget.conversation.conversationId));
    _messageController.addListener(() {
      setState(() => _isComposing = _messageController.text.isNotEmpty);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String? get _currentUserId => FirebaseAuth.instance.currentUser?.uid;

  String? get _receiverId {
    return widget.conversation.participantIds.firstWhere(
      (id) => id != _currentUserId,
      orElse: () => '',
    );
  }

  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    final receiverId = _receiverId;
    if (receiverId == null || receiverId.isEmpty) return;

    _messageController.clear();
    setState(() => _isComposing = false);

    context.read<MessagingBloc>().add(MessageSendRequested(
          conversationId: widget.conversation.conversationId,
          receiverId: receiverId,
          content: content,
        ));

    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 18, color: AppTheme.primaryDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          () {
            final otherId = widget.conversation.participantIds.firstWhere(
              (id) => id != _currentUserId,
              orElse: () => '',
            );
            final name =
                widget.conversation.participantNames[otherId]?.trim() ?? '';
            return name.isNotEmpty ? name : 'Conversation';
          }(),
          style: const TextStyle(
            color: AppTheme.primaryDark,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          const ProfileAvatarButton(),
        ],
      ),
      body: BlocBuilder<MessagingBloc, MessagingState>(
        builder: (context, state) {
          if (state is MessagingLoading || state is MessagingInitial) {
            return const LoadingIndicator();
          }

          if (state is MessagingFailure) {
            return ErrorStateWidget(
              message: state.message,
              onRetry: () => context.read<MessagingBloc>().add(
                  MessagesLoadRequested(widget.conversation.conversationId)),
            );
          }

          final messages =
              state is MessagesLoaded ? state.messages : <Message>[];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Direct\nMessaging',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryDark,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'LIVE CHAT',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.8,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              // ── Messages or empty state ───────────────────────────
              Expanded(
                child: messages.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceColor,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Text(
                            '"Ask about the coffee variety, processing method, altitude, or arrange a shipment directly with the producer."',
                            style: TextStyle(
                              fontSize: 15,
                              fontStyle: FontStyle.italic,
                              color: AppTheme.textSecondary,
                              height: 1.6,
                            ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        itemCount: messages.length,
                        itemBuilder: (context, index) => _MessageBubble(
                          message: messages[index],
                          currentUserId: _currentUserId,
                        ),
                      ),
              ),
              // ── Input field ───────────────────────────────────────
              _EliasInputField(
                controller: _messageController,
                isComposing: _isComposing,
                onSend: _sendMessage,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.currentUserId});

  final Message message;
  final String? currentUserId;

  @override
  Widget build(BuildContext context) {
    final isOutgoing = message.senderId == currentUserId;

    return Align(
      alignment: isOutgoing ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        child: Column(
          crossAxisAlignment:
              isOutgoing ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isOutgoing ? AppTheme.primaryDark : AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                message.content,
                style: TextStyle(
                  color: isOutgoing ? Colors.white : AppTheme.textPrimary,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                DateFormat('HH:mm').format(message.createdAt),
                style: const TextStyle(
                    fontSize: 11, color: AppTheme.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EliasInputField extends StatefulWidget {
  const _EliasInputField({
    required this.controller,
    required this.isComposing,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool isComposing;
  final VoidCallback onSend;

  @override
  State<_EliasInputField> createState() => _EliasInputFieldState();
}

class _EliasInputFieldState extends State<_EliasInputField> {
  final SpeechToText _speech = SpeechToText();
  bool _isListening = false;
  bool _speechAvailable = false;

  @override
  void initState() {
    super.initState();
    _speech.initialize().then((available) {
      if (mounted) setState(() => _speechAvailable = available);
    });
  }

  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
    } else {
      setState(() => _isListening = true);
      await _speech.listen(
        onResult: (result) {
          widget.controller.text = result.recognizedWords;
          widget.controller.selection = TextSelection.fromPosition(
            TextPosition(offset: widget.controller.text.length),
          );
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        localeId: 'en_US',
      );
      // listen() completes when speech ends naturally
      if (mounted) setState(() => _isListening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, 12 + MediaQuery.of(context).viewInsets.bottom),
      color: AppTheme.backgroundColor,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Row(
          children: [
            // Mic button — shown when speech is available
            if (_speechAvailable)
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: IconButton(
                  icon: Icon(
                    _isListening ? Icons.mic : Icons.mic_none,
                    color: _isListening
                        ? AppTheme.primaryColor
                        : AppTheme.textSecondary,
                  ),
                  onPressed: _toggleListening,
                  tooltip: _isListening ? 'Stop listening' : 'Speak',
                ),
              )
            else
              const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: widget.controller,
                maxLines: null,
                minLines: 1,
                decoration: InputDecoration(
                  hintText: _isListening ? 'Listening...' : 'Type a message...',
                  hintStyle: TextStyle(
                    fontSize: 14,
                    color: _isListening
                        ? AppTheme.primaryColor
                        : AppTheme.textHint,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
                textInputAction: TextInputAction.newline,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(6),
              child: GestureDetector(
                onTap: widget.isComposing ? widget.onSend : null,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: widget.isComposing
                        ? AppTheme.primaryDark
                        : AppTheme.textHint,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.arrow_upward,
                      color: Colors.white, size: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
