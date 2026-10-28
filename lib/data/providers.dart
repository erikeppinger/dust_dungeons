import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/day_clock.dart';
import 'db/app_database.dart';
import 'repositories/chore_repository.dart';
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
