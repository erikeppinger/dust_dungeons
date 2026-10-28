import 'package:drift/drift.dart';

import '../../domain/fight/shop.dart';
import '../db/app_database.dart';

enum PurchaseResult { bought, notEnoughPoints, alreadyOwned }

/// Buying with points and using consumables.
class ShopRepository {
  ShopRepository(this._db, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final AppDatabase _db;
  final DateTime Function() _clock;

  /// Owned items: item key → count.
  Stream<Map<String, int>> watchInventory(int profileId) =>
      (_db.select(_db.inventory)..where((i) => i.profileId.equals(profileId)))
          .watch()
          .map((rows) => {for (final r in rows) r.itemKey: r.count});

  /// Buys [item] if the balance allows it. One transaction: the balance check,
  /// the negative ledger entry and the inventory change succeed together.
  /// Spending never lowers XP (that comes from completions only).
  Future<PurchaseResult> buy(int profileId, ShopItem item) =>
      _db.transaction(() async {
        final sum = _db.pointLedger.delta.sum();
        final balance =
            (await (_db.selectOnly(_db.pointLedger)
                      ..addColumns([sum])
                      ..where(_db.pointLedger.profileId.equals(profileId)))
                    .getSingle())
                .read(sum) ??
            0;
        if (balance < item.price) return PurchaseResult.notEnoughPoints;
        final owned = await _row(profileId, item.key);
        if (owned != null && item.kind != ItemKind.consumable) {
          return PurchaseResult.alreadyOwned;
        }
        await _db
            .into(_db.pointLedger)
            .insert(
              PointLedgerCompanion.insert(
                profileId: profileId,
                delta: -item.price,
                reason: LedgerReason.spend,
                createdAt: _clock(),
              ),
            );
        await _db
            .into(_db.inventory)
            .insertOnConflictUpdate(
              InventoryCompanion.insert(
                profileId: profileId,
                itemKey: item.key,
                count: (owned?.count ?? 0) + 1,
              ),
            );
        return PurchaseResult.bought;
      });

  /// Uses one of a consumable; `false` if none is left.
  Future<bool> use(int profileId, ShopItem item) => _db.transaction(() async {
    assert(item.kind == ItemKind.consumable);
    final owned = await _row(profileId, item.key);
    if (owned == null || owned.count < 1) return false;
    await (_db.update(_db.inventory)..where(
          (i) => i.profileId.equals(profileId) & i.itemKey.equals(item.key),
        ))
        .write(InventoryCompanion(count: Value(owned.count - 1)));
    return true;
  });

  Future<InventoryEntry?> _row(int profileId, String key) =>
      (_db.select(_db.inventory)..where(
            (i) => i.profileId.equals(profileId) & i.itemKey.equals(key),
          ))
          .getSingleOrNull();
}
