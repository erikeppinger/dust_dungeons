import 'package:flutter/material.dart';

import '../../app/theme/pixel.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/chore_palette.dart';
import '../../core/widgets/section_header.dart';
import '../../data/db/app_database.dart';
import '../../data/models/progress_stats.dart';
import '../../data/providers.dart';
import '../../domain/points.dart';
import '../../l10n/app_localizations.dart';
import '../chores/chore_icons.dart';
import '../chores/chore_titles.dart';
import '../chores/schedule_text.dart';
import 'leaderboard_card.dart';
import 'realm_card.dart';
import '../../app/art/art.dart';

/// Level, streaks, point totals, the last 7 days and the most done chores.
class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return ref
        .watch(progressStatsProvider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(child: Text(l10n.errorGeneric)),
          data: (stats) => ListView(
            padding: EdgeInsets.fromLTRB(
              12,
              8,
              12,
              16 + MediaQuery.paddingOf(context).bottom,
            ),
            children: [
              if (ref.watch(profilesProvider).length > 1)
                const LeaderboardCard(),
              LevelCard(stats: stats),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _StatTile(
                      icon: const PixelFlame(),
                      value: l10n.streakDays(stats.currentStreak),
                      label: l10n.statsBestStreak(stats.bestStreak),
                    ),
                  ),
                  Expanded(
                    child: _StatTile(
                      icon: PixelIcon(
                        Sprites.uiCheck,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      value: '${stats.completions}',
                      label: l10n.statsChoresDone,
                    ),
                  ),
                ],
              ),
              SectionHeader(l10n.statsRealm),
              const RealmCard(),
              SectionHeader(l10n.statsPoints),
              Card(
                child: Column(
                  children: [
                    _PointsRow(l10n.statsToday, stats.pointsToday),
                    _PointsRow(l10n.statsLast7Days, stats.points7Days),
                    _PointsRow(l10n.statsLast30Days, stats.points30Days),
                    _PointsRow(l10n.statsAllTime, stats.xp),
                  ],
                ),
              ),
              SectionHeader(l10n.statsLast7Days),
              _WeekBars(stats.last7Days),
              SectionHeader(l10n.statsTopChores),
              _TopChores(stats.top30Days),
              SectionHeader(l10n.statsHowPointsWork),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    l10n.statsPointsExplanation(
                      onTimeBonusPercent,
                      streakBonusPercentPerDay,
                      streakBonusPercentPerDay * maxStreakBonusDays,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
  }
}

/// Level with XP progress; also used compactly on the Today screen.
class LevelCard extends StatelessWidget {
  const LevelCard({super.key, required this.stats});

  final ProgressStats stats;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                LevelCoin(level: stats.level, size: 36),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    l10n.levelValue(stats.level),
                    style: theme.textTheme.headlineSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            PixelBar(
              value: stats.levelProgress,
              segments: 20,
              height: 16,
              color: theme.colorScheme.secondary,
              semanticsLabel: l10n.levelValue(stats.level),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.xpToNextLevel(stats.nextLevelXp - stats.xp, stats.level + 1),
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
  });

  final Widget icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            icon,
            const SizedBox(height: 8),
            Text(value, style: theme.textTheme.titleLarge),
            Text(label, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _PointsRow extends StatelessWidget {
  const _PointsRow(this.label, this.points);

  final String label;
  final int points;

  @override
  Widget build(BuildContext context) => ListTile(
    dense: true,
    title: Text(label),
    trailing: Text(
      AppLocalizations.of(context).pointsValue(points),
      style: Theme.of(context).textTheme.titleSmall,
    ),
  );
}

/// Simple bar chart of points per day.
class _WeekBars extends StatelessWidget {
  const _WeekBars(this.days);

  final List<(DateTime, int)> days;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final max = days.fold(0, (m, d) => d.$2 > m ? d.$2 : m);
    const barHeight = 120.0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 16, 8, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final (day, points) in days)
              Expanded(
                child: Semantics(
                  label:
                      '${weekdayShort(context, day.weekday)}: '
                      '${l10n.pointsValue(points)}',
                  excludeSemantics: true,
                  child: Column(
                    children: [
                      Text('$points', style: theme.textTheme.labelSmall),
                      const SizedBox(height: 4),
                      Container(
                        height: max == 0
                            ? 2
                            : 2 + (barHeight - 2) * points / max,
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        weekdayShort(context, day.weekday),
                        style: theme.textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TopChores extends ConsumerWidget {
  const _TopChores(this.top);

  final List<(int, int)> top;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final palette = Theme.of(context).extension<ChorePalette>()!;
    final chores = {
      for (final c in ref.watch(allChoresProvider).value ?? const <Chore>[])
        c.id: c,
    };
    final rows = [
      for (final (id, count) in top)
        if (chores[id] case final chore?)
          ListTile(
            dense: true,
            leading: CircleAvatar(
              radius: 18,
              backgroundColor: palette.colorFor(chore.colorKey),
              child: ChoreIcon(
                chore.iconKey,
                color: palette.onColorFor(chore.colorKey),
              ),
            ),
            title: Text(choreTitle(chore, l10n)),
            trailing: Text(l10n.timesDone(count)),
          ),
    ];
    return Card(
      child: rows.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(16),
              child: Text(l10n.statsNothingYet),
            )
          : Column(children: rows),
    );
  }
}
