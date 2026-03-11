import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:brewmaster/config/theme.dart';
import 'package:brewmaster/domain/models/enums.dart';
import 'package:brewmaster/domain/models/user_profile.dart';
import 'package:brewmaster/presentation/blocs/auth/auth_bloc.dart';
import 'package:brewmaster/presentation/blocs/profile/profile_bloc.dart';
import 'package:brewmaster/presentation/widgets/common/custom_text_field.dart';
import 'package:brewmaster/presentation/widgets/common/custom_button.dart';
import 'package:brewmaster/presentation/widgets/common/error_state_widget.dart';

/// Profile setup screen shown after registration.
/// Displayed by [AuthGate] when the state is [AuthNeedsProfile].
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

  void _handleSave() {
    if (_selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select a role (Farmer or Buyer)')),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final now = DateTime.now();

    // AuthNeedsProfile carries isGoogleUser; read it from the current AuthBloc state
    final authState = context.read<AuthBloc>().state;
    final isGoogleUser =
        authState is AuthNeedsProfile ? authState.isGoogleUser : false;

    final profile = UserProfile(
      id: widget.userId,
      email: widget.email,
      phoneNumber: '',
      role: _selectedRole!,
      displayName: widget.displayName,
      createdAt: now,
      updatedAt: now,
      isVerified: isGoogleUser,
      verificationStatus: isGoogleUser
          ? VerificationStatus.verified
          : VerificationStatus.unverified,
      farmSize: _selectedRole == UserRole.farmer &&
              _farmSizeController.text.isNotEmpty
          ? double.tryParse(_farmSizeController.text)
          : null,
      farmLocation: _selectedRole == UserRole.farmer &&
              _farmLocationController.text.isNotEmpty
          ? _farmLocationController.text.trim()
          : null,
      coffeeVarieties: _selectedRole == UserRole.farmer &&
              _coffeeVarietiesController.text.isNotEmpty
          ? _coffeeVarietiesController.text
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList()
          : null,
      farmRegistrationNumber: _selectedRole == UserRole.farmer &&
              _farmRegNumberController.text.isNotEmpty
          ? _farmRegNumberController.text.trim()
          : null,
      businessName: _selectedRole == UserRole.buyer &&
              _businessNameController.text.isNotEmpty
          ? _businessNameController.text.trim()
          : null,
      businessType: _selectedRole == UserRole.buyer &&
              _businessTypeController.text.isNotEmpty
          ? _businessTypeController.text.trim()
          : null,
      monthlyVolume: _selectedRole == UserRole.buyer &&
              _monthlyVolumeController.text.isNotEmpty
          ? double.tryParse(_monthlyVolumeController.text)
          : null,
    );

    context.read<ProfileBloc>().add(ProfileCreateRequested(profile));
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedRole == null) return _buildRoleSelectionScreen();

    return BlocConsumer<ProfileBloc, ProfileState>(
      listener: (context, state) {
        if (state is ProfileCreateSuccess) {
          final authState = context.read<AuthBloc>().state;
          final isGoogleUser =
              authState is AuthNeedsProfile ? authState.isGoogleUser : false;

          if (isGoogleUser) {
            context.read<AuthBloc>().add(const AuthCheckRequested());
          } else {
            context
                .read<AuthBloc>()
                .add(const AuthVerificationEmailRequested());
          }
        }
        if (state is ProfileFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: const Text('Complete Your Profile')),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.padding24),
              child: Form(
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
                      'Tell us more about your '
                      '${_selectedRole == UserRole.farmer ? 'farm' : 'business'}.',
                      style: AppTheme.caption,
                    ),
                    const SizedBox(height: AppTheme.padding24),

                    if (state is ProfileFailure) ...[
                      ErrorBanner(
                        message: state.message,
                        onDismiss: () {},
                      ),
                      const SizedBox(height: AppTheme.padding16),
                    ],

                    if (_selectedRole == UserRole.farmer) _buildFarmerFields(),
                    if (_selectedRole == UserRole.buyer) _buildBuyerFields(),

                    const SizedBox(height: AppTheme.padding32),

                    CustomButton(
                      text: 'Save Profile',
                      isFullWidth: true,
                      isLoading: state is ProfileLoading,
                      onPressed: _handleSave,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
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
              Text('What is your role?', style: AppTheme.heading1,
                  textAlign: TextAlign.center),
              const SizedBox(height: AppTheme.padding8),
              Text(
                'This helps us show you relevant features and content.',
                style: AppTheme.caption,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.padding32),
              _buildRoleCard(
                title: "I'm a Farmer",
                description: 'Grow and sell coffee beans',
                icon: Icons.agriculture,
                onTap: () => setState(() => _selectedRole = UserRole.farmer),
              ),
              const SizedBox(height: AppTheme.padding16),
              _buildRoleCard(
                title: "I'm a Buyer",
                description: 'Purchase and trade coffee',
                icon: Icons.shopping_cart,
                onTap: () => setState(() => _selectedRole = UserRole.buyer),
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
              Text(title, style: AppTheme.heading2,
                  textAlign: TextAlign.center),
              const SizedBox(height: AppTheme.padding8),
              Text(description, style: AppTheme.caption,
                  textAlign: TextAlign.center),
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
              if (size == null || size <= 0) return 'Enter a valid farm size';
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
              if (volume == null || volume < 0) return 'Enter a valid volume';
            }
            return null;
          },
        ),
      ],
    );
  }
}
