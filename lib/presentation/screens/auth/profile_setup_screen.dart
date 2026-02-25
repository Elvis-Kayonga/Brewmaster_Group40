import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:brewmaster/config/theme.dart';
import 'package:brewmaster/data/providers/user_provider.dart';
import 'package:brewmaster/domain/models/enums.dart';
import 'package:brewmaster/domain/models/user_profile.dart';
import 'package:brewmaster/presentation/widgets/common/custom_text_field.dart';
import 'package:brewmaster/presentation/widgets/common/custom_button.dart';
import 'package:brewmaster/presentation/widgets/common/error_state_widget.dart';

/// Profile setup screen shown after registration.
/// Displays conditional fields based on user role (farmer vs buyer).
class ProfileSetupScreen extends StatefulWidget {
  final String userId;
  final String email;
  final String displayName;
  final UserRole role;

  const ProfileSetupScreen({
    super.key,
    required this.userId,
    required this.email,
    required this.displayName,
    required this.role,
  });

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();

  // Farmer fields
  final _farmSizeController = TextEditingController();
  final _farmLocationController = TextEditingController();
  final _coffeeVarietiesController = TextEditingController();
  final _farmRegNumberController = TextEditingController();

  // Buyer fields
  final _businessNameController = TextEditingController();
  final _businessTypeController = TextEditingController();
  final _monthlyVolumeController = TextEditingController();

  @override
  void dispose() {
    _farmSizeController.dispose();
    _farmLocationController.dispose();
    _coffeeVarietiesController.dispose();
    _farmRegNumberController.dispose();
    _businessNameController.dispose();
    _businessTypeController.dispose();
    _monthlyVolumeController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final now = DateTime.now();
    final profile = UserProfile(
      id: widget.userId,
      email: widget.email,
      phoneNumber: '',
      role: widget.role,
      displayName: widget.displayName,
      createdAt: now,
      updatedAt: now,
      farmSize:
          widget.role == UserRole.farmer && _farmSizeController.text.isNotEmpty
          ? double.tryParse(_farmSizeController.text)
          : null,
      farmLocation:
          widget.role == UserRole.farmer &&
              _farmLocationController.text.isNotEmpty
          ? _farmLocationController.text.trim()
          : null,
      coffeeVarieties:
          widget.role == UserRole.farmer &&
              _coffeeVarietiesController.text.isNotEmpty
          ? _coffeeVarietiesController.text
                .split(',')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList()
          : null,
      farmRegistrationNumber:
          widget.role == UserRole.farmer &&
              _farmRegNumberController.text.isNotEmpty
          ? _farmRegNumberController.text.trim()
          : null,
      businessName:
          widget.role == UserRole.buyer &&
              _businessNameController.text.isNotEmpty
          ? _businessNameController.text.trim()
          : null,
      businessType:
          widget.role == UserRole.buyer &&
              _businessTypeController.text.isNotEmpty
          ? _businessTypeController.text.trim()
          : null,
      monthlyVolume:
          widget.role == UserRole.buyer &&
              _monthlyVolumeController.text.isNotEmpty
          ? double.tryParse(_monthlyVolumeController.text)
          : null,
    );

    final userProvider = context.read<UserProvider>();
    final success = await userProvider.createProfile(profile);
    if (success && mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Complete Your Profile')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.padding24),
          child: Consumer<UserProvider>(
            builder: (context, userProvider, _) {
              return Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      widget.role == UserRole.farmer
                          ? 'Farm Details'
                          : 'Business Details',
                      style: AppTheme.heading2,
                    ),
                    const SizedBox(height: AppTheme.padding8),
                    Text(
                      'Tell us more about your ${widget.role == UserRole.farmer ? 'farm' : 'business'}.',
                      style: AppTheme.caption,
                    ),
                    const SizedBox(height: AppTheme.padding24),

                    if (userProvider.errorMessage != null) ...[
                      ErrorBanner(
                        message: userProvider.errorMessage!,
                        onDismiss: userProvider.clearError,
                      ),
                      const SizedBox(height: AppTheme.padding16),
                    ],

                    if (widget.role == UserRole.farmer) _buildFarmerFields(),
                    if (widget.role == UserRole.buyer) _buildBuyerFields(),

                    const SizedBox(height: AppTheme.padding32),

                    CustomButton(
                      text: 'Save Profile',
                      isFullWidth: true,
                      isLoading: userProvider.isLoading,
                      onPressed: _handleSave,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFarmerFields() {
    return Column(
      children: [
        CustomTextField(
          controller: _farmSizeController,
          labelText: 'Farm Size (hectares)',
          hintText: 'e.g. 5.5',
          prefixIcon: Icons.landscape,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              final size = double.tryParse(value);
              if (size == null || size <= 0) {
                return 'Enter a valid farm size';
              }
            }
            return null;
          },
        ),
        const SizedBox(height: AppTheme.padding16),
        CustomTextField(
          controller: _farmLocationController,
          labelText: 'Farm Location',
          hintText: 'e.g. Kigali, Rwanda',
          prefixIcon: Icons.location_on_outlined,
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: AppTheme.padding16),
        CustomTextField(
          controller: _coffeeVarietiesController,
          labelText: 'Coffee Varieties',
          hintText: 'e.g. Arabica, Robusta',
          prefixIcon: Icons.coffee,
          helperText: 'Separate varieties with commas',
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: AppTheme.padding16),
        CustomTextField(
          controller: _farmRegNumberController,
          labelText: 'Farm Registration Number',
          hintText: 'Optional',
          prefixIcon: Icons.badge_outlined,
        ),
      ],
    );
  }

  Widget _buildBuyerFields() {
    return Column(
      children: [
        CustomTextField(
          controller: _businessNameController,
          labelText: 'Business Name',
          hintText: 'Enter your business name',
          prefixIcon: Icons.business,
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: AppTheme.padding16),
        CustomTextField(
          controller: _businessTypeController,
          labelText: 'Business Type',
          hintText: 'e.g. Roaster, Exporter, Retailer',
          prefixIcon: Icons.category_outlined,
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: AppTheme.padding16),
        CustomTextField(
          controller: _monthlyVolumeController,
          labelText: 'Monthly Volume (kg)',
          hintText: 'e.g. 500',
          prefixIcon: Icons.scale,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              final volume = double.tryParse(value);
              if (volume == null || volume < 0) {
                return 'Enter a valid volume';
              }
            }
            return null;
          },
        ),
      ],
    );
  }
}
