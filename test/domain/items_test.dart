import 'package:flutter_test/flutter_test.dart';
import 'package:homework_and_chores/domain/fight/boss.dart';
import 'package:homework_and_chores/domain/fight/items.dart';
import 'package:homework_and_chores/domain/fight/shop.dart';

/// Gear, loot and curses: docs/design/items.md.
void main() {
  group('catalog', () {
    test('every boss drops something; gear has a slot', () {
      for (final family in BossFamily.values) {
        expect(lootTable(family), isNotEmpty, reason: family.name);
      }
      expect(lootTable(BossFamily.overlord), hasLength(2));
      for (final item in allGear) {
        expect(item.slot, isNotNull, reason: item.key);
        expect(item.kind, ItemKind.gear);
      }
      expect(lootItems.every((i) => i.isLoot && i.price == 0), isTrue);
      expect(armoryGear.every((i) => !i.isLoot && i.price > 0), isTrue);
    });

    test('two hands clash with shields, slots with themselves', () {
      expect(mopOfDoomItem.clashesWith(shieldItem), isTrue);
      expect(shieldItem.clashesWith(mopOfDoomItem), isTrue);
      expect(mopItem.clashesWith(shieldItem), isFalse);
      expect(mopItem.clashesWith(spatulaItem), isTrue);
      expect(colanderItem.clashesWith(vestItem), isFalse);
    });
  });

  group('effects', () {
    test('add up, take the best multiplier and the shortest heal', () {
      final e =
          const Effects(hearts: 1, perfectTimes: 3, comboHeal: 10) +
          const Effects(hearts: 2, perfectTimes: 4) +
          const Effects(comboHeal: 8);
      expect(e.hearts, 3);
      expect(e.perfectTimes, 4);
      expect(e.comboHeal, 8);
    });

    test('strong here: only items with a boss bonus, against that boss', () {
      expect(strongAgainst(plungerItem, BossFamily.bath), isTrue);
      expect(strongAgainst(plungerItem, BossFamily.dust), isFalse);
      expect(strongAgainst(bootsItem, BossFamily.outside), isTrue);
      expect(strongAgainst(mopItem, BossFamily.bath), isFalse);
      final strong = {
        for (final f in BossFamily.values)
          for (final i in allGear)
            if (strongAgainst(i, f)) i,
      };
      expect(strong, {bootsItem, dusterItem, helmItem, plungerItem});
    });

    test('in general, effects against one boss are left out', () {
      const l = Loadout(gear: {GearSlot.feet: bootsItem});
      expect(l.against().hearts, 0);
      expect(l.against(BossFamily.bath).hearts, 2);
    });

    test('equipped keys become items; unknown keys are skipped', () {
      final l = Loadout.fromEquipped({
        GearSlot.head: 'colander_of_clarity',
        GearSlot.body: 'no_such_item',
      });
      expect(l.gear, {GearSlot.head: colanderItem});
    });
  });

  group('curses', () {
    test('each boss has one; only its quests lift it', () {
      for (final family in BossFamily.values) {
        final curse = curseOf(family);
        expect(curse.family, family);
        expect(curse.kind == CurseKind.slotOff, curse.slot != null);
      }
      final socks = curseOf(BossFamily.laundry);
      expect(questLifts(socks, BossFamily.laundry), isTrue);
      expect(questLifts(socks, BossFamily.kitchen), isFalse);
      expect(
        questLifts(curseOf(BossFamily.overlord), BossFamily.kitchen),
        isTrue,
      );
    });
  });

  group('loot', () {
    ShopItem? roll(
      int seed, {
      BossFamily family = BossFamily.laundry,
      int tier = 1,
      Set<String> owned = const {},
      int winsWithoutLoot = 0,
      int bonus = 0,
    }) => rollLoot(
      seed: seed,
      family: family,
      tier: tier,
      owned: owned,
      winsWithoutLoot: winsWithoutLoot,
      bonus: bonus,
    );

    int drops({int tier = 1, int bonus = 0}) => [
      for (var seed = 0; seed < 2000; seed++)
        if (roll(seed, tier: tier, bonus: bonus) != null) seed,
    ].length;

    test('chances grow with the tier and the sock', () {
      expect([1, 2, 3].map(lootChance), [20, 30, 40]);
      expect(drops(tier: 1), inInclusiveRange(330, 470));
      expect(drops(tier: 3), inInclusiveRange(720, 880));
      expect(drops(tier: 1, bonus: 15), inInclusiveRange(620, 780));
    });

    test('the same fight always rolls the same', () {
      for (var seed = 0; seed < 50; seed++) {
        expect(roll(seed), roll(seed));
      }
    });

    test('the Overlord always drops; after 4 dry wins the 5th drops', () {
      for (var seed = 0; seed < 100; seed++) {
        expect(roll(seed, family: BossFamily.overlord), isNotNull);
        expect(roll(seed, winsWithoutLoot: lootPityWins), helmItem);
      }
    });

    test('no duplicates: owned loot turns into a consumable', () {
      for (var seed = 0; seed < 100; seed++) {
        final item = roll(
          seed,
          owned: {helmItem.key},
          winsWithoutLoot: lootPityWins,
        );
        expect(preFightConsumables, contains(item));
        final overlord = roll(
          seed,
          family: BossFamily.overlord,
          owned: {mopOfDoomItem.key},
        );
        expect(overlord, capeItem);
      }
    });
  });
}
