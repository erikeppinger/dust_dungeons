import 'dart:math';

import 'boss.dart';
import 'lanes.dart';
import 'items.dart';

/// Result of one expected beat in the player's echo.
enum Hit { perfect, good, miss }

/// Timing windows for judging taps, in milliseconds either side of a beat.
class TimingWindows {
  const TimingWindows({required this.perfectMs, required this.goodMs});

  static const normal = TimingWindows(perfectMs: 60, goodMs: 120);

  /// With the Metronome Charm.
  static const charmed = TimingWindows(perfectMs: 80, goodMs: 160);

  /// Cursed: narrower than normal.
  static const tight = TimingWindows(perfectMs: 45, goodMs: 95);

  /// Story mode: generous windows (and no damage to the hero).
  static const story = TimingWindows(perfectMs: 100, goodMs: 200);

  final int perfectMs;
  final int goodMs;
}

/// A rhythm the boss plays: beat times in ms from the phrase start.
class Pattern {
  const Pattern(this.beatsMs, {required this.beatMs});

  final List<int> beatsMs;

  /// Length of one pulse (quarter note) in ms.
  final int beatMs;

  /// Phrase length including one trailing pulse of rest.
  int get lengthMs => beatsMs.last + beatMs;
}

/// Builds the boss's patterns: deterministic for a seed, so fights can be
/// replayed in tests.
class PatternGenerator {
  PatternGenerator(
    this.style, {
    required this.tier,
    this.tempo = 1,
    int seed = 0,
  }) : _random = Random(seed);

  final BossStyle style;
  final int tier;

  /// Tempo factor: 1 normally, [EchoDuel.slowTempo] in slow mode.
  final double tempo;
  final Random _random;

  int get beatMs => beatMsFor(style, tier, tempo);

  /// Number of beats grows with tier and the fight's [phase] (0 or 1).
  Pattern next({required int phase}) {
    final minBeats = 2 + tier - 1 + phase;
    final count = minBeats + _random.nextInt(2);
    final eighth = beatMs ~/ 2;
    final beats = <int>[0];
    while (beats.length < count) {
      final gap = _random.nextDouble() < style.eighthChance ? eighth : beatMs;
      var at = beats.last + gap;
      // Syncopation in phase 2: push a beat half a pulse later sometimes.
      if (phase > 0 && _random.nextDouble() < style.offbeatChance) {
        at += eighth;
      }
      beats.add(at);
    }
    return Pattern(beats, beatMs: beatMs);
  }
}

/// Length of one pulse in ms: faster with each tier, slower in slow mode.
int beatMsFor(BossStyle style, int tier, double tempo) =>
    (60000 / (style.baseBpm + 8 * (tier - 1)) / tempo).round();

/// Judges taps (ms from the echo start) against [pattern]. Each beat takes
/// the nearest unused tap inside the good window; taps that match no beat
/// count as misses too, so hammering the pad does not pay off.
List<Hit> judgeEcho(
  Pattern pattern,
  List<int> tapsMs, {
  TimingWindows windows = TimingWindows.normal,
}) {
  final used = List<bool>.filled(tapsMs.length, false);
  final hits = <Hit>[];
  for (final beat in pattern.beatsMs) {
    var best = -1;
    var bestDistance = windows.goodMs + 1;
    for (var i = 0; i < tapsMs.length; i++) {
      final distance = (tapsMs[i] - beat).abs();
      if (!used[i] && distance <= windows.goodMs && distance < bestDistance) {
        best = i;
        bestDistance = distance;
      }
    }
    if (best < 0) {
      hits.add(Hit.miss);
    } else {
      used[best] = true;
      hits.add(bestDistance <= windows.perfectMs ? Hit.perfect : Hit.good);
    }
  }
  final stray = used.where((u) => !u).length;
  return [...hits, for (var i = 0; i < stray; i++) Hit.miss];
}

enum DuelOutcome { ongoing, won, lost }

/// The state of one echo duel: boss and hero health, phase and statistics.
class EchoDuel {
  EchoDuel({
    required this.family,
    required this.tier,
    required HeroStats hero,
    this.loadout = Loadout.none,
    this.storyMode = false,
    this.slowMode = false,
    this.seed = 0,
    int? maxHp,
  }) : effects = loadout.against(family),
       hero = HeroStats(
         maxHp: heartsWith(hero.maxHp, loadout.against(family)),
         damage: hero.damage,
       ),
       bossMaxHp = maxHp ?? bossHpForTier(tier),
       bossHp = maxHp ?? bossHpForTier(tier),
       heroHp = heartsWith(hero.maxHp, loadout.against(family));

  /// Tempo factor in slow mode.
  static const slowTempo = 0.7;

  /// Tempo factor with a slower boss (the Lost Remote).
  static const slowerBossTempo = 0.9;

  final BossFamily family;
  final int tier;

  /// The hero's stats including gear.
  final HeroStats hero;
  final Loadout loadout;

  /// What the loadout does against this boss.
  final Effects effects;
  final bool storyMode;

  /// Slow mode: everything plays at [slowTempo].
  final bool slowMode;

  /// Seeds the rhythms, so a fight can be replayed in tests.
  final int seed;
  final _generators = <BossFamily, PatternGenerator>{};

  double get tempo =>
      (slowMode ? slowTempo : 1) * (effects.slowerBoss ? slowerBossTempo : 1);

  final int bossMaxHp;
  int bossHp;
  int heroHp;
  int perfect = 0, good = 0, miss = 0;
  int combo = 0, bestCombo = 0;
  int _freeMissesUsed = 0;
  bool _firstEcho = true;

  /// Misses that will still cost no heart (shields).
  int get freeMissesLeft => effects.freeMisses - _freeMissesUsed;

  TimingWindows get windows => storyMode
      ? TimingWindows.story
      : effects.tightTiming
      ? TimingWindows.tight
      : (effects.wideTiming ? TimingWindows.charmed : TimingWindows.normal);

  /// Phase 1 below half the boss's health: longer, syncopated patterns.
  int get phase => bossHp * 2 <= bossMaxHp ? 1 : 0;

  int get phaseCount => 2;

  /// Whether the fight is in the Overlord's lane phase.
  bool get lanePhase => false;

  /// Writes the lane notes; only the Overlord has a lane phase.
  LaneGenerator? get lanes => null;

  DuelOutcome get outcome => bossHp <= 0
      ? DuelOutcome.won
      : (heroHp <= 0 ? DuelOutcome.lost : DuelOutcome.ongoing);

  /// Accuracy so far, 0..1 (perfect = 1, good = 0.5).
  double get accuracy {
    final total = perfect + good + miss;
    return total == 0 ? 0 : (perfect + good * 0.5) / total;
  }

  /// The pattern generator for one boss style, created on first use.
  PatternGenerator _generatorFor(BossFamily style) => _generators.putIfAbsent(
    style,
    () => PatternGenerator(
      bossStyles[style]!,
      tier: tier,
      tempo: tempo,
      seed: seed + style.index,
    ),
  );

  Pattern nextPattern() => _generatorFor(family).next(phase: phase);

  /// Applies one judged echo and returns the hits (for display).
  List<Hit> applyEcho(Pattern pattern, List<int> tapsMs) {
    final hits = judgeEcho(pattern, tapsMs, windows: windows);
    applyHits(hits);
    return hits;
  }

  /// A tap that hit nothing (lane phase): breaks the combo, costs no heart.
  void breakCombo() => combo = 0;

  /// Applies judged hits to boss and hero.
  void applyHits(List<Hit> hits) {
    assert(outcome == DuelOutcome.ongoing);
    // Sneak attack: the first echo (or lane note) hits half as hard again.
    final sneak = effects.sneakAttack && _firstEcho;
    _firstEcho = false;
    int dealt(int damage) => sneak ? damage + (damage + 1) ~/ 2 : damage;
    for (final hit in hits) {
      switch (hit) {
        case Hit.perfect:
          perfect++;
          combo++;
          bossHp -= dealt(hero.damage * effects.perfectTimes + effects.damage);
        case Hit.good:
          good++;
          combo++;
          bossHp -= dealt(hero.damage + effects.damage + effects.goodDamage);
        case Hit.miss:
          miss++;
          combo = 0;
          if (storyMode) break;
          if (freeMissesLeft > 0) {
            _freeMissesUsed++;
          } else if (!(effects.thirdMissFree && miss % 3 == 0)) {
            heroHp -= 1;
          }
      }
      final heal = effects.comboHeal;
      if (hit != Hit.miss && heal > 0 && combo % heal == 0) {
        heroHp = min(heroHp + 1, hero.maxHp);
      }
      bestCombo = max(bestCombo, combo);
    }
    // Story mode cannot be lost (misses never hurt the hero); they only
    // break the combo and slow the cleaning meter.
    bossHp = max(bossHp, 0);
    heroHp = max(heroHp, 0);
  }

  /// Second Wind: continue a lost fight with half the hearts (all of them
  /// with the Apron of Holding).
  void revive() {
    assert(outcome == DuelOutcome.lost);
    heroHp = effects.fullRevive ? hero.maxHp : (hero.maxHp + 1) ~/ 2;
    combo = 0;
  }
}

/// The weekly Chore Overlord: two echo phases that borrow the rhythms of
/// [motifs] (the bosses beaten that week), then a lane phase.
class OverlordDuel extends EchoDuel {
  OverlordDuel({
    required super.tier,
    required super.hero,
    required List<BossFamily> motifs,
    super.loadout,
    super.storyMode,
    super.slowMode,
    super.seed,
  }) : motifs = motifs.isEmpty ? const [BossFamily.clutter] : motifs,
       super(family: BossFamily.overlord, maxHp: overlordHpForTier(tier));

  final List<BossFamily> motifs;
  int _round = 0;
  LaneGenerator? _lanes;

  /// Phases by thirds of the health: echo, echo, lanes.
  @override
  int get phase =>
      bossHp * 3 > bossMaxHp * 2 ? 0 : (bossHp * 3 > bossMaxHp ? 1 : 2);

  @override
  int get phaseCount => 3;

  @override
  bool get lanePhase => phase == 2;

  /// Each round borrows the next beaten boss's rhythm.
  @override
  Pattern nextPattern() =>
      _generatorFor(motifs[_round++ % motifs.length]).next(phase: phase);

  /// Writes the lane notes, at the Overlord's own tempo.
  @override
  LaneGenerator get lanes => _lanes ??= LaneGenerator(
    beatMs: beatMsFor(bossStyles[BossFamily.overlord]!, tier, tempo),
    tier: tier,
    seed: seed,
  );
}
