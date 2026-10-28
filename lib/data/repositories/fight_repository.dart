import 'package:drift/drift.dart';

import '../db/app_database.dart';

/// Boss fights: starting one spends a token, finishing records the result.
class FightRepository {
  FightRepository(this._db, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final AppDatabase _db;
  final DateTime Function() _clock;

  /// All fights of a profile, oldest first.
  Stream<List<Fight>> watchAll(int profileId) =>
      (_db.select(_db.fights)
            ..where((f) => f.profileId.equals(profileId))
            ..orderBy([(f) => OrderingTerm.asc(f.startedAt)]))
          .watch();

  /// Records the start of a fight (this spends the token) and returns its id.
  Future<int> start({
    required int profileId,
    required BossFamily family,
    required int tier,
    required bool storyMode,
  }) => _db
      .into(_db.fights)
      .insert(
        FightsCompanion.insert(
          profileId: profileId,
          family: family,
          tier: tier,
          storyMode: Value(storyMode),
          startedAt: _clock(),
        ),
      );

  /// Records how a fight ended. A fight that already has a result is left
  /// unchanged, so a late second call cannot overwrite it.
  Future<void> finish(
    int id, {
    required FightResult result,
    required int perfect,
    required int good,
    required int miss,
  }) async {
    await (_db.update(
      _db.fights,
    )..where((f) => f.id.equals(id) & f.result.isNull())).write(
      FightsCompanion(
        result: Value(result),
        endedAt: Value(_clock()),
        perfect: Value(perfect),
        good: Value(good),
        miss: Value(miss),
      ),
    );
  }
}
