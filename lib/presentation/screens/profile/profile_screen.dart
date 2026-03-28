import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:brewmaster/config/theme.dart';
import 'package:brewmaster/domain/models/enums.dart';
import 'package:brewmaster/domain/models/user_profile.dart';
import 'package:brewmaster/presentation/blocs/auth/auth_bloc.dart';
import 'package:brewmaster/presentation/blocs/profile/profile_bloc.dart';
import 'package:brewmaster/presentation/widgets/common/custom_button.dart';
import 'package:brewmaster/presentation/widgets/common/loading_indicator.dart';
import 'package:brewmaster/presentation/widgets/common/error_state_widget.dart';
import 'package:brewmaster/presentation/widgets/common/status_badge.dart';
import 'package:brewmaster/presentation/screens/profile/edit_profile_screen.dart';
import 'package:brewmaster/presentation/screens/profile/settings_screen.dart';
import 'package:brewmaster/presentation/screens/profile/verification_request_screen.dart';
import 'package:brewmaster/config/localization/app_localizations.dart';
import 'package:brewmaster/presentation/widgets/common/verification_badge.dart';

/// Profile screen displaying user information.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      context
          .read<ProfileBloc>()
          .add(ProfileWatchRequested(authState.profile.id));
    }
  }

UserProfile? _profileFromState(ProfileState state) {
    if (state is ProfileLoaded) return state.profile;
    if (state is ProfileUpdateSuccess) return state.profile;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).profileTitle),
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, authState) {
          if (authState is AuthUnauthenticated) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        },
        child: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state is ProfileFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppTheme.errorColor,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is ProfileLoading) {
            return LoadingIndicator(message: AppLocalizations.of(context).loadingProfile);
          }

          final profile = _profileFromState(state);
          if (profile == null) {
            return ErrorStateWidget(
              message: state is ProfileFailure
                  ? state.message
                  : AppLocalizations.of(context).noProfileFound,
              icon: Icons.person_off_outlined,
              onRetry: () {
                final authState = context.read<AuthBloc>().state;
                if (authState is AuthAuthenticated) {
                  context
                      .read<ProfileBloc>()
                      .add(ProfileLoadRequested(authState.profile.id));
                }
              },
            );
          }

          final loc = AppLocalizations.of(context);
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
                                ? loc.farmer
                                : loc.buyer,
                            type: StatusBadgeType.info,
                            icon: profile.role == UserRole.farmer
                                ? Icons.agriculture
                                : Icons.shopping_bag,
                          ),
                          const SizedBox(width: AppTheme.padding8),
                          // Email verification status (isVerified field)
                          StatusBadge(
                            label: profile.isVerified
                                ? loc.emailVerified
                                : loc.emailUnverified,
                            type: profile.isVerified
                                ? StatusBadgeType.success
                                : StatusBadgeType.neutral,
                            showIndicator: true,
                          ),
                          if (!profile.isVerified) ...[
                            const SizedBox(width: AppTheme.padding8),
                            TextButton.icon(
                              icon: const Icon(Icons.verified_user_outlined),
                              label: Text(loc.verifyEmail),
                              onPressed: () => context
                                  .read<AuthBloc>()
                                  .add(const AuthVerificationEmailRequested()),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.padding8),
                // Identity verification badge + action
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    VerificationBadge(status: profile.verificationStatus),
                    if (profile.verificationStatus.name == 'unverified' ||
                        profile.verificationStatus.name == 'rejected') ...[
                      const SizedBox(width: AppTheme.padding8),
                      TextButton.icon(
                        icon: const Icon(Icons.upload_file),
                        label: Text(loc.getVerified),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const VerificationRequestScreen(),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppTheme.padding32),
                const Divider(),
                const SizedBox(height: AppTheme.padding16),

                // Role-specific details
                if (profile.role == UserRole.farmer) ...[
                  Text(loc.farmDetailsLabel, style: AppTheme.heading2),
                  const SizedBox(height: AppTheme.padding16),
                  _buildInfoRow(Icons.landscape, loc.farmSize,
                      profile.farmSize != null
                          ? '${profile.farmSize} hectares'
                          : loc.notSet),
                  _buildInfoRow(Icons.location_on_outlined, loc.location,
                      profile.farmLocation ?? loc.notSet),
                  _buildInfoRow(Icons.coffee, loc.coffeeVarietiesLabel,
                      profile.coffeeVarieties?.join(', ') ?? loc.notSet),
                  _buildInfoRow(Icons.badge_outlined, loc.registrationNo,
                      profile.farmRegistrationNumber ?? loc.notSet),
                ],

                if (profile.role == UserRole.buyer) ...[
                  Text(loc.businessDetailsLabel, style: AppTheme.heading2),
                  const SizedBox(height: AppTheme.padding16),
                  _buildInfoRow(Icons.business, loc.businessName,
                      profile.businessName ?? loc.notSet),
                  _buildInfoRow(Icons.category_outlined, loc.businessType,
                      profile.businessType ?? loc.notSet),
                  _buildInfoRow(
                      Icons.scale,
                      loc.monthlyVolume,
                      profile.monthlyVolume != null
                          ? '${profile.monthlyVolume} kg'
                          : loc.notSet),
                ],

                const SizedBox(height: AppTheme.padding32),

                CustomButton(
                  text: loc.editProfile,
                  type: ButtonType.outlined,
                  isFullWidth: true,
                  leadingIcon: Icons.edit,
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditProfileScreen(userProfile: profile),
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.padding12),
                CustomButton(
                  text: loc.settings,
                  type: ButtonType.outlined,
                  isFullWidth: true,
                  leadingIcon: Icons.settings_outlined,
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SettingsScreen(),
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.padding16),
                Center(
                  child: TextButton.icon(
                    icon: const Icon(Icons.logout),
                    label: Text(loc.signOut),
                    onPressed: () => context
                        .read<AuthBloc>()
                        .add(const AuthSignOutRequested()),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.padding12),
      child: Row(
        children: [
          Icon(icon,
              size: AppTheme.iconSizeMedium, color: AppTheme.textSecondary),
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
