import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/day_clock.dart';
import 'db/app_database.dart';
import 'models/fight_progress.dart';
import 'models/progress_stats.dart';
import 'models/scheduled_chore.dart';
import 'repositories/chore_repository.dart';
import 'repositories/fight_repository.dart';
import 'repositories/progress_repository.dart';
import 'repositories/settings_repository.dart';

/// The open database. Overridden in `main.dart` (and with an in-memory
/// database in tests).
final databaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError('databaseProvider must be overridden'),
);

/// The active profile. Overridden in `main.dart`; switching arrives in 0.8.
final currentProfileIdProvider = Provider<int>(
  (ref) =>
      throw UnimplementedError('currentProfileIdProvider must be overridden'),
);

final choreRepositoryProvider = Provider(
  (ref) => ChoreRepository(ref.watch(databaseProvider)),
);

final progressRepositoryProvider = Provider(
  (ref) => ProgressRepository(ref.watch(databaseProvider)),
);

final settingsRepositoryProvider = Provider(
  (ref) => SettingsRepository(ref.watch(databaseProvider)),
);

final activeChoresProvider = StreamProvider(
  (ref) => ref.watch(choreRepositoryProvider).watchActive(),
);

final allChoresProvider = StreamProvider(
  (ref) => ref.watch(choreRepositoryProvider).watchAll(),
);

final balanceProvider = StreamProvider(
  (ref) => ref
      .watch(progressRepositoryProvider)
      .watchBalance(ref.watch(currentProfileIdProvider)),
);

/// Completions per chore id for today; resets at midnight.
final todayCountsProvider = StreamProvider<Map<int, int>>(
  (ref) => ref
      .watch(progressRepositoryProvider)
      .watchCompletionCounts(
        ref.watch(currentProfileIdProvider),
        ref.watch(todayProvider),
      ),
);

/// Latest counted completion per chore id.
final lastDoneProvider = StreamProvider<Map<int, DateTime>>(
  (ref) => ref
      .watch(progressRepositoryProvider)
      .watchLastDone(ref.watch(currentProfileIdProvider)),
);

/// Active chores with their due state for today.
final scheduledChoresProvider = Provider<AsyncValue<List<ScheduledChore>>>((
  ref,
) {
  final chores = ref.watch(activeChoresProvider);
  final lastDone = ref.watch(lastDoneProvider);
  final counts = ref.watch(todayCountsProvider);
  final today = ref.watch(todayProvider);
  if (chores.hasError) return AsyncError(chores.error!, chores.stackTrace!);
  if (lastDone.hasError) {
    return AsyncError(lastDone.error!, lastDone.stackTrace!);
  }
  if (counts.hasError) return AsyncError(counts.error!, counts.stackTrace!);
  final list = chores.value, last = lastDone.value, done = counts.value;
  if (list == null || last == null || done == null) {
    return const AsyncLoading();
  }
  return AsyncData([
    for (final chore in list)
      ScheduledChore(
        chore: chore,
        lastDone: last[chore.id],
        doneToday: done[chore.id] ?? 0,
        today: today,
      ),
  ]);
});

/// Completions in `[from, to)`, e.g. one calendar month.
/// Auto-disposed, so months that are no longer shown stop their query.
final completionsBetweenProvider = StreamProvider.autoDispose
    .family<List<Completion>, (DateTime, DateTime)>(
      (ref, range) => ref
          .watch(progressRepositoryProvider)
          .watchCompletionsBetween(
            ref.watch(currentProfileIdProvider),
            range.$1,
            range.$2,
          ),
    );

/// XP, level, streaks and point totals from the whole completion history.
final progressStatsProvider = Provider<AsyncValue<ProgressStats>>((ref) {
  final today = ref.watch(todayProvider);
  return ref
      .watch(allCompletionsProvider)
      .whenData((list) => ProgressStats(list, today: today));
});

/// Every completion (not undone), oldest first.
final allCompletionsProvider = StreamProvider<List<Completion>>(
  (ref) => ref
      .watch(progressRepositoryProvider)
      .watchAllCompletions(ref.watch(currentProfileIdProvider)),
);

final fightRepositoryProvider = Provider(
  (ref) => FightRepository(ref.watch(databaseProvider)),
);

final fightsProvider = StreamProvider<List<Fight>>(
  (ref) => ref
      .watch(fightRepositoryProvider)
      .watchAll(ref.watch(currentProfileIdProvider)),
);

/// Tokens, wins and tiers per boss family.
final fightProgressProvider = Provider<AsyncValue<FightProgress>>((ref) {
  final completions = ref.watch(allCompletionsProvider);
  final chores = ref.watch(allChoresProvider);
  final fights = ref.watch(fightsProvider);
  for (final value in [completions, chores, fights]) {
    if (value.hasError) return AsyncError(value.error!, value.stackTrace!);
  }
  final c = completions.value, ch = chores.value, f = fights.value;
  if (c == null || ch == null || f == null) return const AsyncLoading();
  return AsyncData(FightProgress(completions: c, chores: ch, fights: f));
});
