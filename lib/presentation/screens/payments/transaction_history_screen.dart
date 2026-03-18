import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../config/theme.dart';
import '../../../domain/models/escrow_transaction.dart' as models;
import '../../widgets/common/profile_avatar_button.dart';
import '../../../domain/models/enums.dart';
import '../../blocs/payment/payment_bloc.dart';
import '../../widgets/common/empty_state_widget.dart';
import 'transaction_detail_screen.dart';

/// Screen displaying transaction history — supply chain tracking design.
/// Requirements: 6.7, 15.3
class TransactionHistoryScreen extends StatefulWidget {
  final String userId;
  final bool isFarmer;

  const TransactionHistoryScreen({
    super.key,
    required this.userId,
    required this.isFarmer,
  });

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  @override
  void initState() {
    super.initState();
    context.read<PaymentBloc>().add(PaymentHistoryRequested(widget.userId));
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
      body: BlocBuilder<PaymentBloc, PaymentState>(
        builder: (context, state) {
          if (state is! PaymentHistoryLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'My Orders',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryDark,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Track your coffee purchases and supply chain status.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (state.transactions.isEmpty)
                SliverFillRemaining(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const EmptyStateWidget(
                        icon: Icons.receipt_long,
                        title: 'No Transactions Yet',
                        description:
                            'Your coffee orders and payments will appear here.',
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                        child: OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 40, vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                            side: const BorderSide(
                                color: AppTheme.primaryColor, width: 1.5),
                          ),
                          child: const Text(
                            'View all',
                            style: TextStyle(
                              fontSize: 15,
                              color: AppTheme.primaryDark,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _HeritageOrderCard(
                        transaction: state.transactions[index],
                        userId: widget.userId,
                        isFarmer: widget.isFarmer,
                      ),
                      childCount: state.transactions.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _HeritageOrderCard extends StatelessWidget {
  final models.Transaction transaction;
  final String userId;
  final bool isFarmer;

  const _HeritageOrderCard({
    required this.transaction,
    required this.userId,
    required this.isFarmer,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = transaction.status == TransactionStatus.fundsHeld ||
        transaction.status == TransactionStatus.delivered ||
        transaction.status == TransactionStatus.pending;
    final shortId = 'TRC-ORD-${transaction.id.substring(0, 4).toUpperCase()}';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TransactionDetailScreen(
            transactionId: transaction.id,
            userId: userId,
            isFarmer: isFarmer,
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppTheme.primaryDark,
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.greenAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Text(
                          'LIVE TRACE: ACTIVE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: Colors.greenAccent,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _statusLabel(transaction.status),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: Colors.white60,
                      ),
                    ),
                  ),
                Text(
                  shortId,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white54,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Title ────────────────────────────────────────────
            Text(
              _cardTitle(transaction.status),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Batch · \$${transaction.amount.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 13, color: Colors.white60),
            ),
            const SizedBox(height: 20),

            // ── Progress bar ─────────────────────────────────────
            _TransitProgressBar(status: transaction.status),
            const SizedBox(height: 20),

            // ── Date ─────────────────────────────────────────────
            Row(
              children: [
                const Icon(Icons.schedule, size: 14, color: Colors.white38),
                const SizedBox(width: 6),
                Text(
                  DateFormat('hh:mm a').format(transaction.createdAt),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white38,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _cardTitle(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.pending:
        return 'Awaiting Payment';
      case TransactionStatus.fundsHeld:
        return 'In Escrow';
      case TransactionStatus.delivered:
        return 'In Transit';
      case TransactionStatus.completed:
        return 'Delivered';
      case TransactionStatus.disputed:
        return 'Under Dispute';
      case TransactionStatus.cancelled:
        return 'Cancelled';
    }
  }

  String _statusLabel(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.completed:
        return 'DELIVERED';
      case TransactionStatus.cancelled:
        return 'CANCELLED';
      case TransactionStatus.disputed:
        return 'DISPUTED';
      default:
        return 'PENDING';
    }
  }
}

class _TransitProgressBar extends StatelessWidget {
  final TransactionStatus status;

  const _TransitProgressBar({required this.status});

  int get _activeStep {
    switch (status) {
      case TransactionStatus.pending:
        return 0;
      case TransactionStatus.fundsHeld:
        return 1;
      case TransactionStatus.delivered:
        return 3;
      case TransactionStatus.completed:
        return 4;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    const steps = ['Origin', 'Processing', 'Export', 'Freight', 'Delivery'];
    final active = _activeStep;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (active + 1) / steps.length,
            backgroundColor: Colors.white12,
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            minHeight: 4,
          ),
        ),
        const SizedBox(height: 12),
        // Step dots
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(steps.length, (i) {
            final isDone = i <= active;
            return Column(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: isDone ? AppTheme.primaryColor : Colors.white24,
                    shape: BoxShape.circle,
                    border: isDone
                        ? null
                        : Border.all(color: Colors.white38, width: 1.5),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  steps[i],
                  style: TextStyle(
                    fontSize: 9,
                    color: isDone ? Colors.white70 : Colors.white30,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }
}
