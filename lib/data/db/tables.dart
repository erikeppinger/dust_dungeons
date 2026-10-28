import 'package:drift/drift.dart';

import '../../domain/recurrence.dart';

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

enum LedgerReason { completion, undo }

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

/// Simple key/value store for app settings.
@DataClassName('SettingEntry')
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}
