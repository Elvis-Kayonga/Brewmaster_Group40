import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:brewmaster/config/theme.dart';
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
        ));
  }

  void _handleGoogleSignUp() {
    context.read<AuthBloc>().add(const AuthGoogleSignInRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.padding24),
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
                // Pop SignupScreen so AuthGate's updated content becomes visible.
                // canPop() guard prevents double-pop if both the manual
                // _AuthUserChanged dispatch and the stream fire.
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
                    ..._buildEmailPasswordStep(),
                    const SizedBox(height: AppTheme.padding16),
                    CustomTextField(
                      controller: _displayNameController,
                      labelText: 'Display name',
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: AppTheme.padding32),
                    CustomButton(
                      text: 'Sign Up',
                      isFullWidth: true,
                      isLoading: isLoading,
                      onPressed: _handleSignUp,
                    ),
                    const SizedBox(height: AppTheme.padding16),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Already have an account? ',
                            style: AppTheme.caption),
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
          if (value == null || value.trim().isEmpty) return 'Email is required';
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
        validator: (value) => PasswordValidator.validate(value),
      ),
      const SizedBox(height: AppTheme.padding8),
      _buildPasswordStrengthIndicator(),
      const SizedBox(height: AppTheme.padding16),
      PasswordTextField(
        controller: _confirmPasswordController,
        labelText: 'Confirm Password',
        textInputAction: TextInputAction.done,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please confirm your password';
          }
          if (value != _passwordController.text) return 'Passwords do not match';
          return null;
        },
      ),
    ];
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
                  minHeight: 8,
                  backgroundColor: Colors.grey[300],
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
        const SizedBox(height: AppTheme.padding8),
        Text('Requirements:',
            style: AppTheme.caption.copyWith(fontWeight: FontWeight.w600)),
        _buildRequirement(
            'At least 8 characters', _passwordController.text.length >= 8),
        _buildRequirement('Uppercase letter (A-Z)',
            _passwordController.text.contains(RegExp(r'[A-Z]'))),
        _buildRequirement('Lowercase letter (a-z)',
            _passwordController.text.contains(RegExp(r'[a-z]'))),
        _buildRequirement(
            'Number (0-9)', _passwordController.text.contains(RegExp(r'[0-9]'))),
        _buildRequirement(
            'Special character (!@#\$%^&*)', _hasSpecialCharacter()),
      ],
    );
  }

  bool _hasSpecialCharacter() {
    const specialChars = '!@#\$%^&*()_+-=[]{}:;\'",.<>?/\\|`~';
    return _passwordController.text
        .split('')
        .any((char) => specialChars.contains(char));
  }

  Widget _buildRequirement(String text, bool met) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.padding4),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 16,
            color: met ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: AppTheme.padding8),
          Text(
            text,
            style: AppTheme.body.copyWith(
              color: met ? Colors.green : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
