import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kLanguageKey = 'language';

/// Persists and notifies listeners of the app's display [Locale].
///
/// Supported: English (en), Kinyarwanda (rw), Swahili (sw).
/// Reads from SharedPreferences on init and writes on every change.
/// Requirements: 1.5, 5.7, 10.6, 10.7 (multilingual support)
class LocaleNotifier extends ChangeNotifier {
  LocaleNotifier._(this._locale);

  Locale _locale;
  Locale get locale => _locale;

  static const Map<String, String> languageNames = {
    'en': 'English',
    'rw': 'Kinyarwanda',
    'sw': 'Kiswahili',
  };

  /// Load the saved language from SharedPreferences (call before [runApp]).
  static Future<LocaleNotifier> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kLanguageKey) ?? 'en';
    return LocaleNotifier._(Locale(saved));
  }

  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLanguageKey, locale.languageCode);
  }
}
