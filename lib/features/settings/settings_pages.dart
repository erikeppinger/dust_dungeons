import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../app/art/art_gallery.dart';
import '../../app/theme/chore_palette.dart';
import '../../l10n/app_localizations.dart';
import 'settings_controller.dart';

/// Language names are shown in their own language, so they are not translated.
const languageNames = {'de': 'Deutsch', 'en': 'English'};

/// A settings category on its own page.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.title, required this.child});

  /// Looked up on every build, so the title follows a language change made
  /// on the page itself.
  final String Function(AppLocalizations) title;
  final Widget child;

  static Future<void> open(
    BuildContext context,
    String Function(AppLocalizations) title,
    Widget child,
  ) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => SettingsPage(title: title, child: child),
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title(AppLocalizations.of(context)))),
    body: ListView(
      padding: EdgeInsets.only(
        top: 8,
        bottom: 16 + MediaQuery.paddingOf(context).bottom,
      ),
      children: [child],
    ),
  );
}

class AppearanceSettings extends ConsumerWidget {
  const AppearanceSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);
    final palette = Theme.of(context).extension<ChorePalette>()!;
    return Column(
      children: [
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
      ],
    );
  }
}

class LanguageSettings extends ConsumerWidget {
  const LanguageSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);
    return RadioGroup<String?>(
      groupValue: settings.locale?.languageCode,
      onChanged: (code) =>
          controller.setLocale(code == null ? null : Locale(code)),
      child: Column(
        children: [
          RadioListTile<String?>(value: null, title: Text(l10n.languageSystem)),
          for (final entry in languageNames.entries)
            RadioListTile<String?>(value: entry.key, title: Text(entry.value)),
        ],
      ),
    );
  }
}

/// The installed version, read from the platform.
final appVersionProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return '${info.version} (${info.buildNumber})';
});

class AboutSettings extends ConsumerWidget {
  const AboutSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final version = ref.watch(appVersionProvider).value;
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.lock_outline),
          title: Text(l10n.aboutPrivacy),
        ),
        ListTile(
          leading: const Icon(Icons.code),
          title: Text(l10n.aboutLicense),
        ),
        if (version != null)
          ListTile(
            leading: const Icon(Icons.tag),
            title: Text(l10n.aboutVersion(version)),
          ),
        // For checking new pixel art (docs/ART_GUIDE.md).
        if (kDebugMode)
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: Text(l10n.artGallery),
            onTap: () => ArtGallery.open(context),
          ),
        ListTile(
          leading: const Icon(Icons.school_outlined),
          title: Text(l10n.aboutReplayIntro),
          onTap: () {
            ref
                .read(settingsProvider.notifier)
                .update((s) => s.copyWith(onboardingDone: false));
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        ),
      ],
    );
  }
}
