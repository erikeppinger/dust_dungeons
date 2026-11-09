import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/app_database.dart';
import '../../data/models/fight_progress.dart';
import '../../data/providers.dart';
import '../../domain/default_chores.dart';
import '../../domain/fight/boss.dart';
import '../../l10n/app_localizations.dart';
import '../fight/boss_art.dart';

/// Chore bosses that sleep: no tokens to fight them, and no active quest
/// feeds them (docs/design/more-bosses.md).
Set<BossFamily> sleepingBosses(FightProgress progress, List<Chore> chores) {
  final fed = {
    for (final c in chores)
      if (!c.isArchived) c.family,
  };
  return {
    for (final family in choreFamilies)
      if (progress.tokens(family) == 0 && !fed.contains(family)) family,
  };
}

/// The suggested quests for [family] still waiting in the archive.
List<Chore> suggestionsFor(BossFamily family, List<Chore> chores) => [
  for (final c in chores)
    if (c.isArchived &&
        suggestedSeeds.contains(c.seedKey) &&
        c.family == family)
      c,
];

/// The sleeping bosses, small and in one row at the end of the Arena. A tap
/// says which quests wake one, and offers its suggested quests.
class SleepingBosses extends ConsumerWidget {
  const SleepingBosses({super.key, required this.sleeping});

  final List<BossFamily> sleeping;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: [
          for (final family in sleeping)
            Tooltip(
              message: l10n.worldSleepingBoss(bossName(l10n, family)),
              child: InkWell(
                key: ValueKey('sleeping-${family.name}'),
                onTap: () => _explain(context, ref, family),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Opacity(
                    opacity: 0.6,
                    child: BossArt(
                      family: family,
                      size: 48,
                      mood: BossMood.defeated,
                      semanticLabel: l10n.worldSleepingBoss(
                        bossName(l10n, family),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _explain(
    BuildContext context,
    WidgetRef ref,
    BossFamily family,
  ) async {
    final l10n = AppLocalizations.of(context);
    final chores = ref.read(allChoresProvider).value ?? const <Chore>[];
    final waiting = suggestionsFor(family, chores);
    final wake = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(bossName(l10n, family)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: BossArt(
                family: family,
                size: 96,
                mood: BossMood.defeated,
                semanticLabel: '',
              ),
            ),
            const SizedBox(height: 12),
            Text(l10n.worldSleepingBody(bossSource(l10n, family))),
            if (waiting.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(l10n.worldSleepingSuggestions(waiting.length)),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              waiting.isEmpty ? l10n.worldSleepingOk : l10n.worldSleepingLater,
            ),
          ),
          if (waiting.isNotEmpty)
            FilledButton(
              key: const ValueKey('wake-boss'),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.worldSleepingWake),
            ),
        ],
      ),
    );
    if (wake != true) return;
    final repo = ref.read(choreRepositoryProvider);
    for (final chore in waiting) {
      await repo.setArchived(chore.id, archived: false);
    }
  }
}
