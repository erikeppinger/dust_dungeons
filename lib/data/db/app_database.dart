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
  tables: [
    Profiles,
    Chores,
    Completions,
    PointLedger,
    Settings,
    Fights,
    Inventory,
    ScreenDays,
    ChoreAssignees,
    Equipped,
  ],
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
  int get schemaVersion => 10;

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
            // Only columns that exist at v2; later ones get their defaults
            // when their own step adds them.
            _v2ScheduleColumns(
              scheduleColumns(seed.defaultRecurrence(_clock(), i), _clock()),
            ),
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
      if (from < 5) {
        // v5: the shop's inventory. The ledger gains the "spend" reason,
        // which needs no schema change (stored as text).
        await m.createTable(inventory);
      }
      if (from < 6) {
        // v6: the soft screen-time budget's daily totals.
        await m.createTable(screenDays);
      }
      if (from < 7) {
        // v7: profiles. Every chore is for anyone; the hero's look and the
        // fight modes move from settings onto the (only) profile.
        for (final column in [
          profiles.avatarSkin,
          profiles.avatarHair,
          profiles.avatarCape,
          profiles.avatarHat,
          profiles.storyMode,
          profiles.slowMode,
          profiles.archivedAt,
        ]) {
          await m.addColumn(profiles, column);
        }
        await m.addColumn(chores, chores.assignment);
        await m.createTable(choreAssignees);
        await customStatement("""
          UPDATE profiles SET
            avatar_skin = COALESCE((SELECT CAST(value AS INTEGER) FROM settings WHERE key = 'avatarSkin'), 0),
            avatar_hair = COALESCE((SELECT CAST(value AS INTEGER) FROM settings WHERE key = 'avatarHair'), 0),
            avatar_cape = COALESCE((SELECT CAST(value AS INTEGER) FROM settings WHERE key = 'avatarCape'), 0),
            avatar_hat = COALESCE((SELECT CAST(value AS INTEGER) FROM settings WHERE key = 'avatarHat'), 0),
            story_mode = COALESCE((SELECT value = 'true' FROM settings WHERE key = 'fightStoryMode'), 0),
            slow_mode = COALESCE((SELECT value = 'true' FROM settings WHERE key = 'fightSlowMode'), 0)
        """);
        await customStatement(
          "DELETE FROM settings WHERE key IN ('avatarSkin', 'avatarHair', "
          "'avatarCape', 'avatarHat', 'fightStoryMode', 'fightSlowMode')",
        );
      }
      if (from < 8) {
        // v8: better schedules. Existing chores keep their behaviour: on the
        // day of the month, open for one day, at any time.
        await m.addColumn(chores, chores.repeatMonthWeek);
        await m.addColumn(chores, chores.windowDays);
        await m.addColumn(chores, chores.windowFrom);
        await m.addColumn(chores, chores.windowTo);
      }
      if (from < 9) {
        // v9: loot & gear. Everyone wears the gear they own; the four items
        // from before sit in four different slots, so no effect is lost.
        await m.createTable(equipped);
        await m.addColumn(profiles, profiles.curseFamily);
        // Databases from before v4 got the fights table in its current shape.
        if (!await _hasColumn('fights', 'loot')) {
          await m.addColumn(fights, fights.loot);
        }
        await customStatement('''
          INSERT INTO equipped (profile_id, slot, item_key)
          SELECT profile_id, CASE item_key
              WHEN 'sponge_shield' THEN 'shield'
              WHEN 'turbo_mop' THEN 'weapon'
              WHEN 'metronome_charm' THEN 'charm'
              WHEN 'rubber_gloves' THEN 'body'
            END, item_key
          FROM inventory
          WHERE count > 0 AND item_key IN
            ('sponge_shield', 'turbo_mop', 'metronome_charm', 'rubber_gloves')
        ''');
      }
      if (from < 10) {
        // v10: fight difficulty per person; everyone starts on balanced.
        await m.addColumn(profiles, profiles.difficulty);
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
      await _ensureDefaults();
    },
  );

  Future<bool> _hasColumn(String table, String column) async =>
      (await customSelect(
        'SELECT 1 FROM pragma_table_info(?) WHERE name = ?',
        variables: [Variable(table), Variable(column)],
      ).get()).isNotEmpty;

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
    monthWeek: repeatMonthWeek,
    windowDays: windowDays < 0 ? 1 : windowDays,
    start: repeatStart ?? createdAt,
  );

  /// The times of day it's meant to be done; `null` = any time.
  TimeWindow? get timeWindow {
    final from = windowFrom, to = windowTo;
    return from == null || to == null ? null : TimeWindow(from, to);
  }

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
      repeatMonthWeek: s.repeatMonthWeek,
      windowDays: s.windowDays,
      repeatStart: s.repeatStart,
      repeatSetAt: s.repeatSetAt,
    );
  }
}

/// [all] limited to the schedule columns of schema v2.
ChoresCompanion _v2ScheduleColumns(ChoresCompanion all) => ChoresCompanion(
  repeatType: all.repeatType,
  repeatInterval: all.repeatInterval,
  repeatWeekdays: all.repeatWeekdays,
  repeatDayOfMonth: all.repeatDayOfMonth,
  repeatStart: all.repeatStart,
  repeatSetAt: all.repeatSetAt,
);

/// Columns to write when a chore's schedule is set.
ChoresCompanion scheduleColumns(Recurrence r, DateTime now) => ChoresCompanion(
  repeatType: Value(r.type),
  repeatInterval: Value(r.interval),
  repeatWeekdays: Value(weekdaysToMask(r.weekdays)),
  repeatDayOfMonth: Value(r.dayOfMonth),
  repeatMonthWeek: Value(r.monthWeek),
  windowDays: Value(r.windowDays),
  repeatStart: Value(r.start),
  repeatSetAt: Value(now),
);
