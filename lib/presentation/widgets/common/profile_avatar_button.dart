import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../config/theme.dart';
import '../../../domain/models/enums.dart';
import '../../../domain/models/user_profile.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/profile/profile_bloc.dart';
import '../../blocs/saved_lots/saved_lots_bloc.dart';
import '../../screens/saved_lots/saved_lots_screen.dart';
import 'notification_bell_button.dart';

/// AppBar avatar that shows the signed-in user's initial (or photo) and
/// navigates to the Profile screen on tap.
///
/// Listens to [ProfileBloc] for real-time updates (e.g. after a photo upload)
/// and falls back to [AuthBloc]'s cached profile when ProfileBloc has no data.
class ProfileAvatarButton extends StatelessWidget {
  const ProfileAvatarButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        return BlocBuilder<ProfileBloc, ProfileState>(
          builder: (context, profileState) {
            // Prefer ProfileBloc's data — it reflects real-time Firestore
            // updates (e.g. after photo upload) while AuthBloc only holds the
            // profile snapshot captured at login time.
            UserProfile? profile;
            if (profileState is ProfileLoaded) {
              profile = profileState.profile;
            } else if (profileState is ProfileUpdateSuccess) {
              profile = profileState.profile;
            } else if (authState is AuthAuthenticated) {
              profile = authState.profile;
            }

            final name = profile?.displayName ?? '';
            final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
            final photoUrl = profile?.photoUrl;

            final isBuyer = profile?.role == UserRole.buyer;

            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isBuyer)
                  BlocBuilder<SavedLotsBloc, SavedLotsState>(
                    builder: (context, savedState) {
                      return IconButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SavedLotsScreen(),
                          ),
                        ),
                        icon: Badge(
                          isLabelVisible: savedState.itemCount > 0,
                          label: Text('${savedState.itemCount}'),
                          child: const Icon(Icons.favorite_border),
                        ),
                        color: AppTheme.primaryDark,
                      );
                    },
                  ),
                const NotificationBellButton(),
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pushNamed('/profile'),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: AppTheme.primaryDark,
                      backgroundImage:
                          photoUrl != null ? NetworkImage(photoUrl) : null,
                      child: photoUrl == null
                          ? Text(
                              initial,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
