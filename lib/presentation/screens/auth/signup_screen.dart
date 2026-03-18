import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:brewmaster/config/theme.dart';
import 'package:brewmaster/domain/models/enums.dart';
import 'package:brewmaster/presentation/blocs/auth/auth_bloc.dart';
import 'package:brewmaster/presentation/widgets/common/custom_text_field.dart';
import 'package:brewmaster/presentation/widgets/common/custom_button.dart';
import 'package:brewmaster/utils/password_validator.dart';

/// Sign-up screen. Navigation after register is handled by [AuthGate].
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
  PasswordStrength _passwordStrength = PasswordStrength.none;
  bool _isBuyer = true;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(() {
      setState(() {
        _passwordStrength =
            PasswordValidator.getStrength(_passwordController.text);
      });
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  void _handleSignUp() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.read<AuthBloc>().add(AuthRegisterRequested(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          displayName: _displayNameController.text.trim(),
          role: _isBuyer ? UserRole.buyer : UserRole.farmer,
        ));
  }

  void _handleGoogleSignUp() {
    context.read<AuthBloc>().add(const AuthGoogleSignInRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
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
              } else if (state is AuthNeedsProfile ||
                  state is AuthEmailNotVerified ||
                  state is AuthAuthenticated) {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              }
            },
            builder: (context, state) {
              final isLoading = state is AuthLoading;
              return Form(
                key: _formKey,
                child: Column(
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
                          Icons.person_add_outlined,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.padding24),

                    // Heading
                    const Text(
                      'Join BrewMaster',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppTheme.padding8),
                    const Text(
                      'Choose your role and start your journey.',
                      style: AppTheme.caption,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppTheme.padding32),

                    // Buy / Sell role toggle
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
                          // Full Name
                          const Text('Full Name',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textPrimary,
                              )),
                          const SizedBox(height: AppTheme.padding8),
                          CustomTextField(
                            controller: _displayNameController,
                            hintText: 'Coffee enthusiast',
                            prefixIcon: Icons.person_outline,
                            validator: (v) =>
                                v == null || v.trim().isEmpty
                                    ? 'Name is required'
                                    : null,
                          ),
                          const SizedBox(height: AppTheme.padding16),

                          // Email
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
                              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                                  .hasMatch(value.trim())) {
                                return 'Enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppTheme.padding16),

                          // Password
                          const Text('Password',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textPrimary,
                              )),
                          const SizedBox(height: AppTheme.padding8),
                          PasswordTextField(
                            controller: _passwordController,
                            textInputAction: TextInputAction.next,
                            validator: (value) =>
                                PasswordValidator.validate(value),
                          ),
                          const SizedBox(height: AppTheme.padding8),
                          _buildPasswordStrengthIndicator(),
                          const SizedBox(height: AppTheme.padding16),

                          // Confirm password
                          const Text('Confirm Password',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textPrimary,
                              )),
                          const SizedBox(height: AppTheme.padding8),
                          PasswordTextField(
                            controller: _confirmPasswordController,
                            textInputAction: TextInputAction.done,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please confirm your password';
                              }
                              if (value != _passwordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppTheme.padding24),

                          // Sign up button
                          CustomButton(
                            text: _isBuyer
                                ? 'Sign up as Buyer'
                                : 'Sign up as Seller',
                            isFullWidth: true,
                            isLoading: isLoading,
                            onPressed: _handleSignUp,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppTheme.padding16),

                    // OR + Google
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
                      text: 'Sign up with Google',
                      type: ButtonType.outlined,
                      isFullWidth: true,
                      leadingIcon: Icons.g_mobiledata,
                      isLoading: isLoading,
                      onPressed: _handleGoogleSignUp,
                    ),
                    const SizedBox(height: AppTheme.padding24),

                    // Sign in link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Already have an account? ',
                            style: AppTheme.caption),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Text(
                            'Sign In',
                            style: AppTheme.caption.copyWith(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w600,
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
    );
  }

  Widget _buildPasswordStrengthIndicator() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _passwordStrength.index /
                      PasswordStrength.values.length,
                  minHeight: 6,
                  backgroundColor: AppTheme.inputFillColor,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _passwordStrength.color,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppTheme.padding8),
            Text(
              _passwordStrength.label,
              style: AppTheme.caption.copyWith(
                color: _passwordStrength.color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

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
            label: 'I want to buy',
            selected: isBuyer,
            onTap: () => onChanged(true),
          ),
          _Tab(
            label: 'I want to sell',
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
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppTheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
