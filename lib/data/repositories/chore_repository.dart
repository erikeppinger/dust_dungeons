import 'package:drift/drift.dart';

import '../../domain/recurrence.dart';
import '../db/app_database.dart';

class ChoreRepository {
  ChoreRepository(this._db, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final AppDatabase _db;
  final DateTime Function() _clock;

  /// All chores, active first, each group in display order.
  Stream<List<Chore>> watchAll() =>
      (_db.select(_db.chores)..orderBy([
            (c) => OrderingTerm.asc(c.isArchived),
            (c) => OrderingTerm.asc(c.sortOrder),
            (c) => OrderingTerm.asc(c.id),
          ]))
          .watch();

  /// Non-archived chores in display order.
  Stream<List<Chore>> watchActive() =>
      (_db.select(_db.chores)
            ..where((c) => c.isArchived.equals(false))
            ..orderBy([
              (c) => OrderingTerm.asc(c.sortOrder),
              (c) => OrderingTerm.asc(c.id),
            ]))
          .watch();

  /// Adds a user chore at the end of the list and returns its id.
  Future<int> add({
    required String title,
    required String iconKey,
    required int colorKey,
    required int basePoints,
    required Recurrence recurrence,
    int? reminderMinutes,
    BossFamily? bossFamily,
    TimeWindow? times,
  }) => _db.transaction(() async {
    final maxOrder = _db.chores.sortOrder.max();
    final row = await (_db.selectOnly(
      _db.chores,
    )..addColumns([maxOrder])).getSingle();
    return _db
        .into(_db.chores)
        .insert(
          ChoresCompanion.insert(
            customTitle: Value(title),
            iconKey: iconKey,
            colorKey: colorKey,
            basePoints: basePoints,
            sortOrder: Value((row.read(maxOrder) ?? -1) + 1),
            reminderMinutes: Value(reminderMinutes),
            bossFamily: Value(bossFamily),
            windowFrom: Value(times?.from),
            windowTo: Value(times?.to),
          ).withSchedule(recurrence, _clock()),
        );
  });

  /// Updates a chore. A `null` [customTitle] means "use the built-in localized
  /// title" and is only valid for chores with a seed key. The schedule (and
  /// its "set at" time) is only rewritten when [recurrence] changed.
  Future<void> update(
    int id, {
    required String? customTitle,
    required String iconKey,
    required int colorKey,
    required int basePoints,
    required Recurrence recurrence,
    int? reminderMinutes,
    BossFamily? bossFamily,
    TimeWindow? times,
  }) => _db.transaction(() async {
    final current = await (_db.select(
      _db.chores,
    )..where((c) => c.id.equals(id))).getSingle();
    var changes = ChoresCompanion(
      customTitle: Value(customTitle),
      iconKey: Value(iconKey),
      colorKey: Value(colorKey),
      basePoints: Value(basePoints),
      reminderMinutes: Value(reminderMinutes),
      bossFamily: Value(bossFamily),
      windowFrom: Value(times?.from),
      windowTo: Value(times?.to),
    );
    if (current.recurrence != recurrence) {
      changes = changes.withSchedule(recurrence, _clock());
    }
    await (_db.update(
      _db.chores,
    )..where((c) => c.id.equals(id))).write(changes);
  });

  Future<void> setArchived(int id, {required bool archived}) async {
    await (_db.update(_db.chores)..where((c) => c.id.equals(id))).write(
      ChoresCompanion(isArchived: Value(archived)),
    );
  }
}
