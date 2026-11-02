import 'package:drift/drift.dart';

import '../../domain/fight/items.dart';
import '../../domain/fight/shop.dart';
import '../db/app_database.dart';
import 'shop_repository.dart';

/// Boss fights: starting one spends a token, finishing records the result,
/// the loot and the curse.
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

  /// Records the start of a fight (this spends the token) and returns its
  /// id. A waiting curse works in this fight, so it's used up now.
  Future<int> start({
    required int profileId,
    required BossFamily family,
    required int tier,
    required bool storyMode,
  }) => _db.transaction(() async {
    await _setCurse(profileId, null);
    return _db
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
  });

  /// Records how a fight ended and returns what a win dropped. A fight that
  /// already has a result is left unchanged, so a late second call can't
  /// overwrite it (or drop loot twice). A loss leaves the boss's curse when
  /// [curses] is on and the fight wasn't in story mode.
  Future<ShopItem?> finish(
    int id, {
    required FightResult result,
    required int perfect,
    required int good,
    required int miss,
    bool curses = false,
  }) => _db.transaction(() async {
    final changed =
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
    if (changed == 0) return null;
    final fight = await (_db.select(
      _db.fights,
    )..where((f) => f.id.equals(id))).getSingle();
    if (result == FightResult.lost && curses && !fight.storyMode) {
      await _setCurse(fight.profileId, fight.family);
    }
    if (result != FightResult.won) return null;
    final loot = await _rollLoot(fight);
    if (loot == null) return null;
    await (_db.update(_db.fights)..where((f) => f.id.equals(id))).write(
      FightsCompanion(loot: Value(loot.key)),
    );
    final have =
        await (_db.select(_db.inventory)..where(
              (i) =>
                  i.profileId.equals(fight.profileId) &
                  i.itemKey.equals(loot.key),
            ))
            .getSingleOrNull();
    await _db
        .into(_db.inventory)
        .insertOnConflictUpdate(
          InventoryCompanion.insert(
            profileId: fight.profileId,
            itemKey: loot.key,
            count: (have?.count ?? 0) + 1,
          ),
        );
    await wearIfFree(_db, fight.profileId, loot);
    return loot;
  });

  Future<ShopItem?> _rollLoot(Fight fight) async {
    final earlier =
        await (_db.select(_db.fights)
              ..where(
                (f) =>
                    f.profileId.equals(fight.profileId) &
                    f.id.isSmallerThanValue(fight.id) &
                    f.result.equalsValue(FightResult.won),
              )
              ..orderBy([(f) => OrderingTerm.desc(f.id)]))
            .get();
    final winsWithoutLoot = earlier.takeWhile((f) => f.loot == null).length;
    final owned = {
      for (final i in await (_db.select(
        _db.inventory,
      )..where((i) => i.profileId.equals(fight.profileId))).get())
        if (i.count > 0) i.itemKey,
    };
    final worn = await (_db.select(
      _db.equipped,
    )..where((e) => e.profileId.equals(fight.profileId))).get();
    final bonus = Loadout.fromEquipped({
      for (final w in worn) w.slot: w.itemKey,
    }).against(fight.family).lootBonus;
    return rollLoot(
      seed: fight.id,
      family: fight.family,
      tier: fight.tier,
      owned: owned,
      winsWithoutLoot: winsWithoutLoot,
      bonus: bonus,
    );
  }

  Future<void> _setCurse(int profileId, BossFamily? family) =>
      (_db.update(_db.profiles)..where((p) => p.id.equals(profileId))).write(
        ProfilesCompanion(curseFamily: Value(family)),
      );
}
