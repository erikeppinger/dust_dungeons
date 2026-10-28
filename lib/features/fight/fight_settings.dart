import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../settings/settings_controller.dart';

/// Settings page content for boss fights.
class FightSettings extends ConsumerWidget {
  const FightSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final s = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);
    return Column(
      children: [
        SwitchListTile(
          secondary: const Icon(Icons.volume_up_outlined),
          title: Text(l10n.fightSettingSound),
          value: s.fightSound,
          onChanged: (v) => controller.update((x) => x.copyWith(fightSound: v)),
        ),
        SwitchListTile(
          secondary: const Icon(Icons.vibration),
          title: Text(l10n.fightSettingHaptics),
          value: s.fightHaptics,
          onChanged: (v) =>
              controller.update((x) => x.copyWith(fightHaptics: v)),
        ),
        SwitchListTile(
          secondary: const Icon(Icons.auto_stories_outlined),
          title: Text(l10n.fightSettingStory),
          subtitle: Text(l10n.fightSettingStorySubtitle),
          value: s.fightStoryMode,
          onChanged: (v) =>
              controller.update((x) => x.copyWith(fightStoryMode: v)),
        ),
      ],
    );
  }
}
