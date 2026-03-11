import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/providers/message_provider.dart';
import '../../../domain/models/conversation.dart';
import '../../../domain/models/message.dart';
import '../../../config/theme.dart';
import '../../../presentation/widgets/common/loading_indicator.dart';
import '../../../presentation/widgets/common/error_state_widget.dart';
import 'package:intl/intl.dart';

/// Screen for chatting in a conversation
class ChatScreen extends StatefulWidget {
  final Conversation conversation;

  const ChatScreen({Key? key, required this.conversation}) : super(key: key);

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MessageProvider>(
        context,
        listen: false,
      ).loadConversationMessages(widget.conversation.conversationId);
    });
    _messageController.addListener(_onComposingChanged);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onComposingChanged() {
    setState(() {
      _isComposing = _messageController.text.isNotEmpty;
    });
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.isEmpty) return;

    final content = _messageController.text;
    _messageController.clear();
    setState(() {
      _isComposing = false;
    });

    // Get the other participant ID
    final String? receiverId = widget.conversation.participantIds.firstWhere(
      (id) => id != Provider.of<MessageProvider>(context, listen: false),
      orElse: () => '',
    );

    if (receiverId == null || receiverId.isEmpty) return;

    await Provider.of<MessageProvider>(context, listen: false).sendMessage(
      conversationId: widget.conversation.conversationId,
      receiverId: receiverId,
      content: content,
      messageType: MessageType.text,
    );

    _scrollToBottom();
  }

  void _scrollToBottom() {
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
          'Chat #${widget.conversation.conversationId.substring(0, 8)}',
        ),
        elevation: 0,
      ),
      body: Consumer<MessageProvider>(
        builder: (context, messageProvider, child) {
          if (messageProvider.currentConversationMessages.isEmpty &&
              messageProvider.isLoading) {
            return const LoadingIndicator();
          }

          if (messageProvider.error != null) {
            return ErrorStateWidget(
              message: messageProvider.error ?? 'Failed to load messages',
              onRetry: () {
                messageProvider.loadConversationMessages(
                  widget.conversation.conversationId,
                );
              },
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: messageProvider.currentConversationMessages.length,
                  itemBuilder: (context, index) {
                    final message =
                        messageProvider.currentConversationMessages[index];
                    return _MessageBubble(message: message);
                  },
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

/// Widget for displaying a message bubble
class _MessageBubble extends StatelessWidget {
  final Message message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    // TODO: Get actual current user ID from Firebase Auth and compare with senderId
    // For now, determine by message properties - always true as placeholder
    final bool isOutgoing = message.senderId.isNotEmpty; // Placeholder logic

    final bubbleColor = isOutgoing
        ? AppTheme.primaryColor
        : Colors.grey.withOpacity(0.2);
    final textColor = isOutgoing ? Colors.white : Colors.black;
    final alignment = isOutgoing ? Alignment.centerRight : Alignment.centerLeft;
    final crossAlignment = isOutgoing
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start;

    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: crossAlignment,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                message.content,
                style: TextStyle(color: textColor, fontSize: 16),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _formatTime(message.createdAt),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    return DateFormat('HH:mm').format(dateTime);
  }
}

/// Widget for message input field
class _MessageInputField extends StatelessWidget {
  final TextEditingController controller;
  final bool isComposing;
  final VoidCallback onSend;

  const _MessageInputField({
    required this.controller,
    required this.isComposing,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        8,
        12 + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.2))),
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
                fillColor: Colors.grey.withOpacity(0.1),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                prefixIcon: IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    // Handle attachment in future
                  },
                ),
              ),
              textInputAction: TextInputAction.newline,
            ),
          ),
          const SizedBox(width: 8),
          FloatingActionButton(
            mini: true,
            backgroundColor: isComposing ? AppTheme.primaryColor : Colors.grey,
            onPressed: isComposing ? onSend : null,
            child: const Icon(Icons.send, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
