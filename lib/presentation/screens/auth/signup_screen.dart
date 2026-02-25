import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:brewmaster/config/theme.dart';
import 'package:brewmaster/data/providers/auth_provider.dart';
import 'package:brewmaster/domain/models/enums.dart';
import 'package:brewmaster/presentation/widgets/common/custom_text_field.dart';
import 'package:brewmaster/presentation/widgets/common/custom_button.dart';
import 'package:brewmaster/presentation/widgets/common/custom_dropdown.dart';
import 'package:brewmaster/presentation/widgets/common/error_state_widget.dart';

/// Sign-up screen with a 3-step registration flow.
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

  int _currentStep = 0;
  UserRole? _selectedRole;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _formKey.currentState!.validate();
      case 1:
        if (_selectedRole == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a role.')),
          );
          return false;
        }
        return true;
      case 2:
        return _formKey.currentState!.validate();
      default:
        return false;
    }
  }

  void _nextStep() {
    if (!_validateCurrentStep()) return;
    setState(() => _currentStep++);
  }

  void _previousStep() {
    setState(() => _currentStep--);
  }

  Future<void> _handleSignUp() async {
    if (!_validateCurrentStep()) return;
    final authProvider = context.read<AuthProvider>();
    await authProvider.signUp(
      _emailController.text.trim(),
      _passwordController.text,
    );
  }

  Future<void> _handleGoogleSignUp() async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.signInWithGoogle();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _previousStep,
              )
            : null,
      ),
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
                    // Step indicator
                    _buildStepIndicator(),
                    const SizedBox(height: AppTheme.padding24),

                    // Error banner
                    if (auth.errorMessage != null) ...[
                      ErrorBanner(
                        message: auth.errorMessage!,
                        onDismiss: auth.clearError,
                      ),
                      const SizedBox(height: AppTheme.padding16),
                    ],

                    // Step content
                    if (_currentStep == 0) _buildEmailPasswordStep(),
                    if (_currentStep == 1) _buildRoleSelectionStep(),
                    if (_currentStep == 2) _buildDisplayNameStep(auth),

                    const SizedBox(height: AppTheme.padding32),

                    // Navigation buttons
                    if (_currentStep < 2)
                      CustomButton(
                        text: 'Next',
                        isFullWidth: true,
                        onPressed: _nextStep,
                      )
                    else
                      CustomButton(
                        text: 'Sign Up',
                        isFullWidth: true,
                        isLoading: auth.isLoading,
                        onPressed: _handleSignUp,
                      ),

                    // Google sign-up (step 0 only)
                    if (_currentStep == 0) ...[
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
                    ],

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

  Widget _buildStepIndicator() {
    return Row(
      children: List.generate(3, (index) {
        final isActive = index <= _currentStep;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: index < 2 ? AppTheme.padding8 : 0),
            height: 4,
            decoration: BoxDecoration(
              color: isActive ? AppTheme.primaryColor : AppTheme.textHint,
              borderRadius: AppTheme.borderRadiusSmallAll,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildEmailPasswordStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Step 1: Email & Password', style: AppTheme.heading2),
        const SizedBox(height: AppTheme.padding24),
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
      ],
    );
  }

  Widget _buildRoleSelectionStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Step 2: Select Your Role', style: AppTheme.heading2),
        const SizedBox(height: AppTheme.padding8),
        Text('Choose how you want to use BrewMaster.', style: AppTheme.caption),
        const SizedBox(height: AppTheme.padding24),
        CustomDropdown<UserRole>(
          items: const [
            DropdownItem(
              value: UserRole.farmer,
              label: 'Farmer',
              icon: Icons.agriculture,
            ),
            DropdownItem(
              value: UserRole.buyer,
              label: 'Buyer',
              icon: Icons.shopping_bag,
            ),
          ],
          value: _selectedRole,
          onChanged: (role) => setState(() => _selectedRole = role),
          labelText: 'Role',
          hintText: 'Select your role',
          prefixIcon: Icons.person_outline,
        ),
      ],
    );
  }

  Widget _buildDisplayNameStep(AuthProvider auth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Step 3: Your Name', style: AppTheme.heading2),
        const SizedBox(height: AppTheme.padding8),
        Text('How should we address you?', style: AppTheme.caption),
        const SizedBox(height: AppTheme.padding24),
        CustomTextField(
          controller: _displayNameController,
          labelText: 'Display Name',
          hintText: 'Enter your name',
          prefixIcon: Icons.person_outline,
          textInputAction: TextInputAction.done,
          textCapitalization: TextCapitalization.words,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Display name is required';
            }
            if (value.trim().length < 2) {
              return 'Name must be at least 2 characters';
            }
            return null;
          },
        ),
      ],
    );
  }
}
