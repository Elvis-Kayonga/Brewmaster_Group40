import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kThemeModeKey = 'app_theme_mode';

/// Persists and notifies listeners of the app's [ThemeMode].
///
/// Reads from SharedPreferences on init and writes on every change.
/// Requirements: 19 (SharedPreferences persistence)
class ThemeNotifier extends ChangeNotifier {
  ThemeNotifier._(this._mode);

  ThemeMode _mode;
  ThemeMode get mode => _mode;
  bool get isDark => _mode == ThemeMode.dark;

  /// Load saved theme from SharedPreferences (call before [runApp]).
  static Future<ThemeNotifier> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kThemeModeKey);
    final mode = saved == 'dark' ? ThemeMode.dark : ThemeMode.light;
    return ThemeNotifier._(mode);
  }

  Future<void> setDark(bool dark) async {
    _mode = dark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kThemeModeKey, dark ? 'dark' : 'light');
  }
}
