import 'package:flutter/material.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/app_database.dart';
import '../../data/providers.dart';
import '../../game/game_data.dart' show overlordHolidays;
import '../../game/game_texts.dart';
import '../../l10n/app_localizations.dart';
import '../settings/settings_controller.dart';
import 'calibration_screen.dart';
import '../../app/art/art.dart';
import '../../app/theme/pixel.dart';

String difficultyName(AppLocalizations l10n, Difficulty d) => switch (d) {
  Difficulty.easy => l10n.difficultyEasy,
  Difficulty.balanced => l10n.difficultyBalanced,
  Difficulty.hard => l10n.difficultyHard,
};

/// Settings page content for boss fights.
class FightSettings extends ConsumerWidget {
  const FightSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final s = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);
    final people = ref.watch(profilesProvider);
    final person = ref.watch(currentProfileProvider);
    final profiles = ref.read(profileRepositoryProvider);
    return Column(
      children: [
        SwitchListTile(
          secondary: const PixelIcon(Sprites.uiVolume),
          title: Text(l10n.fightSettingSound),
          value: s.fightSound,
          onChanged: (v) => controller.update((x) => x.copyWith(fightSound: v)),
        ),
        SwitchListTile(
          secondary: const PixelIcon(Sprites.uiVibration),
          title: Text(l10n.fightSettingHaptics),
          value: s.fightHaptics,
          onChanged: (v) =>
              controller.update((x) => x.copyWith(fightHaptics: v)),
        ),
        SwitchListTile(
          key: const ValueKey('setting-curses'),
          secondary: const PixelIcon(Sprites.uiSad),
          title: Text(l10n.fightSettingCurses),
          subtitle: Text(l10n.fightSettingCursesSubtitle),
          value: s.curses,
          onChanged: (v) async {
            controller.update((x) => x.copyWith(curses: v));
            // Off lifts every waiting curse.
            if (!v) await profiles.liftAllCurses();
          },
        ),
        SwitchListTile(
          key: const ValueKey('setting-holidays'),
          secondary: const PixelIcon(Sprites.uiCalendar),
          title: Text(l10n.fightSettingHolidays),
          subtitle: Text(l10n.fightSettingHolidaysSubtitle),
          value: s.holidays.isNotEmpty,
          onChanged: (v) => controller.update(
            (x) => x.copyWith(
              holidays: v ? overlordHolidays.keys.toSet() : const {},
            ),
          ),
        ),
        if (s.holidays.isNotEmpty)
          for (final holiday in overlordHolidays.keys)
            CheckboxListTile(
              key: ValueKey('setting-holiday-$holiday'),
              contentPadding: const EdgeInsetsDirectional.only(
                start: 72,
                end: 16,
              ),
              title: Text(gameHolidaySetting(l10n, holiday) ?? holiday),
              value: s.holidays.contains(holiday),
              onChanged: (v) => controller.update(
                (x) => x.copyWith(
                  holidays: v == true
                      ? {...x.holidays, holiday}
                      : ({...x.holidays}..remove(holiday)),
                ),
              ),
            ),
        // Story and slow mode belong to the person; the rest to the phone.
        if (people.length > 1)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                l10n.fightModesFor(person.name),
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
          ),
        SwitchListTile(
          secondary: const PixelIcon(Sprites.uiBook),
          title: Text(l10n.fightSettingStory),
          subtitle: Text(l10n.fightSettingStorySubtitle),
          value: person.storyMode,
          onChanged: (v) => profiles.update(
            person.id,
            ProfilesCompanion(storyMode: Value(v)),
          ),
        ),
        ListTile(
          leading: const PixelIcon(Sprites.uiSpeed),
          title: Text(l10n.fightSettingDifficulty),
          subtitle: Text(l10n.fightSettingDifficultySubtitle),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: SizedBox(
            width: double.infinity,
            child: SegmentedButton<Difficulty>(
              key: const ValueKey('difficulty'),
              showSelectedIcon: false,
              segments: [
                for (final d in Difficulty.values)
                  ButtonSegment(value: d, label: Text(difficultyName(l10n, d))),
              ],
              selected: {person.difficulty},
              onSelectionChanged: (picked) => profiles.update(
                person.id,
                ProfilesCompanion(difficulty: Value(picked.single)),
              ),
            ),
          ),
        ),
        SwitchListTile(
          secondary: const PixelIcon(Sprites.uiSlow),
          title: Text(l10n.fightSettingSlow),
          subtitle: Text(l10n.fightSettingSlowSubtitle),
          value: person.slowMode,
          onChanged: (v) =>
              profiles.update(person.id, ProfilesCompanion(slowMode: Value(v))),
        ),
        ListTile(
          leading: const PixelIcon(Sprites.uiTimer),
          title: Text(l10n.fightSettingCalibrate),
          subtitle: Text(l10n.fightSettingCalibrateSubtitle(s.fightLatencyMs)),
          trailing: const PixelIcon(Sprites.uiChevronRight),
          onTap: () => CalibrationScreen.open(context),
        ),
      ],
    );
  }
}
