import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../../l10n/app_localizations.dart';
import '../backup/backup_screen.dart';
import '../backup/backups.dart';
import '../chores/manage_chores_screen.dart';
import '../fight/fight_settings.dart';
import '../notifications/notification_settings.dart';
import '../people/people_screen.dart';
import '../screen_time/screen_time_providers.dart';
import '../screen_time/screen_time_screen.dart';
import 'settings_controller.dart';
import 'settings_pages.dart';

/// Settings overview: one entry per category, each opening its own page.
/// Subtitles show the current state so most settings can be checked at a
/// glance without opening anything.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(settingsProvider);
    final permitted = ref.watch(notificationPermissionProvider).value ?? true;

    final theme = switch (settings.themeMode) {
      ThemeMode.system => l10n.themeSystem,
      ThemeMode.light => l10n.themeLight,
      ThemeMode.dark => l10n.themeDark,
    };
    final notifications = !settings.notificationsEnabled
        ? l10n.stateOff
        : permitted
        ? l10n.stateOn
        : l10n.notifBlockedShort;
    final fights = [
      if (settings.fightSound) l10n.fightSettingSound,
      if (settings.fightHaptics) l10n.fightSettingHaptics,
      if (ref.watch(currentProfileProvider).storyMode) l10n.fightSettingStory,
    ];
    final backupOn = ref.watch(backupStateProvider).value?.folder != null;
    final backupName = ref.watch(backupFolderNameProvider);
    final backupFolder = backupName.value;
    final language =
        languageNames[settings.locale?.languageCode] ?? l10n.languageSystem;

    return ListView(
      padding: EdgeInsets.only(
        top: 8,
        bottom: 16 + MediaQuery.paddingOf(context).bottom,
      ),
      children: [
        _Entry(
          icon: Icons.checklist,
          title: l10n.manageChores,
          subtitle: l10n.manageChoresSubtitle,
          onTap: () => ManageChoresScreen.open(context),
        ),
        _Entry(
          icon: Icons.group_outlined,
          title: l10n.peopleTitle,
          subtitle: l10n.peopleSubtitle(ref.watch(profilesProvider).length),
          onTap: () => PeopleScreen.open(context),
        ),
        _Entry(
          icon: Icons.palette_outlined,
          title: l10n.settingsAppearance,
          subtitle: settings.colorblindSafe
              ? '$theme · ${l10n.colorblindOn}'
              : theme,
          onTap: () => SettingsPage.open(
            context,
            (l) => l.settingsAppearance,
            const AppearanceSettings(),
          ),
        ),
        _Entry(
          icon: Icons.notifications_outlined,
          title: l10n.settingsNotifications,
          subtitle: notifications,
          onTap: () => SettingsPage.open(
            context,
            (l) => l.settingsNotifications,
            const NotificationSettings(),
          ),
        ),
        _Entry(
          icon: Icons.sports_martial_arts,
          title: l10n.settingsFights,
          subtitle: fights.isEmpty ? l10n.stateOff : fights.join(' · '),
          onTap: () => SettingsPage.open(
            context,
            (l) => l.settingsFights,
            const FightSettings(),
          ),
        ),
        _Entry(
          icon: Icons.phone_android,
          title: l10n.settingsScreenTime,
          subtitle: ref.watch(screenTimeActiveProvider)
              ? l10n.screenOnSubtitle(settings.screenBaseMinutes)
              : l10n.stateOff,
          onTap: () => ScreenTimeScreen.open(context),
        ),
        _Entry(
          icon: Icons.language,
          title: l10n.settingsLanguage,
          subtitle: language,
          onTap: () => SettingsPage.open(
            context,
            (l) => l.settingsLanguage,
            const LanguageSettings(),
          ),
        ),
        _Entry(
          icon: Icons.save_outlined,
          title: l10n.settingsBackup,
          subtitle: !backupOn
              ? l10n.backupSubtitleOff
              : backupFolder != null
              ? l10n.backupSubtitleOn(backupFolder)
              : backupName.hasValue
              ? l10n.backupSubtitleLost
              : '…',
          onTap: () => BackupScreen.open(context),
        ),
        _Entry(
          icon: Icons.info_outline,
          title: l10n.settingsAbout,
          subtitle: l10n.settingsAboutSubtitle,
          onTap: () => SettingsPage.open(
            context,
            (l) => l.settingsAbout,
            const AboutSettings(),
          ),
        ),
      ],
    );
  }
}

class _Entry extends StatelessWidget {
  const _Entry({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon),
    title: Text(title),
    subtitle: Text(subtitle),
    trailing: const Icon(Icons.chevron_right),
    onTap: onTap,
  );
}
