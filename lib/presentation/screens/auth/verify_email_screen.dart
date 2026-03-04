import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:brewmaster/config/theme.dart';
import 'package:brewmaster/data/providers/auth_provider.dart';
import 'package:brewmaster/presentation/screens/auth/profile_setup_screen.dart';

class VerifyEmailScreen extends StatefulWidget {
  final String email;
  const VerifyEmailScreen({super.key, required this.email});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _codeController = TextEditingController();
  bool _isProcessing = false;
  String? _message;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // if the user somehow navigated here but their email is already
    // verified (e.g. they signed in with Google or clicked the link
    // externally) then we can skip the screen and proceed to profile
    // setup immediately.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = context.read<AuthProvider>();
      final verified = await auth.checkEmailVerified();
      if (verified && mounted) {
        final user = auth.currentUser;
        if (user != null) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => ProfileSetupScreen(
                userId: user.uid,
                email: user.email ?? widget.email,
                displayName: user.displayName ?? '',
                role: null,
              ),
            ),
          );
        }
      }
    });
  }

  Future<void> _resend() async {
    setState(() {
      _isProcessing = true;
      _message = null;
    });
    final auth = context.read<AuthProvider>();
    final ok = await auth.sendEmailVerification();
    setState(() {
      _isProcessing = false;
      if (ok) {
        _message = 'Verification email sent.';
      } else {
        // show any error message or default info
        _message =
            auth.errorMessage ??
            'No email sent. It may already be verified or you are not signed in.';
      }
    });
  }

  Future<void> _checkVerified() async {
    setState(() {
      _isProcessing = true;
      _message = null;
    });
    final auth = context.read<AuthProvider>();
    final verified = await auth.checkEmailVerified();
    // debug log
    // ignore: avoid_print
    print(
      '🔍 checkVerified returned $verified for user ${auth.currentUser?.email}',
    );
    setState(() {
      _isProcessing = false;
    });
    if (verified && mounted) {
      final user = auth.currentUser;
      if (user != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => ProfileSetupScreen(
              userId: user.uid,
              email: user.email ?? widget.email,
              displayName: user.displayName ?? '',
              role: null,
            ),
          ),
        );
      }
    } else {
      setState(() {
        _message =
            'Email not verified yet. Please check your inbox (or sign out and back in if you already clicked the link).';
      });
    }
  }

  Future<void> _applyCode() async {
    final raw = _codeController.text.trim();
    if (raw.isEmpty) return;
    // attempt to extract oobCode if a full link was pasted
    String code = raw;
    final uri = Uri.tryParse(raw);
    if (uri != null && uri.queryParameters.containsKey('oobCode')) {
      code = uri.queryParameters['oobCode']!;
    }

    setState(() {
      _isProcessing = true;
      _message = null;
    });

    final auth = context.read<AuthProvider>();
    bool applied = false;
    try {
      applied = await auth.applyEmailActionCode(code);
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }

    if (applied) {
      // After applying, re-check verification and navigate if successful.
      await _checkVerified();
    } else {
      // The code was rejected.  It may already have been used or expired
      // (which is normal if the user clicked the link in a browser).  Even
      // if the code failed, the email might still be marked verified by the
      // time we reach here, so check again and navigate.
      final verified = await auth.checkEmailVerified();
      if (verified && mounted) {
        final user = auth.currentUser;
        if (user != null) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => ProfileSetupScreen(
                userId: user.uid,
                email: user.email ?? widget.email,
                displayName: user.displayName ?? '',
                role: null,
              ),
            ),
          );
          return;
        }
      }

      // Otherwise show the underlying message (mapped through AuthProvider).
      setState(() {
        _message = auth.errorMessage ?? 'Failed to apply code.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify Your Email')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.padding24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('We sent a verification email to:', style: AppTheme.caption),
              const SizedBox(height: AppTheme.padding8),
              Text(widget.email, style: AppTheme.heading2),
              const SizedBox(height: AppTheme.padding24),
              Text(
                'Please open the email and click the verification link. When done, come back and tap "I have verified". If you pasted the link instead, you can paste it below and press "Apply".',
                style: AppTheme.body,
              ),
              const SizedBox(height: AppTheme.padding24),

              TextField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: 'Paste verification link or code',
                ),
              ),
              const SizedBox(height: AppTheme.padding16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isProcessing ? null : _applyCode,
                      child: _isProcessing
                          ? const CircularProgressIndicator()
                          : const Text('Apply'),
                    ),
                  ),
                  const SizedBox(width: AppTheme.padding16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isProcessing ? null : _resend,
                      child: const Text('Resend'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.padding16),
              ElevatedButton(
                onPressed: _isProcessing ? null : _checkVerified,
                child: const Text("I've verified"),
              ),
              const SizedBox(height: AppTheme.padding16),
              if (_message != null) ...[
                Text(_message!, style: AppTheme.caption),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
