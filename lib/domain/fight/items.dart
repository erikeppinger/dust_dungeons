import 'dart:math';

import '../../game/game_data.dart';
import 'boss.dart';
import 'effects.dart';
import 'shop.dart';

export 'effects.dart';

/// What [item] does against [family]; `null` family: in general (as shown
/// on the hero card), without effects against one boss.
Effects effectsOf(ShopItem item, [BossFamily? family]) =>
    (family == null ? null : item.against[family]) ?? item.effects;

/// Whether [item] does more against [family] than in general (for the
/// "strong here" hint before a fight).
bool strongAgainst(ShopItem item, BossFamily family) =>
    effectsOf(item, family) != effectsOf(item);

/// What a curse does: never more than one of these.
enum CurseKind {
  /// One heart fewer (never below 3).
  heart,

  /// Timing windows narrower than normal.
  tightTiming,

  /// The item in [Curse.slot] does nothing.
  slotOff,
}

/// The curse a boss leaves after winning against the hero. It works in the
/// next fight only.
class Curse {
  const Curse(this.family, this.kind, [this.slot]);

  /// The boss that cast it; its quests lift it.
  final BossFamily family;
  final CurseKind kind;

  /// For [CurseKind.slotOff].
  final GearSlot? slot;

  Effects get effects => switch (kind) {
    CurseKind.heart => const Effects(hearts: -1),
    CurseKind.tightTiming => const Effects(tightTiming: true),
    CurseKind.slotOff => Effects.none,
  };
}

/// Each boss's curse (game/bosses.toml).
Curse curseOf(BossFamily family) => bossCurses[family]!;

/// Whether doing a quest of [questFamily] lifts [curse]. The Overlord feeds
/// on no quest, so any quest lifts its curse.
bool questLifts(Curse curse, BossFamily questFamily) =>
    curse.family == BossFamily.overlord || curse.family == questFamily;

/// The fewest hearts a curse can leave.
const cursedMinHearts = cursesMinHearts;

/// What a hero brings to a fight: the gear worn, the consumables picked for
/// it, and a curse if one is waiting.
class Loadout {
  const Loadout({
    this.gear = const {},
    this.consumables = const [],
    this.curse,
  });

  /// From the worn items (slot → item key).
  factory Loadout.fromEquipped(
    Map<GearSlot, String> equipped, {
    List<ShopItem> consumables = const [],
    Curse? curse,
  }) => Loadout(
    gear: {
      for (final MapEntry(:key, :value) in equipped.entries)
        key: ?shopItem(value),
    },
    consumables: consumables,
    curse: curse,
  );

  final Map<GearSlot, ShopItem> gear;
  final List<ShopItem> consumables;
  final Curse? curse;

  static const none = Loadout();

  /// The worn items that work (a curse can switch one off).
  Iterable<ShopItem> get working => gear.entries
      .where((e) => !(curse?.kind == CurseKind.slotOff && curse?.slot == e.key))
      .map((e) => e.value);

  /// Everything together, against [family] (`null`: in general).
  Effects against([BossFamily? family]) {
    var total = Effects.none;
    for (final item in [...working, ...consumables]) {
      total += effectsOf(item, family);
    }
    return total + (curse?.effects ?? Effects.none);
  }
}

/// Hero hearts with [effects]: a curse never takes them below
/// [cursedMinHearts] (or below what the hero has without it, if fewer).
int heartsWith(int baseHearts, Effects effects) =>
    max(baseHearts + effects.hearts, min(baseHearts, cursedMinHearts));

/// Loot chance in percent for a boss of [tier] (1–3).
int lootChance(int tier) => lootChanceByTier[tier.clamp(1, 3) - 1];

/// Wins in a row without loot after which the next win always drops.
const lootPityWins = lootSureAfterDryWins;

/// The items [family] can drop.
List<ShopItem> lootTable(BossFamily family) => [
  for (final item in lootItems)
    if (item.dropsFrom == family) item,
];

/// What a won fight drops, or `null`. [owned]: keys of the items the hero
/// has; [winsWithoutLoot]: wins since the last drop. Seeded, so a fight
/// always rolls the same.
ShopItem? rollLoot({
  required int seed,
  required BossFamily family,
  required int tier,
  required Set<String> owned,
  required int winsWithoutLoot,
  int bonus = 0,
}) {
  final random = Random(seed);
  final roll = random.nextInt(100);
  final drops =
      family == BossFamily.overlord ||
      winsWithoutLoot >= lootPityWins ||
      roll < lootChance(tier) + bonus;
  if (!drops) return null;
  final missing = [
    for (final item in lootTable(family))
      if (!owned.contains(item.key)) item,
  ];
  if (missing.isNotEmpty) return missing[random.nextInt(missing.length)];
  return preFightConsumables[random.nextInt(preFightConsumables.length)];
}
