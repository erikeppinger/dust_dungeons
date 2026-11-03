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
        await wearIfFree(_db, profileId, item);
        return PurchaseResult.bought;
      });

  /// The worn gear: slot → item key.
  Stream<Map<GearSlot, String>> watchEquipped(int profileId) =>
      (_db.select(_db.equipped)..where((e) => e.profileId.equals(profileId)))
          .watch()
          .map((rows) => {for (final r in rows) r.slot: r.itemKey});

  /// Wears [item] (which must be owned gear), taking off what clashes with
  /// it: the item in its slot, and a shield or two-handed weapon.
  Future<void> wear(int profileId, ShopItem item) => _db.transaction(() async {
    assert(item.kind == ItemKind.gear);
    final owned = await _row(profileId, item.key);
    if (owned == null || owned.count < 1) return;
    for (final worn in await _worn(_db, profileId)) {
      if (item.clashesWith(worn)) await takeOff(profileId, worn.slot!);
    }
    await _db
        .into(_db.equipped)
        .insertOnConflictUpdate(
          EquippedCompanion.insert(
            profileId: profileId,
            slot: item.slot!,
            itemKey: item.key,
          ),
        );
  });

  /// Empties [slot].
  Future<void> takeOff(int profileId, GearSlot slot) =>
      (_db.delete(_db.equipped)..where(
            (e) => e.profileId.equals(profileId) & e.slot.equalsValue(slot),
          ))
          .go();

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

  /// Uses a Soap of Uncursing on the waiting curse; `false` if there's no
  /// curse or no soap.
  Future<bool> useSoap(int profileId) => _db.transaction(() async {
    final profile = await (_db.select(
      _db.profiles,
    )..where((p) => p.id.equals(profileId))).getSingle();
    if (profile.curseFamily == null || !await use(profileId, curseLiftItem)) {
      return false;
    }
    await (_db.update(_db.profiles)..where((p) => p.id.equals(profileId)))
        .write(const ProfilesCompanion(curseFamily: Value(null)));
    return true;
  });

  Future<InventoryEntry?> _row(int profileId, String key) =>
      (_db.select(_db.inventory)..where(
            (i) => i.profileId.equals(profileId) & i.itemKey.equals(key),
          ))
          .getSingleOrNull();
}

Future<List<ShopItem>> _worn(AppDatabase db, int profileId) async => [
  for (final row in await (db.select(
    db.equipped,
  )..where((e) => e.profileId.equals(profileId))).get())
    ?shopItem(row.itemKey),
];

/// Puts on newly gotten [item] if nothing worn clashes with it, so a first
/// shield or mop works right away. Not gear: nothing happens.
Future<void> wearIfFree(AppDatabase db, int profileId, ShopItem item) async {
  if (item.kind != ItemKind.gear) return;
  final worn = await _worn(db, profileId);
  if (worn.any(item.clashesWith)) return;
  await db
      .into(db.equipped)
      .insertOnConflictUpdate(
        EquippedCompanion.insert(
          profileId: profileId,
          slot: item.slot!,
          itemKey: item.key,
        ),
      );
}
