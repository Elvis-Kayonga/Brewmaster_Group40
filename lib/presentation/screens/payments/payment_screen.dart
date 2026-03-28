import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutterwave_standard/flutterwave.dart';
import '../../../config/localization/app_localizations.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../config/theme.dart';
import '../../../data/services/exchange_rate_service.dart';
import '../../../domain/models/enums.dart';
import '../../blocs/payment/payment_bloc.dart';
import '../../widgets/common/custom_button.dart';

/// Screen for initiating a Flutterwave payment transaction.
///
/// Listing prices are always in USD. Before handing off to Flutterwave this
/// screen converts the USD amount to the buyer's local currency so they are
/// charged in a familiar denomination.
///
/// Requirements: 6.1, 6.2
class PaymentScreen extends StatefulWidget {
  final String listingId;
  final String farmerId;
  final String buyerId;

  /// Price in USD (canonical storage currency for all listings).
  final double amount;

  /// Buyer's country — used to pick the charge currency for Flutterwave.
  final String? buyerCountry;

  const PaymentScreen({
    super.key,
    required this.listingId,
    required this.farmerId,
    required this.buyerId,
    required this.amount,
    this.buyerCountry,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _agreedToTerms = false;
  bool _loadingRate = true;

  /// Buyer's local currency code (derived from their country).
  late final String _localCurrencyCode;

  /// USD amount converted to buyer's local currency (fetched on init).
  double? _convertedAmount;

  final _exchangeRateService = ExchangeRateService();

  @override
  void initState() {
    super.initState();
    _localCurrencyCode = CurrencyUtils.codeFromCountry(widget.buyerCountry);
    _fetchRate();
  }

  Future<void> _fetchRate() async {
    final result = await _exchangeRateService.convertFromUsd(
      widget.amount,
      _localCurrencyCode,
    );
    if (!mounted) return;
    setState(() {
      _convertedAmount = result.amount;
      _loadingRate = false;
    });
  }

  Future<void> _launchFlutterwaveCheckout() async {
    final loc = AppLocalizations.of(context);
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.pleaseAgreeTerms),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    if (_convertedAmount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.fetchingRate)),
      );
      return;
    }

    final publicKey = dotenv.env['FLUTTERWAVE_PUBLIC_KEY'] ?? '';
    // isTestMode must match the API key prefix:
    // - FLWPUBK_TEST- keys → sandbox API → returns checkout-v2.dev-flutterwave.com (public)
    // - FLWPUBK- keys      → prod API    → returns the live checkout URL
    // Mixing a test key with isTestMode=false causes the prod API to return an
    // internal dev checkout URL (checkout-v3-ui-dev.myflutterwave.com) that
    // cannot be resolved publicly.
    final isTestMode = publicKey.startsWith('FLWPUBK_TEST-');

    if (publicKey.isEmpty || publicKey.startsWith('FLWPUBK_TEST-XXX')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.paymentNotConfigured),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    final txRef =
        'BREW-${widget.buyerId.substring(0, widget.buyerId.length.clamp(0, 8))}-${DateTime.now().millisecondsSinceEpoch}';

    final customer = Customer(
      name: currentUser?.displayName ?? 'Customer',
      phoneNumber: currentUser?.phoneNumber ?? '0700000000',
      email: currentUser?.email ?? '',
    );

    // Charge the buyer in their local currency using the converted amount.
    final chargeAmount = _convertedAmount!;
    final chargeCurrency = _localCurrencyCode;

    final flutterwave = Flutterwave(
      publicKey: publicKey,
      currency: chargeCurrency,
      amount: chargeAmount.toStringAsFixed(2),
      customer: customer,
      txRef: txRef,
      paymentOptions: 'card, mobilemoneyrw, mpesa, ussd',
      customization: Customization(
        title: 'Brewmaster Payment',
        description: 'Escrow payment for coffee listing',
      ),
      isTestMode: isTestMode,
      redirectUrl: 'https://brewmaster.app/payment-callback',
    );

    try {
      final response = await flutterwave.charge(context);
      if (!mounted) return;

      if (response.status == 'cancelled') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.paymentCancelled)),
        );
        return;
      }

      if (response.status == 'successful') {
        // Store the canonical USD amount in the transaction record.
        context.read<PaymentBloc>().add(PaymentInitiateRequested(
              buyerId: widget.buyerId,
              farmerId: widget.farmerId,
              listingId: widget.listingId,
              amount: widget.amount,
              currency: 'USD',
              paymentMethod: PaymentMethod.flutterwave,
              flutterwaveTxId: response.transactionId,
            ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('${loc.paymentError}: ${response.status ?? 'failed'}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.paymentError),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).makePayment), centerTitle: true),
      body: BlocConsumer<PaymentBloc, PaymentState>(
        listener: (context, state) {
          if (state is PaymentProcessed) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context).paymentSuccessful),
                backgroundColor: AppTheme.successColor,
              ),
            );
            Navigator.of(context).pop(true);
          }
          if (state is PaymentFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppTheme.errorColor,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is PaymentLoading;
          final loc = AppLocalizations.of(context);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Payment summary card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.paymentSummary,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        // Always show price in USD (canonical currency)
                        _buildSummaryRow(
                          '${loc.amountUsd}:',
                          CurrencyUtils.format(widget.amount, 'USD'),
                        ),
                        _buildSummaryRow(
                          '${loc.transactionFee}:',
                          CurrencyUtils.format(0, 'USD'),
                        ),
                        const Divider(height: 20),
                        _buildSummaryRow(
                          '${loc.totalUsd}:',
                          CurrencyUtils.format(widget.amount, 'USD'),
                          isTotal: true,
                        ),
                        // Show the local-currency equivalent that Flutterwave will charge
                        if (_localCurrencyCode != 'USD') ...[
                          const SizedBox(height: 8),
                          _buildConversionNote(),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Flutterwave branding note
                Card(
                  color: AppTheme.primaryColor.withValues(alpha: 0.08),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        Icon(Icons.payment, color: AppTheme.primaryColor),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            loc.poweredByFlutterwave,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
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
                        child: Text(
                          loc.agreeTerms,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Escrow info card
                Card(
                  color: Colors.amber.withValues(alpha: 0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        const Icon(Icons.lock_outline, color: Colors.amber),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            loc.escrowInfo,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                CustomButton(
                  text: loc.payWithFlutterwave,
                  onPressed:
                      (isLoading || _loadingRate) ? null : _launchFlutterwaveCheckout,
                  type: ButtonType.primary,
                  size: ButtonSize.large,
                  isFullWidth: true,
                  isLoading: isLoading || _loadingRate,
                  leadingIcon: Icons.payment,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildConversionNote() {
    if (_loadingRate) {
      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          children: [
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 1.5),
            ),
            const SizedBox(width: 8),
            Text(
              AppLocalizations.of(context).fetchingRate,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    }
    if (_convertedAmount == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Charged in $_localCurrencyCode:',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          Text(
            CurrencyUtils.format(_convertedAmount!, _localCurrencyCode),
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value,
      {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: isTotal ? 16 : 14,
                fontWeight:
                    isTotal ? FontWeight.bold : FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight:
                  isTotal ? FontWeight.bold : FontWeight.w600,
              color: isTotal ? AppTheme.successColor : null,
            ),
          ),
        ],
      ),
    );
  }
}
