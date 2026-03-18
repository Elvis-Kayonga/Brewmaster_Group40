// Feature: brewmaster-verification
// Screen allowing a user to submit identity/farm documents for verification.
//
// Requirements: 7.1, 7.2, 7.3
// Developer: Developer 1

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../config/theme.dart';
import '../../../domain/models/enums.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/verification/verification_bloc.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/loading_indicator.dart';

class VerificationRequestScreen extends StatefulWidget {
  /// When true, shown as an onboarding step by AuthGate.
  /// On success, dispatches AuthCheckRequested instead of popping.
  final bool isOnboarding;

  const VerificationRequestScreen({super.key, this.isOnboarding = false});

  @override
  State<VerificationRequestScreen> createState() =>
      _VerificationRequestScreenState();
}

class _VerificationRequestScreenState
    extends State<VerificationRequestScreen> {
  final List<File> _selectedFiles = [];
  final _picker = ImagePicker();
  bool _showResubmitForm = false;

  @override
  void initState() {
    super.initState();
    final userId = _userId(context.read<AuthBloc>().state);
    if (userId != null) {
      context
          .read<VerificationBloc>()
          .add(VerificationStatusLoadRequested(userId));
    }
  }

  /// Extracts the user ID from whichever auth state is currently active.
  /// The screen is shown for both [AuthNeedsKycVerification] (onboarding) and
  /// [AuthAuthenticated] (profile → verify from settings).
  String? _userId(AuthState authState) {
    if (authState is AuthAuthenticated) return authState.profile.id;
    if (authState is AuthNeedsKycVerification) return authState.profile.id;
    return null;
  }

  Future<void> _pickDocuments() async {
    final picked = await _picker.pickMultiImage();
    if (picked.isNotEmpty) {
      setState(() {
        _selectedFiles.addAll(picked.map((x) => File(x.path)));
      });
    }
  }

  void _removeFile(int index) {
    setState(() => _selectedFiles.removeAt(index));
  }

  void _submit() {
    final userId = _userId(context.read<AuthBloc>().state);
    if (userId == null) return;
    if (_selectedFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one document.')),
      );
      return;
    }
    context.read<VerificationBloc>().add(
          VerificationDocumentSubmitted(
            userId: userId,
            documents: List.from(_selectedFiles),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Identity'),
        elevation: 0,
        automaticallyImplyLeading: !widget.isOnboarding,
        actions: widget.isOnboarding
            ? [
                TextButton(
                  onPressed: () => context
                      .read<AuthBloc>()
                      .add(const AuthCheckRequested()),
                  child: const Text('Skip for now'),
                ),
              ]
            : null,
      ),
      body: BlocConsumer<VerificationBloc, VerificationState>(
        listener: (context, state) {
          if (state is VerificationSubmitSuccess) {
            setState(() => _showResubmitForm = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Documents submitted. We will review within 2 business days.'),
              ),
            );
            if (widget.isOnboarding) {
              // Let AuthBloc re-read the profile (now pending) so AuthGate
              // routes to HomeShell automatically.
              context.read<AuthBloc>().add(const AuthCheckRequested());
            } else {
              Navigator.pop(context);
            }
          }
          if (state is VerificationFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppTheme.errorColor,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is VerificationLoading) {
            return const LoadingIndicator(message: 'Loading…');
          }

          // Show status view if a submission exists and we're not re-submitting
          if (state is VerificationStatusLoaded &&
              state.status != VerificationStatus.unverified &&
              !_showResubmitForm) {
            return _buildStatusView(state);
          }

          return _buildSubmitForm();
        },
      ),
    );
  }

  Widget _buildStatusView(VerificationStatusLoaded state) {
    final statusText = switch (state.status.name) {
      'pending' => 'Your documents are under review.',
      'verified' => 'Your account has been verified.',
      'rejected' =>
        'Your submission was rejected. Please re-submit with clearer documents.',
      _ => 'Verification not started.',
    };

    final icon = switch (state.status.name) {
      'verified' => Icons.verified,
      'pending' => Icons.hourglass_top,
      'rejected' => Icons.cancel_outlined,
      _ => Icons.info_outline,
    };

    final color = switch (state.status.name) {
      'verified' => AppTheme.successColor,
      'pending' => AppTheme.warningColor,
      'rejected' => AppTheme.errorColor,
      _ => AppTheme.textSecondary,
    };

    return Padding(
      padding: const EdgeInsets.all(AppTheme.padding24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 72, color: color),
          const SizedBox(height: AppTheme.padding16),
          Text(statusText,
              textAlign: TextAlign.center, style: AppTheme.body),
          if (state.status.name == 'rejected') ...[
            if (state.rejectionReason != null) ...[
              const SizedBox(height: AppTheme.padding12),
              Text(
                'Reason: ${state.rejectionReason}',
                textAlign: TextAlign.center,
                style: AppTheme.caption.copyWith(color: AppTheme.errorColor),
              ),
            ],
            const SizedBox(height: AppTheme.padding24),
            CustomButton(
              text: 'Re-submit Documents',
              onPressed: () => setState(() => _showResubmitForm = true),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubmitForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.padding24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Submit Verification Documents', style: AppTheme.heading2),
          const SizedBox(height: AppTheme.padding8),
          Text(
            'Upload clear photos of your national ID, farm registration certificate, or business permit.',
            style: AppTheme.body.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: AppTheme.padding24),

          // Document list
          if (_selectedFiles.isNotEmpty) ...[
            Text('Selected documents:', style: AppTheme.caption),
            const SizedBox(height: AppTheme.padding8),
            ..._selectedFiles.asMap().entries.map(
                  (e) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.insert_drive_file_outlined),
                    title: Text(
                      e.value.path.split('/').last,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.close, color: AppTheme.errorColor),
                      onPressed: () => _removeFile(e.key),
                    ),
                  ),
                ),
            const SizedBox(height: AppTheme.padding16),
          ],

          CustomButton(
            text: 'Pick Documents',
            type: ButtonType.outlined,
            isFullWidth: true,
            leadingIcon: Icons.upload_file,
            onPressed: _pickDocuments,
          ),
          const SizedBox(height: AppTheme.padding16),
          CustomButton(
            text: 'Submit for Verification',
            isFullWidth: true,
            leadingIcon: Icons.send,
            onPressed: _selectedFiles.isEmpty ? null : _submit,
          ),
        ],
      ),
    );
  }
}
