import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:homework_and_chores/data/db/app_database.dart';
import 'package:homework_and_chores/data/repositories/progress_repository.dart';
import 'package:homework_and_chores/data/repositories/screen_time_repository.dart';
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

  Future<Map<GearSlot, String>> worn() => shop.watchEquipped(profile).first;

  test('new gear is worn when its slot is free', () async {
    await earn(15);
    await shop.buy(profile, mopItem);
    await shop.buy(profile, spatulaItem);
    expect(await worn(), {GearSlot.weapon: 'turbo_mop'});
    await shop.buy(profile, secondWindItem);
    expect(await worn(), hasLength(1));
  });

  test('wearing swaps the slot; two hands push out the shield', () async {
    await earn(20);
    await shop.buy(profile, mopItem);
    await shop.buy(profile, spatulaItem);
    await shop.buy(profile, shieldItem);
    await shop.wear(profile, spatulaItem);
    expect(await worn(), {
      GearSlot.weapon: 'spatula_of_flipping',
      GearSlot.shield: 'sponge_shield',
    });
    await db
        .into(db.inventory)
        .insert(
          InventoryCompanion.insert(
            profileId: profile,
            itemKey: mopOfDoomItem.key,
            count: 1,
          ),
        );
    await shop.wear(profile, mopOfDoomItem);
    expect(await worn(), {GearSlot.weapon: 'mop_of_doom'});
    await shop.wear(profile, shieldItem);
    expect(await worn(), {GearSlot.shield: 'sponge_shield'});
    await shop.takeOff(profile, GearSlot.shield);
    expect(await worn(), isEmpty);
  });

  test('only owned gear can be worn', () async {
    await shop.wear(profile, vestItem);
    expect(await worn(), isEmpty);
  });

  test('soap lifts a curse, and is kept without one', () async {
    await earn(1);
    await shop.buy(profile, soapItem);
    expect(await shop.useSoap(profile), isFalse);
    await (db.update(db.profiles)..where((p) => p.id.equals(profile))).write(
      const ProfilesCompanion(curseFamily: Value(BossFamily.trash)),
    );
    expect(await shop.useSoap(profile), isTrue);
    final p = await (db.select(
      db.profiles,
    )..where((p) => p.id.equals(profile))).getSingle();
    expect(p.curseFamily, isNull);
    expect((await shop.watchInventory(profile).first)[soapItem.key], 0);
  });

  test('every shop item key is unique', () {
    final keys = shopItems.map((i) => i.key).toList();
    expect(keys.toSet(), hasLength(keys.length));
    expect(shopItem('turbo_mop'), mopItem);
    expect(shopItem('nope'), isNull);
  });

  group('screen-time vouchers', () {
    final day = DateTime(2026, 10, 29);

    test(
      'using one takes it from the inventory and books its minutes',
      () async {
        final screen = ScreenTimeRepository(db);
        final voucher = screenVouchers.first;
        expect(await screen.useVoucher(profile, voucher, day), isFalse);
        await earn(2); // 80 points
        expect(await shop.buy(profile, voucher), PurchaseResult.bought);
        expect(await shop.buy(profile, voucher), PurchaseResult.bought);
        expect(await screen.useVoucher(profile, voucher, day), isTrue);
        expect(await screen.useVoucher(profile, voucher, day), isTrue);
        expect(await screen.useVoucher(profile, voucher, day), isFalse);
        final days = await screen.watchDays(profile).first;
        expect(days.single.voucherMinutes, 30);

        // Saving the day's use keeps the voucher minutes.
        await screen.saveDay(profile, day, usedMinutes: 50, budgetMinutes: 90);
        final saved = (await screen.watchDays(profile).first).single;
        expect(
          (saved.usedMinutes, saved.budgetMinutes, saved.voucherMinutes),
          (50, 90, 30),
        );
      },
    );

    test('vouchers are consumables that add 15 or 30 minutes', () {
      expect(screenVouchers.map(voucherMinutes), [15, 30]);
      expect(
        screenVouchers.every((v) => v.kind == ItemKind.consumable),
        isTrue,
      );
    });
  });
}
