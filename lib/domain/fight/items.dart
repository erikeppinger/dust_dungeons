import 'dart:math';

import 'boss.dart';
import 'shop.dart';

/// What gear, consumables and curses do in a fight (docs/design/items.md).
/// They add up; none of them touch points, XP or streaks.
class Effects {
  const Effects({
    this.hearts = 0,
    this.damage = 0,
    this.goodDamage = 0,
    this.perfectTimes = 2,
    this.freeMisses = 0,
    this.wideTiming = false,
    this.tightTiming = false,
    this.comboHeal = 0,
    this.sneakAttack = false,
    this.slowerBoss = false,
    this.thirdMissFree = false,
    this.fullRevive = false,
    this.lootBonus = 0,
  });

  /// Extra (or, cursed, fewer) hearts.
  final int hearts;

  /// Extra damage on every hit.
  final int damage;

  /// Extra damage on Good hits.
  final int goodDamage;

  /// A Perfect hit deals this many times the hero's damage.
  final int perfectTimes;

  /// Misses that cost no heart, the first ones of the fight.
  final int freeMisses;

  /// Wider timing windows; [tightTiming] wins over it.
  final bool wideTiming;
  final bool tightTiming;

  /// Heals a heart after this many hits in a row (0: never).
  final int comboHeal;

  /// The first echo deals 50 % more damage (rounded up per hit).
  final bool sneakAttack;

  /// The boss plays 10 % slower.
  final bool slowerBoss;

  /// Every third miss costs no heart.
  final bool thirdMissFree;

  /// Second Wind brings back all hearts, not half.
  final bool fullRevive;

  /// Percentage points added to the loot chance.
  final int lootBonus;

  static const none = Effects();

  List<Object> get _fields => [
    hearts,
    damage,
    goodDamage,
    perfectTimes,
    freeMisses,
    wideTiming,
    tightTiming,
    comboHeal,
    sneakAttack,
    slowerBoss,
    thirdMissFree,
    fullRevive,
    lootBonus,
  ];

  @override
  bool operator ==(Object other) {
    if (other is! Effects) return false;
    final mine = _fields, theirs = other._fields;
    for (var i = 0; i < mine.length; i++) {
      if (mine[i] != theirs[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(_fields);

  Effects operator +(Effects other) => Effects(
    hearts: hearts + other.hearts,
    damage: damage + other.damage,
    goodDamage: goodDamage + other.goodDamage,
    perfectTimes: max(perfectTimes, other.perfectTimes),
    freeMisses: freeMisses + other.freeMisses,
    wideTiming: wideTiming || other.wideTiming,
    tightTiming: tightTiming || other.tightTiming,
    comboHeal: comboHeal == 0 || other.comboHeal == 0
        ? max(comboHeal, other.comboHeal)
        : min(comboHeal, other.comboHeal),
    sneakAttack: sneakAttack || other.sneakAttack,
    slowerBoss: slowerBoss || other.slowerBoss,
    thirdMissFree: thirdMissFree || other.thirdMissFree,
    fullRevive: fullRevive || other.fullRevive,
    lootBonus: lootBonus + other.lootBonus,
  );
}

/// What [item] does against [family]; `null` family: in general (as shown
/// on the hero card), without effects against one boss.
Effects effectsOf(ShopItem item, [BossFamily? family]) {
  bool against(BossFamily f) => family == f;
  return switch (item.key) {
    'sponge_shield' => const Effects(freeMisses: 1),
    'turbo_mop' => const Effects(perfectTimes: 3),
    'metronome_charm' => const Effects(wideTiming: true),
    'rubber_gloves' => const Effects(hearts: 1),
    'colander_of_clarity' => const Effects(hearts: 1),
    'spatula_of_flipping' => const Effects(goodDamage: 1),
    'hi_vis_vest' => const Effects(hearts: 2),
    'rubber_boots' =>
      against(BossFamily.bath) || against(BossFamily.outside)
          ? const Effects(hearts: 2)
          : Effects.none,
    'lucky_odd_sock' => const Effects(lootBonus: 15),
    'feather_duster' => Effects(
      comboHeal: 10,
      damage: against(BossFamily.dust) ? 1 : 0,
    ),
    'laundry_basket_helm' => Effects(
      hearts: against(BossFamily.laundry) ? 2 : 1,
    ),
    'apron_of_holding' => const Effects(hearts: 1, fullRevive: true),
    'plunger_of_smiting' => Effects(
      perfectTimes: against(BossFamily.bath) ? 4 : 3,
    ),
    'trash_can_lid' => const Effects(freeMisses: 2),
    'fuzzy_slippers' => const Effects(sneakAttack: true),
    'garden_gnome' => const Effects(thirdMissFree: true),
    'lost_remote' => const Effects(slowerBoss: true),
    'mop_of_doom' => const Effects(perfectTimes: 3, goodDamage: 1),
    'cape_of_clean_sweep' => const Effects(hearts: 2, comboHeal: 10),
    'coffee_of_haste' => const Effects(goodDamage: 1),
    'snack_break' => const Effects(hearts: 2),
    _ => Effects.none,
  };
}

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

/// Each boss's curse.
Curse curseOf(BossFamily family) => switch (family) {
  BossFamily.dust => const Curse(BossFamily.dust, CurseKind.tightTiming),
  BossFamily.laundry => const Curse(BossFamily.laundry, CurseKind.heart),
  BossFamily.kitchen => const Curse(
    BossFamily.kitchen,
    CurseKind.slotOff,
    GearSlot.weapon,
  ),
  BossFamily.bath => const Curse(BossFamily.bath, CurseKind.tightTiming),
  BossFamily.trash => const Curse(BossFamily.trash, CurseKind.heart),
  BossFamily.bedroom => const Curse(
    BossFamily.bedroom,
    CurseKind.slotOff,
    GearSlot.head,
  ),
  BossFamily.outside => const Curse(
    BossFamily.outside,
    CurseKind.slotOff,
    GearSlot.feet,
  ),
  BossFamily.clutter => const Curse(BossFamily.clutter, CurseKind.heart),
  BossFamily.overlord => const Curse(BossFamily.overlord, CurseKind.heart),
};

/// Whether doing a quest of [questFamily] lifts [curse]. The Overlord feeds
/// on no quest, so any quest lifts its curse.
bool questLifts(Curse curse, BossFamily questFamily) =>
    curse.family == BossFamily.overlord || curse.family == questFamily;

/// The fewest hearts a curse can leave.
const cursedMinHearts = 3;

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
int lootChance(int tier) => 10 + 10 * tier.clamp(1, 3);

/// Wins in a row without loot after which the next win always drops.
const lootPityWins = 4;

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
