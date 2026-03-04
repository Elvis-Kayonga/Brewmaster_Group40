import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:brewmaster/config/theme.dart';
import 'package:brewmaster/data/providers/user_provider.dart';
import 'package:brewmaster/domain/models/enums.dart';
import 'package:brewmaster/domain/models/user_profile.dart';
import 'package:brewmaster/presentation/widgets/common/custom_text_field.dart';
import 'package:brewmaster/presentation/widgets/common/custom_button.dart';
import 'package:brewmaster/presentation/widgets/common/error_state_widget.dart';
import 'package:brewmaster/presentation/screens/profile/profile_screen.dart';
import 'package:brewmaster/data/providers/auth_provider.dart';

/// Profile setup screen shown after registration.
/// Displays conditional fields based on user role (farmer vs buyer).
class ProfileSetupScreen extends StatefulWidget {
  final String userId;
  final String email;
  final String displayName;
  final UserRole? role;

  const ProfileSetupScreen({
    super.key,
    required this.userId,
    required this.email,
    required this.displayName,
    this.role,
  });

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();

  // Track selected role if not provided
  late UserRole? _selectedRole;

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
  void initState() {
    super.initState();
    _selectedRole = widget.role;
  }

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
    if (_selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a role (Farmer or Buyer)')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final now = DateTime.now();
    // Determine initial verification info.  The Firebase user may not have
    // `emailVerified` set when the account comes from Google, but Google's
    // identity provider already ensures the address belongs to the user.
    final auth = context.read<AuthProvider>();
    final firebaseUser = auth.currentUser;
    final bool isEmailVerified =
        firebaseUser?.emailVerified == true ||
        (firebaseUser?.providerData.any((p) => p.providerId == 'google.com') ??
            false);

    final profile = UserProfile(
      id: widget.userId,
      email: widget.email,
      phoneNumber: '',
      role: _selectedRole!,
      displayName: widget.displayName,
      createdAt: now,
      updatedAt: now,
      isVerified: isEmailVerified,
      verificationStatus: isEmailVerified
          ? VerificationStatus.verified
          : VerificationStatus.unverified,
      farmSize:
          _selectedRole == UserRole.farmer &&
              _farmSizeController.text.isNotEmpty
          ? double.tryParse(_farmSizeController.text)
          : null,
      farmLocation:
          _selectedRole == UserRole.farmer &&
              _farmLocationController.text.isNotEmpty
          ? _farmLocationController.text.trim()
          : null,
      coffeeVarieties:
          _selectedRole == UserRole.farmer &&
              _coffeeVarietiesController.text.isNotEmpty
          ? _coffeeVarietiesController.text
                .split(',')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList()
          : null,
      farmRegistrationNumber:
          _selectedRole == UserRole.farmer &&
              _farmRegNumberController.text.isNotEmpty
          ? _farmRegNumberController.text.trim()
          : null,
      businessName:
          _selectedRole == UserRole.buyer &&
              _businessNameController.text.isNotEmpty
          ? _businessNameController.text.trim()
          : null,
      businessType:
          _selectedRole == UserRole.buyer &&
              _businessTypeController.text.isNotEmpty
          ? _businessTypeController.text.trim()
          : null,
      monthlyVolume:
          _selectedRole == UserRole.buyer &&
              _monthlyVolumeController.text.isNotEmpty
          ? double.tryParse(_monthlyVolumeController.text)
          : null,
    );

    final userProvider = context.read<UserProvider>();
    final success = await userProvider.createProfile(profile);
    if (success && mounted) {
      // Redirect user to their profile screen once the profile is created.
      // Clear the back stack so onboarding cannot be revisited.
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const ProfileScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show role selection if not yet selected
    if (_selectedRole == null) {
      return _buildRoleSelectionScreen();
    }

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
                      _selectedRole == UserRole.farmer
                          ? 'Farm Details'
                          : 'Business Details',
                      style: AppTheme.heading2,
                    ),
                    const SizedBox(height: AppTheme.padding8),
                    Text(
                      'Tell us more about your ${_selectedRole == UserRole.farmer ? 'farm' : 'business'}.',
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

                    if (_selectedRole == UserRole.farmer) _buildFarmerFields(),
                    if (_selectedRole == UserRole.buyer) _buildBuyerFields(),

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

  Widget _buildRoleSelectionScreen() {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Your Role')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.padding24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'What is your role?',
                style: AppTheme.heading1,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.padding8),
              Text(
                'This helps us show you relevant features and content.',
                style: AppTheme.caption,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.padding32),
              const SizedBox(height: AppTheme.padding16),
              // Farmer option
              _buildRoleCard(
                title: 'I\'m a Farmer',
                description: 'Grow and sell coffee beans',
                icon: Icons.agriculture,
                onTap: () {
                  setState(() {
                    _selectedRole = UserRole.farmer;
                  });
                },
              ),
              const SizedBox(height: AppTheme.padding16),
              // Buyer option
              _buildRoleCard(
                title: 'I\'m a Buyer',
                description: 'Purchase and trade coffee',
                icon: Icons.shopping_cart,
                onTap: () {
                  setState(() {
                    _selectedRole = UserRole.buyer;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.padding24),
          child: Column(
            children: [
              Icon(icon, size: 48, color: AppTheme.primaryColor),
              const SizedBox(height: AppTheme.padding16),
              Text(
                title,
                style: AppTheme.heading2,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.padding8),
              Text(
                description,
                style: AppTheme.caption,
                textAlign: TextAlign.center,
              ),
            ],
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
