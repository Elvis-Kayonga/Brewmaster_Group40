import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:brewmaster/config/theme.dart';
import 'package:brewmaster/config/localization/app_localizations.dart';
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

  // Shared fields
  String? _selectedCountry;

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
  void didUpdateWidget(ProfileSetupScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_selectedRole == null && widget.role != null) {
      setState(() => _selectedRole = widget.role);
    }
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
    final loc = AppLocalizations.of(context);
    if (_selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.pleaseSelectRole)),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final now = DateTime.now();

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
      verificationStatus: VerificationStatus.unverified,
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
      country: _selectedCountry,
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
        final loc = AppLocalizations.of(context);
        return Scaffold(
          appBar: AppBar(title: Text(loc.completeYourProfile)),
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
                          ? loc.farmDetails
                          : loc.businessDetails,
                      style: AppTheme.heading2,
                    ),
                    const SizedBox(height: AppTheme.padding8),
                    Text(
                      _selectedRole == UserRole.farmer
                          ? loc.tellUsAboutFarm
                          : loc.tellUsAboutBusiness,
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

                    _buildCountryDropdown(loc),
                    const SizedBox(height: AppTheme.padding16),

                    if (_selectedRole == UserRole.farmer) _buildFarmerFields(loc),
                    if (_selectedRole == UserRole.buyer) _buildBuyerFields(loc),

                    const SizedBox(height: AppTheme.padding32),

                    CustomButton(
                      text: loc.saveProfile,
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
    return Builder(builder: (context) {
      final loc = AppLocalizations.of(context);
      return Scaffold(
        appBar: AppBar(title: Text(loc.selectYourRole)),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.padding24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(loc.whatIsYourRole,
                    style: AppTheme.heading1, textAlign: TextAlign.center),
                const SizedBox(height: AppTheme.padding8),
                Text(
                  loc.roleHelpText,
                  style: AppTheme.caption,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.padding32),
                _buildRoleCard(
                  title: loc.imAFarmer,
                  description: loc.growSellCoffee,
                  icon: Icons.agriculture,
                  onTap: () => setState(() => _selectedRole = UserRole.farmer),
                ),
                const SizedBox(height: AppTheme.padding16),
                _buildRoleCard(
                  title: loc.imABuyer,
                  description: loc.purchaseTradeCoffee,
                  icon: Icons.shopping_cart,
                  onTap: () => setState(() => _selectedRole = UserRole.buyer),
                ),
              ],
            ),
          ),
        ),
      );
    });
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
              Text(title, style: AppTheme.heading2, textAlign: TextAlign.center),
              const SizedBox(height: AppTheme.padding8),
              Text(description, style: AppTheme.caption, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  static const _eastAfricanCountries = [
    'Kenya',
    'Ethiopia',
    'Uganda',
    'Tanzania',
    'Rwanda',
    'Burundi',
    'Other',
  ];

  Widget _buildCountryDropdown(AppLocalizations loc) {
    return DropdownButtonFormField<String>(
      initialValue: _selectedCountry,
      decoration: InputDecoration(
        labelText: loc.country,
        prefixIcon: const Icon(Icons.flag_outlined),
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
          borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
        ),
      ),
      hint: Text(loc.selectCountry),
      items: _eastAfricanCountries
          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
          .toList(),
      onChanged: (v) => setState(() => _selectedCountry = v),
    );
  }

  Widget _buildFarmerFields(AppLocalizations loc) {
    return Column(
      children: [
        CustomTextField(
          controller: _farmSizeController,
          labelText: loc.farmSizeHectares,
          hintText: 'e.g. 5.5',
          prefixIcon: Icons.landscape,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              final size = double.tryParse(value);
              if (size == null || size <= 0) return loc.enterValidFarmSize;
            }
            return null;
          },
        ),
        const SizedBox(height: AppTheme.padding16),
        CustomTextField(
          controller: _farmLocationController,
          labelText: loc.farmLocation,
          hintText: 'e.g. Kigali, Rwanda',
          prefixIcon: Icons.location_on_outlined,
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: AppTheme.padding16),
        CustomTextField(
          controller: _coffeeVarietiesController,
          labelText: loc.coffeeVarieties,
          hintText: loc.coffeeVarietiesHint,
          prefixIcon: Icons.coffee,
          helperText: loc.separateWithCommas,
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: AppTheme.padding16),
        CustomTextField(
          controller: _farmRegNumberController,
          labelText: loc.farmRegistrationNumber,
          hintText: loc.optional,
          prefixIcon: Icons.badge_outlined,
        ),
      ],
    );
  }

  Widget _buildBuyerFields(AppLocalizations loc) {
    return Column(
      children: [
        CustomTextField(
          controller: _businessNameController,
          labelText: loc.businessName,
          hintText: loc.businessNameHint,
          prefixIcon: Icons.business,
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: AppTheme.padding16),
        CustomTextField(
          controller: _businessTypeController,
          labelText: loc.businessType,
          hintText: loc.businessTypeHint,
          prefixIcon: Icons.category_outlined,
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: AppTheme.padding16),
        CustomTextField(
          controller: _monthlyVolumeController,
          labelText: loc.monthlyVolumeKg,
          hintText: 'e.g. 500',
          prefixIcon: Icons.scale,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              final volume = double.tryParse(value);
              if (volume == null || volume < 0) return loc.enterValidVolume;
            }
            return null;
          },
        ),
      ],
    );
  }
}
