import 'package:flutter/material.dart';
import '../../../domain/models/message.dart';
import '../../../config/theme.dart';
import 'package:intl/intl.dart';

/// Widget for displaying message bubbles
class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isOutgoing;
  final VoidCallback? onTap;

  const MessageBubble({
    Key? key,
    required this.message,
    required this.isOutgoing,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Align(
        alignment: isOutgoing ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          child: Column(
            crossAxisAlignment: isOutgoing
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isOutgoing
                      ? AppTheme.primaryColor
                      : Colors.grey.withOpacity(0.2),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isOutgoing ? 16 : 4),
                    bottomRight: Radius.circular(isOutgoing ? 4 : 16),
                  ),
                ),
                child: _buildMessageContent(),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 8, right: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(message.createdAt),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    if (isOutgoing) ...[
                      const SizedBox(width: 4),
                      Icon(
                        message.isRead ? Icons.done_all : Icons.done,
                        size: 12,
                        color: Colors.grey,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageContent() {
    if (message.messageType == MessageType.listingReference &&
        message.listingId != null) {
      return _ListingReferenceContent(
        content: message.content,
        listingId: message.listingId!,
        isOutgoing: isOutgoing,
      );
    }

    return Text(
      message.content,
      style: TextStyle(
        color: isOutgoing ? Colors.white : Colors.black,
        fontSize: 16,
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    return DateFormat('HH:mm').format(dateTime);
  }
}

/// Widget for displaying listing reference in messages
class _ListingReferenceContent extends StatelessWidget {
  final String content;
  final String listingId;
  final bool isOutgoing;

  const _ListingReferenceContent({
    required this.content,
    required this.listingId,
    required this.isOutgoing,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          content,
          style: TextStyle(
            color: isOutgoing ? Colors.white : Colors.black,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isOutgoing ? Colors.white.withOpacity(0.2) : Colors.grey,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.local_offer, size: 16, color: Colors.orange),
              const SizedBox(width: 8),
              Text(
                'Listing #${listingId.substring(0, 8)}',
                style: TextStyle(
                  color: isOutgoing ? Colors.white : Colors.black,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Widget for displaying typing indicator
class TypingIndicator extends StatefulWidget {
  final bool isVisible;

  const TypingIndicator({Key? key, required this.isVisible}) : super(key: key);

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) {
      return const SizedBox.shrink();
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DotAnimation(
              animation: Tween<double>(begin: 0, end: 1).animate(
                CurvedAnimation(
                  parent: _controller,
                  curve: const Interval(0.0, 0.33),
                ),
              ),
            ),
            const SizedBox(width: 4),
            _DotAnimation(
              animation: Tween<double>(begin: 0, end: 1).animate(
                CurvedAnimation(
                  parent: _controller,
                  curve: const Interval(0.33, 0.66),
                ),
              ),
            ),
            const SizedBox(width: 4),
            _DotAnimation(
              animation: Tween<double>(begin: 0, end: 1).animate(
                CurvedAnimation(
                  parent: _controller,
                  curve: const Interval(0.66, 1.0),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget for animated typing dot
class _DotAnimation extends StatelessWidget {
  final Animation<double> animation;

  const _DotAnimation({required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -8 * animation.value),
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}
