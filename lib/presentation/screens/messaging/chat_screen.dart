import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../config/theme.dart';
import '../../../domain/models/conversation.dart';
import '../../../domain/models/message.dart';
import '../../blocs/messaging/messaging_bloc.dart';
import '../../widgets/common/error_state_widget.dart';
import '../../widgets/common/loading_indicator.dart';

/// Chat screen for a single conversation.
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
      appBar: AppBar(
        title: Text(
            'Chat #${widget.conversation.conversationId.substring(0, 8)}'),
        elevation: 0,
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
            children: [
              Expanded(
                child: ListView.builder(
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
              _MessageInputField(
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
    final bubbleColor =
        isOutgoing ? AppTheme.primaryColor : AppTheme.inputFillColor;
    final textColor = isOutgoing ? AppTheme.onPrimaryColor : AppTheme.textPrimary;

    return Align(
      alignment:
          isOutgoing ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75),
        child: Column(
          crossAxisAlignment: isOutgoing
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(message.content,
                  style: TextStyle(color: textColor, fontSize: 16)),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                DateFormat('HH:mm').format(message.createdAt),
                style: AppTheme.caption,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageInputField extends StatelessWidget {
  const _MessageInputField({
    required this.controller,
    required this.isComposing,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool isComposing;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 8, 12 + MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        border:
            Border(top: BorderSide(color: AppTheme.textHint)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: null,
              minLines: 1,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AppTheme.inputFillColor,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                prefixIcon: IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {}, // attachment placeholder
                ),
              ),
              textInputAction: TextInputAction.newline,
            ),
          ),
          const SizedBox(width: 8),
          FloatingActionButton(
            mini: true,
            backgroundColor:
                isComposing ? AppTheme.primaryColor : AppTheme.textSecondary,
            onPressed: isComposing ? onSend : null,
            child: const Icon(Icons.send, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
