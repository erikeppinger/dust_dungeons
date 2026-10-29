import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/day_clock.dart';
import 'db/app_database.dart';
import 'models/fight_progress.dart';
import 'models/progress_stats.dart';
import 'models/scheduled_chore.dart';
import 'repositories/chore_repository.dart';
import 'repositories/fight_repository.dart';
import 'backup/merge.dart' show currentProfileSetting;
import 'repositories/profile_repository.dart';
import 'repositories/progress_repository.dart';
import 'repositories/settings_repository.dart';
import 'repositories/shop_repository.dart';

/// The open database. Overridden in `main.dart` (and with an in-memory
/// database in tests).
final databaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError('databaseProvider must be overridden'),
);

final profileRepositoryProvider = Provider(
  (ref) => ProfileRepository(ref.watch(databaseProvider)),
);

/// The people loaded before the first frame. Overridden in `main.dart`.
final initialProfilesProvider = Provider<List<Profile>>(
  (ref) =>
      throw UnimplementedError('initialProfilesProvider must be overridden'),
);

/// Who was using the app last time. Overridden in `main.dart`.
final initialProfileIdProvider = Provider<int>(
  (ref) =>
      throw UnimplementedError('initialProfileIdProvider must be overridden'),
);

final _profilesStreamProvider = StreamProvider<List<Profile>>(
  (ref) => ref.watch(profileRepositoryProvider).watchActive(),
);

/// The people sharing this phone (not removed ones), oldest first. Never
/// empty.
final profilesProvider = Provider<List<Profile>>(
  (ref) =>
      ref.watch(_profilesStreamProvider).value ??
      ref.watch(initialProfilesProvider),
);

/// Who is using the app. Remembered on this phone (never taken from a
/// backup); falls back to the first person when the current one is removed.
class CurrentProfile extends Notifier<int> {
  @override
  int build() {
    ref.listen(profilesProvider, (_, people) {
      if (people.isNotEmpty && !people.any((p) => p.id == state)) {
        unawaited(select(people.first.id));
      }
    });
    return ref.read(initialProfileIdProvider);
  }

  Future<void> select(int id) async {
    state = id;
    final db = ref.read(databaseProvider);
    await db
        .into(db.settings)
        .insertOnConflictUpdate(
          SettingsCompanion.insert(key: currentProfileSetting, value: '$id'),
        );
  }
}

/// The active profile's id; everything per person watches this.
final currentProfileIdProvider = NotifierProvider<CurrentProfile, int>(
  CurrentProfile.new,
);

/// The active profile.
final currentProfileProvider = Provider<Profile>((ref) {
  final people = ref.watch(profilesProvider);
  final id = ref.watch(currentProfileIdProvider);
  return people.firstWhere((p) => p.id == id, orElse: () => people.first);
});

/// Who each chore is for, by chore id (only chores with assignees).
final choreAssigneesProvider = StreamProvider<Map<int, Set<int>>>(
  (ref) => ref.watch(profileRepositoryProvider).watchAssignees(),
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

/// Completions today per (chore id, profile id); resets at midnight.
final todayByPersonProvider = StreamProvider<Map<(int, int), int>>(
  (ref) => ref
      .watch(progressRepositoryProvider)
      .watchCountsByPerson(ref.watch(todayProvider)),
);

/// Latest counted completion per (chore id, profile id).
final lastDoneByPersonProvider = StreamProvider<Map<(int, int), DateTime>>(
  (ref) => ref.watch(progressRepositoryProvider).watchLastDoneByPerson(),
);

/// The schedule for [person], or the household's for `null` (see
/// [schedule]).
final _scheduleProvider =
    Provider.family<AsyncValue<List<ScheduledChore>>, int?>((ref, person) {
      final inputs = [
        ref.watch(activeChoresProvider),
        ref.watch(choreAssigneesProvider),
        ref.watch(lastDoneByPersonProvider),
        ref.watch(todayByPersonProvider),
      ];
      for (final input in inputs) {
        if (input.hasError) return AsyncError(input.error!, input.stackTrace!);
        if (!input.hasValue) return const AsyncLoading();
      }
      return AsyncData(
        schedule(
          chores: ref.watch(activeChoresProvider).requireValue,
          assignees: ref.watch(choreAssigneesProvider).requireValue,
          lastDone: ref.watch(lastDoneByPersonProvider).requireValue,
          doneToday: ref.watch(todayByPersonProvider).requireValue,
          today: ref.watch(todayProvider),
          person: person,
        ),
      );
    });

/// The current person's chores (anyone's and their own) with their due
/// state for today.
final scheduledChoresProvider = Provider<AsyncValue<List<ScheduledChore>>>(
  (ref) => ref.watch(_scheduleProvider(ref.watch(currentProfileIdProvider))),
);

/// Everyone's chores: anyone's once, personal ones once per person. For
/// notifications, since the phone is shared.
final householdScheduleProvider = Provider<AsyncValue<List<ScheduledChore>>>(
  (ref) => ref.watch(_scheduleProvider(null)),
);

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

/// Everyone's completions (not undone), oldest first: the household's
/// totals and the leaderboard.
final householdCompletionsProvider = StreamProvider<List<Completion>>(
  (ref) => ref.watch(progressRepositoryProvider).watchAllCompletions(null),
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

final shopRepositoryProvider = Provider(
  (ref) => ShopRepository(ref.watch(databaseProvider)),
);

/// Items bought in the shop: item key → count.
final inventoryProvider = StreamProvider<Map<String, int>>(
  (ref) => ref
      .watch(shopRepositoryProvider)
      .watchInventory(ref.watch(currentProfileIdProvider)),
);
