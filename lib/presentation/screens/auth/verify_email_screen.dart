import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:brewmaster/config/theme.dart';
import 'package:brewmaster/data/providers/auth_provider.dart';
import 'package:brewmaster/data/providers/user_provider.dart';
import 'package:brewmaster/presentation/screens/auth/profile_setup_screen.dart';
import 'package:brewmaster/presentation/screens/profile/profile_screen.dart';

class VerifyEmailScreen extends StatefulWidget {
  final String email;
  const VerifyEmailScreen({super.key, required this.email});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen>
    with WidgetsBindingObserver {
  final _codeController = TextEditingController();
  bool _isProcessing = false;
  String? _message;
  
  // Resend cooldown to prevent Firebase rate limiting
  DateTime? _lastResendTime;
  static const _resendCooldownSeconds = 60;

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _codeController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Add lifecycle observer to detect when user returns from email
    WidgetsBinding.instance.addObserver(this);
    
    // Initial check when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _checkAndProceedIfVerified();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Check verification when user returns to app from email
    if (state == AppLifecycleState.resumed) {
      // ignore: avoid_print
      print('📱 App resumed - checking if email was verified...');
      _checkAndProceedIfVerified();
    }
  }

  Future<void> _checkAndProceedIfVerified() async {
    if (!mounted) return;
    
    try {
      final auth = context.read<AuthProvider>();
      final userProvider = context.read<UserProvider>();
      
      // Force refresh the current user to get latest email verification status
      // ignore: avoid_print
      print('🔄 Refreshing user...');
      await auth.refresh();
      
      // ignore: avoid_print
      print('📧 Checking email verification status...');
      final verified = await auth.checkEmailVerified();
      final email = auth.currentUser?.email;
      // ignore: avoid_print
      print('🔍 Check verification: emailVerified=$verified for $email');
      
      if (verified && mounted) {
        // ignore: avoid_print
        print('✅ Email is verified! Proceeding...');
        await _proceedAfterVerification(auth, userProvider);
      }
    } catch (e) {
      // ignore: avoid_print
      print('❌ Error in _checkAndProceedIfVerified: $e');
    }
  }

  Future<void> _proceedAfterVerification(
    AuthProvider auth,
    UserProvider userProvider,
  ) async {
    final user = auth.currentUser;
    if (user == null) {
      // ignore: avoid_print
      print('❌ No user found');
      return;
    }

    // ignore: avoid_print
    print('✅ Email verified, updating Firestore for user ${user.uid}');

    try {
      // Update the database to mark email as verified
      await userProvider.updateProfile(user.uid, {'isVerified': true});
      // ignore: avoid_print
      print('✅ Database updated: isVerified=true');

      final profile = await userProvider.fetchProfileQuietly(user.uid);
      // ignore: avoid_print
      print('📋 Profile fetched: ${profile?.displayName} (verified=${profile?.isVerified})');
      
      if (profile != null && mounted) {
        // Profile exists - go to profile screen
        // ignore: avoid_print
        print('➡️ Navigating to ProfileScreen');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ProfileScreen()),
        );
      } else if (mounted) {
        // No profile yet - go to profile setup
        // ignore: avoid_print
        print('➡️ Navigating to ProfileSetupScreen (no profile found)');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => ProfileSetupScreen(
              userId: user.uid,
              email: user.email ?? '',
              displayName: user.displayName ?? 'User',
              role: null,
            ),
          ),
        );
      }
    } catch (e) {
      // ignore: avoid_print
      print('❌ Error proceeding after verification: $e');
      if (mounted) {
        // On error, go to profile setup anyway
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => ProfileSetupScreen(
              userId: user.uid,
              email: user.email ?? '',
              displayName: user.displayName ?? 'User',
              role: null,
            ),
          ),
        );
      }
    }
  }

  Future<void> _resend() async {
    // Prevent rapid resends to avoid Firebase rate limiting
    if (_lastResendTime != null) {
      final secondsSinceLastResend =
          DateTime.now().difference(_lastResendTime!).inSeconds;
      if (secondsSinceLastResend < _resendCooldownSeconds) {
        final secondsRemaining =
            _resendCooldownSeconds - secondsSinceLastResend;
        setState(() {
          _message =
              'Please wait ${secondsRemaining}s before resending. Firebase rate-limits email sends.';
        });
        return;
      }
    }

    setState(() {
      _isProcessing = true;
      _message = null;
    });
    final auth = context.read<AuthProvider>();
    final ok = await auth.sendEmailVerification();
    setState(() {
      _isProcessing = false;
      _lastResendTime = DateTime.now();
      if (ok) {
        _message =
            'Verification email sent. Check your inbox (cooldown: 60 seconds).';
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
    final userProvider = context.read<UserProvider>();
    
    // Force refresh the current user to get latest email verification status
    await auth.refresh();
    final verified = await auth.checkEmailVerified();
    
    // debug log
    // ignore: avoid_print
    print(
      '🔍 checkVerified: email verified=$verified for ${auth.currentUser?.email}',
    );
    
    setState(() {
      _isProcessing = false;
    });
    
    if (verified && mounted) {
      await _proceedAfterVerification(auth, userProvider);
    } else if (mounted) {
      // if not verified or no user, show message
      setState(() {
        _message =
            'Email not verified yet. Please click the verification link in your email and return here.';
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
    final userProvider = context.read<UserProvider>();
    bool applied = false;
    try {
      applied = await auth.applyEmailActionCode(code);
      // ignore: avoid_print
      print('✅ Code applied successfully');
    } catch (e) {
      // ignore: avoid_print
      print('❌ Error applying code: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }

    if (applied) {
      // After applying code, verify and proceed
      // ignore: avoid_print
      print('ℹ️ Code applied, checking verification status...');
      await _checkAndProceedIfVerified();
    } else {
      // The code was rejected or there was an error
      // Still check if email is verified (user might have verified via email)
      await auth.refresh();
      final verified = await auth.checkEmailVerified();
      if (verified && mounted) {
        // ignore: avoid_print
        print('✅ Email is verified (via email link), proceeding...');
        await _proceedAfterVerification(auth, userProvider);
        return;
      }

      // Otherwise show error message
      if (mounted) {
        setState(() {
          _message = auth.errorMessage ??
              'Verification link invalid or expired. Please request a new one.';
        });
      }
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
                      onPressed:
                          (_isProcessing ||
                                  (_lastResendTime != null &&
                                      DateTime.now()
                                              .difference(_lastResendTime!)
                                              .inSeconds <
                                          _resendCooldownSeconds))
                              ? null
                              : _resend,
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
