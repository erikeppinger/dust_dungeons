import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/art/art.dart';
import '../../app/theme/pixel.dart';
import '../../core/day_clock.dart';
import '../../data/db/app_database.dart';
import '../../data/providers.dart';
import '../../domain/dates.dart';
import '../../domain/leaderboard.dart';
import '../../l10n/app_localizations.dart';
import '../people/people_screen.dart';

/// "This week": everyone ranked by points earned since Monday, with last
/// week's winner. Shown in the Hall of Fame when several people share the
/// phone (docs/design/profiles.md).
class LeaderboardCard extends ConsumerWidget {
  const LeaderboardCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final people = ref.watch(profilesProvider);
    final week = weekStartOf(ref.watch(todayProvider));
    final done = [
      for (final c
          in ref.watch(householdCompletionsProvider).value ??
              const <Completion>[])
        (c.profileId, c.completedAt, c.pointsAwarded),
    ];
    final ids = [for (final p in people) p.id];
    final byId = {for (final p in people) p.id: p};
    final rows = leaderboard(completions: done, people: ids, weekStart: week);
    final last = weekWinners(
      completions: done,
      people: ids,
      weekStart: addDays(week, -7),
    );
    final lastPoints = last.isEmpty
        ? 0
        : leaderboard(
            completions: done,
            people: ids,
            weekStart: addDays(week, -7),
          ).first.points;
    return Card(
      key: const ValueKey('leaderboard'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.leaderboardTitle, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            for (final row in rows) _Row(row: row, person: byId[row.person]!),
            if (last.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                last.length == 1
                    ? l10n.leaderboardLastWeek(
                        byId[last.first]!.name,
                        lastPoints,
                      )
                    : l10n.leaderboardLastWeekTie(
                        [for (final id in last) byId[id]!.name].join(', '),
                        lastPoints,
                      ),
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.row, required this.person});

  final LeaderRow row;
  final Profile person;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final leads = row.rank == 1 && row.points > 0;
    // One TalkBack node per row; the rank is said, never only shown.
    return MergeSemantics(
      child: Semantics(
        label: l10n.leaderboardRow(
          row.rank,
          person.name,
          row.points,
          l10n.leaderboardQuests(row.quests),
        ),
        excludeSemantics: true,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              SizedBox(
                width: 32,
                child: Text(
                  '${row.rank}.',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontFamily: pixelFont,
                    fontSize: 12,
                  ),
                ),
              ),
              PersonAvatar(person),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        person.name,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    if (leads) ...[
                      const SizedBox(width: 6),
                      PixelIcon(
                        Sprites.crown,
                        size: 24,
                        palette: PixelColors.of(context).palette.colors,
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    l10n.pointsValue(row.points),
                    style: theme.textTheme.titleSmall,
                  ),
                  Text(
                    l10n.leaderboardQuests(row.quests),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
