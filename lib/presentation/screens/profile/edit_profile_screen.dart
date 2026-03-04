import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:brewmaster/config/theme.dart';
import 'package:brewmaster/data/providers/user_provider.dart';
import 'package:brewmaster/domain/models/enums.dart';
import 'package:brewmaster/domain/models/user_profile.dart';
import 'package:brewmaster/presentation/widgets/common/custom_text_field.dart';
import 'package:brewmaster/presentation/widgets/common/custom_button.dart';
import 'package:brewmaster/presentation/widgets/common/error_state_widget.dart';
import 'package:brewmaster/presentation/widgets/common/status_badge.dart';

/// Edit profile screen allowing users to modify their profile information.
/// Displays conditional fields based on user role (farmer vs buyer).
class EditProfileScreen extends StatefulWidget {
  final UserProfile userProfile;

  const EditProfileScreen({super.key, required this.userProfile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  // Common fields
  late final TextEditingController _displayNameController;
  late final TextEditingController _photoUrlController;

  // Farmer fields
  late final TextEditingController _farmSizeController;
  late final TextEditingController _farmLocationController;
  late final TextEditingController _coffeeVarietiesController;
  late final TextEditingController _farmRegNumberController;

  // Buyer fields
  late final TextEditingController _businessNameController;
  late final TextEditingController _businessTypeController;
  late final TextEditingController _monthlyVolumeController;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final profile = widget.userProfile;

    _displayNameController = TextEditingController(text: profile.displayName);
    _photoUrlController = TextEditingController(text: profile.photoUrl ?? '');

    // Farmer fields
    _farmSizeController = TextEditingController(
      text: profile.farmSize != null ? profile.farmSize.toString() : '',
    );
    _farmLocationController = TextEditingController(
      text: profile.farmLocation ?? '',
    );
    _coffeeVarietiesController = TextEditingController(
      text: profile.coffeeVarieties?.join(', ') ?? '',
    );
    _farmRegNumberController = TextEditingController(
      text: profile.farmRegistrationNumber ?? '',
    );

    // Buyer fields
    _businessNameController = TextEditingController(
      text: profile.businessName ?? '',
    );
    _businessTypeController = TextEditingController(
      text: profile.businessType ?? '',
    );
    _monthlyVolumeController = TextEditingController(
      text: profile.monthlyVolume != null
          ? profile.monthlyVolume.toString()
          : '',
    );
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _photoUrlController.dispose();
    _farmSizeController.dispose();
    _farmLocationController.dispose();
    _coffeeVarietiesController.dispose();
    _farmRegNumberController.dispose();
    _businessNameController.dispose();
    _businessTypeController.dispose();
    _monthlyVolumeController.dispose();
    super.dispose();
  }

  StatusBadgeType _verificationBadgeType(VerificationStatus status) {
    switch (status) {
      case VerificationStatus.verified:
        return StatusBadgeType.success;
      case VerificationStatus.pending:
        return StatusBadgeType.pending;
      case VerificationStatus.rejected:
        return StatusBadgeType.error;
      case VerificationStatus.unverified:
        return StatusBadgeType.neutral;
    }
  }

  bool _hasChanges() {
    final profile = widget.userProfile;

    if (_displayNameController.text != profile.displayName) return true;
    if (_photoUrlController.text != (profile.photoUrl ?? '')) return true;

    if (profile.role == UserRole.farmer) {
      final originalFarmSize = profile.farmSize != null
          ? profile.farmSize.toString()
          : '';
      if (_farmSizeController.text != originalFarmSize) return true;
      if (_farmLocationController.text != (profile.farmLocation ?? '')) {
        return true;
      }
      if (_coffeeVarietiesController.text !=
          (profile.coffeeVarieties?.join(', ') ?? '')) {
        return true;
      }
      if (_farmRegNumberController.text !=
          (profile.farmRegistrationNumber ?? '')) {
        return true;
      }
    }

    if (profile.role == UserRole.buyer) {
      final originalMonthlyVolume = profile.monthlyVolume != null
          ? profile.monthlyVolume.toString()
          : '';
      if (_businessNameController.text != (profile.businessName ?? '')) {
        return true;
      }
      if (_businessTypeController.text != (profile.businessType ?? '')) {
        return true;
      }
      if (_monthlyVolumeController.text != originalMonthlyVolume) return true;
    }

    return false;
  }

  Map<String, dynamic> _buildUpdateMap() {
    final map = <String, dynamic>{
      'displayName': _displayNameController.text.trim(),
      'photoUrl': _photoUrlController.text.isEmpty
          ? null
          : _photoUrlController.text,
      'updatedAt': DateTime.now(),
    };

    if (widget.userProfile.role == UserRole.farmer) {
      map['farmSize'] = double.tryParse(_farmSizeController.text);
      map['farmLocation'] = _farmLocationController.text.isEmpty
          ? null
          : _farmLocationController.text;
      final varieties = _coffeeVarietiesController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      map['coffeeVarieties'] = varieties.isEmpty ? null : varieties;
      map['farmRegistrationNumber'] = _farmRegNumberController.text.isEmpty
          ? null
          : _farmRegNumberController.text;
    }

    if (widget.userProfile.role == UserRole.buyer) {
      map['businessName'] = _businessNameController.text.isEmpty
          ? null
          : _businessNameController.text;
      map['businessType'] = _businessTypeController.text.isEmpty
          ? null
          : _businessTypeController.text;
      map['monthlyVolume'] = double.tryParse(_monthlyVolumeController.text);
    }

    return map;
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final success = await userProvider.updateProfile(
        widget.userProfile.id,
        _buildUpdateMap(),
      );

      if (!mounted) return;

      if (success) {
        Navigator.pop(context);
      }
      // On failure, the ErrorBanner reads userProvider.errorMessage automatically
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<bool> _confirmDiscard() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text(
          'You have unsaved changes. Are you sure you want to discard them?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (!_hasChanges()) {
          if (context.mounted) Navigator.pop(context);
          return;
        }
        final shouldDiscard = await _confirmDiscard();
        if (shouldDiscard && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Edit Profile')),
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
                      // Role and verification status badges
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          StatusBadge(
                            label: widget.userProfile.role == UserRole.farmer
                                ? 'Farmer'
                                : 'Buyer',
                            type: StatusBadgeType.info,
                            icon: widget.userProfile.role == UserRole.farmer
                                ? Icons.agriculture
                                : Icons.shopping_bag,
                          ),
                          const SizedBox(width: AppTheme.padding8),
                          StatusBadge(
                            label: widget.userProfile.verificationStatus.name,
                            type: _verificationBadgeType(
                              widget.userProfile.verificationStatus,
                            ),
                            showIndicator: true,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.padding24),

                      if (userProvider.errorMessage != null) ...[
                        ErrorBanner(
                          message: userProvider.errorMessage!,
                          onDismiss: userProvider.clearError,
                        ),
                        const SizedBox(height: AppTheme.padding16),
                      ],

                      // Display Name field (required)
                      CustomTextField(
                        controller: _displayNameController,
                        labelText: 'Display Name',
                        hintText: 'Enter your display name',
                        prefixIcon: Icons.person_outline,
                        isRequired: true,
                        textCapitalization: TextCapitalization.words,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Display name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppTheme.padding16),

                      // Photo URL field (no validation)
                      CustomTextField(
                        controller: _photoUrlController,
                        labelText: 'Photo URL',
                        hintText: 'Enter photo URL',
                        prefixIcon: Icons.image_outlined,
                      ),
                      const SizedBox(height: AppTheme.padding16),

                      // Role-specific fields
                      if (widget.userProfile.role == UserRole.farmer)
                        _buildFarmerFields(),
                      if (widget.userProfile.role == UserRole.buyer)
                        _buildBuyerFields(),
                      const SizedBox(height: AppTheme.padding32),

                      CustomButton(
                        text: 'Save Changes',
                        isFullWidth: true,
                        isLoading: _isSaving,
                        onPressed: _isSaving ? null : _handleSave,
                      ),
                    ],
                  ),
                );
              },
            ),
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
