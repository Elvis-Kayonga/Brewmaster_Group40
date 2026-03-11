import 'package:flutter/material.dart';
import 'package:brewmaster/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:brewmaster/data/repositories/firebase_auth_repository.dart';
import 'package:brewmaster/data/repositories/firebase_user_repository.dart';
import 'package:brewmaster/data/repositories/firebase_payment_repository.dart';
import 'package:brewmaster/data/repositories/firebase_listing_repository.dart';
import 'package:brewmaster/data/repositories/firebase_message_repository.dart';
import 'package:brewmaster/data/repositories/firebase_notification_repository.dart';
import 'package:brewmaster/data/repositories/firebase_offline_sync_repository.dart';
import 'package:brewmaster/data/repositories/firebase_verification_repository.dart';
import 'package:brewmaster/presentation/blocs/auth/auth_bloc.dart';
import 'package:brewmaster/presentation/blocs/connectivity/connectivity_bloc.dart';
import 'package:brewmaster/presentation/blocs/listing/listing_bloc.dart';
import 'package:brewmaster/presentation/blocs/profile/profile_bloc.dart';
import 'package:brewmaster/presentation/blocs/payment/payment_bloc.dart';
import 'package:brewmaster/presentation/blocs/messaging/messaging_bloc.dart';
import 'package:brewmaster/presentation/blocs/messaging/notification_bloc.dart';
import 'package:brewmaster/presentation/blocs/verification/verification_bloc.dart';
import 'package:brewmaster/presentation/screens/auth/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Enable Firestore offline persistence
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  // Build repositories once — shared across all BLoCs
  final authRepository = FirebaseAuthRepository();
  final userRepository = FirebaseUserRepository();
  final paymentRepository = FirebasePaymentRepository();
  final listingRepository = FirebaseListingRepository();
  final messageRepository = FirebaseMessageRepository();
  final notificationRepository = FirebaseNotificationRepository();
  final offlineSyncRepository = FirebaseOfflineSyncRepository();
  final verificationRepository = FirebaseVerificationRepository();

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => AuthBloc(
            authRepository: authRepository,
            userRepository: userRepository,
          ),
        ),
        BlocProvider<ProfileBloc>(
          create: (_) => ProfileBloc(userRepository: userRepository),
        ),
        BlocProvider<PaymentBloc>(
          create: (_) => PaymentBloc(paymentRepository: paymentRepository),
        ),
        BlocProvider<ListingBloc>(
          create: (_) => ListingBloc(repository: listingRepository),
        ),
        BlocProvider<MessagingBloc>(
          create: (_) => MessagingBloc(repository: messageRepository),
        ),
        BlocProvider<NotificationBloc>(
          create: (_) =>
              NotificationBloc(repository: notificationRepository),
        ),
        BlocProvider<ConnectivityBloc>(
          create: (_) =>
              ConnectivityBloc(repository: offlineSyncRepository),
        ),
        BlocProvider<VerificationBloc>(
          create: (_) =>
              VerificationBloc(repository: verificationRepository),
        ),
      ],
      child: const BrewMasterApp(),
    ),
  );
}

class BrewMasterApp extends StatelessWidget {
  const BrewMasterApp({super.key});

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
