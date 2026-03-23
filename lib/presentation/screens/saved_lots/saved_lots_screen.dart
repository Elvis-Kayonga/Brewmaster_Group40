import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../config/theme.dart';
import '../../../domain/models/saved_lot.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/messaging/messaging_bloc.dart';
import '../../blocs/saved_lots/saved_lots_bloc.dart';
import '../messaging/chat_screen.dart';
import '../payments/payment_screen.dart';

class SavedLotsScreen extends StatelessWidget {
  const SavedLotsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        title: const Text(
          'Saved Lots',
          style: TextStyle(
            color: AppTheme.primaryDark,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          BlocBuilder<SavedLotsBloc, SavedLotsState>(
            builder: (context, state) {
              if (state.items.isEmpty) return const SizedBox.shrink();
              return TextButton(
                onPressed: () => context
                    .read<SavedLotsBloc>()
                    .add(const SavedLotsCleared()),
                child: const Text(
                  'Clear All',
                  style: TextStyle(
                    color: AppTheme.errorColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: BlocListener<MessagingBloc, MessagingState>(
        listener: (context, state) {
          if (state is ConversationReady) {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => ChatScreen(conversation: state.conversation),
            ));
          }
        },
        child: BlocBuilder<SavedLotsBloc, SavedLotsState>(
          builder: (context, state) {
            if (state.items.isEmpty) return const _EmptyState();
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: state.items.length,
              itemBuilder: (context, index) =>
                  _SavedLotTile(lot: state.items[index]),
            );
          },
        ),
      ),
    );
  }
}

// ── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.favorite_border, size: 72, color: AppTheme.textHint),
          const SizedBox(height: 16),
          const Text(
            'No saved lots yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryDark,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap the heart on any listing in the Shop to save it here.',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Saved lot tile ───────────────────────────────────────────────────────────

class _SavedLotTile extends StatelessWidget {
  final SavedLot lot;
  const _SavedLotTile({required this.lot});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: Stack(
              children: [
                lot.imageUrl != null
                    ? Image.network(
                        lot.imageUrl!,
                        height: 140,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _placeholder(),
                      )
                    : _placeholder(),
                // Remove button
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => context
                        .read<SavedLotsBloc>()
                        .add(SavedLotRemoved(lot.listingId)),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.favorite,
                        color: Colors.redAccent,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lot.location.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  lot.variety,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryDark,
                  ),
                ),
                if (lot.farmerName != null)
                  Text(
                    lot.farmerName!,
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Price / KG',
                          style: TextStyle(
                              fontSize: 10, color: AppTheme.textSecondary),
                        ),
                        Text(
                          '\$${lot.pricePerKg.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryDark,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      '${lot.availableQuantity.toStringAsFixed(0)} kg available',
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => context
                            .read<MessagingBloc>()
                            .add(StartConversationRequested(lot.farmerId)),
                        icon: const Icon(Icons.chat_bubble_outline, size: 14),
                        label: const Text(
                          'Message',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryDark,
                          side: const BorderSide(color: AppTheme.primaryDark),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final authState = context.read<AuthBloc>().state;
                          final buyerId = authState is AuthAuthenticated
                              ? authState.profile.id
                              : '';
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PaymentScreen(
                                listingId: lot.listingId,
                                farmerId: lot.farmerId,
                                buyerId: buyerId,
                                amount:
                                    lot.pricePerKg * lot.availableQuantity,
                                farmerCountry: lot.location,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.payments_outlined,
                            size: 14, color: Colors.white),
                        label: const Text(
                          'Direct Pay',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryDark,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
        height: 140,
        width: double.infinity,
        color: AppTheme.inputFillColor,
        child: const Icon(Icons.coffee, size: 40, color: AppTheme.textHint),
      );
}
