import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:brewmaster/config/theme.dart';
import 'package:brewmaster/data/providers/auth_provider.dart';
import 'package:brewmaster/domain/models/enums.dart';
import 'package:brewmaster/presentation/widgets/common/custom_text_field.dart';
import 'package:brewmaster/presentation/widgets/common/custom_button.dart';
import 'package:brewmaster/presentation/widgets/common/custom_dropdown.dart';
import 'package:brewmaster/presentation/widgets/common/error_state_widget.dart';
import 'package:brewmaster/presentation/screens/auth/profile_setup_screen.dart';
import 'package:brewmaster/presentation/screens/auth/verify_email_screen.dart';

/// Sign-up screen collecting email, password and display name in a single step.
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _displayNameController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  bool _validateInputs() {
    return _formKey.currentState?.validate() ?? false;
  }

  Future<void> _handleSignUp() async {
    if (!_validateInputs()) return;
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.signUp(
      _emailController.text.trim(),
      _passwordController.text,
    );
    if (success && mounted) {
      final user = authProvider.currentUser;
      if (user != null) {
        // Send verification email in background, but navigate directly to
        // profile setup so the UX matches Google sign-up.
        await authProvider.sendEmailVerification();
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => ProfileSetupScreen(
              userId: user.uid,
              email: user.email ?? '',
              displayName: _displayNameController.text.trim().isNotEmpty
                  ? _displayNameController.text.trim()
                  : (user.displayName ?? ''),
              role: null,
            ),
          ),
        );
      }
    }
  }

  Future<void> _handleGoogleSignUp() async {
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.signInWithGoogle();
    if (success && mounted) {
      final user = authProvider.currentUser;
      if (user != null) {
        // Google sign-ins are implicitly trusted; even if Firebase reports
        // emailVerified==false the address belongs to Google so we'll treat it
        // as verified and skip the separate email flow.
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => ProfileSetupScreen(
              userId: user.uid,
              email: user.email ?? '',
              displayName: user.displayName ?? '',
              role: null,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.padding24),
          child: Consumer<AuthProvider>(
            builder: (context, auth, _) {
              return Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Error banner
                    if (auth.errorMessage != null) ...[
                      ErrorBanner(
                        message: auth.errorMessage!,
                        onDismiss: auth.clearError,
                      ),
                      const SizedBox(height: AppTheme.padding16),
                    ],

                    // Single-step inputs
                    ..._buildEmailPasswordStep(),
                    const SizedBox(height: AppTheme.padding16),
                    CustomTextField(
                      controller: _displayNameController,
                      labelText: 'Display name',
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                    ),

                    const SizedBox(height: AppTheme.padding32),

                    // Sign up button
                    CustomButton(
                      text: 'Sign Up',
                      isFullWidth: true,
                      isLoading: auth.isLoading,
                      onPressed: _handleSignUp,
                    ),

                    // Google sign-up
                    const SizedBox(height: AppTheme.padding16),
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.padding16,
                          ),
                          child: Text('OR', style: AppTheme.caption),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: AppTheme.padding16),
                    CustomButton(
                      text: 'Sign up with Google',
                      type: ButtonType.outlined,
                      isFullWidth: true,
                      leadingIcon: Icons.g_mobiledata,
                      isLoading: auth.isLoading,
                      onPressed: _handleGoogleSignUp,
                    ),

                    const SizedBox(height: AppTheme.padding24),

                    // Sign in link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: AppTheme.caption,
                        ),
                        CustomButton(
                          text: 'Sign In',
                          type: ButtonType.text,
                          size: ButtonSize.small,
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
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

  List<Widget> _buildEmailPasswordStep() {
    return [
      EmailTextField(
        controller: _emailController,
        labelText: 'Email',
        hintText: 'Enter your email',
        textInputAction: TextInputAction.next,
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Email is required';
          }
          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value.trim())) {
            return 'Enter a valid email';
          }
          return null;
        },
      ),
      const SizedBox(height: AppTheme.padding16),
      PasswordTextField(
        controller: _passwordController,
        labelText: 'Password',
        textInputAction: TextInputAction.next,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Password is required';
          }
          if (value.length < 6) {
            return 'Password must be at least 6 characters';
          }
          return null;
        },
      ),
      const SizedBox(height: AppTheme.padding16),
      PasswordTextField(
        controller: _confirmPasswordController,
        labelText: 'Confirm Password',
        textInputAction: TextInputAction.done,
        validator: (value) {
          if (value != _passwordController.text) {
            return 'Passwords do not match';
          }
          return null;
        },
      ),
    ];
  }
}
