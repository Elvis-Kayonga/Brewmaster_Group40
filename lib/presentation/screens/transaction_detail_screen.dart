import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../domain/models/escrow_transaction.dart' as models;
import '../../domain/models/enums.dart';
import '../../domain/validators/payment_validator.dart';
import '../providers/payment_provider.dart';
import '../widgets/common/status_badge.dart';
import '../widgets/common/custom_button.dart';
import '../widgets/common/confirmation_dialog.dart';
import '../widgets/common/custom_text_field.dart';

/// Screen displaying detailed information about a transaction
/// Requirements: 6.3, 6.4, 6.5
class TransactionDetailScreen extends StatefulWidget {
  final String transactionId;
  final String userId;
  final bool isFarmer;

  const TransactionDetailScreen({
    super.key,
    required this.transactionId,
    required this.userId,
    required this.isFarmer,
  });

  @override
  State<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  final _disputeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PaymentProvider>().loadTransaction(widget.transactionId);
    });
  }

  @override
  void dispose() {
    _disputeController.dispose();
    super.dispose();
  }

  Future<void> _confirmDelivery(models.Transaction transaction) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: 'Confirm Delivery',
        message:
            'Have you delivered the coffee to the buyer? This action cannot be undone.',
        confirmText: 'Confirm Delivery',
        cancelText: 'Cancel',
        type: ConfirmationDialogType.confirm,
      ),
    );

    if (confirmed != true) return;

    if (!mounted) return;
    final provider = context.read<PaymentProvider>();
    final success = await provider.confirmDelivery(transaction.id);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Delivery confirmed successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Failed to confirm delivery'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _confirmReceipt(models.Transaction transaction) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: 'Confirm Receipt',
        message:
            'Have you received the coffee in good condition? Funds will be released to the farmer.',
        confirmText: 'Confirm & Release Funds',
        cancelText: 'Cancel',
        type: ConfirmationDialogType.confirm,
      ),
    );

    if (confirmed != true) return;

    if (!mounted) return;
    final provider = context.read<PaymentProvider>();
    final success = await provider.confirmReceiptAndReleaseFunds(
      transaction.id,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Receipt confirmed and funds released'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Failed to release funds'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _raiseDispute(models.Transaction transaction) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Raise Dispute'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Please describe the issue with this transaction:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _disputeController,
              labelText: 'Dispute Reason',
              hintText: 'Describe the issue...',
              maxLines: 4,
              validator: PaymentValidator.validateDisputeReason,
            ),
          ],
        ),
        actions: [
          CustomButton(
            text: 'Cancel',
            onPressed: () => Navigator.pop(context),
            type: ButtonType.text,
            size: ButtonSize.small,
          ),
          CustomButton(
            text: 'Submit Dispute',
            onPressed: () {
              final error = PaymentValidator.validateDisputeReason(
                _disputeController.text,
              );
              if (error != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(error), backgroundColor: Colors.red),
                );
                return;
              }
              Navigator.pop(context, _disputeController.text);
            },
            type: ButtonType.danger,
            size: ButtonSize.small,
          ),
        ],
      ),
    );

    if (result == null) return;

    if (!mounted) return;
    final provider = context.read<PaymentProvider>();
    final success = await provider.raiseDispute(transaction.id, result);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dispute raised successfully'),
          backgroundColor: Colors.orange,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Failed to raise dispute'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Details'),
        centerTitle: true,
      ),
      body: Consumer<PaymentProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final transaction = provider.currentTransaction;
          if (transaction == null) {
            return const Center(child: Text('Transaction not found'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Status badge
                Center(
                  child: StatusBadge(
                    label: _getStatusLabel(transaction.status),
                    type: _getStatusBadgeType(transaction.status),
                    size: StatusBadgeSize.large,
                    icon: _getStatusIcon(transaction.status),
                    showIndicator: _isActiveStatus(transaction.status),
                  ),
                ),
                const SizedBox(height: 24),

                // Transaction info card
                _buildInfoCard(transaction),
                const SizedBox(height: 16),

                // Timeline card
                _buildTimelineCard(transaction),
                const SizedBox(height: 16),

                // Dispute info if applicable
                if (transaction.disputeReason != null)
                  _buildDisputeCard(transaction),

                const SizedBox(height: 24),

                // Action buttons
                ..._buildActionButtons(transaction),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard(models.Transaction transaction) {
    final dateFormat = DateFormat('MMM dd, yyyy HH:mm');

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Transaction Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 24),
            _buildInfoRow('Transaction ID', transaction.id),
            _buildInfoRow(
              'Amount',
              '\$${transaction.amount.toStringAsFixed(2)}',
            ),
            _buildInfoRow(
              'Payment Method',
              _getPaymentMethodLabel(transaction.paymentMethod),
            ),
            _buildInfoRow('Created', dateFormat.format(transaction.createdAt)),
            if (transaction.retryCount > 0)
              _buildInfoRow(
                'Retry Attempts',
                transaction.retryCount.toString(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineCard(models.Transaction transaction) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Status Timeline',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 24),
            ...transaction.statusHistory.entries.map((entry) {
              return _buildTimelineItem(
                entry.key,
                DateFormat('MMM dd, HH:mm').format(entry.value),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildDisputeCard(models.Transaction transaction) {
    return Card(
      color: Colors.orange.shade50,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                Text(
                  'Dispute Raised',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              transaction.disputeReason ?? 'No reason provided',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(String status, String time) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(Icons.check_circle, size: 16, color: Colors.green.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _getStatusLabel(TransactionStatusExtension.fromJson(status)),
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(time, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  List<Widget> _buildActionButtons(models.Transaction transaction) {
    final buttons = <Widget>[];

    // Farmer actions
    if (widget.isFarmer) {
      if (transaction.status == TransactionStatus.fundsHeld) {
        buttons.add(
          CustomButton(
            text: 'Confirm Delivery',
            onPressed: () => _confirmDelivery(transaction),
            type: ButtonType.primary,
            size: ButtonSize.large,
            isFullWidth: true,
            leadingIcon: Icons.local_shipping,
          ),
        );
      }
    }
    // Buyer actions
    else {
      if (transaction.status == TransactionStatus.delivered) {
        buttons.add(
          CustomButton(
            text: 'Confirm Receipt & Release Funds',
            onPressed: () => _confirmReceipt(transaction),
            type: ButtonType.success,
            size: ButtonSize.large,
            isFullWidth: true,
            leadingIcon: Icons.check_circle,
          ),
        );
      }
    }

    // Dispute button (available to both parties)
    if (transaction.status != TransactionStatus.completed &&
        transaction.status != TransactionStatus.cancelled &&
        transaction.status != TransactionStatus.disputed) {
      if (buttons.isNotEmpty) buttons.add(const SizedBox(height: 12));
      buttons.add(
        CustomButton(
          text: 'Raise Dispute',
          onPressed: () => _raiseDispute(transaction),
          type: ButtonType.danger,
          size: ButtonSize.medium,
          isFullWidth: true,
          leadingIcon: Icons.flag,
        ),
      );
    }

    return buttons;
  }

  String _getStatusLabel(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.pending:
        return 'Pending Payment';
      case TransactionStatus.fundsHeld:
        return 'Funds Held in Escrow';
      case TransactionStatus.delivered:
        return 'Awaiting Buyer Confirmation';
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

  IconData _getStatusIcon(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.pending:
        return Icons.pending;
      case TransactionStatus.fundsHeld:
        return Icons.account_balance_wallet;
      case TransactionStatus.delivered:
        return Icons.local_shipping;
      case TransactionStatus.completed:
        return Icons.check_circle;
      case TransactionStatus.disputed:
        return Icons.flag;
      case TransactionStatus.cancelled:
        return Icons.cancel;
    }
  }

  bool _isActiveStatus(TransactionStatus status) {
    return status == TransactionStatus.pending ||
        status == TransactionStatus.fundsHeld ||
        status == TransactionStatus.delivered;
  }

  String _getPaymentMethodLabel(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.mpesa:
        return 'M-Pesa';
      case PaymentMethod.mtnMobileMoney:
        return 'MTN Mobile Money';
    }
  }
}
