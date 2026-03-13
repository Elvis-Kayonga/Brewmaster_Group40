import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:brewmaster/config/theme.dart';
import 'package:brewmaster/presentation/blocs/auth/auth_bloc.dart';
import 'package:brewmaster/presentation/widgets/common/custom_text_field.dart';
import 'package:brewmaster/presentation/widgets/common/custom_button.dart';
import 'signup_screen.dart';

/// Login screen with email/password and Google sign-in.
/// Navigation is handled entirely by [AuthGate] via [AuthBloc] state.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isBuyer = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleSignIn() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(AuthSignInRequested(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        ));
  }

  void _handleGoogleSignIn() {
    context.read<AuthBloc>().add(const AuthGoogleSignInRequested());
  }

  void _handleForgotPassword() {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email first.')),
      );
      return;
    }
    context.read<AuthBloc>().add(AuthPasswordResetRequested(email));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.padding24,
              vertical: AppTheme.padding32,
            ),
            child: BlocConsumer<AuthBloc, AuthState>(
              listener: (context, state) {
                if (state is AuthFailure) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: AppTheme.errorColor,
                    ),
                  );
                }
                if (state is AuthPasswordResetSent) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password reset email sent.'),
                      backgroundColor: AppTheme.successColor,
                    ),
                  );
                }
              },
              builder: (context, state) {
                final isLoading = state is AuthLoading;
                return Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // App logo
                      Center(
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.bolt,
                            color: Colors.white,
                            size: 44,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppTheme.padding24),

                      // Heading
                      const Text(
                        'Welcome Back',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppTheme.padding8),
                      const Text(
                        'Log in to your BrewMaster account.',
                        style: AppTheme.caption,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppTheme.padding32),

                      // Buyer / Seller role toggle
                      _RoleToggle(
                        isBuyer: _isBuyer,
                        onChanged: (isBuyer) =>
                            setState(() => _isBuyer = isBuyer),
                      ),
                      const SizedBox(height: AppTheme.padding24),

                      // Form card
                      Container(
                        padding: const EdgeInsets.all(AppTheme.padding24),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceColor,
                          borderRadius: BorderRadius.circular(
                              AppTheme.borderRadiusXLarge),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Email field
                            const Text('Email Address',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.textPrimary,
                                )),
                            const SizedBox(height: AppTheme.padding8),
                            EmailTextField(
                              controller: _emailController,
                              hintText: 'hello@example.com',
                              textInputAction: TextInputAction.next,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Email is required';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: AppTheme.padding16),

                            // Password field
                            const Text('Password',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.textPrimary,
                                )),
                            const SizedBox(height: AppTheme.padding8),
                            PasswordTextField(
                              controller: _passwordController,
                              textInputAction: TextInputAction.done,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Password is required';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: AppTheme.padding24),

                            // Sign in button
                            CustomButton(
                              text: _isBuyer
                                  ? 'Sign In as Buyer'
                                  : 'Sign In as Seller',
                              isFullWidth: true,
                              isLoading: isLoading,
                              onPressed: _handleSignIn,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppTheme.padding16),

                      // Forgot password
                      Center(
                        child: CustomButton(
                          text: 'Forgot password?',
                          type: ButtonType.text,
                          size: ButtonSize.small,
                          onPressed: _handleForgotPassword,
                        ),
                      ),
                      const SizedBox(height: AppTheme.padding8),

                      // OR divider + Google
                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppTheme.padding16),
                            child: Text('OR', style: AppTheme.caption),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: AppTheme.padding16),
                      CustomButton(
                        text: 'Sign in with Google',
                        type: ButtonType.outlined,
                        isFullWidth: true,
                        leadingIcon: Icons.g_mobiledata,
                        isLoading: isLoading,
                        onPressed: _handleGoogleSignIn,
                      ),
                      const SizedBox(height: AppTheme.padding24),

                      // Sign up link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account? ",
                            style: AppTheme.caption,
                          ),
                          GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SignupScreen(),
                              ),
                            ),
                            child: Text(
                              'Create one',
                              style: AppTheme.caption.copyWith(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.none,
                              ),
                            ),
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
      ),
    );
  }
}

/// Pill-shaped role toggle: Buyer ↔ Seller (or custom labels).
class _RoleToggle extends StatelessWidget {
  final bool isBuyer;
  final ValueChanged<bool> onChanged;

  const _RoleToggle({required this.isBuyer, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusXLarge),
      ),
      child: Row(
        children: [
          _Tab(
            label: 'Buyer',
            selected: isBuyer,
            onTap: () => onChanged(true),
          ),
          _Tab(
            label: 'Seller',
            selected: !isBuyer,
            onTap: () => onChanged(false),
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Tab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: selected ? AppTheme.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppTheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
