import 'package:flutter_test/flutter_test.dart';
import 'package:homework_and_chores/data/db/app_database.dart';
import 'package:homework_and_chores/data/repositories/progress_repository.dart';
import 'package:homework_and_chores/data/repositories/shop_repository.dart';
import 'package:homework_and_chores/domain/fight/shop.dart';

import '../helpers.dart';

void main() {
  late AppDatabase db;
  late ShopRepository shop;
  late ProgressRepository progress;
  late int profile;

  setUp(() async {
    db = memoryDb();
    shop = ShopRepository(db);
    progress = ProgressRepository(db);
    profile = await db.defaultProfileId();
  });

  tearDown(() => db.close());

  /// Earns points by completing the 40-point "clean windows" chore.
  Future<void> earn(int times) async {
    final windows = (await db.select(db.chores).get()).singleWhere(
      (c) => c.seedKey == 'clean_windows',
    );
    for (var i = 0; i < times; i++) {
      await progress.complete(choreId: windows.id, profileId: profile);
    }
  }

  Future<int> balance() => progress.watchBalance(profile).first;

  test('buying costs points, never XP, and needs enough of them', () async {
    expect(await shop.buy(profile, charmItem), PurchaseResult.notEnoughPoints);
    await earn(3); // 120 points
    expect(await shop.buy(profile, charmItem), PurchaseResult.bought);
    expect(await balance(), 20);
    expect(await shop.watchInventory(profile).first, {'metronome_charm': 1});

    // XP is the sum of completions and is unaffected by spending.
    final completions = await db.select(db.completions).get();
    expect(completions.fold(0, (s, c) => s + c.pointsAwarded), 120);
    final ledger = await db.select(db.pointLedger).get();
    expect(ledger.last.reason, LedgerReason.spend);
    expect(ledger.last.delta, -100);
  });

  test('gear and hats are bought once; consumables stack', () async {
    await earn(10); // 400 points
    expect(await shop.buy(profile, charmItem), PurchaseResult.bought);
    expect(await shop.buy(profile, charmItem), PurchaseResult.alreadyOwned);
    expect(await shop.buy(profile, hats.first), PurchaseResult.bought);
    expect(await shop.buy(profile, hats.first), PurchaseResult.alreadyOwned);
    expect(await shop.buy(profile, secondWindItem), PurchaseResult.bought);
    expect(await shop.buy(profile, secondWindItem), PurchaseResult.bought);
    expect((await shop.watchInventory(profile).first)['second_wind'], 2);
    expect(await balance(), 400 - 100 - 80 - 60 - 60);
  });

  test('consumables are used up one at a time', () async {
    await earn(2);
    await shop.buy(profile, secondWindItem);
    expect(await shop.use(profile, secondWindItem), isTrue);
    expect(await shop.use(profile, secondWindItem), isFalse);
    expect((await shop.watchInventory(profile).first)['second_wind'], 0);
  });

  test('loadout comes from what is owned', () {
    final l = Loadout.fromInventory({'sponge_shield': 1, 'second_wind': 3});
    expect(l.shield, isTrue);
    expect(l.turboMop, isFalse);
    expect(Loadout.fromInventory(const {}).gloves, isFalse);
  });

  test('every shop item key is unique', () {
    final keys = shopItems.map((i) => i.key).toList();
    expect(keys.toSet(), hasLength(keys.length));
    expect(shopItem('turbo_mop'), mopItem);
    expect(shopItem('nope'), isNull);
  });
}
