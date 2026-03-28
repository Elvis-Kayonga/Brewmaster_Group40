import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../config/localization/app_localizations.dart';
import '../../../config/theme.dart';
import '../../../domain/models/escrow_transaction.dart' as models;
import '../../../domain/models/enums.dart';
import '../../../domain/validators/payment_validator.dart';
import '../../blocs/payment/payment_bloc.dart';
import '../../widgets/common/status_badge.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/confirmation_dialog.dart';
import '../../widgets/common/custom_text_field.dart';

/// Screen displaying detailed information about a transaction.
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
    context
        .read<PaymentBloc>()
        .add(PaymentTransactionLoadRequested(widget.transactionId));
  }

  @override
  void dispose() {
    _disputeController.dispose();
    super.dispose();
  }

  void _confirmDelivery(models.Transaction transaction) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: AppLocalizations.of(context).confirmDeliveryTitle,
        message: AppLocalizations.of(context).confirmDeliveryMessage,
        confirmText: AppLocalizations.of(context).confirmDelivery,
        cancelText: AppLocalizations.of(context).cancel,
        type: ConfirmationDialogType.confirm,
      ),
    );
    if (confirmed != true || !mounted) return;
    context.read<PaymentBloc>().add(PaymentDeliveryConfirmed(transaction.id));
  }

  void _confirmReceipt(models.Transaction transaction) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: AppLocalizations.of(context).confirmReceiptTitle,
        message: AppLocalizations.of(context).confirmReceiptMessage,
        confirmText: AppLocalizations.of(context).confirmReleaseFunds,
        cancelText: AppLocalizations.of(context).cancel,
        type: ConfirmationDialogType.confirm,
      ),
    );
    if (confirmed != true || !mounted) return;
    context.read<PaymentBloc>().add(PaymentReceiptConfirmed(transaction.id));
  }

  void _raiseDispute(models.Transaction transaction) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        final loc = AppLocalizations.of(context);
        return AlertDialog(
        title: Text(loc.raiseDispute),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              loc.disputeDescription,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _disputeController,
              labelText: loc.disputeReason,
              hintText: loc.describeIssue,
              maxLines: 4,
              validator: PaymentValidator.validateDisputeReason,
            ),
          ],
        ),
        actions: [
          CustomButton(
            text: loc.cancel,
            onPressed: () => Navigator.pop(context),
            type: ButtonType.text,
            size: ButtonSize.small,
          ),
          CustomButton(
            text: loc.submitDispute,
            onPressed: () {
              final error = PaymentValidator.validateDisputeReason(
                  _disputeController.text);
              if (error != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(error),
                        backgroundColor: AppTheme.errorColor));
                return;
              }
              Navigator.pop(context, _disputeController.text);
            },
            type: ButtonType.danger,
            size: ButtonSize.small,
          ),
        ],
      );
      },
    );

    if (result == null || !mounted) return;
    context.read<PaymentBloc>().add(
        PaymentDisputeRaised(transactionId: transaction.id, reason: result));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: Text(AppLocalizations.of(context).transactionDetails), centerTitle: true),
      body: BlocConsumer<PaymentBloc, PaymentState>(
        listener: (context, state) {
          if (state is PaymentActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context).actionCompleted),
                backgroundColor: AppTheme.successColor,
              ),
            );
            // Reload transaction after an action
            context
                .read<PaymentBloc>()
                .add(PaymentTransactionLoadRequested(widget.transactionId));
          }
          if (state is PaymentFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppTheme.errorColor),
            );
          }
        },
        builder: (context, state) {
          if (state is PaymentLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          models.Transaction? transaction;
          if (state is PaymentTransactionLoaded) {
            transaction = state.transaction;
          }

          if (transaction == null) {
            return Center(
              child: Text(state is PaymentFailure
                  ? state.message
                  : AppLocalizations.of(context).transactionNotFound),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                _buildInfoCard(transaction),
                const SizedBox(height: 16),
                _buildTimelineCard(transaction),
                const SizedBox(height: 16),
                if (transaction.disputeReason != null)
                  _buildDisputeCard(transaction),
                const SizedBox(height: 24),
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
            Text(AppLocalizations.of(context).transactionInformation,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(height: 24),
            _buildInfoRow(AppLocalizations.of(context).transactionId, transaction.id),
            if (widget.isFarmer && transaction.buyerName != null)
              _buildInfoRow(AppLocalizations.of(context).buyerLabel, transaction.buyerName!),
            _buildInfoRow(
                AppLocalizations.of(context).amountLabel, '\$${transaction.amount.toStringAsFixed(2)}'),
            _buildInfoRow(AppLocalizations.of(context).paymentMethod,
                _getPaymentMethodLabel(transaction.paymentMethod)),
            _buildInfoRow(AppLocalizations.of(context).createdLabel, dateFormat.format(transaction.createdAt)),
            if (transaction.retryCount > 0)
              _buildInfoRow(
                  AppLocalizations.of(context).retryAttempts, transaction.retryCount.toString()),
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
            Text(AppLocalizations.of(context).statusTimeline,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(height: 24),
            ...transaction.statusHistory.entries.map((entry) {
              return _buildTimelineItem(
                  entry.key,
                  DateFormat('MMM dd, HH:mm').format(entry.value));
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildDisputeCard(models.Transaction transaction) {
    return Card(
      color: AppTheme.warningColor.withValues(alpha: 0.12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber, color: AppTheme.warningColor),
                const SizedBox(width: 8),
                Text(AppLocalizations.of(context).disputeRaised,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface)),
              ],
            ),
            const SizedBox(height: 12),
            Text(transaction.disputeReason ?? 'No reason provided',
                style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text('$label:',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface.withValues(alpha: 0.6))),
          ),
          Expanded(
              child: Text(value,
                  style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(String status, String time) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(Icons.check_circle, size: 16, color: AppTheme.successColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _getStatusLabel(TransactionStatusExtension.fromJson(status)),
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(time,
              style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurface.withValues(alpha: 0.6))),
        ],
      ),
    );
  }

  List<Widget> _buildActionButtons(models.Transaction transaction) {
    final buttons = <Widget>[];
    if (widget.isFarmer) {
      if (transaction.status == TransactionStatus.fundsHeld) {
        buttons.add(CustomButton(
          text: AppLocalizations.of(context).confirmDelivery,
          onPressed: () => _confirmDelivery(transaction),
          type: ButtonType.primary,
          size: ButtonSize.large,
          isFullWidth: true,
          leadingIcon: Icons.local_shipping,
        ));
      }
    } else {
      if (transaction.status == TransactionStatus.delivered) {
        buttons.add(CustomButton(
          text: AppLocalizations.of(context).confirmReleaseFunds,
          onPressed: () => _confirmReceipt(transaction),
          type: ButtonType.success,
          size: ButtonSize.large,
          isFullWidth: true,
          leadingIcon: Icons.check_circle,
        ));
      }
    }
    if (transaction.status != TransactionStatus.completed &&
        transaction.status != TransactionStatus.cancelled &&
        transaction.status != TransactionStatus.disputed) {
      if (buttons.isNotEmpty) buttons.add(const SizedBox(height: 12));
      buttons.add(CustomButton(
        text: AppLocalizations.of(context).raiseDispute,
        onPressed: () => _raiseDispute(transaction),
        type: ButtonType.danger,
        size: ButtonSize.medium,
        isFullWidth: true,
        leadingIcon: Icons.flag,
      ));
    }
    return buttons;
  }

  String _getStatusLabel(TransactionStatus status) {
    final loc = AppLocalizations.of(context);
    switch (status) {
      case TransactionStatus.pending:
        return loc.pendingPayment;
      case TransactionStatus.fundsHeld:
        return loc.fundsHeldEscrow;
      case TransactionStatus.delivered:
        return loc.awaitingBuyerConfirmation;
      case TransactionStatus.completed:
        return loc.completed;
      case TransactionStatus.disputed:
        return loc.disputed;
      case TransactionStatus.cancelled:
        return loc.cancelled;
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

  bool _isActiveStatus(TransactionStatus status) =>
      status == TransactionStatus.pending ||
      status == TransactionStatus.fundsHeld ||
      status == TransactionStatus.delivered;

  String _getPaymentMethodLabel(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.mpesa:
        return 'M-Pesa';
      case PaymentMethod.mtnMobileMoney:
        return 'MTN Mobile Money';
      case PaymentMethod.flutterwave:
        return 'Flutterwave';
    }
  }
}
