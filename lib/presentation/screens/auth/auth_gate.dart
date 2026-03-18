import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:brewmaster/presentation/blocs/auth/auth_bloc.dart';
import 'package:brewmaster/presentation/screens/auth/login_screen.dart';
import 'package:brewmaster/presentation/screens/auth/email_verification_screen.dart';
import 'package:brewmaster/presentation/screens/auth/profile_setup_screen.dart';
import 'package:brewmaster/presentation/screens/profile/verification_pending_screen.dart';
import 'package:brewmaster/presentation/screens/profile/verification_request_screen.dart';
import 'package:brewmaster/presentation/widgets/common/home_shell.dart';

/// Routes to the appropriate screen based on the current [AuthState].
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthAuthenticated) {
          return HomeShell(profile: state.profile);
        }
        if (state is AuthKycPending) {
          return const VerificationPendingScreen();
        }
        if (state is AuthNeedsKycVerification) {
          return const VerificationRequestScreen(isOnboarding: true);
        }
        if (state is AuthNeedsProfile) {
          return ProfileSetupScreen(
            userId: state.uid,
            email: state.email ?? '',
            displayName: state.displayName ?? '',
            role: state.role,
          );
        }
        if (state is AuthEmailNotVerified) {
          return const EmailVerificationScreen();
        }
        if (state is AuthUnauthenticated || state is AuthFailure) {
          return const LoginScreen();
        }
        // AuthInitial / AuthLoading / AuthPasswordResetSent / AuthVerificationEmailSent
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}
