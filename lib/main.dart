import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:brewmaster/data/providers/auth_provider.dart';
import 'package:brewmaster/data/providers/user_provider.dart';
import 'package:brewmaster/presentation/screens/auth/login_screen.dart';
import 'package:brewmaster/presentation/screens/auth/profile_setup_screen.dart';
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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
  late Future<Widget> _routeFuture;
  bool _lastAuthState = false;

  @override
  void initState() {
    super.initState();
    _routeFuture = _determineRoute();
  }

  Future<Widget> _determineRoute() async {
    final authProvider = context.read<AuthProvider>();

    // Not authenticated - show login
    // Do not refresh here; the provider already performed an initial reload
    // during initialization. Avoid calling refresh after every auth change to
    // prevent transient reload errors from logging a newly created user out.
    if (!authProvider.isAuthenticated || authProvider.currentUser == null) {
      return const LoginScreen();
    }

    final userId = authProvider.currentUser!.uid;
    final userProvider = context.read<UserProvider>();

    try {
      // Check if profile exists (silently, without updating provider state)
      final profile = await userProvider.fetchProfileQuietly(userId);

      if (profile != null) {
        // Profile exists - show home
        return const Scaffold(body: Center(child: Text('BrewMaster Home')));
      } else {
        // Profile doesn't exist - show profile setup
        return ProfileSetupScreen(
          userId: userId,
          email: authProvider.currentUser!.email ?? '',
          displayName: authProvider.currentUser!.displayName ?? 'User',
          role: null, // User will select role in ProfileSetupScreen
        );
      }
    } catch (e) {
      print('Error determining route: $e');
      // On error, show login screen
      return const LoginScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        // if authentication state changed, re-evaluate routing
        if (auth.isAuthenticated != _lastAuthState) {
          _lastAuthState = auth.isAuthenticated;
          _routeFuture = _determineRoute();
        }

        return FutureBuilder<Widget>(
          future: _routeFuture,
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
      },
    );
  }
}
