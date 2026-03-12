import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:brewmaster/config/cloudinary_config.dart';
import 'package:brewmaster/config/theme.dart';
import 'package:brewmaster/domain/models/enums.dart';
import 'package:brewmaster/domain/models/user_profile.dart';
import 'package:brewmaster/presentation/blocs/profile/profile_bloc.dart';
import 'package:brewmaster/presentation/widgets/common/custom_text_field.dart';
import 'package:brewmaster/presentation/widgets/common/custom_button.dart';
import 'package:brewmaster/presentation/widgets/common/error_state_widget.dart';
import 'package:brewmaster/presentation/widgets/common/status_badge.dart';

/// Edit profile screen allowing users to modify their profile information.
class EditProfileScreen extends StatefulWidget {
  final UserProfile userProfile;

  const EditProfileScreen({super.key, required this.userProfile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _displayNameController;
  late final TextEditingController _photoUrlController;

  bool _isUploadingPhoto = false;

  // Farmer fields
  late final TextEditingController _farmSizeController;
  late final TextEditingController _farmLocationController;
  late final TextEditingController _coffeeVarietiesController;
  late final TextEditingController _farmRegNumberController;

  // Buyer fields
  late final TextEditingController _businessNameController;
  late final TextEditingController _businessTypeController;
  late final TextEditingController _monthlyVolumeController;

  @override
  void initState() {
    super.initState();
    final p = widget.userProfile;
    _displayNameController = TextEditingController(text: p.displayName);
    _photoUrlController = TextEditingController(text: p.photoUrl ?? '');
    _farmSizeController =
        TextEditingController(text: p.farmSize?.toString() ?? '');
    _farmLocationController =
        TextEditingController(text: p.farmLocation ?? '');
    _coffeeVarietiesController =
        TextEditingController(text: p.coffeeVarieties?.join(', ') ?? '');
    _farmRegNumberController =
        TextEditingController(text: p.farmRegistrationNumber ?? '');
    _businessNameController =
        TextEditingController(text: p.businessName ?? '');
    _businessTypeController =
        TextEditingController(text: p.businessType ?? '');
    _monthlyVolumeController =
        TextEditingController(text: p.monthlyVolume?.toString() ?? '');
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

bool _hasChanges() {
    final p = widget.userProfile;
    if (_displayNameController.text != p.displayName) return true;
    if (_photoUrlController.text != (p.photoUrl ?? '')) return true;
    if (p.role == UserRole.farmer) {
      if (_farmSizeController.text != (p.farmSize?.toString() ?? '')) {
        return true;
      }
      if (_farmLocationController.text != (p.farmLocation ?? '')) return true;
      if (_coffeeVarietiesController.text !=
          (p.coffeeVarieties?.join(', ') ?? '')) {
        return true;
      }
      if (_farmRegNumberController.text != (p.farmRegistrationNumber ?? '')) {
        return true;
      }
    }
    if (p.role == UserRole.buyer) {
      if (_businessNameController.text != (p.businessName ?? '')) return true;
      if (_businessTypeController.text != (p.businessType ?? '')) return true;
      if (_monthlyVolumeController.text !=
          (p.monthlyVolume?.toString() ?? '')) {
        return true;
      }
    }
    return false;
  }

  Map<String, dynamic> _buildUpdateMap() {
    final map = <String, dynamic>{
      'displayName': _displayNameController.text.trim(),
      'photoUrl':
          _photoUrlController.text.isEmpty ? null : _photoUrlController.text,
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

  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );
    if (picked == null) return;
    setState(() => _isUploadingPhoto = true);
    try {
      final file = File(picked.path);
      final uri = Uri.parse(CloudinaryConfig.uploadUrl);
      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = CloudinaryConfig.uploadPreset
        ..fields['public_id'] = 'avatars/${widget.userProfile.id}'
        ..files.add(await http.MultipartFile.fromPath('file', file.path));
      final response = await request.send();
      final body = await response.stream.bytesToString();
      if (response.statusCode == 200) {
        final json = jsonDecode(body) as Map<String, dynamic>;
        final url = json['secure_url'] as String;
        setState(() => _photoUrlController.text = url);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo upload failed. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  void _handleSave() {
    if (!_formKey.currentState!.validate()) return;
    context.read<ProfileBloc>().add(ProfileUpdateRequested(
          userId: widget.userProfile.id,
          updates: _buildUpdateMap(),
        ));
  }

  Future<bool> _confirmDiscard() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text(
            'You have unsaved changes. Are you sure you want to discard them?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Discard')),
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
        if (shouldDiscard && context.mounted) Navigator.pop(context);
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Edit Profile')),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.padding24),
            child: BlocConsumer<ProfileBloc, ProfileState>(
              listener: (context, state) {
                if (state is ProfileUpdateSuccess) {
                  Navigator.pop(context);
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
                return Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
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
                            label: widget.userProfile.isVerified
                                ? 'Email Verified'
                                : 'Email Unverified',
                            type: widget.userProfile.isVerified
                                ? StatusBadgeType.success
                                : StatusBadgeType.neutral,
                            showIndicator: true,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.padding24),

                      if (state is ProfileFailure) ...[
                        ErrorBanner(
                            message: state.message, onDismiss: () {}),
                        const SizedBox(height: AppTheme.padding16),
                      ],

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
                      Center(
                        child: Stack(
                          children: [
                            GestureDetector(
                              onTap: _isUploadingPhoto ? null : _pickAndUploadPhoto,
                              child: CircleAvatar(
                                radius: 48,
                                backgroundColor: AppTheme.primaryLight,
                                backgroundImage: _photoUrlController.text.isNotEmpty
                                    ? NetworkImage(_photoUrlController.text)
                                    : null,
                                child: _isUploadingPhoto
                                    ? const CircularProgressIndicator()
                                    : _photoUrlController.text.isEmpty
                                        ? const Icon(Icons.camera_alt, size: 32)
                                        : null,
                              ),
                            ),
                            if (!_isUploadingPhoto)
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: CircleAvatar(
                                  radius: 14,
                                  backgroundColor: AppTheme.primaryColor,
                                  child: const Icon(Icons.edit, size: 14, color: Colors.white),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppTheme.padding24),

                      if (widget.userProfile.role == UserRole.farmer)
                        _buildFarmerFields(),
                      if (widget.userProfile.role == UserRole.buyer)
                        _buildBuyerFields(),

                      const SizedBox(height: AppTheme.padding32),
                      CustomButton(
                        text: 'Save Changes',
                        isFullWidth: true,
                        isLoading: state is ProfileLoading,
                        onPressed:
                            state is ProfileLoading ? null : _handleSave,
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
