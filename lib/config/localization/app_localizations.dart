// lib/config/localization/app_localizations.dart
//
// Hand-written localization delegate for English (en), Kinyarwanda (rw),
// and Swahili (sw). No code generation required — keys are looked up from
// a static const map with English fallback.
//
// Requirements: 1.5, 5.7, 10.6, 10.7
// Developer: Developer 6

import 'package:flutter/material.dart';

/// Provides localised strings for the three supported locales.
///
/// Usage:
/// ```dart
/// final loc = AppLocalizations.of(context);
/// Text(loc.login)
/// ```
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations)!;

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('en'), // English
    Locale('rw'), // Kinyarwanda
    Locale('sw'), // Swahili
  ];

  /// All keys that every locale must define.
  static const List<String> requiredKeys = [
    'app_name',
    'login',
    'sign_up',
    'email',
    'password',
    'dashboard',
    'search',
    'messages',
    'profile',
    'listings',
    'market_prices',
    'sign_out',
    'error_network',
    'error_server',
    'error_auth',
    'error_unknown',
    'error_permission',
    'retry',
    'cancel',
    'save',
    'delete',
    'confirm',
    'voice_input_hint',
    'voice_listening',
    'voice_not_available',
    'verified',
    'pending',
    'rejected',
    'get_verified',
  ];

  static const Map<String, Map<String, String>> _strings = {
    'en': {
      'app_name': 'BrewMaster',
      'login': 'Login',
      'sign_up': 'Sign Up',
      'email': 'Email',
      'password': 'Password',
      'dashboard': 'Dashboard',
      'search': 'Search',
      'messages': 'Messages',
      'profile': 'Profile',
      'listings': 'Listings',
      'market_prices': 'Market Prices',
      'sign_out': 'Sign Out',
      'error_network':
          'No internet connection. Please check your network.',
      'error_server': 'Server error. Please try again later.',
      'error_auth': 'Authentication failed. Please sign in again.',
      'error_unknown': 'An unexpected error occurred.',
      'error_permission': 'Permission denied.',
      'retry': 'Try again',
      'cancel': 'Cancel',
      'save': 'Save',
      'delete': 'Delete',
      'confirm': 'Confirm',
      'voice_input_hint': 'Tap the mic to speak',
      'voice_listening': 'Listening...',
      'voice_not_available': 'Voice input not available',
      'verified': 'Verified',
      'pending': 'Pending',
      'rejected': 'Rejected',
      'get_verified': 'Get Verified',
    },
    'rw': {
      // Kinyarwanda
      'app_name': 'BrewMaster',
      'login': 'Injira',
      'sign_up': 'Iyandikishe',
      'email': 'Imeyili',
      'password': 'Ijambo ryibanga',
      'dashboard': 'Imbonerahamwe',
      'search': 'Shakisha',
      'messages': 'Ubutumwa',
      'profile': 'Umwirondoro',
      'listings': 'Urutonde',
      'market_prices': "Ibiciro by'isoko",
      'sign_out': 'Sohoka',
      'error_network': 'Nta savisi ya internet. Reba umuyoboro wawe.',
      'error_server': 'Ikosa rya seriveri. Gerageza nyuma.',
      'error_auth': 'Kwinjira ntibyakunze. Injira nanone.',
      'error_unknown': 'Hari ikosa ritaretse.',
      'error_permission': 'Ntufite uburenganzira.',
      'retry': 'Gerageza nanone',
      'cancel': 'Reka',
      'save': 'Bika',
      'delete': 'Siba',
      'confirm': 'Emeza',
      'voice_input_hint': 'Kanda micro uvuge',
      'voice_listening': 'Kumva...',
      'voice_not_available': 'Injiza ijwi ntiboneka',
      'verified': 'Byemejwe',
      'pending': 'Birimo gutegerezwa',
      'rejected': 'Byanzwe',
      'get_verified': 'Emezwa',
    },
    'sw': {
      // Swahili
      'app_name': 'BrewMaster',
      'login': 'Ingia',
      'sign_up': 'Jisajili',
      'email': 'Barua pepe',
      'password': 'Nenosiri',
      'dashboard': 'Dashibodi',
      'search': 'Tafuta',
      'messages': 'Ujumbe',
      'profile': 'Wasifu',
      'listings': 'Orodha',
      'market_prices': 'Bei za soko',
      'sign_out': 'Toka',
      'error_network':
          'Hakuna mtandao. Tafadhali angalia muunganiko wako.',
      'error_server': 'Hitilafu ya seva. Jaribu tena baadaye.',
      'error_auth': 'Uthibitishaji umeshindwa. Tafadhali ingia tena.',
      'error_unknown': 'Hitilafu isiyotarajiwa imetokea.',
      'error_permission': 'Ruhusa imekataliwa.',
      'retry': 'Jaribu tena',
      'cancel': 'Ghairi',
      'save': 'Hifadhi',
      'delete': 'Futa',
      'confirm': 'Thibitisha',
      'voice_input_hint': 'Gonga maikrofoni kuongea',
      'voice_listening': 'Inasikiliza...',
      'voice_not_available': 'Ingizo la sauti halipatikani',
      'verified': 'Imethibitishwa',
      'pending': 'Inasubiri',
      'rejected': 'Imekataliwa',
      'get_verified': 'Thibitisha',
    },
  };

  /// Looks up [key] in the current locale, falls back to English.
  String translate(String key) {
    final langCode = locale.languageCode;
    return _strings[langCode]?[key] ?? _strings['en']?[key] ?? key;
  }

  // ---------------------------------------------------------------------------
  // Convenience getters
  // ---------------------------------------------------------------------------

  String get appName => translate('app_name');
  String get login => translate('login');
  String get signUp => translate('sign_up');
  String get email => translate('email');
  String get password => translate('password');
  String get dashboard => translate('dashboard');
  String get search => translate('search');
  String get messages => translate('messages');
  String get profile => translate('profile');
  String get listings => translate('listings');
  String get marketPrices => translate('market_prices');
  String get signOut => translate('sign_out');
  String get errorNetwork => translate('error_network');
  String get errorServer => translate('error_server');
  String get errorAuth => translate('error_auth');
  String get errorUnknown => translate('error_unknown');
  String get errorPermission => translate('error_permission');
  String get retry => translate('retry');
  String get cancel => translate('cancel');
  String get save => translate('save');
  String get delete => translate('delete');
  String get confirm => translate('confirm');
  String get voiceInputHint => translate('voice_input_hint');
  String get voiceListening => translate('voice_listening');
  String get voiceNotAvailable => translate('voice_not_available');
  String get verified => translate('verified');
  String get pending => translate('pending');
  String get rejected => translate('rejected');
  String get getVerified => translate('get_verified');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => AppLocalizations.supportedLocales
      .any((l) => l.languageCode == locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
