import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:brewmaster/config/theme.dart';
import 'package:brewmaster/data/providers/user_provider.dart';
import 'package:brewmaster/domain/models/enums.dart';
import 'package:brewmaster/presentation/widgets/common/custom_button.dart';
import 'package:brewmaster/presentation/widgets/common/loading_indicator.dart';
import 'package:brewmaster/presentation/widgets/common/error_state_widget.dart';
import 'package:brewmaster/presentation/widgets/common/status_badge.dart';
import 'package:brewmaster/presentation/screens/profile/edit_profile_screen.dart';
import 'package:brewmaster/presentation/screens/auth/login_screen.dart';
import 'package:brewmaster/data/providers/auth_provider.dart';
import 'package:brewmaster/presentation/screens/dashboard/dashboard_screen.dart';
import 'package:brewmaster/presentation/screens/auth/verify_email_screen.dart';

/// Profile screen displaying user information.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _hasPrompted = false;
  UserProvider? _userProvider;

  StatusBadgeType _verificationBadgeType(VerificationStatus status) {
    switch (status) {
      case VerificationStatus.verified:
        return StatusBadgeType.success;
      case VerificationStatus.pending:
        return StatusBadgeType.pending;
      case VerificationStatus.rejected:
        return StatusBadgeType.error;
      case VerificationStatus.unverified:
        return StatusBadgeType.neutral;
    }
  }

  void _onUserProviderChanged() {
    if (!_hasPrompted) _maybePromptResend();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final up = Provider.of<UserProvider>(context);
    if (_userProvider != up) {
      _userProvider?.removeListener(_onUserProviderChanged);
      _userProvider = up;
      _userProvider?.addListener(_onUserProviderChanged);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybePromptResend());
  }

  @override
  void dispose() {
    _userProvider?.removeListener(_onUserProviderChanged);
    super.dispose();
  }

  Future<void> _maybePromptResend() async {
    final profile = _userProvider?.userProfile;
    if (profile == null) return;
    if (profile.verificationStatus != VerificationStatus.unverified) return;
    if (_hasPrompted) return;
    _hasPrompted = true;

    // Auto-resend once (no prompt)
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final ok = await auth.sendEmailVerification();
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => VerifyEmailScreen(email: profile.email),
        ),
      );
    } else {
      final msg = auth.errorMessage ?? 'Failed to send verification email.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            tooltip: 'Dashboard',
            icon: const Icon(Icons.dashboard),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const DashboardScreen()),
              );
            },
          ),
        ],
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, _) {
          if (userProvider.isLoading) {
            return const LoadingIndicator(message: 'Loading profile...');
          }

          if (userProvider.errorMessage != null) {
            return ErrorStateWidget(
              message: userProvider.errorMessage!,
              onRetry: () {
                final profile = userProvider.userProfile;
                if (profile != null) {
                  userProvider.loadProfile(profile.id);
                }
              },
            );
          }

          final profile = userProvider.userProfile;
          if (profile == null) {
            return const ErrorStateWidget(
              message: 'No profile found.',
              icon: Icons.person_off_outlined,
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.padding24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar and name
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundColor: AppTheme.primaryLight,
                        backgroundImage: profile.photoUrl != null
                            ? NetworkImage(profile.photoUrl!)
                            : null,
                        child: profile.photoUrl == null
                            ? Text(
                                profile.displayName.isNotEmpty
                                    ? profile.displayName[0].toUpperCase()
                                    : '?',
                                style: AppTheme.heading1.copyWith(
                                  color: AppTheme.onPrimaryColor,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(height: AppTheme.padding12),
                      Text(profile.displayName, style: AppTheme.heading1),
                      const SizedBox(height: AppTheme.padding4),
                      Text(profile.email, style: AppTheme.caption),
                      const SizedBox(height: AppTheme.padding8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          StatusBadge(
                            label: profile.role == UserRole.farmer
                                ? 'Farmer'
                                : 'Buyer',
                            type: StatusBadgeType.info,
                            icon: profile.role == UserRole.farmer
                                ? Icons.agriculture
                                : Icons.shopping_bag,
                          ),
                          const SizedBox(width: AppTheme.padding8),
                          StatusBadge(
                            label: profile.verificationStatus.name,
                            type: _verificationBadgeType(
                              profile.verificationStatus,
                            ),
                            showIndicator: true,
                          ),
                          const SizedBox(width: AppTheme.padding8),
                          // If user is unverified, offer a button to resend verification
                          if (profile.verificationStatus ==
                              VerificationStatus.unverified)
                            TextButton.icon(
                              icon: const Icon(Icons.verified_user_outlined),
                              label: const Text('Verify Email'),
                              onPressed: () async {
                                final auth = Provider.of<AuthProvider>(
                                  context,
                                  listen: false,
                                );
                                final ok = await auth.sendEmailVerification();
                                if (ok && context.mounted) {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => VerifyEmailScreen(
                                        email: profile.email,
                                      ),
                                    ),
                                  );
                                } else if (context.mounted) {
                                  final msg =
                                      auth.errorMessage ??
                                      'Failed to send verification email.';
                                  ScaffoldMessenger.of(
                                    context,
                                  ).showSnackBar(SnackBar(content: Text(msg)));
                                }
                              },
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.padding32),
                const Divider(),
                const SizedBox(height: AppTheme.padding16),

                // Role-specific details
                if (profile.role == UserRole.farmer) ...[
                  Text('Farm Details', style: AppTheme.heading2),
                  const SizedBox(height: AppTheme.padding16),
                  _buildInfoRow(
                    Icons.landscape,
                    'Farm Size',
                    profile.farmSize != null
                        ? '${profile.farmSize} hectares'
                        : 'Not set',
                  ),
                  _buildInfoRow(
                    Icons.location_on_outlined,
                    'Location',
                    profile.farmLocation ?? 'Not set',
                  ),
                  _buildInfoRow(
                    Icons.coffee,
                    'Coffee Varieties',
                    profile.coffeeVarieties?.join(', ') ?? 'Not set',
                  ),
                  _buildInfoRow(
                    Icons.badge_outlined,
                    'Registration No.',
                    profile.farmRegistrationNumber ?? 'Not set',
                  ),
                ],

                if (profile.role == UserRole.buyer) ...[
                  Text('Business Details', style: AppTheme.heading2),
                  const SizedBox(height: AppTheme.padding16),
                  _buildInfoRow(
                    Icons.business,
                    'Business Name',
                    profile.businessName ?? 'Not set',
                  ),
                  _buildInfoRow(
                    Icons.category_outlined,
                    'Business Type',
                    profile.businessType ?? 'Not set',
                  ),
                  _buildInfoRow(
                    Icons.scale,
                    'Monthly Volume',
                    profile.monthlyVolume != null
                        ? '${profile.monthlyVolume} kg'
                        : 'Not set',
                  ),
                ],

                const SizedBox(height: AppTheme.padding32),

                // Edit profile button
                CustomButton(
                  text: 'Edit Profile',
                  type: ButtonType.outlined,
                  isFullWidth: true,
                  leadingIcon: Icons.edit,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditProfileScreen(userProfile: profile),
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppTheme.padding16),
                // Sign out link
                Center(
                  child: TextButton.icon(
                    icon: const Icon(Icons.logout),
                    label: const Text('Sign out'),
                    onPressed: () async {
                      final auth = Provider.of<AuthProvider>(
                        context,
                        listen: false,
                      );
                      // capture navigator before the async gap
                      final navigator = Navigator.of(context);
                      await auth.signOut();
                      if (!mounted) return;
                      // after logout, send user to login page and clear stack
                      navigator.pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (r) => false,
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.padding12),
      child: Row(
        children: [
          Icon(
            icon,
            size: AppTheme.iconSizeMedium,
            color: AppTheme.textSecondary,
          ),
          const SizedBox(width: AppTheme.padding12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTheme.caption),
                const SizedBox(height: 2),
                Text(value, style: AppTheme.body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
