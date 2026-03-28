import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:brewmaster/firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:brewmaster/app_router.dart';
import 'package:brewmaster/config/localization/app_localizations.dart';
import 'package:brewmaster/config/locale_notifier.dart';
import 'package:brewmaster/config/theme.dart';
import 'package:brewmaster/config/theme_notifier.dart';
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
import 'package:brewmaster/presentation/blocs/voice/voice_bloc.dart';
import 'package:brewmaster/presentation/blocs/verification/verification_bloc.dart';
import 'package:brewmaster/presentation/screens/auth/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Enable Firestore offline persistence with a 40 MB cap.
  // CACHE_SIZE_UNLIMITED grows forever and slows startup as the cache expands.
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: 40 * 1024 * 1024, // 40 MB
  );

  final themeNotifier = await ThemeNotifier.load();
  final localeNotifier = await LocaleNotifier.load();

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
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeNotifier>.value(value: themeNotifier),
        ChangeNotifierProvider<LocaleNotifier>.value(value: localeNotifier),
      ],
      child: MultiBlocProvider(
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
            create: (ctx) => SavedLotsBloc(
              userRepository: userRepository,
              userId: FirebaseAuth.instance.currentUser?.uid,
            ),
          ),
          BlocProvider<VoiceAssistantBloc>(
            create: (_) => VoiceAssistantBloc(),
          ),
        ],
        child: const BrewMasterApp(),
      ),
    ),
  );
}

/// Fallback delegate that supplies English [MaterialLocalizations] for any
/// locale not covered by [GlobalMaterialLocalizations] (e.g. Kinyarwanda 'rw').
/// It must be placed *after* GlobalMaterialLocalizations in the delegate list so
/// that supported locales (en, sw, …) are handled by the real implementation
/// first, and only truly unsupported ones fall through here.
class _FallbackMaterialLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const _FallbackMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      GlobalMaterialLocalizations.delegate.load(const Locale('en'));

  @override
  bool shouldReload(_FallbackMaterialLocalizationsDelegate old) => false;
}

class BrewMasterApp extends StatelessWidget {
  const BrewMasterApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeNotifier = context.watch<ThemeNotifier>();
    final localeNotifier = context.watch<LocaleNotifier>();
    return MaterialApp(
      title: 'BrewMaster',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeNotifier.mode,
      locale: localeNotifier.locale,
      // Localization
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        // Must be last — catches locales unsupported by Global* delegates (e.g. 'rw')
        _FallbackMaterialLocalizationsDelegate(),
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      // Named routes
      onGenerateRoute: generateRoute,
      home: const AuthGate(),
    );
  }
}
