import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/app_database.dart';
import '../../core/widgets/section_header.dart';
import '../../data/models/scheduled_chore.dart';
import '../../data/providers.dart';
import '../../domain/points.dart';
import '../../l10n/app_localizations.dart';
import 'chore_edit_screen.dart';
import 'chore_tile.dart';
import 'chore_titles.dart';
import 'schedule_text.dart';

/// Active chores grouped into overdue, due today, done today and later.
/// Tap to complete (with undo), long-press to edit.
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
    final scheduled = ref.watch(scheduledChoresProvider);

    return Scaffold(
      body: scheduled.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(child: Text(l10n.errorGeneric)),
        data: (list) {
          final sections = TodaySections(list);
          final nothingDue =
              sections.overdue.isEmpty && sections.dueToday.isEmpty;
          return CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(child: _BalanceHeader()),
              if (list.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _Message(l10n.noChores),
                )
              else ...[
                if (nothingDue)
                  SliverToBoxAdapter(child: _Message(l10n.allCaughtUp)),
                ..._section(l10n.sectionOverdue, sections.overdue),
                ..._section(l10n.sectionDueToday, sections.dueToday),
                ..._section(l10n.sectionDoneToday, sections.doneToday),
                ..._section(l10n.sectionLater, sections.later),
                // Keeps the last row clear of the FAB.
                const SliverToBoxAdapter(child: SizedBox(height: 88)),
              ],
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'addChore',
        onPressed: () => ChoreEditScreen.open(context, null),
        icon: const Icon(Icons.add),
        label: Text(l10n.addChore),
      ),
    );
  }

  /// Header plus tile grid; nothing for an empty section.
  List<Widget> _section(String title, List<ScheduledChore> chores) {
    if (chores.isEmpty) return const [];
    final l10n = AppLocalizations.of(context);
    return [
      SliverToBoxAdapter(child: SectionHeader('$title (${chores.length})')),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        sliver: SliverGrid.builder(
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 200,
            mainAxisExtent: 168,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
          ),
          itemCount: chores.length,
          itemBuilder: (context, i) {
            final s = chores[i];
            return ChoreTile(
              key: ValueKey(s.chore.id),
              title: choreTitle(s.chore, l10n),
              iconKey: s.chore.iconKey,
              colorKey: s.chore.colorKey,
              points: pointsForCompletion(basePoints: s.chore.basePoints),
              doneToday: s.doneToday,
              status: dueLabel(l10n, s.due, s.today),
              overdue: s.isOverdue,
              onTap: () => _complete(s.chore),
              onLongPress: () => ChoreEditScreen.open(context, s.chore),
            );
          },
        ),
      ),
    ];
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

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Center(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleMedium,
      ),
    ),
  );
}
