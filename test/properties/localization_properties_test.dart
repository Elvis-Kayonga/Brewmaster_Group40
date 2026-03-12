// test/properties/localization_properties_test.dart
//
// Property-based tests for task 29.3: AppLocalizations correctness.
// Verifies that all three locales (en, rw, sw) define every required key,
// that the English fallback works for unknown locales, and that the
// delegate correctly identifies supported/unsupported locales.
//
// Developer: Developer 6

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brewmaster/config/localization/app_localizations.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

AppLocalizations _loc(String langCode) =>
    AppLocalizations(Locale(langCode));

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('AppLocalizations — key completeness (task 29.3)', () {
    test('English defines all required keys', () {
      final loc = _loc('en');
      for (final key in AppLocalizations.requiredKeys) {
        final value = loc.translate(key);
        expect(value, isNot(key),
            reason: 'Key "$key" is missing from English translations');
        expect(value, isNotEmpty,
            reason: 'Key "$key" has an empty English translation');
      }
    });

    test('Kinyarwanda defines all required keys', () {
      final loc = _loc('rw');
      for (final key in AppLocalizations.requiredKeys) {
        final value = loc.translate(key);
        expect(value, isNot(key),
            reason: 'Key "$key" is missing from Kinyarwanda translations');
        expect(value, isNotEmpty,
            reason: 'Key "$key" has an empty Kinyarwanda translation');
      }
    });

    test('Swahili defines all required keys', () {
      final loc = _loc('sw');
      for (final key in AppLocalizations.requiredKeys) {
        final value = loc.translate(key);
        expect(value, isNot(key),
            reason: 'Key "$key" is missing from Swahili translations');
        expect(value, isNotEmpty,
            reason: 'Key "$key" has an empty Swahili translation');
      }
    });
  });

  group('AppLocalizations — locale isolation (task 29.3)', () {
    test('login differs between English and Kinyarwanda', () {
      expect(_loc('en').login, isNot(_loc('rw').login));
    });

    test('login differs between English and Swahili', () {
      expect(_loc('en').login, isNot(_loc('sw').login));
    });

    test('login differs between Kinyarwanda and Swahili', () {
      expect(_loc('rw').login, isNot(_loc('sw').login));
    });

    test('English app_name is BrewMaster', () {
      expect(_loc('en').appName, 'BrewMaster');
    });

    test('app_name is identical across all locales', () {
      // Brand name must not be translated.
      expect(_loc('rw').appName, _loc('en').appName);
      expect(_loc('sw').appName, _loc('en').appName);
    });
  });

  group('AppLocalizations — English fallback (task 29.3)', () {
    test('unknown locale falls back to English', () {
      final loc = _loc('fr'); // French — not supported
      expect(loc.translate('login'), 'Login');
    });

    test('unknown key returns the key itself as fallback', () {
      final loc = _loc('en');
      expect(loc.translate('__nonexistent_key__'), '__nonexistent_key__');
    });

    test('unknown locale + unknown key returns the key', () {
      final loc = _loc('fr');
      expect(loc.translate('__nonexistent__'), '__nonexistent__');
    });
  });

  group('AppLocalizations — delegate (task 29.3)', () {
    test('English is supported', () {
      expect(AppLocalizations.delegate.isSupported(const Locale('en')),
          isTrue);
    });

    test('Kinyarwanda is supported', () {
      expect(AppLocalizations.delegate.isSupported(const Locale('rw')),
          isTrue);
    });

    test('Swahili is supported', () {
      expect(AppLocalizations.delegate.isSupported(const Locale('sw')),
          isTrue);
    });

    test('French is not supported', () {
      expect(AppLocalizations.delegate.isSupported(const Locale('fr')),
          isFalse);
    });

    test('shouldReload returns false', () {
      expect(
          AppLocalizations.delegate
              .shouldReload(AppLocalizations.delegate),
          isFalse);
    });

    test('exactly 3 supported locales', () {
      expect(AppLocalizations.supportedLocales, hasLength(3));
    });
  });

  group('AppLocalizations — convenience getters (task 29.3)', () {
    test('errorNetwork is non-empty in all locales', () {
      for (final code in ['en', 'rw', 'sw']) {
        expect(_loc(code).errorNetwork, isNotEmpty);
      }
    });

    test('voiceInputHint is non-empty in all locales', () {
      for (final code in ['en', 'rw', 'sw']) {
        expect(_loc(code).voiceInputHint, isNotEmpty);
      }
    });

    test('verified is non-empty in all locales', () {
      for (final code in ['en', 'rw', 'sw']) {
        expect(_loc(code).verified, isNotEmpty);
      }
    });
  });
}
