import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:brewmaster/config/theme.dart';
import 'package:brewmaster/data/providers/auth_provider.dart';
import 'package:brewmaster/data/providers/user_provider.dart';
import 'package:brewmaster/presentation/widgets/common/custom_text_field.dart';
import 'package:brewmaster/presentation/widgets/common/custom_button.dart';
import 'package:brewmaster/presentation/widgets/common/error_state_widget.dart';
import 'signup_screen.dart';
import 'profile_setup_screen.dart';
import '../dashboard/dashboard_screen.dart';

/// Login screen with email/password and Google sign-in.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    if (!_formKey.currentState!.validate()) return;
    final authProvider = context.read<AuthProvider>();
    final nav = Navigator.of(context);
    final success = await authProvider.signIn(
      _emailController.text.trim(),
      _passwordController.text,
    );
    if (success && mounted) {
      final user = authProvider.currentUser;
      // capture providers/navigator before any awaits to satisfy lint
      final userProvider = context.read<UserProvider>();
      if (user != null) {
        // Check if profile exists
        try {
          final profile = await userProvider.fetchProfileQuietly(user.uid);
          if (profile != null) {
            // Profile exists - go to dashboard
            nav.pushReplacement(
              MaterialPageRoute(builder: (_) => const DashboardScreen()),
            );
          } else {
            // Profile doesn't exist - go to profile setup
            nav.pushReplacement(
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
          // On error, assume new user and go to profile setup
          nav.pushReplacement(
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
  }

  Future<void> _handleGoogleSignIn() async {
    final authProvider = context.read<AuthProvider>();
    final nav = Navigator.of(context);
    final success = await authProvider.signInWithGoogle();
    if (success && mounted) {
      final user = authProvider.currentUser;
      if (user != null) {
        // Google accounts are treated as verified, no email check needed.
        // Check if profile exists
        final userProvider = context.read<UserProvider>();
        try {
          final profile = await userProvider.fetchProfileQuietly(user.uid);
          if (profile != null) {
            // Profile exists - go to dashboard
            nav.pushReplacement(
              MaterialPageRoute(builder: (_) => const DashboardScreen()),
            );
          } else {
            // Profile doesn't exist - go to profile setup
            nav.pushReplacement(
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
          // On error, assume new user and go to profile setup
          nav.pushReplacement(
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
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email first.')),
      );
      return;
    }
    final authProvider = context.read<AuthProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final sent = await authProvider.sendPasswordResetEmail(email);
    if (sent && mounted) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Password reset email sent.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.padding24),
            child: Consumer<AuthProvider>(
              builder: (context, auth, _) {
                return Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      Icon(
                        Icons.coffee,
                        size: AppTheme.iconSizeXLarge * 1.5,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(height: AppTheme.padding16),
                      Text(
                        'Welcome to BrewMaster',
                        style: AppTheme.heading1,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppTheme.padding8),
                      Text(
                        'Sign in to continue',
                        style: AppTheme.caption,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppTheme.padding32),

                      // Error banner
                      if (auth.errorMessage != null) ...[
                        ErrorBanner(
                          message: auth.errorMessage!,
                          onDismiss: auth.clearError,
                        ),
                        const SizedBox(height: AppTheme.padding16),
                      ],

                      // Email field
                      EmailTextField(
                        controller: _emailController,
                        labelText: 'Email',
                        hintText: 'Enter your email',
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
                      PasswordTextField(
                        controller: _passwordController,
                        labelText: 'Password',
                        textInputAction: TextInputAction.done,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Password is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppTheme.padding8),

                      // Forgot password
                      Align(
                        alignment: Alignment.centerRight,
                        child: CustomButton(
                          text: 'Forgot password?',
                          type: ButtonType.text,
                          size: ButtonSize.small,
                          onPressed: _handleForgotPassword,
                        ),
                      ),
                      const SizedBox(height: AppTheme.padding24),

                      // Sign in button
                      CustomButton(
                        text: 'Sign In',
                        isFullWidth: true,
                        isLoading: auth.isLoading,
                        onPressed: _handleSignIn,
                      ),
                      const SizedBox(height: AppTheme.padding16),

                      // Divider
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

                      // Google sign-in button
                      CustomButton(
                        text: 'Sign in with Google',
                        type: ButtonType.outlined,
                        isFullWidth: true,
                        leadingIcon: Icons.g_mobiledata,
                        isLoading: auth.isLoading,
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
                          CustomButton(
                            text: 'Sign Up',
                            type: ButtonType.text,
                            size: ButtonSize.small,
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const SignupScreen(),
                                ),
                              );
                            },
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
