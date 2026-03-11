import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:brewmaster/config/theme.dart';
import 'package:brewmaster/presentation/blocs/auth/auth_bloc.dart';

/// Shown when a new email/password user needs to verify their email.
/// Polls Firebase every 3 seconds until emailVerified == true,
/// then dispatches [AuthCheckRequested] to let AuthGate re-route.
class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen>
    with WidgetsBindingObserver {
  Timer? _pollTimer;
  Timer? _cooldownTimer;
  int _cooldownSeconds = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startPolling();
    // Start with a cooldown so the initial send (done right after profile
    // creation) counts against the limit before the screen even appears.
    _startCooldown();
  }

  void _startCooldown() {
    setState(() => _cooldownSeconds = 60);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        _cooldownSeconds--;
        if (_cooldownSeconds <= 0) t.cancel();
      });
    });
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) {
        context.read<AuthBloc>().add(const AuthCheckRequested());
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When user returns to the app (e.g. after clicking verification link),
    // check immediately instead of waiting for the next timer tick.
    if (state == AppLifecycleState.resumed && mounted) {
      context.read<AuthBloc>().add(const AuthCheckRequested());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthVerificationEmailSent) {
          _startCooldown();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Verification email sent! Check your inbox.'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
        if (state is AuthFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
        // AuthAuthenticated / AuthNeedsProfile handled by AuthGate rebuild
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Verify Your Email'),
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.padding24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.mark_email_unread_outlined,
                  size: 80,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(height: AppTheme.padding24),
                Text(
                  'Check your inbox',
                  style: AppTheme.heading1,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.padding16),
                Text(
                  'We sent a verification link to your email address. '
                  'Click the link to verify, then come back — '
                  'this screen will update automatically.',
                  style: AppTheme.body,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.padding8),
                const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                const SizedBox(height: AppTheme.padding32),
                OutlinedButton(
                  onPressed: _cooldownSeconds > 0
                      ? null
                      : () => context
                          .read<AuthBloc>()
                          .add(const AuthVerificationEmailRequested()),
                  child: Text(_cooldownSeconds > 0
                      ? 'Resend in ${_cooldownSeconds}s'
                      : 'Resend Email'),
                ),
                const SizedBox(height: AppTheme.padding16),
                TextButton(
                  onPressed: () => context
                      .read<AuthBloc>()
                      .add(const AuthSignOutRequested()),
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
