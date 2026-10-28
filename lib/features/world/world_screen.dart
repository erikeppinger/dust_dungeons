import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/day_clock.dart';
import '../../core/widgets/section_header.dart';
import '../../data/models/fight_progress.dart';
import '../../data/providers.dart';
import '../../domain/fight/boss.dart';
import '../../domain/fight/shop.dart';
import '../../l10n/app_localizations.dart';
import '../fight/boss_art.dart';
import '../fight/fight_screen.dart';
import '../fight/fight_settings.dart';
import '../fight/hero_art.dart';
import '../settings/settings_controller.dart';
import '../settings/settings_pages.dart';
import 'avatar_editor.dart';
import 'quest_map.dart';
import 'shop_screen.dart';

/// The hub: your hero, the weekly Overlord, the bosses with their tokens,
/// and the trophy shelf.
class WorldScreen extends ConsumerWidget {
  const WorldScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    // Watched here so it is loaded before any fight reads the gear.
    final inventory = ref.watch(inventoryProvider).value ?? const {};
    final today = ref.watch(todayProvider);
    return ref
        .watch(fightProgressProvider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(child: Text(l10n.errorGeneric)),
          data: (progress) =>
              _list(context, progress, Loadout.fromInventory(inventory), today),
        );
  }

  Widget _list(
    BuildContext context,
    FightProgress progress,
    Loadout loadout,
    DateTime today,
  ) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: EdgeInsets.fromLTRB(
        12,
        4,
        12,
        16 + MediaQuery.paddingOf(context).bottom,
      ),
      children: [
        const _HeroCard(),
        SectionHeader(l10n.worldWeeklyBoss),
        _OverlordCard(progress: progress, loadout: loadout, today: today),
        SectionHeader(
          '${l10n.worldBosses} · ${l10n.worldTokens(progress.totalTokens)}',
        ),
        // Two cards per row, each row as tall as its fuller card: names and
        // buttons wrap differently by language and font size.
        for (var i = 0; i < choreFamilies.length; i += 2)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final family in choreFamilies.skip(i).take(2))
                  Expanded(
                    child: _BossCard(
                      family: family,
                      progress: progress,
                      loadout: loadout,
                    ),
                  ),
              ],
            ),
          ),
        SectionHeader(l10n.worldTrophies),
        _TrophyShelf(progress: progress),
        const SizedBox(height: 8),
        ListTile(
          leading: const Icon(Icons.tune),
          title: Text(l10n.settingsFights),
          trailing: const Icon(Icons.chevron_right),
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

class _HeroCard extends ConsumerWidget {
  const _HeroCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    final stats = ref.watch(progressStatsProvider).value;
    final level = stats?.level ?? 1;
    final loadout = Loadout.fromInventory(
      ref.watch(inventoryProvider).value ?? const {},
    );
    final hero = HeroStats.forLevel(level);
    final hearts = hero.maxHp + (loadout.gloves ? 1 : 0);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            HeroArt(
              skin: settings.avatarSkin,
              hair: settings.avatarHair,
              cape: settings.avatarCape,
              hat: settings.avatarHat,
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
                  LinearProgressIndicator(
                    value: stats?.levelProgress ?? 0,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                    semanticsLabel: l10n.levelValue(level),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.worldHeroStats(hearts, hero.damage),
                    style: theme.textTheme.bodySmall,
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
  const _BossCard({
    required this.family,
    required this.progress,
    required this.loadout,
  });

  final BossFamily family;
  final FightProgress progress;
  final Loadout loadout;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final (_, light) = bossColors(family);
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
                BossArt(family: family, size: 60),
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
              bossName(l10n, family),
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
                      onPressed: () => FightScreen.open(
                        context,
                        family,
                        progress.tier(family),
                        loadout,
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
    required this.loadout,
    required this.today,
  });

  final FightProgress progress;
  final Loadout loadout;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    const family = BossFamily.overlord;
    final wins = progress.weekWinFamilies(today);
    final ready = progress.overlordReady(today);
    final beaten = progress.overlordBeaten(today);
    final (_, light) = bossColors(family);
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
            Text(bossName(l10n, family), style: theme.textTheme.titleMedium),
            Text(
              l10n.worldTier(progress.tier(family)),
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            QuestMap(
              wins: wins,
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
                onPressed: () => FightScreen.open(
                  context,
                  family,
                  progress.tier(family),
                  loadout,
                  motifs: progress.weekBeaten(today),
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
              leading: const Icon(Icons.emoji_events, color: Color(0xFFE6C463)),
              title: Text(trophyName(l10n, family)),
              subtitle: Text(
                l10n.worldTrophyWins(
                  progress.wins(family),
                  ((progress.bestAccuracy(family) ?? 0) * 100).round(),
                ),
              ),
              trailing: BossArt(family: family, size: 36),
            ),
        ],
      ),
    );
  }
}
