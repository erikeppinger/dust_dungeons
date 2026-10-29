import 'package:drift/drift.dart';

import '../../domain/fight/boss.dart';
import '../../domain/recurrence.dart';

export '../../domain/fight/boss.dart' show BossFamily;
export '../../domain/recurrence.dart' show RepeatType;

/// A person using the app. 0.1 uses a single default profile; switching arrives in 0.8.
class Profiles extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  IntColumn get colorKey => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// A chore definition. Built-in chores have a [seedKey] and a localized title
/// unless the user renamed them ([customTitle]). User chores always have a [customTitle].
@DataClassName('Chore')
class Chores extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get seedKey => text().nullable().unique()();
  TextColumn get customTitle => text().nullable()();
  TextColumn get iconKey => text()();
  IntColumn get colorKey => integer()();
  IntColumn get basePoints => integer()();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  // Schedule (schema v2), see `Recurrence`.
  TextColumn get repeatType =>
      textEnum<RepeatType>().withDefault(const Constant('anytime'))();
  IntColumn get repeatInterval => integer().withDefault(const Constant(1))();

  /// Bitmask of weekdays, bit 0 = Monday.
  IntColumn get repeatWeekdays => integer().withDefault(const Constant(0))();
  IntColumn get repeatDayOfMonth => integer().nullable()();

  /// First occurrence; `null` falls back to [createdAt].
  DateTimeColumn get repeatStart => dateTime().nullable()();

  /// When the schedule was last changed. One-off chores only count
  /// completions made after this.
  DateTimeColumn get repeatSetAt => dateTime().nullable()();

  /// Reminder on due days, as minutes after midnight (schema v3); `null` = off.
  IntColumn get reminderMinutes => integer().nullable()();

  /// Boss family for fight tokens (schema v4); `null` = the default for the
  /// built-in chore, or the Clutter Imp for user chores.
  TextColumn get bossFamily => textEnum<BossFamily>().nullable()();
}

/// One time a chore was done. Undo sets [undoneAt] instead of deleting the row.
class Completions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get choreId => integer().references(Chores, #id)();
  IntColumn get profileId => integer().references(Profiles, #id)();
  DateTimeColumn get completedAt => dateTime()();
  IntColumn get pointsAwarded => integer()();
  DateTimeColumn get undoneAt => dateTime().nullable()();
}

/// Stored by name: only ever add values.
enum LedgerReason { completion, undo, spend }

/// Append-only point history. A profile's balance is the sum of its [delta]s.
@DataClassName('LedgerEntry')
class PointLedger extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get profileId => integer().references(Profiles, #id)();
  IntColumn get delta => integer()();
  TextColumn get reason => textEnum<LedgerReason>()();
  IntColumn get completionId =>
      integer().nullable().references(Completions, #id)();
  DateTimeColumn get createdAt => dateTime()();
}

enum FightResult { won, lost, abandoned }

/// One boss fight (schema v4). Starting a fight spends a token of its
/// family; [result] stays `null` while it runs (or if the app was killed,
/// which counts as abandoned).
class Fights extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get profileId => integer().references(Profiles, #id)();
  TextColumn get family => textEnum<BossFamily>()();
  IntColumn get tier => integer()();
  BoolColumn get storyMode => boolean().withDefault(const Constant(false))();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();
  TextColumn get result => textEnum<FightResult>().nullable()();
  IntColumn get perfect => integer().withDefault(const Constant(0))();
  IntColumn get good => integer().withDefault(const Constant(0))();
  IntColumn get miss => integer().withDefault(const Constant(0))();
}

/// Items bought in the shop (schema v5): gear and hats have count 1,
/// consumables any count.
@DataClassName('InventoryEntry')
class Inventory extends Table {
  IntColumn get profileId => integer().references(Profiles, #id)();
  TextColumn get itemKey => text()();
  IntColumn get count => integer()();

  @override
  Set<Column<Object>> get primaryKey => {profileId, itemKey};
}

/// Screen time per day (soft budget): saved so history, the Tired effect
/// and the daily summary survive Android dropping old usage after ~a week.
class ScreenDays extends Table {
  IntColumn get profileId => integer().references(Profiles, #id)();

  /// Local midnight of the day.
  DateTimeColumn get day => dateTime()();

  /// Foreground minutes of the chosen apps (last known for today).
  IntColumn get usedMinutes => integer().withDefault(const Constant(0))();

  /// The day's whole budget: base + earned by quests + vouchers.
  IntColumn get budgetMinutes => integer().withDefault(const Constant(0))();

  /// Minutes added by vouchers that day (part of [budgetMinutes]).
  IntColumn get voucherMinutes => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {profileId, day};
}

/// Simple key/value store for app settings.
@DataClassName('SettingEntry')
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}
