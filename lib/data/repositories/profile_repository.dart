import 'package:drift/drift.dart';

import '../db/app_database.dart';

/// The people sharing this phone (docs/design/profiles.md).
class ProfileRepository {
  ProfileRepository(this._db);

  final AppDatabase _db;

  /// Active people (not removed), oldest first.
  Stream<List<Profile>> watchActive() =>
      (_db.select(_db.profiles)
            ..where((p) => p.archivedAt.isNull())
            ..orderBy([(p) => OrderingTerm.asc(p.id)]))
          .watch();

  Future<List<Profile>> active() =>
      (_db.select(_db.profiles)
            ..where((p) => p.archivedAt.isNull())
            ..orderBy([(p) => OrderingTerm.asc(p.id)]))
          .get();

  static String _key(String name) => name.trim().toLowerCase();

  /// Whether an active person other than [exceptId] has this name (case
  /// and outer spaces ignored): backups match people by name.
  Future<bool> nameTaken(String name, {int? exceptId}) async => (await active())
      .any((p) => p.id != exceptId && _key(p.name) == _key(name));

  /// Adds a person. A removed person with the same name comes back, with
  /// their history.
  Future<int> add({
    required String name,
    int colorKey = 0,
    int avatarSkin = 0,
    int avatarHair = 0,
    int avatarCape = 0,
  }) => _db.transaction(() async {
    final removed =
        (await (_db.select(
              _db.profiles,
            )..where((p) => p.archivedAt.isNotNull())).get())
            .where((p) => _key(p.name) == _key(name))
            .firstOrNull;
    if (removed != null) {
      await (_db.update(_db.profiles)..where((p) => p.id.equals(removed.id)))
          .write(const ProfilesCompanion(archivedAt: Value(null)));
      return removed.id;
    }
    return _db
        .into(_db.profiles)
        .insert(
          ProfilesCompanion.insert(
            name: name.trim(),
            colorKey: Value(colorKey),
            avatarSkin: Value(avatarSkin),
            avatarHair: Value(avatarHair),
            avatarCape: Value(avatarCape),
          ),
        );
  });

  /// Lifts every waiting curse (when curses are turned off).
  Future<void> liftAllCurses() => _db
      .update(_db.profiles)
      .write(const ProfilesCompanion(curseFamily: Value(null)));

  Future<void> update(int id, ProfilesCompanion changes) =>
      (_db.update(_db.profiles)..where((p) => p.id.equals(id))).write(changes);

  /// Removes a person but keeps their history. Chores only they were
  /// assigned become anyone's; they leave "each" chores, and an "each"
  /// chore with nobody left becomes anyone's too. The last person can't be
  /// removed.
  Future<void> remove(int id) => _db.transaction(() async {
    if ((await active()).length <= 1) {
      throw StateError('the last person cannot be removed');
    }
    await (_db.update(_db.profiles)..where((p) => p.id.equals(id))).write(
      ProfilesCompanion(archivedAt: Value(DateTime.now())),
    );
    final theirs = await (_db.select(
      _db.choreAssignees,
    )..where((a) => a.profileId.equals(id))).get();
    await (_db.delete(
      _db.choreAssignees,
    )..where((a) => a.profileId.equals(id))).go();
    for (final a in theirs) {
      final left = await (_db.select(
        _db.choreAssignees,
      )..where((x) => x.choreId.equals(a.choreId))).get();
      if (left.isEmpty) {
        await (_db.update(_db.chores)..where((c) => c.id.equals(a.choreId)))
            .write(const ChoresCompanion(assignment: Value(Assignment.anyone)));
      }
    }
  });

  /// Who each chore is for, by chore id (only chores with assignees).
  Stream<Map<int, Set<int>>> watchAssignees() =>
      _db.select(_db.choreAssignees).watch().map((rows) {
        final map = <int, Set<int>>{};
        for (final r in rows) {
          map.putIfAbsent(r.choreId, () => {}).add(r.profileId);
        }
        return map;
      });

  /// Sets who [choreId] is for. [people] is ignored for anyone's chores and
  /// must not be empty otherwise.
  Future<void> assign(int choreId, Assignment assignment, Set<int> people) =>
      _db.transaction(() async {
        final kept = assignment == Assignment.anyone ? <int>{} : people;
        final kind = kept.isEmpty ? Assignment.anyone : assignment;
        await (_db.update(_db.chores)..where((c) => c.id.equals(choreId)))
            .write(ChoresCompanion(assignment: Value(kind)));
        await (_db.delete(
          _db.choreAssignees,
        )..where((a) => a.choreId.equals(choreId))).go();
        for (final person in kind == Assignment.one ? kept.take(1) : kept) {
          await _db
              .into(_db.choreAssignees)
              .insert(
                ChoreAssigneesCompanion.insert(
                  choreId: choreId,
                  profileId: person,
                ),
              );
        }
      });
}
