import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/providers/message_provider.dart';
import '../../../domain/models/conversation.dart';
import '../../../config/theme.dart';
import '../../../presentation/widgets/common/loading_indicator.dart';
import '../../../presentation/widgets/common/empty_state_widget.dart';
import '../../../presentation/widgets/common/error_state_widget.dart';
import 'chat_screen.dart';

/// Screen displaying all conversations for the current user
class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({Key? key}) : super(key: key);

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MessageProvider>(
        context,
        listen: false,
      ).initConversationListener();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Messages'), elevation: 0),
      body: Consumer<MessageProvider>(
        builder: (context, messageProvider, child) {
          if (messageProvider.isLoading &&
              messageProvider.conversations.isEmpty) {
            return const LoadingIndicator();
          }

          if (messageProvider.error != null &&
              messageProvider.conversations.isEmpty) {
            return ErrorStateWidget(
              message: messageProvider.error ?? 'Failed to load conversations',
              onRetry: () {
                messageProvider.initConversationListener();
              },
            );
          }

          if (messageProvider.conversations.isEmpty) {
            return const EmptyStateWidget(
              title: 'No Messages',
              description:
                  'Start a conversation to connect with farmers or buyers',
              icon: Icons.mail_outline,
            );
          }

          final conversations = _filterConversations(
            messageProvider.conversations,
          );

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search conversations...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: conversations.length,
                  itemBuilder: (context, index) {
                    final conversation = conversations[index];
                    return _ConversationTile(
                      conversation: conversation,
                      onTap: () {
                        messageProvider.loadConversationMessages(
                          conversation.conversationId,
                        );
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                ChatScreen(conversation: conversation),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Conversation> _filterConversations(List<Conversation> conversations) {
    if (_searchQuery.isEmpty) {
      return conversations;
    }
    // Filter conversations based on search query
    // In a real app, you would match against participant names
    return conversations;
  }
}

/// Widget representing a single conversation tile
class _ConversationTile extends StatelessWidget {
  final Conversation conversation;
  final VoidCallback onTap;

  const _ConversationTile({required this.conversation, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final lastMessage = conversation.lastMessage;
    final isUnread = conversation.unreadCount > 0;

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: AppTheme.primaryColor,
        child: Text(
          'US',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      title: Text(
        'User #${conversation.conversationId.substring(0, 8)}',
        style: TextStyle(
          fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Text(
        lastMessage?.content ?? 'No messages yet',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: isUnread ? Colors.black : Colors.grey,
          fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _formatTime(conversation.updatedAt),
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          if (isUnread)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                conversation.unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.month}/${dateTime.day}';
    }
  }
}
