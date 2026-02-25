import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../domain/models/escrow_transaction.dart' as models;
import '../../domain/models/enums.dart';
import '../providers/payment_provider.dart';
import '../widgets/common/status_badge.dart';
import '../widgets/common/empty_state_widget.dart';
import 'transaction_detail_screen.dart';

/// Screen displaying transaction history
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

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PaymentProvider>().subscribeToUserTransactions(
        widget.userId,
      );
      context.read<PaymentProvider>().loadUserStatistics(widget.userId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Active'),
            Tab(text: 'Completed'),
            Tab(text: 'Disputed'),
          ],
        ),
      ),
      body: Consumer<PaymentProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              // Statistics card
              if (provider.statistics != null) _buildStatisticsCard(provider),

              // Transaction list
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTransactionList(provider.transactions, null),
                    _buildTransactionList(
                      provider.transactions,
                      TransactionStatus.fundsHeld,
                      additionalStatuses: [
                        TransactionStatus.pending,
                        TransactionStatus.delivered,
                      ],
                    ),
                    _buildTransactionList(
                      provider.transactions,
                      TransactionStatus.completed,
                    ),
                    _buildTransactionList(
                      provider.transactions,
                      TransactionStatus.disputed,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatisticsCard(PaymentProvider provider) {
    final stats = provider.statistics!;
    final totalEarnings = stats['totalEarnings'] as double;
    final completedCount = stats['completedTransactions'] as int;
    final pendingCount = stats['pendingTransactions'] as int;

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Total Earnings',
                  '\$${totalEarnings.toStringAsFixed(2)}',
                  Icons.attach_money,
                  Colors.green,
                ),
                _buildStatItem(
                  'Completed',
                  completedCount.toString(),
                  Icons.check_circle,
                  Colors.blue,
                ),
                _buildStatItem(
                  'Pending',
                  pendingCount.toString(),
                  Icons.pending,
                  Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildTransactionList(
    List<models.Transaction> allTransactions,
    TransactionStatus? filterStatus, {
    List<TransactionStatus>? additionalStatuses,
  }) {
    List<models.Transaction> filtered;
    if (filterStatus == null) {
      filtered = allTransactions;
    } else {
      filtered = allTransactions.where((t) {
        if (t.status == filterStatus) return true;
        if (additionalStatuses != null &&
            additionalStatuses.contains(t.status)) {
          return true;
        }
        return false;
      }).toList();
    }

    if (filtered.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.receipt_long,
        title: 'No Transactions',
        description: _getEmptyMessage(filterStatus),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        return _buildTransactionCard(filtered[index]);
      },
    );
  }

  Widget _buildTransactionCard(models.Transaction transaction) {
    final dateFormat = DateFormat('MMM dd, yyyy HH:mm');
    final isUserBuyer = transaction.buyerId == widget.userId;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TransactionDetailScreen(
                transactionId: transaction.id,
                userId: widget.userId,
                isFarmer: widget.isFarmer,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with amount and status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '\$${transaction.amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  StatusBadge(
                    label: _getStatusLabel(transaction.status),
                    type: _getStatusBadgeType(transaction.status),
                    size: StatusBadgeSize.small,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Transaction details
              Row(
                children: [
                  Icon(
                    isUserBuyer ? Icons.arrow_upward : Icons.arrow_downward,
                    size: 16,
                    color: isUserBuyer ? Colors.red : Colors.green,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isUserBuyer ? 'Payment Sent' : 'Payment Received',
                    style: TextStyle(
                      fontSize: 14,
                      color: isUserBuyer ? Colors.red : Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Date and payment method
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    dateFormat.format(transaction.createdAt),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    _getPaymentMethodIcon(transaction.paymentMethod),
                    size: 14,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _getPaymentMethodLabel(transaction.paymentMethod),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),

              // Retry indicator if applicable
              if (transaction.retryCount > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    children: [
                      const Icon(Icons.refresh, size: 14, color: Colors.orange),
                      const SizedBox(width: 4),
                      Text(
                        'Retried ${transaction.retryCount} time(s)',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),

              // Dispute indicator if applicable
              if (transaction.status == TransactionStatus.disputed)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    children: [
                      const Icon(Icons.flag, size: 14, color: Colors.red),
                      const SizedBox(width: 4),
                      const Text(
                        'Under dispute',
                        style: TextStyle(fontSize: 12, color: Colors.red),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _getEmptyMessage(TransactionStatus? status) {
    if (status == null) {
      return 'No transactions yet. Start by making a purchase!';
    }
    switch (status) {
      case TransactionStatus.completed:
        return 'No completed transactions yet';
      case TransactionStatus.disputed:
        return 'No disputed transactions';
      default:
        return 'No active transactions';
    }
  }

  String _getStatusLabel(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.pending:
        return 'Pending';
      case TransactionStatus.fundsHeld:
        return 'In Escrow';
      case TransactionStatus.delivered:
        return 'Delivered';
      case TransactionStatus.completed:
        return 'Completed';
      case TransactionStatus.disputed:
        return 'Disputed';
      case TransactionStatus.cancelled:
        return 'Cancelled';
    }
  }

  StatusBadgeType _getStatusBadgeType(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.pending:
        return StatusBadgeType.pending;
      case TransactionStatus.fundsHeld:
      case TransactionStatus.delivered:
        return StatusBadgeType.active;
      case TransactionStatus.completed:
        return StatusBadgeType.success;
      case TransactionStatus.disputed:
        return StatusBadgeType.warning;
      case TransactionStatus.cancelled:
        return StatusBadgeType.error;
    }
  }

  IconData _getPaymentMethodIcon(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.mpesa:
      case PaymentMethod.mtnMobileMoney:
        return Icons.phone_android;
    }
  }

  String _getPaymentMethodLabel(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.mpesa:
        return 'M-Pesa';
      case PaymentMethod.mtnMobileMoney:
        return 'MTN';
    }
  }
}
