import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/section_header.dart';
import '../../data/models/scheduled_chore.dart';
import '../../data/providers.dart';
import '../../domain/points.dart';
import '../../domain/progress.dart';
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
  /// Taps within this window after a completion are ignored. Global, not per
  /// chore: a completed tile moves to another section, so the second tap of
  /// a double tap would otherwise land on whichever tile took its place.
  static const _tapCooldown = Duration(milliseconds: 700);
  DateTime? _lastCompletion;

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
    final streakBeforeToday =
        ref.watch(progressStatsProvider).value?.streakBefore ?? 0;
    return [
      SliverToBoxAdapter(child: SectionHeader('$title (${chores.length})')),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        sliver: SliverGrid.builder(
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 200,
            mainAxisExtent: ChoreTile.heightFor(context),
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
          ),
          itemCount: chores.length,
          itemBuilder: (context, i) {
            final s = chores[i];
            // The points this tap would earn right now, bonuses included.
            final points = pointsFor(
              basePoints: s.chore.basePoints,
              onTime: s.isDueToday,
              streakDays: streakBeforeToday,
            );
            return ChoreTile(
              key: ValueKey(s.chore.id),
              title: choreTitle(s.chore, l10n),
              iconKey: s.chore.iconKey,
              colorKey: s.chore.colorKey,
              points: points.total,
              bonus: points.bonus,
              doneToday: s.doneToday,
              status: dueLabel(l10n, s.due, s.today),
              overdue: s.isOverdue,
              onTap: () => _complete(s),
              onLongPress: () => ChoreEditScreen.open(context, s.chore),
            );
          },
        ),
      ),
    ];
  }

  Future<void> _complete(ScheduledChore scheduled) async {
    final chore = scheduled.chore;
    final now = DateTime.now();
    final last = _lastCompletion;
    if (last != null && now.difference(last) < _tapCooldown) return;
    _lastCompletion = now;

    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final progress = ref.read(progressRepositoryProvider);
    final xpBefore = ref.read(progressStatsProvider).value?.xp;
    final result = await progress.complete(
      choreId: chore.id,
      profileId: ref.read(currentProfileIdProvider),
      onTime: scheduled.isDueToday,
    );
    unawaited(HapticFeedback.lightImpact());
    final points = result.points;
    final title = choreTitle(chore, l10n);
    final done = points.bonus > 0
        ? l10n.choreCompletedBonus(title, points.total, points.bonus)
        : l10n.choreCompleted(title, points.total);
    final newLevel = levelForXp((xpBefore ?? 0) + points.total);
    final leveledUp = xpBefore != null && newLevel > levelForXp(xpBefore);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(leveledUp ? '${l10n.levelUp(newLevel)}\n$done' : done),
          action: SnackBarAction(
            label: l10n.undo,
            onPressed: () => unawaited(progress.undo(result.completionId)),
          ),
          // Snackbars with an action stay forever by default; Undo is only
          // offered for a few seconds.
          persist: false,
          duration: const Duration(seconds: 5),
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
    final balance = ref.watch(balanceProvider).value;
    final stats = ref.watch(progressStatsProvider).value;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.stars, color: theme.colorScheme.primary, size: 32),
              const SizedBox(width: 8),
              Flexible(
                // Counts up to a new balance (instantly with reduced motion).
                // Built only once the balance is known, so opening the app
                // does not count up from zero.
                child: balance == null
                    ? const SizedBox.shrink()
                    : TweenAnimationBuilder<double>(
                        tween: Tween(end: balance.toDouble()),
                        duration: MediaQuery.disableAnimationsOf(context)
                            ? Duration.zero
                            : const Duration(milliseconds: 500),
                        curve: Curves.easeOut,
                        builder: (context, value, _) => Text(
                          l10n.pointsValue(value.round()),
                          style: theme.textTheme.headlineSmall,
                        ),
                      ),
              ),
            ],
          ),
          if (stats != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  Chip(
                    avatar: const Icon(Icons.military_tech, size: 18),
                    label: Text(l10n.levelValue(stats.level)),
                    visualDensity: VisualDensity.compact,
                  ),
                  Chip(
                    avatar: const Icon(Icons.local_fire_department, size: 18),
                    label: Text(l10n.streakDays(stats.currentStreak)),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
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
