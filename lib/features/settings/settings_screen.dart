import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/chore_palette.dart';
import '../../core/widgets/section_header.dart';
import '../chores/manage_chores_screen.dart';
import '../../l10n/app_localizations.dart';
import 'settings_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  // Language names are shown in their own language, so they are not translated.
  static const _languages = {'de': 'Deutsch', 'en': 'English'};

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);
    final palette = Theme.of(context).extension<ChorePalette>()!;

    return ListView(
      children: [
        SectionHeader(l10n.settingsChores),
        ListTile(
          leading: const Icon(Icons.checklist),
          title: Text(l10n.manageChores),
          subtitle: Text(l10n.manageChoresSubtitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => ManageChoresScreen.open(context),
        ),
        SectionHeader(l10n.settingsAppearance),
        ListTile(
          title: Text(l10n.settingsTheme),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: SegmentedButton<ThemeMode>(
              segments: [
                ButtonSegment(
                  value: ThemeMode.system,
                  icon: const Icon(Icons.brightness_auto),
                  label: Text(l10n.themeSystem),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  icon: const Icon(Icons.light_mode),
                  label: Text(l10n.themeLight),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  icon: const Icon(Icons.dark_mode),
                  label: Text(l10n.themeDark),
                ),
              ],
              selected: {settings.themeMode},
              onSelectionChanged: (s) => controller.setThemeMode(s.first),
            ),
          ),
        ),
        SwitchListTile(
          secondary: const Icon(Icons.visibility),
          title: Text(l10n.settingsColorblind),
          subtitle: Text(l10n.settingsColorblindSubtitle),
          value: settings.colorblindSafe,
          onChanged: controller.setColorblindSafe,
        ),
        ListTile(
          title: Text(l10n.settingsChoreColors),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final color in palette.colors)
                  CircleAvatar(radius: 14, backgroundColor: color),
              ],
            ),
          ),
        ),
        SectionHeader(l10n.settingsLanguage),
        RadioGroup<String?>(
          groupValue: settings.locale?.languageCode,
          onChanged: (code) =>
              controller.setLocale(code == null ? null : Locale(code)),
          child: Column(
            children: [
              RadioListTile<String?>(
                value: null,
                title: Text(l10n.languageSystem),
              ),
              for (final entry in _languages.entries)
                RadioListTile<String?>(
                  value: entry.key,
                  title: Text(entry.value),
                ),
            ],
          ),
        ),
        SectionHeader(l10n.settingsAbout),
        ListTile(
          leading: const Icon(Icons.lock_outline),
          title: Text(l10n.aboutPrivacy),
        ),
        ListTile(
          leading: const Icon(Icons.code),
          title: Text(l10n.aboutLicense),
        ),
      ],
    );
  }
}
