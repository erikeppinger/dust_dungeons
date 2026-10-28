import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/app_database.dart';
import '../../data/providers.dart';
import '../../domain/points.dart';
import '../../l10n/app_localizations.dart';
import 'chore_edit_screen.dart';
import 'chore_tile.dart';
import 'chore_titles.dart';

/// Grid of active chores. Tap to complete (with undo), long-press to edit.
/// Becomes the "due today" list once scheduling exists (0.2.0).
class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key});

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen> {
  /// Taps on the same chore within this window count as one (double taps).
  static const _tapCooldown = Duration(seconds: 1);
  final _lastTap = <int, DateTime>{};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final chores = ref.watch(activeChoresProvider);
    final counts = ref.watch(todayCountsProvider).value ?? const {};

    return Scaffold(
      body: chores.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(child: Text(l10n.errorGeneric)),
        data: (list) => CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: _BalanceHeader()),
            if (list.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      l10n.noChores,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                // Bottom padding keeps the last row clear of the FAB.
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 88),
                sliver: SliverGrid.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 200,
                    mainAxisExtent: 150,
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 4,
                  ),
                  itemCount: list.length,
                  itemBuilder: (context, i) {
                    final chore = list[i];
                    return ChoreTile(
                      key: ValueKey(chore.id),
                      title: choreTitle(chore, l10n),
                      iconKey: chore.iconKey,
                      colorKey: chore.colorKey,
                      points: pointsForCompletion(basePoints: chore.basePoints),
                      doneToday: counts[chore.id] ?? 0,
                      onTap: () => _complete(chore),
                      onLongPress: () => ChoreEditScreen.open(context, chore),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'addChore',
        onPressed: () => ChoreEditScreen.open(context, null),
        icon: const Icon(Icons.add),
        label: Text(l10n.addChore),
      ),
    );
  }

  Future<void> _complete(Chore chore) async {
    final now = DateTime.now();
    final last = _lastTap[chore.id];
    if (last != null && now.difference(last) < _tapCooldown) return;
    _lastTap[chore.id] = now;

    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final progress = ref.read(progressRepositoryProvider);
    final result = await progress.complete(
      choreId: chore.id,
      profileId: ref.read(currentProfileIdProvider),
    );
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            l10n.choreCompleted(choreTitle(chore, l10n), result.points),
          ),
          action: SnackBarAction(
            label: l10n.undo,
            onPressed: () => unawaited(progress.undo(result.completionId)),
          ),
        ),
      );
  }
}

class _BalanceHeader extends ConsumerWidget {
  const _BalanceHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final balance = ref.watch(balanceProvider).value ?? 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.stars, color: theme.colorScheme.primary, size: 32),
              const SizedBox(width: 8),
              Text(
                l10n.pointsValue(balance),
                style: theme.textTheme.headlineSmall,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(l10n.tapToComplete, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
