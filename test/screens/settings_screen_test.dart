// Widget + unit tests for SettingsScreen and ThemeNotifier.
//
// Coverage:
// 1.  "Settings" app bar title visible
// 2.  APPEARANCE and NOTIFICATIONS section headers visible
// 3.  Dark mode toggle starts off in light mode
// 4.  Toggling dark mode switch updates ThemeNotifier
// 5.  All four notification tiles render with updated labels
// 6.  Correct updated subtitles (no old "Promotions", "matching your interests")
// 7.  5 Switch widgets total (1 dark mode + 4 notifications)
// 8.  Toggling a notification switch fires update via bloc
// 9.  Footer persistence note visible
// 10. Back button present and pops navigator
// 11. ThemeNotifier defaults to light on fresh install
// 12. ThemeNotifier.setDark persists and is restored by load()

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:brewmaster/config/localization/app_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:brewmaster/config/theme_notifier.dart';
import 'package:brewmaster/config/locale_notifier.dart';
import 'package:brewmaster/presentation/blocs/messaging/notification_bloc.dart';
import 'package:brewmaster/presentation/screens/profile/settings_screen.dart';

import '../helpers/fake_repositories.dart';

// ── Helper ────────────────────────────────────────────────────────────────────

Future<Widget> _buildScreen({
  ThemeNotifier? theme,
  NotificationBloc? bloc,
}) async {
  final t = theme ?? await ThemeNotifier.load();
  final l = await LocaleNotifier.load();
  final b = bloc ??
      NotificationBloc(repository: FakeNotificationRepository())
        ..emit(const NotificationPreferencesLoaded({
          'messagesEnabled': true,
          'listingsEnabled': true,
          'paymentsEnabled': true,
          'promotionsEnabled': true,
        }));
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<ThemeNotifier>.value(value: t),
      ChangeNotifierProvider<LocaleNotifier>.value(value: l),
    ],
    child: BlocProvider<NotificationBloc>.value(
      value: b,
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: const SettingsScreen(),
      ),
    ),
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  // ── ThemeNotifier unit tests ─────────────────────────────────────────────

  group('ThemeNotifier', () {
    test('load() defaults to light mode', () async {
      final n = await ThemeNotifier.load();
      expect(n.mode, ThemeMode.light);
      expect(n.isDark, isFalse);
    });

    test('setDark(true) sets dark mode and notifies', () async {
      final n = await ThemeNotifier.load();
      var fired = false;
      n.addListener(() => fired = true);

      await n.setDark(true);

      expect(n.isDark, isTrue);
      expect(n.mode, ThemeMode.dark);
      expect(fired, isTrue);
    });

    test('setDark(false) restores light mode', () async {
      final n = await ThemeNotifier.load();
      await n.setDark(true);
      await n.setDark(false);
      expect(n.isDark, isFalse);
    });

    test('load() restores dark preference after setDark(true)', () async {
      await (await ThemeNotifier.load()).setDark(true);
      final restored = await ThemeNotifier.load();
      expect(restored.mode, ThemeMode.dark);
    });

    test('load() restores light preference after setDark(false)', () async {
      await (await ThemeNotifier.load()).setDark(true);
      await (await ThemeNotifier.load()).setDark(false);
      final restored = await ThemeNotifier.load();
      expect(restored.mode, ThemeMode.light);
    });
  });

  // ── SettingsScreen widget tests ──────────────────────────────────────────

  group('SettingsScreen', () {
    testWidgets('shows "Settings" in app bar', (tester) async {
      await tester.pumpWidget(await _buildScreen());
      await tester.pump();
      await tester.pump();
      await tester.pump();
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('shows APPEARANCE and NOTIFICATIONS section headers',
        (tester) async {
      await tester.pumpWidget(await _buildScreen());
      await tester.pump();
      await tester.pump();
      expect(find.text('APPEARANCE'), findsOneWidget);
      expect(find.text('NOTIFICATIONS'), findsOneWidget);
    });

    testWidgets('dark mode toggle starts off (light mode)', (tester) async {
      await tester.pumpWidget(await _buildScreen());
      await tester.pump();
      await tester.pump();
      expect(find.text('Dark Mode'), findsOneWidget);
      final darkSwitch =
          tester.widgetList<Switch>(find.byType(Switch)).first;
      expect(darkSwitch.value, isFalse);
    });

    testWidgets('toggling dark mode switch updates ThemeNotifier',
        (tester) async {
      final theme = await ThemeNotifier.load();
      await tester.pumpWidget(await _buildScreen(theme: theme));
      await tester.pump();
      await tester.pump();

      await tester.tap(find.byType(Switch).first);
      await tester.pump();

      expect(theme.isDark, isTrue);
    });

    testWidgets('renders all four notification tiles', (tester) async {
      await tester.pumpWidget(await _buildScreen());
      await tester.pump();
      await tester.pump();
      expect(find.text('Messages'), findsOneWidget);
      expect(find.text('New Listings'), findsOneWidget);
      expect(find.text('Payments'), findsOneWidget);
      expect(find.text('Market & Price Alerts'), findsOneWidget);
    });

    testWidgets('shows correct updated subtitles', (tester) async {
      await tester.pumpWidget(await _buildScreen());
      await tester.pump();
      await tester.pump();
      expect(find.text('Alerts when new coffee lots are posted'), findsOneWidget);
      expect(find.text('Transaction status & dispute alerts'), findsOneWidget);
      expect(find.text('Coffee price movements and market updates'), findsOneWidget);
      // Old labels must not appear
      expect(find.textContaining('matching your interests'), findsNothing);
      expect(find.text('Promotions'), findsNothing);
    });

    testWidgets('renders 5 Switch widgets (dark mode + 4 notifications)',
        (tester) async {
      await tester.pumpWidget(await _buildScreen());
      await tester.pump();
      await tester.pump();
      expect(find.byType(Switch), findsNWidgets(5));
    });

    testWidgets('toggling Messages switch updates bloc preference',
        (tester) async {
      final repo = FakeNotificationRepository()
        ..preferences = {
          'messagesEnabled': true,
          'listingsEnabled': true,
          'paymentsEnabled': true,
          'promotionsEnabled': true,
        };
      final bloc = NotificationBloc(repository: repo)
        ..emit(NotificationPreferencesLoaded(repo.preferences));

      await tester.pumpWidget(await _buildScreen(bloc: bloc));
      await tester.pump();
      await tester.pump();

      // Switch at index 1 is Messages (index 0 is dark mode)
      await tester.tap(find.byType(Switch).at(1));
      await tester.pump();

      expect(repo.preferences['messagesEnabled'], isFalse);
      bloc.close();
    });

    testWidgets('shows footer persistence note', (tester) async {
      await tester.pumpWidget(await _buildScreen());
      await tester.pump();
      await tester.pump();
      // Footer may be off-screen; check widget tree including offstage
      expect(
        find.textContaining('persist across app restarts', skipOffstage: false),
        findsOneWidget,
      );
    });

    testWidgets('back button is present', (tester) async {
      await tester.pumpWidget(await _buildScreen());
      await tester.pump();
      await tester.pump();
      expect(find.byIcon(Icons.arrow_back_ios_new), findsOneWidget);
    });

    testWidgets('back button pops navigator', (tester) async {
      bool popped = false;
      final theme = await ThemeNotifier.load();
      final locale = await LocaleNotifier.load();
      final bloc = NotificationBloc(repository: FakeNotificationRepository());

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ThemeNotifier>.value(value: theme),
            ChangeNotifierProvider<LocaleNotifier>.value(value: locale),
          ],
          child: BlocProvider<NotificationBloc>.value(
            value: bloc,
            child: MaterialApp(
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              home: Builder(
                builder: (ctx) => ElevatedButton(
                  onPressed: () {
                    Navigator.push<void>(
                      ctx,
                      MaterialPageRoute<void>(
                        builder: (_) => MultiProvider(
                          providers: [
                            ChangeNotifierProvider<ThemeNotifier>.value(value: theme),
                            ChangeNotifierProvider<LocaleNotifier>.value(value: locale),
                          ],
                          child: BlocProvider<NotificationBloc>.value(
                            value: bloc,
                            child: const SettingsScreen(),
                          ),
                        ),
                      ),
                    ).then((_) => popped = true);
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
      await tester.pumpAndSettle();

      expect(popped, isTrue);
      bloc.close();
    });
  });
}
