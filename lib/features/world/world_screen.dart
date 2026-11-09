import 'package:flutter/material.dart';

import '../../app/theme/pixel.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/day_clock.dart';
import '../../core/widgets/section_header.dart';
import '../../data/models/fight_progress.dart';
import '../../data/providers.dart';
import '../../domain/fight/boss.dart';
import '../../domain/fight/overworld.dart';
import '../../domain/fight/items.dart';
import '../../domain/fight/overlord.dart';
import '../../game/game_data.dart' show overlordSchemes;
import '../../game/game_texts.dart';
import '../../l10n/app_localizations.dart';
import '../fight/boss_art.dart';
import '../fight/fight_prep_screen.dart';
import '../fight/fight_settings.dart';
import '../fight/hero_art.dart';
import '../fight/overlord_art.dart';
import '../settings/settings_controller.dart';
import '../settings/settings_pages.dart';
import '../../domain/screen_time.dart';
import '../screen_time/screen_time_providers.dart';
import 'avatar_editor.dart';
import 'gear_screen.dart';
import 'quest_map.dart';
import 'shop_screen.dart';
import 'sleeping_bosses.dart';
import '../../app/art/art.dart';

/// The hub: your hero, the weekly Overlord, the bosses with their tokens,
/// and the trophy shelf.
class WorldScreen extends ConsumerWidget {
  const WorldScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    // Watched here so it is loaded before a fight's start screen reads it.
    ref.watch(inventoryProvider);
    ref.watch(equippedProvider);
    final curse = ref.watch(curseProvider);
    final today = ref.watch(todayProvider);
    final holidays = ref.watch(settingsProvider.select((s) => s.holidays));
    final seed = ref.watch(settingsProvider.select((s) => s.overlordSeed));
    // Until the quests are loaded, no boss counts as sleeping.
    final chores = ref.watch(allChoresProvider).value;
    return ref
        .watch(fightProgressProvider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(child: Text(l10n.errorGeneric)),
          data: (progress) => _list(
            context,
            progress,
            curse,
            today,
            weekOverlord(progress, today, holidays, seed: seed),
            chores == null ? const {} : sleepingBosses(progress, chores),
          ),
        );
  }

  Widget _list(
    BuildContext context,
    FightProgress progress,
    Curse? curse,
    DateTime today,
    OverlordLook look,
    Set<BossFamily> sleeping,
  ) {
    final l10n = AppLocalizations.of(context);
    final awake = [
      for (final f in choreFamilies)
        if (!sleeping.contains(f)) f,
    ];
    return ListView(
      padding: EdgeInsets.fromLTRB(
        12,
        4,
        12,
        16 + MediaQuery.paddingOf(context).bottom,
      ),
      children: [
        const _HeroCard(),
        if (curse != null) CurseCard(curse: curse),
        SectionHeader(l10n.worldWeeklyBoss),
        _OverlordCard(progress: progress, today: today, look: look),
        SectionHeader(
          '${l10n.worldBosses} · ${l10n.worldTokens(progress.totalTokens)}',
        ),
        // Two cards per row, each row as tall as its fuller card: names and
        // buttons wrap differently by language and font size.
        // Bosses with tokens first, in the usual order.
        for (final row in _pairs([
          ...awake.where((f) => progress.tokens(f) > 0),
          ...awake.where((f) => progress.tokens(f) == 0),
        ]))
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final family in row)
                  Expanded(
                    child: _BossCard(family: family, progress: progress),
                  ),
                if (row.length == 1) const Expanded(child: SizedBox()),
              ],
            ),
          ),
        if (sleeping.isNotEmpty) ...[
          SectionHeader(l10n.worldSleeping),
          SleepingBosses(
            sleeping: [
              for (final f in choreFamilies)
                if (sleeping.contains(f)) f,
            ],
          ),
        ],
        SectionHeader(l10n.worldTrophies),
        _TrophyShelf(progress: progress),
        const SizedBox(height: 8),
        ListTile(
          leading: const PixelIcon(Sprites.uiTune),
          title: Text(l10n.settingsFights),
          trailing: const PixelIcon(Sprites.uiChevronRight),
          onTap: () => SettingsPage.open(
            context,
            (l) => l.settingsFights,
            const FightSettings(),
          ),
        ),
      ],
    );
  }
}

/// [items] two by two.
List<List<T>> _pairs<T>(List<T> items) => [
  for (var i = 0; i < items.length; i += 2) items.skip(i).take(2).toList(),
];

class _HeroCard extends ConsumerWidget {
  const _HeroCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final person = ref.watch(currentProfileProvider);
    final stats = ref.watch(progressStatsProvider).value;
    final level = stats?.level ?? 1;
    final hero = HeroStats.forLevel(level);
    final tired = ref.watch(tiredProvider);
    final hearts = heartsWith(
      tiredMaxHp(hero.maxHp, tired: tired),
      ref.watch(gearLoadoutProvider).against(),
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            HeroArt(
              skin: person.avatarSkin,
              hair: person.avatarHair,
              cape: person.avatarCape,
              hat: person.avatarHat,
              gear: ref.watch(equippedProvider).value ?? const {},
              size: 96,
              semanticLabel: l10n.worldHeroLevel(level),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.worldHeroLevel(level),
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  PixelBar(
                    value: stats?.levelProgress ?? 0,
                    color: theme.colorScheme.secondary,
                    semanticsLabel: l10n.levelValue(level),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.worldHeroStats(hearts, hero.damage),
                    style: theme.textTheme.bodySmall,
                  ),
                  if (tired)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Tooltip(
                        message: l10n.screenTiredHelp,
                        triggerMode: TooltipTriggerMode.tap,
                        child: Chip(
                          key: const ValueKey('tired'),
                          avatar: const PixelIcon(Sprites.uiMoon, size: 18),
                          label: Text(l10n.screenTired),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      OutlinedButton(
                        onPressed: () => AvatarEditor.open(context),
                        child: Text(l10n.worldCustomize),
                      ),
                      OutlinedButton(
                        key: const ValueKey('open-gear'),
                        onPressed: () => GearScreen.open(context),
                        child: Text(l10n.worldGear),
                      ),
                      FilledButton(
                        onPressed: () => ShopScreen.open(context),
                        child: Text(l10n.worldShop),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BossCard extends StatelessWidget {
  const _BossCard({required this.family, required this.progress});

  final BossFamily family;
  final FightProgress progress;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final (_, light) = bossFormColorPair(family, progress.tier(family));
    final tokens = progress.tokens(family);
    final background = Color.alphaBlend(
      light.withValues(alpha: 0.28),
      theme.colorScheme.surfaceContainerLow,
    );
    return Card(
      key: ValueKey('boss-${family.name}'),
      color: background,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BossArt(family: family, tier: progress.tier(family), size: 60),
                const Spacer(),
                Chip(
                  label: Text(l10n.worldTokenCount(tokens)),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Spacer(),
            Text(
              bossName(l10n, family, null, progress.tier(family)),
              style: theme.textTheme.titleSmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${l10n.worldTier(progress.tier(family))} · ${bossSource(l10n, family)}',
              style: theme.textTheme.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: progress.canFight(family)
                  ? FilledButton(
                      onPressed: () => FightPrepScreen.open(
                        context,
                        family,
                        progress.tier(family),
                      ),
                      child: Text(l10n.worldFight),
                    )
                  : FilledButton.tonal(
                      onPressed: null,
                      child: Text(
                        l10n.worldNoTokens,
                        textAlign: TextAlign.center,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The weekly Chore Overlord: how close it is, ready to fight, or beaten.
class _OverlordCard extends StatelessWidget {
  const _OverlordCard({
    required this.progress,
    required this.today,
    required this.look,
  });

  final FightProgress progress;
  final DateTime today;

  /// This week's Overlord.
  final OverlordLook look;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    const family = BossFamily.overlord;
    final wins = progress.weekWinFamilies(today);
    final ready = progress.overlordReady(today);
    final beaten = progress.overlordBeaten(today);
    // The week's Overlord's own light color.
    final light = Color(overlordSchemes[look.scheme]?.$2 ?? 0xFFB39DDB);
    return Card(
      key: const ValueKey('boss-overlord'),
      color: ready
          ? Color.alphaBlend(
              light.withValues(alpha: 0.35),
              theme.colorScheme.surfaceContainerLow,
            )
          : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                OverlordArt(
                  look: look,
                  size: 72,
                  mood: beaten ? BossMood.defeated : BossMood.idle,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        overlordName(l10n, look),
                        key: const ValueKey('overlord-name'),
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        '${l10n.gameBossOverlord} · '
                        '${l10n.worldTier(progress.tier(family))}',
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        overlordTraitLine(l10n, look),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            QuestMap(
              map: WeekMap.forWeek(today),
              wins: wins,
              tiers: progress.weekWinTiers(today),
              beaten: beaten,
              semanticLabel: l10n.worldOverlordProgress(
                wins.length.clamp(0, overlordWinsNeeded),
                overlordWinsNeeded,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              beaten
                  ? l10n.worldOverlordBeaten
                  : (ready
                        ? l10n.worldOverlordReady
                        : l10n.worldOverlordLocked),
            ),
            if (!ready && !beaten) ...[
              const SizedBox(height: 4),
              Text(
                l10n.worldOverlordProgress(wins.length, overlordWinsNeeded),
                style: theme.textTheme.bodySmall,
              ),
            ],
            if (ready) ...[
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () => FightPrepScreen.open(
                  context,
                  family,
                  progress.tier(family),
                  motifs: progress.weekBeaten(today),
                  look: look,
                ),
                child: Text(l10n.worldFight),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TrophyShelf extends StatelessWidget {
  const _TrophyShelf({required this.progress});

  final FightProgress progress;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final won = BossFamily.values.where((f) => progress.wins(f) > 0).toList();
    if (won.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(l10n.worldNoTrophies),
      );
    }
    return Card(
      child: Column(
        children: [
          for (final family in won)
            ListTile(
              leading: PixelTrophy(
                size: 32,
                tier: family == BossFamily.overlord
                    ? 3
                    : progress.bestTier(family),
              ),
              title: Text(trophyName(l10n, family)),
              subtitle: Text(
                l10n.worldTrophyWins(
                  progress.wins(family),
                  ((progress.bestAccuracy(family) ?? 0) * 100).round(),
                ),
              ),
              trailing: BossArt(
                family: family,
                tier: progress.bestTier(family),
                size: 36,
              ),
            ),
          for (final MapEntry(key: holiday, value: wins)
              in progress.holidayWins.entries)
            ListTile(
              key: ValueKey('holiday-trophy-$holiday'),
              leading: const PixelTrophy(size: 32),
              title: Text(gameHolidayTrophy(l10n, holiday) ?? holiday),
              subtitle: Text(l10n.worldHolidayTrophyWins(wins)),
              trailing: OverlordArt(look: holidayLook(holiday), size: 36),
            ),
        ],
      ),
    );
  }
}
