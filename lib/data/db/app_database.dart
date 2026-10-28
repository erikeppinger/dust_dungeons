import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

import '../../domain/default_chores.dart';
import '../../domain/fight/boss.dart';
import '../../domain/recurrence.dart';
import 'tables.dart';

export 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [Profiles, Chores, Completions, PointLedger, Settings, Fights],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  /// The on-device database file in the app's private support directory.
  AppDatabase.open()
    : _clock = DateTime.now,
      super(
        driftDatabase(
          name: 'chores',
          native: const DriftNativeOptions(
            databaseDirectory: getApplicationSupportDirectory,
          ),
        ),
      );

  final DateTime Function() _clock;

  /// Bump on every schema change, add a step to [migration], dump the schema
  /// (`dart run drift_dev schema dump ... drift_schemas/`) and add a
  /// migration test.
  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        // v2: schedules. Built-in chores get their default rhythm.
        await m.addColumn(chores, chores.repeatType);
        await m.addColumn(chores, chores.repeatInterval);
        await m.addColumn(chores, chores.repeatWeekdays);
        await m.addColumn(chores, chores.repeatDayOfMonth);
        await m.addColumn(chores, chores.repeatStart);
        await m.addColumn(chores, chores.repeatSetAt);
        for (final (i, seed) in defaultChores.indexed) {
          await (update(
            chores,
          )..where((c) => c.seedKey.equals(seed.key))).write(
            scheduleColumns(seed.defaultRecurrence(_clock(), i), _clock()),
          );
        }
      }
      if (from < 3) {
        // v3: optional per-chore reminder time.
        await m.addColumn(chores, chores.reminderMinutes);
      }
      if (from < 4) {
        // v4: boss fights. Tokens are derived, so nothing to backfill:
        // every past completion already counts as an earned token.
        await m.addColumn(chores, chores.bossFamily);
        await m.createTable(fights);
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
      await _ensureDefaults();
    },
  );

  /// Creates the default profile and inserts built-in chores that are missing.
  /// Runs on every start, so chores added to [defaultChores] in later versions
  /// appear after an update. Existing rows (including archived or edited ones)
  /// are never touched.
  Future<void> _ensureDefaults() => transaction(() async {
    final hasProfile = await (select(profiles)..limit(1)).getSingleOrNull();
    if (hasProfile == null) {
      await into(profiles).insert(ProfilesCompanion.insert(name: 'Me'));
    }
    for (final (i, seed) in defaultChores.indexed) {
      await into(chores).insert(
        ChoresCompanion.insert(
          seedKey: Value(seed.key),
          iconKey: seed.iconKey,
          colorKey: seed.colorKey,
          basePoints: seed.basePoints,
          sortOrder: Value(i),
        ).withSchedule(seed.defaultRecurrence(_clock(), i), _clock()),
        mode: InsertMode.insertOrIgnore,
      );
    }
  });

  /// The profile used until profile switching exists (0.8).
  Future<int> defaultProfileId() async {
    final first =
        await (select(profiles)
              ..orderBy([(p) => OrderingTerm.asc(p.id)])
              ..limit(1))
            .getSingle();
    return first.id;
  }
}

/// Boss family of a stored chore.
extension ChoreFamily on Chore {
  BossFamily get family => bossFamily ?? familyOfSeed(seedKey);
}

/// Schedule of a stored chore.
extension ChoreSchedule on Chore {
  Recurrence get recurrence => Recurrence(
    type: repeatType,
    interval: repeatInterval < 1 ? 1 : repeatInterval,
    weekdays: weekdaysFromMask(repeatWeekdays),
    dayOfMonth: repeatDayOfMonth,
    start: repeatStart ?? createdAt,
  );

  /// The last completion that counts for the schedule: one-off chores ignore
  /// completions from before the schedule was set.
  DateTime? countedLastDone(DateTime? lastDone) {
    final setAt = repeatSetAt;
    if (repeatType == RepeatType.once &&
        lastDone != null &&
        setAt != null &&
        lastDone.isBefore(setAt)) {
      return null;
    }
    return lastDone;
  }
}

extension ChoresCompanionSchedule on ChoresCompanion {
  /// This companion with the schedule columns of [r] set.
  ChoresCompanion withSchedule(Recurrence r, DateTime now) {
    final s = scheduleColumns(r, now);
    return copyWith(
      repeatType: s.repeatType,
      repeatInterval: s.repeatInterval,
      repeatWeekdays: s.repeatWeekdays,
      repeatDayOfMonth: s.repeatDayOfMonth,
      repeatStart: s.repeatStart,
      repeatSetAt: s.repeatSetAt,
    );
  }
}

/// Columns to write when a chore's schedule is set.
ChoresCompanion scheduleColumns(Recurrence r, DateTime now) => ChoresCompanion(
  repeatType: Value(r.type),
  repeatInterval: Value(r.interval),
  repeatWeekdays: Value(weekdaysToMask(r.weekdays)),
  repeatDayOfMonth: Value(r.dayOfMonth),
  repeatStart: Value(r.start),
  repeatSetAt: Value(now),
);
