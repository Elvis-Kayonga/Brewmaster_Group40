import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:brewmaster/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:brewmaster/app_router.dart';
import 'package:brewmaster/config/localization/app_localizations.dart';
import 'package:brewmaster/data/repositories/firebase_auth_repository.dart';
import 'package:brewmaster/data/repositories/firebase_user_repository.dart';
import 'package:brewmaster/data/repositories/firebase_payment_repository.dart';
import 'package:brewmaster/data/repositories/firebase_listing_repository.dart';
import 'package:brewmaster/data/repositories/firebase_message_repository.dart';
import 'package:brewmaster/data/repositories/firebase_notification_repository.dart';
import 'package:brewmaster/data/repositories/firebase_offline_sync_repository.dart';
import 'package:brewmaster/data/repositories/firebase_verification_repository.dart';
import 'package:brewmaster/data/repositories/firebase_dashboard_repository.dart';
import 'package:brewmaster/data/repositories/firebase_market_price_repository.dart';
import 'package:brewmaster/presentation/blocs/auth/auth_bloc.dart';
import 'package:brewmaster/presentation/blocs/connectivity/connectivity_bloc.dart';
import 'package:brewmaster/presentation/blocs/dashboard/dashboard_bloc.dart';
import 'package:brewmaster/presentation/blocs/listing/listing_bloc.dart';
import 'package:brewmaster/presentation/blocs/market_price/market_price_bloc.dart';
import 'package:brewmaster/presentation/blocs/profile/profile_bloc.dart';
import 'package:brewmaster/presentation/blocs/payment/payment_bloc.dart';
import 'package:brewmaster/presentation/blocs/messaging/messaging_bloc.dart';
import 'package:brewmaster/presentation/blocs/messaging/notification_bloc.dart';
import 'package:brewmaster/presentation/blocs/saved_lots/saved_lots_bloc.dart';
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
  final notificationRepository = FirebaseNotificationRepository();
  final paymentRepository = FirebasePaymentRepository(
    notificationRepository: notificationRepository,
  );
  final listingRepository = FirebaseListingRepository();
  final messageRepository = FirebaseMessageRepository(
    notificationRepository: notificationRepository,
  );
  final offlineSyncRepository = FirebaseOfflineSyncRepository();
  final verificationRepository = FirebaseVerificationRepository();
  final dashboardRepository = FirebaseDashboardRepository();
  final marketPriceRepository = FirebaseMarketPriceRepository();

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
        BlocProvider<DashboardBloc>(
          create: (_) => DashboardBloc(repository: dashboardRepository),
        ),
        BlocProvider<MarketPriceBloc>(
          create: (_) =>
              MarketPriceBloc(repository: marketPriceRepository),
        ),
        BlocProvider<SavedLotsBloc>(
          create: (_) => SavedLotsBloc(),
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
      // Localization
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      // Named routes
      onGenerateRoute: generateRoute,
      home: const AuthGate(),
    );
  }
}
