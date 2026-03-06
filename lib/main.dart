// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:app_links/app_links.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:brewmaster/data/providers/auth_provider.dart';
import 'package:brewmaster/data/providers/user_provider.dart';
import 'package:brewmaster/presentation/screens/auth/login_screen.dart';
import 'package:brewmaster/presentation/screens/auth/profile_setup_screen.dart';
import 'package:brewmaster/presentation/screens/dashboard/dashboard_screen.dart';
import 'firebase_options.dart';

// ignore_for_file: avoid_print

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Enable Firestore offline persistence
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..init()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _appLinks = AppLinks();

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  void _initDeepLinks() async {
    print('🚀 [DEEP_LINK] Initializing deep link listener...');
    
    // Handle deep links when app is opened from terminated state
    try {
      print('🚀 [DEEP_LINK] Checking for initial link...');
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        print('🚀 [DEEP_LINK] Found initial link: $initialLink');
        _handleDeepLink(initialLink);
      } else {
        print('🚀 [DEEP_LINK] No initial link found');
      }
    } catch (e) {
      print('❌ [DEEP_LINK] Error getting initial link: $e');
    }

    // Handle deep links when app is already running
    print('🚀 [DEEP_LINK] Setting up listener for active deep links...');
    _appLinks.uriLinkStream.listen((Uri? uri) {
      if (uri != null) {
        print('🚀 [DEEP_LINK] Received active link: $uri');
        _handleDeepLink(uri);
      }
    }, onError: (err) {
      print('❌ [DEEP_LINK] Deep link stream error: $err');
    });
  }

  void _handleDeepLink(Uri deepLink) async {
    print('🔗 [DEEP_LINK] Received deep link: $deepLink');
    print('🔗 [DEEP_LINK] Query params: ${deepLink.queryParameters}');

    // Check if this is an email verification link
    if (deepLink.queryParameters.containsKey('oobCode')) {
      final oobCode = deepLink.queryParameters['oobCode']!;
      print('📧 [VERIFICATION] oobCode: $oobCode');

      // Capture everything BEFORE any async operations
      final authProvider = context.read<AuthProvider>();
      final userProvider = context.read<UserProvider>();
      final navContext = context;

      // Give Firebase time to initialize if needed
      await Future.delayed(const Duration(milliseconds: 500));

      // Apply the action code to verify the email
      try {
        // First check the action code to get the email
        print('🔍 [VERIFICATION] Checking action code...');
        final email = await authProvider.checkEmailActionCode(oobCode);
        if (email == null) {
          print('❌ [VERIFICATION] Could not get email from action code');
          _showVerificationErrorUI('Invalid verification link');
          return;
        }
        print('✅ [VERIFICATION] Action code is for email: $email');

        // Find the user profile by email (now with case-insensitive matching)
        print('🔍 [VERIFICATION] Looking up profile for email: $email');
        var userProfile = await userProvider.fetchProfileByEmail(email);
        
        if (userProfile == null) {
          print('❌ [VERIFICATION] Could not find user profile for email: $email');
          print('⚠️ [VERIFICATION] This may mean the user profile hasn\'t been created yet');
          _showVerificationErrorUI('User profile not found. Please sign up first.');
          return;
        }
        print('✅ [VERIFICATION] Found user profile - ID: ${userProfile.id}, Current isVerified: ${userProfile.isVerified}');

        // Apply the action code
        print('🔍 [VERIFICATION] Applying action code to Firebase Auth...');
        final applied = await authProvider.applyEmailActionCode(oobCode);

        if (applied) {
          print('✅ [VERIFICATION] Firebase Auth verification successful');

          // Update the database
          print('🔍 [VERIFICATION] Updating Firestore - setting isVerified=true for user ${userProfile.id}');
          final updateSuccess = await userProvider.updateProfile(userProfile.id, {'isVerified': true});
          print('✅ [VERIFICATION] Database update result: $updateSuccess');

          // Reload profile to verify the update
          print('🔍 [VERIFICATION] Reloading profile to verify update...');
          final updatedProfile = await userProvider.fetchProfileQuietly(userProfile.id);
          print('✅ [VERIFICATION] Updated profile isVerified: ${updatedProfile?.isVerified}');

          // Navigate to dashboard
          if (mounted) {
            print('📱 [VERIFICATION] Navigating to dashboard...');
            Navigator.of(navContext).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const DashboardScreen()),
              (route) => false,
            );
          }
        } else {
          print('❌ [VERIFICATION] Firebase Auth verification failed - applyEmailActionCode returned false');
          _showVerificationErrorUI('Email verification failed. Please try again.');
        }
      } catch (e, st) {
        print('❌ [VERIFICATION] Error handling email verification deep link: $e');
        print('❌ [VERIFICATION] Stack trace: $st');
        _showVerificationErrorUI('An error occurred during verification: $e');
      }
    } else {
      print('⚠️ [VERIFICATION] Deep link received but no oobCode parameter found');
    }
  }

  void _showVerificationErrorUI(String message) {
    // Schedule the snackbar to show on next frame to avoid BuildContext issues
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BrewMaster',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.brown),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  Future<Widget> _determineRoute(firebase_auth.User user) async {
    final userId = user.uid;
    final userProvider = context.read<UserProvider>();

    try {
      // Check if profile exists (silently, without updating provider state)
      final profile = await userProvider.fetchProfileQuietly(userId);

      if (profile != null) {
        // Profile exists - show dashboard
        return const DashboardScreen();
      } else {
        // Profile doesn't exist - show profile setup
        return ProfileSetupScreen(
          userId: userId,
          email: user.email ?? '',
          displayName: user.displayName ?? 'User',
          role: null, // User will select role in ProfileSetupScreen
        );
      }
    } catch (e) {
      print('Error determining route: $e');
      // On error, assume new user and show profile setup
      return ProfileSetupScreen(
        userId: userId,
        email: user.email ?? '',
        displayName: user.displayName ?? 'User',
        role: null,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final user = auth.currentUser;
        if (user == null) {
          return const LoginScreen();
        } else {
          return FutureBuilder<Widget>(
            future: _determineRoute(user),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError) {
                return Scaffold(
                  body: Center(child: Text('Error: ${snapshot.error}')),
                );
              }

              return snapshot.data ?? const LoginScreen();
            },
          );
        }
      },
    );
  }
}
