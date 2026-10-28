import 'package:drift/drift.dart';

import '../db/app_database.dart';

class ChoreRepository {
  ChoreRepository(this._db);

  final AppDatabase _db;

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
          ),
        );
  });

  /// Updates a chore. A `null` [customTitle] means "use the built-in localized
  /// title" and is only valid for chores with a seed key.
  Future<void> update(
    int id, {
    required String? customTitle,
    required String iconKey,
    required int colorKey,
    required int basePoints,
  }) async {
    await (_db.update(_db.chores)..where((c) => c.id.equals(id))).write(
      ChoresCompanion(
        customTitle: Value(customTitle),
        iconKey: Value(iconKey),
        colorKey: Value(colorKey),
        basePoints: Value(basePoints),
      ),
    );
  }

  Future<void> setArchived(int id, {required bool archived}) async {
    await (_db.update(_db.chores)..where((c) => c.id.equals(id))).write(
      ChoresCompanion(isArchived: Value(archived)),
    );
  }
}
