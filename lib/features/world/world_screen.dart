import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/section_header.dart';
import '../../data/models/fight_progress.dart';
import '../../data/providers.dart';
import '../../domain/fight/boss.dart';
import '../../l10n/app_localizations.dart';
import '../fight/boss_art.dart';
import '../fight/fight_screen.dart';
import '../fight/fight_settings.dart';
import '../fight/hero_art.dart';
import '../settings/settings_controller.dart';
import '../settings/settings_pages.dart';
import 'avatar_editor.dart';

/// The hub: your hero, the bosses with their tokens, and the trophy shelf.
class WorldScreen extends ConsumerWidget {
  const WorldScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return ref
        .watch(fightProgressProvider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(child: Text(l10n.errorGeneric)),
          data: (progress) => ListView(
            padding: EdgeInsets.fromLTRB(
              12,
              4,
              12,
              16 + MediaQuery.paddingOf(context).bottom,
            ),
            children: [
              const _HeroCard(),
              SectionHeader(
                '${l10n.worldBosses} · ${l10n.worldTokens(progress.totalTokens)}',
              ),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 0.78,
                children: [
                  // Playable bosses first.
                  for (final family in [
                    ...BossFamily.values.where(playableFamilies.contains),
                    ...BossFamily.values.where(
                      (f) => !playableFamilies.contains(f),
                    ),
                  ])
                    _BossCard(family: family, progress: progress),
                ],
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
          ),
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
    final hero = HeroStats.forLevel(level);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            HeroArt(
              skin: settings.avatarSkin,
              hair: settings.avatarHair,
              cape: settings.avatarCape,
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
                    l10n.worldHeroStats(hero.maxHp, hero.damage),
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () => AvatarEditor.open(context),
                    child: Text(l10n.worldCustomize),
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
    final (_, light) = bossColors(family);
    final playable = playableFamilies.contains(family);
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
                Opacity(
                  opacity: playable ? 1 : 0.55,
                  child: BossArt(family: family, size: 60),
                ),
                const Spacer(),
                Chip(
                  label: Text(l10n.worldTokenCount(tokens)),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
            const Spacer(),
            Text(
              bossName(l10n, family),
              style: theme.textTheme.titleSmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              playable
                  ? '${l10n.worldTier(progress.tier(family))} · ${bossSource(l10n, family)}'
                  : bossSource(l10n, family),
              style: theme.textTheme.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: playable && tokens > 0
                  ? FilledButton(
                      onPressed: () => FightScreen.open(
                        context,
                        family,
                        progress.tier(family),
                      ),
                      child: Text(l10n.worldFight),
                    )
                  : FilledButton.tonal(
                      onPressed: null,
                      child: Text(
                        playable ? l10n.worldNoTokens : l10n.worldComingSoon,
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
