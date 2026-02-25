import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/models/enums.dart';
import '../../domain/validators/payment_validator.dart';
import '../providers/payment_provider.dart';
import '../widgets/common/custom_text_field.dart';
import '../widgets/common/custom_button.dart';
import '../widgets/common/custom_dropdown.dart';

/// Screen for initiating a payment transaction
/// Requirements: 6.1, 6.2
class PaymentScreen extends StatefulWidget {
  final String listingId;
  final String farmerId;
  final String buyerId;
  final double amount;

  const PaymentScreen({
    super.key,
    required this.listingId,
    required this.farmerId,
    required this.buyerId,
    required this.amount,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _pinController = TextEditingController();

  PaymentMethod _selectedMethod = PaymentMethod.mpesa;
  bool _agreedToTerms = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to terms and conditions'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final provider = context.read<PaymentProvider>();

    // Create transaction
    final transaction = await provider.createTransaction(
      buyerId: widget.buyerId,
      farmerId: widget.farmerId,
      listingId: widget.listingId,
      amount: widget.amount,
      paymentMethod: _selectedMethod,
    );

    if (transaction == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Failed to create transaction'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Process payment
    final success = await provider.processPayment(transaction.id);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment successful! Funds are now held in escrow.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Payment failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Make Payment'), centerTitle: true),
      body: Consumer<PaymentProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Payment summary card
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Payment Summary',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildSummaryRow(
                            'Amount:',
                            '\$${widget.amount.toStringAsFixed(2)}',
                          ),
                          _buildSummaryRow('Transaction Fee:', '\$0.00'),
                          const Divider(height: 20),
                          _buildSummaryRow(
                            'Total:',
                            '\$${widget.amount.toStringAsFixed(2)}',
                            isTotal: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Payment method selection
                  const Text(
                    'Select Payment Method',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  CustomDropdown<PaymentMethod>(
                    value: _selectedMethod,
                    items: PaymentMethod.values
                        .map(
                          (method) => DropdownItem(
                            value: method,
                            label: _getPaymentMethodLabel(method),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedMethod = value);
                        _phoneController.clear();
                      }
                    },
                    labelText: 'Payment Method',
                  ),
                  const SizedBox(height: 16),

                  // Phone number field
                  CustomTextField(
                    controller: _phoneController,
                    labelText: 'Mobile Money Number',
                    hintText: _getPhoneHint(_selectedMethod),
                    prefixIcon: Icons.phone,
                    keyboardType: TextInputType.phone,
                    validator: (value) => PaymentValidator.validatePhoneNumber(
                      value,
                      _selectedMethod,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // PIN field
                  CustomTextField(
                    controller: _pinController,
                    labelText: 'Payment PIN',
                    hintText: 'Enter 4-digit PIN',
                    prefixIcon: Icons.lock_outline,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    validator: PaymentValidator.validatePaymentPin,
                  ),
                  const SizedBox(height: 16),

                  // Terms and conditions checkbox
                  Row(
                    children: [
                      Checkbox(
                        value: _agreedToTerms,
                        onChanged: (value) {
                          setState(() => _agreedToTerms = value ?? false);
                        },
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _agreedToTerms = !_agreedToTerms);
                          },
                          child: const Text(
                            'I agree to the terms and conditions of escrow payment',
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Info card
                  Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Your payment will be held in escrow until delivery is confirmed by both parties.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.blue.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Submit button
                  CustomButton(
                    text: 'Process Payment',
                    onPressed: provider.isLoading ? null : _processPayment,
                    type: ButtonType.primary,
                    size: ButtonSize.large,
                    isFullWidth: true,
                    isLoading: provider.isLoading,
                    leadingIcon: Icons.payment,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              color: isTotal ? Colors.green.shade700 : null,
            ),
          ),
        ],
      ),
    );
  }

  String _getPaymentMethodLabel(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.mpesa:
        return 'M-Pesa';
      case PaymentMethod.mtnMobileMoney:
        return 'MTN Mobile Money';
    }
  }

  String _getPhoneHint(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.mpesa:
        return 'e.g., 0712345678';
      case PaymentMethod.mtnMobileMoney:
        return 'e.g., 0781234567';
    }
  }
}
