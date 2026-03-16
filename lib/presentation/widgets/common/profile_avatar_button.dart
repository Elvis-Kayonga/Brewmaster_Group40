import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../config/theme.dart';
import '../../blocs/auth/auth_bloc.dart';

/// AppBar avatar that shows the signed-in user's initial (or photo) and
/// navigates to the Profile screen on tap.
class ProfileAvatarButton extends StatelessWidget {
  const ProfileAvatarButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        String initial = '?';
        String? photoUrl;

        if (state is AuthAuthenticated) {
          final name = state.profile.displayName;
          initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
          photoUrl = state.profile.photoUrl;
        }

        return Padding(
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
        );
      },
    );
  }
}
