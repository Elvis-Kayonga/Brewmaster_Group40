import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../config/locale_notifier.dart';
import '../../../config/localization/app_localizations.dart';
import '../../../config/theme_notifier.dart';
import '../../blocs/messaging/notification_bloc.dart';

/// Settings screen — persisted via SharedPreferences.
///
/// Saves: dark mode toggle + four notification toggles.
/// Requirements: 19 (SharedPreferences persistence across restarts)
/// Developer: Developer 6
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    context
        .read<NotificationBloc>()
        .add(const NotificationPreferencesLoadRequested());
  }

  void _toggle(Map<String, bool> current, String key, bool value) {
    final updated = Map<String, bool>.from(current)..[key] = value;
    context
        .read<NotificationBloc>()
        .add(NotificationPreferencesUpdateRequested(updated));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final themeNotifier = context.watch<ThemeNotifier>();
    final localeNotifier = context.watch<LocaleNotifier>();
    final loc = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(loc.settings),
      ),
      body: BlocBuilder<NotificationBloc, NotificationState>(
        buildWhen: (_, curr) =>
            curr is NotificationPreferencesLoaded || curr is NotificationFailure,
        builder: (context, state) {
          final prefs = state is NotificationPreferencesLoaded
              ? state.preferences
              : <String, bool>{
                  'messagesEnabled': true,
                  'listingsEnabled': true,
                  'paymentsEnabled': true,
                  'promotionsEnabled': true,
                };

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              // ── Appearance section ──────────────────────────────────
              _SectionHeader(label: loc.appearance.toUpperCase()),
              _SettingsCard(
                children: [
                  _PrefTile(
                    icon: themeNotifier.isDark
                        ? Icons.dark_mode_outlined
                        : Icons.light_mode_outlined,
                    title: loc.darkMode,
                    subtitle: themeNotifier.isDark
                        ? loc.usingDarkTheme
                        : loc.usingLightTheme,
                    value: themeNotifier.isDark,
                    onChanged: (v) =>
                        context.read<ThemeNotifier>().setDark(v),
                    showDivider: false,
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ── Language section ─────────────────────────────────────
              _SectionHeader(label: loc.language.toUpperCase()),
              _SettingsCard(
                children: [
                  for (final entry
                      in LocaleNotifier.languageNames.entries) ...[
                    _LanguageTile(
                      languageCode: entry.key,
                      displayName: entry.value,
                      isSelected:
                          localeNotifier.locale.languageCode == entry.key,
                      onTap: () => context
                          .read<LocaleNotifier>()
                          .setLocale(Locale(entry.key)),
                      showDivider:
                          entry.key != LocaleNotifier.languageNames.keys.last,
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 20),

              // ── Notifications section ────────────────────────────────
              _SectionHeader(label: loc.notificationsLabel.toUpperCase()),
              _SettingsCard(
                children: [
                  _PrefTile(
                    icon: Icons.chat_bubble_outline,
                    title: loc.messages,
                    subtitle: loc.messagesSubtitle,
                    value: prefs['messagesEnabled'] ?? true,
                    onChanged: (v) => _toggle(prefs, 'messagesEnabled', v),
                    showDivider: true,
                  ),
                  _PrefTile(
                    icon: Icons.local_cafe_outlined,
                    title: loc.newListings,
                    subtitle: loc.newListingsSubtitle,
                    value: prefs['listingsEnabled'] ?? true,
                    onChanged: (v) => _toggle(prefs, 'listingsEnabled', v),
                    showDivider: true,
                  ),
                  _PrefTile(
                    icon: Icons.payments_outlined,
                    title: loc.paymentsLabel,
                    subtitle: loc.paymentsSubtitle,
                    value: prefs['paymentsEnabled'] ?? true,
                    onChanged: (v) => _toggle(prefs, 'paymentsEnabled', v),
                    showDivider: true,
                  ),
                  _PrefTile(
                    icon: Icons.trending_up_outlined,
                    title: loc.marketPriceAlerts,
                    subtitle: loc.marketAlertsSubtitle,
                    value: prefs['promotionsEnabled'] ?? true,
                    onChanged: (v) => _toggle(prefs, 'promotionsEnabled', v),
                    showDivider: false,
                  ),
                ],
              ),

              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  loc.preferencesSavedInfo,
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurface.withValues(alpha: 0.45),
                    height: 1.5,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.8,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: children),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.languageCode,
    required this.displayName,
    required this.isSelected,
    required this.onTap,
    required this.showDivider,
  });

  final String languageCode;
  final String displayName;
  final bool isSelected;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.language, color: cs.primary, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    displayName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle, color: cs.primary, size: 20)
                else
                  Icon(Icons.radio_button_unchecked,
                      color: cs.onSurface.withValues(alpha: 0.3), size: 20),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: 64,
            endIndent: 16,
            color: cs.onSurface.withValues(alpha: 0.1),
          ),
      ],
    );
  }
}

class _PrefTile extends StatelessWidget {
  const _PrefTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.showDivider,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: cs.primary, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
                activeThumbColor: cs.primary,
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: 64,
            endIndent: 16,
            color: cs.onSurface.withValues(alpha: 0.1),
          ),
      ],
    );
  }
}
