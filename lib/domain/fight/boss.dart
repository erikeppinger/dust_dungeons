import 'dart:math';

import '../../game/game_data.dart';

export '../../game/game_data.dart' show bossStyles, seedFamilies;

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

  /// The weekly boss: appears after [overlordWinsNeeded] wins in a week and
  /// is fed by no chore.
  overlord,

  // Chore bosses from 0.16.0, after the Overlord so stored indexes of the
  // older ones stay the same.
  homework,
  pets,
  garden,
  cooking,
}

/// The bosses fed by chores (all but the weekly Overlord).
const choreFamilies = [
  BossFamily.dust,
  BossFamily.laundry,
  BossFamily.kitchen,
  BossFamily.bath,
  BossFamily.trash,
  BossFamily.bedroom,
  BossFamily.outside,
  BossFamily.clutter,
  BossFamily.homework,
  BossFamily.pets,
  BossFamily.garden,
  BossFamily.cooking,
];

/// Wins against chore bosses in one week (Mon–Sun) that call the Overlord.
const overlordWinsNeeded = bossesOverlordWinsNeeded;

/// Default family of each built-in chore (game/quests.toml); user chores
/// are [BossFamily.clutter].
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

/// Boss tier grows with how often you have beaten it: 1, 2 or 3.
int tierForWins(int wins) =>
    wins >= bossesTierWins[1] ? 3 : (wins >= bossesTierWins[0] ? 2 : 1);

/// Cleaning points needed to win, by tier.
int bossHpForTier(int tier) => bossesHealthBase + bossesHealthPerTier * tier;

/// The Overlord has three phases and more health.
int overlordHpForTier(int tier) =>
    bossesOverlordHealthTimes * bossHpForTier(tier);

/// Hero strength from the player's level (XP from chores).
class HeroStats {
  const HeroStats({required this.maxHp, required this.damage});

  factory HeroStats.forLevel(int level) => HeroStats(
    maxHp: (heroHeartsBase + (level + heroHeartsOffset) ~/ heroHeartsEvery)
        .clamp(heroHeartsMin, heroHeartsMax),
    damage: (heroDamageBase + (level + heroDamageOffset) ~/ heroDamageEvery)
        .clamp(heroDamageMin, heroDamageMax),
  );

  final int maxHp;

  /// Cleaning points per *Good* hit; a *Perfect* deals twice that.
  final int damage;
}

/// A small change to how a boss plays, on top of its style and tier: an
/// Overlord's body (docs/design/weekly-overlords.md) or a boss's form
/// (docs/design/more-bosses.md).
class BossTrait {
  const BossTrait({
    this.bpm = 0,
    this.beats = 0,
    this.offbeat = 0.0,
    this.eighth = 0.0,
    this.lanes = 0.0,
  });

  /// Tempo change in beats per minute.
  final int bpm;

  /// More beats per rhythm.
  final int beats;

  /// Added chances of an offbeat and of an eighth.
  final double offbeat, eighth;

  /// Added chance of a lane note between two beats.
  final double lanes;

  /// [style] with this trait on top.
  BossStyle apply(BossStyle style) => BossStyle(
    baseBpm: style.baseBpm + bpm,
    offbeatChance: min(1, style.offbeatChance + offbeat),
    eighthChance: min(1, style.eighthChance + eighth),
  );
}

/// A chore boss's form at tier 2 or 3 (game/bosses.toml): its colors and
/// how it plays differently.
class BossForm {
  const BossForm({
    required this.main,
    required this.light,
    this.trait = const BossTrait(),
  });

  /// Main and light color as ARGB; the shades are made darker.
  final int main, light;
  final BossTrait trait;
}

/// [family]'s form at [tier]; `null` at tier 1 and for the Overlord.
BossForm? bossForm(BossFamily family, int tier) {
  final forms = bossForms[family];
  return forms == null || tier < 2 ? null : forms[min(tier, 3) - 2];
}
