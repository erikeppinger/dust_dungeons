import 'dart:math';

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
