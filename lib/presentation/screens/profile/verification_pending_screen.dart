// Feature: brewmaster-verification
// Shown while the user's KYC documents are under admin review.
// Polls AuthBloc every 30 seconds; AuthGate re-routes automatically
// when the status changes to verified or rejected.
//
// Requirements: 7.2, 7.3
// Developer: Developer 1

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../config/theme.dart';
import '../../../domain/models/enums.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/verification/verification_bloc.dart';

class VerificationPendingScreen extends StatefulWidget {
  const VerificationPendingScreen({super.key});

  @override
  State<VerificationPendingScreen> createState() =>
      _VerificationPendingScreenState();
}

class _VerificationPendingScreenState extends State<VerificationPendingScreen> {
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();

    // Start the real-time Firestore stream so VerificationBloc fires when an
    // admin changes verifications/{userId}.state.
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthKycPending) {
      context
          .read<VerificationBloc>()
          .add(VerificationStatusLoadRequested(authState.profile.id));
    }

    // Fallback poll every 30 seconds in case the stream misses an update.
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) context.read<AuthBloc>().add(const AuthCheckRequested());
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<VerificationBloc, VerificationState>(
      listenWhen: (_, state) =>
          state is VerificationStatusLoaded &&
          state.status != VerificationStatus.pending,
      listener: (context, _) {
        // Status changed (verified or rejected) — re-check auth so AuthGate
        // routes to HomeShell or back to the resubmit form.
        context.read<AuthBloc>().add(const AuthCheckRequested());
      },
      child: Scaffold(
      appBar: AppBar(
        title: const Text('Verification Pending'),
        automaticallyImplyLeading: false,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.padding24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.hourglass_top_rounded,
                size: 80,
                color: AppTheme.warningColor,
              ),
              const SizedBox(height: AppTheme.padding24),
              Text(
                'Documents Under Review',
                style: AppTheme.heading1,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.padding16),
              Text(
                'Your verification documents have been submitted and are currently '
                'being reviewed by our team.',
                style: AppTheme.body,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.padding16),
              Container(
                padding: const EdgeInsets.all(AppTheme.padding16),
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.warningColor.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.email_outlined, color: AppTheme.warningColor),
                    const SizedBox(height: AppTheme.padding8),
                    Text(
                      'You will receive an email notification once your verification '
                      'is approved or if further action is required.',
                      style: AppTheme.caption.copyWith(color: AppTheme.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.padding16),
              Text(
                'This usually takes 1–2 business days.',
                style: AppTheme.caption.copyWith(color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.padding8),
              const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              const SizedBox(height: AppTheme.padding32),
              OutlinedButton(
                onPressed: () =>
                    context.read<AuthBloc>().add(const AuthCheckRequested()),
                child: const Text('Check Status'),
              ),
              const SizedBox(height: AppTheme.padding16),
              TextButton(
                onPressed: () =>
                    context.read<AuthBloc>().add(const AuthSignOutRequested()),
                child: const Text('Sign Out'),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

