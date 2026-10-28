/// Boss families: every chore belongs to one, and completing it earns a
/// fight token for that family. Stored by name: never rename values.
enum BossFamily {
  dust,
  laundry,
  kitchen,
  bath,
  trash,
  bedroom,
  outside,
  clutter,
}

/// Families with a playable boss in this version (the rest arrive in 0.5.1;
/// their tokens are collected already).
const playableFamilies = {BossFamily.dust, BossFamily.clutter};

/// Default family of each built-in chore; user chores are [BossFamily.clutter].
const seedFamilies = <String, BossFamily>{
  'dusting': BossFamily.dust,
  'sweeping': BossFamily.dust,
  'vacuuming': BossFamily.dust,
  'mopping': BossFamily.dust,
  'laundry': BossFamily.laundry,
  'hang_laundry': BossFamily.laundry,
  'fold_laundry': BossFamily.laundry,
  'ironing': BossFamily.laundry,
  'dishes': BossFamily.kitchen,
  'dishwasher': BossFamily.kitchen,
  'clean_kitchen': BossFamily.kitchen,
  'clean_fridge': BossFamily.kitchen,
  'clean_bathroom': BossFamily.bath,
  'clean_toilet': BossFamily.bath,
  'take_out_trash': BossFamily.trash,
  'recycling': BossFamily.trash,
  'change_bed_sheets': BossFamily.bedroom,
  'tidy_up': BossFamily.bedroom,
  'clean_windows': BossFamily.outside,
  'water_plants': BossFamily.outside,
  'groceries': BossFamily.outside,
};

BossFamily familyOfSeed(String? seedKey) =>
    seedFamilies[seedKey] ?? BossFamily.clutter;

/// How a boss plays: tempo and rhythm vocabulary.
class BossStyle {
  const BossStyle({
    required this.baseBpm,
    required this.offbeatChance,
    required this.eighthChance,
  });

  final int baseBpm;

  /// Chance that a beat lands between two pulses (syncopation).
  final double offbeatChance;

  /// Chance that the gap to the next beat is an eighth instead of a quarter.
  final double eighthChance;
}

const bossStyles = <BossFamily, BossStyle>{
  // Light, bouncy, even beats.
  BossFamily.dust: BossStyle(baseBpm: 96, offbeatChance: 0, eighthChance: 0.3),
  // A random mix with some off-beats.
  BossFamily.clutter: BossStyle(
    baseBpm: 104,
    offbeatChance: 0.25,
    eighthChance: 0.35,
  ),
  BossFamily.laundry: BossStyle(
    baseBpm: 100,
    offbeatChance: 0.1,
    eighthChance: 0.3,
  ),
  BossFamily.kitchen: BossStyle(
    baseBpm: 108,
    offbeatChance: 0.15,
    eighthChance: 0.4,
  ),
  BossFamily.bath: BossStyle(
    baseBpm: 84,
    offbeatChance: 0.05,
    eighthChance: 0.1,
  ),
  BossFamily.trash: BossStyle(
    baseBpm: 100,
    offbeatChance: 0.35,
    eighthChance: 0.2,
  ),
  BossFamily.bedroom: BossStyle(
    baseBpm: 92,
    offbeatChance: 0.2,
    eighthChance: 0.2,
  ),
  BossFamily.outside: BossStyle(
    baseBpm: 112,
    offbeatChance: 0.1,
    eighthChance: 0.5,
  ),
};

/// Boss tier grows with how often you have beaten it: 1, 2 or 3.
int tierForWins(int wins) => wins >= 8 ? 3 : (wins >= 3 ? 2 : 1);

/// Cleaning points needed to win, by tier.
int bossHpForTier(int tier) => 10 + 6 * tier;

/// Hero strength from the player's level (XP from chores).
class HeroStats {
  const HeroStats({required this.maxHp, required this.damage});

  factory HeroStats.forLevel(int level) => HeroStats(
    maxHp: (4 + (level + 1) ~/ 2).clamp(5, 12),
    damage: (1 + level ~/ 4).clamp(1, 4),
  );

  final int maxHp;

  /// Cleaning points per *Good* hit; a *Perfect* deals twice that.
  final int damage;
}
