import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../config/theme.dart';
import '../../../domain/models/conversation.dart';
import '../../widgets/common/profile_avatar_button.dart';
import '../../blocs/messaging/messaging_bloc.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/error_state_widget.dart';
import '../../widgets/common/loading_indicator.dart';
import 'chat_screen.dart';

/// Screen displaying all conversations — "Elias" messaging design.
///
/// Requirements: 5.2, 5.5, 5.6, 16.1 (Clean Architecture)
/// Developer: Developer 3
class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    context.read<MessagingBloc>().add(const ConversationsLoadRequested());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
              onRetry: () => context
                  .read<MessagingBloc>()
                  .add(const ConversationsLoadRequested()),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Messages',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryDark,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'DIRECT MESSAGING',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.8,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _searchQuery = v),
                      decoration: InputDecoration(
                        hintText: 'Search conversations...',
                        hintStyle: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textHint,
                        ),
                        prefixIcon: const Icon(Icons.search,
                            color: AppTheme.textSecondary, size: 20),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close,
                                    size: 18, color: AppTheme.textSecondary),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: AppTheme.surfaceColor,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(28),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(28),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(28),
                          borderSide: const BorderSide(
                              color: AppTheme.primaryColor, width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Conversation list ───────────────────────────────────
              if (state is ConversationsLoaded)
                state.conversations.isEmpty
                    ? const Expanded(
                        child: EmptyStateWidget(
                          title: 'No Messages',
                          description:
                              'Start a conversation to connect with farmers or buyers',
                          icon: Icons.chat_bubble_outline,
                        ),
                      )
                    : Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: state.conversations.length,
                          itemBuilder: (context, index) {
                            final conversation = state.conversations[index];
                            if (_searchQuery.isNotEmpty &&
                                !conversation.conversationId
                                    .contains(_searchQuery)) {
                              return const SizedBox.shrink();
                            }
                            return _ConversationTile(
                              conversation: conversation,
                              onTap: () {
                                context.read<MessagingBloc>().add(
                                    MessagesLoadRequested(
                                        conversation.conversationId));
                                context.read<MessagingBloc>().add(
                                    MessagesMarkReadRequested(
                                        conversation.conversationId));
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ChatScreen(conversation: conversation),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      )
              else
                const SizedBox.shrink(),
            ],
          );
        },
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({required this.conversation, required this.onTap});

  final Conversation conversation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final lastMessage = conversation.lastMessage;
    final isUnread = conversation.unreadCount > 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isUnread ? AppTheme.primaryDark : AppTheme.primaryColor,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text(
                  'E',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chat #${conversation.conversationId.substring(0, 8)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          isUnread ? FontWeight.bold : FontWeight.w600,
                      color: AppTheme.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    lastMessage?.content ?? 'No messages yet',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: isUnread
                          ? AppTheme.textPrimary
                          : AppTheme.textSecondary,
                      fontWeight:
                          isUnread ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatTime(conversation.updatedAt),
                  style: const TextStyle(
                      fontSize: 11, color: AppTheme.textSecondary),
                ),
                if (isUnread) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      conversation.unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays == 1) return 'yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${dt.month}/${dt.day}';
  }
}
