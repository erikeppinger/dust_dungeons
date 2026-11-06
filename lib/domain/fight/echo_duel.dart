import 'dart:math';

import '../../game/game_data.dart';
import 'boss.dart';
import 'difficulty.dart';
import 'lanes.dart';
import 'items.dart';

/// Result of one expected beat in the player's echo.
enum Hit { perfect, good, miss }

/// Timing windows for judging taps, in milliseconds either side of a beat.
class TimingWindows {
  const TimingWindows({required this.perfectMs, required this.goodMs});

  static const normal = timingNormal;

  /// With wide timing (the Metronome Charm).
  static const charmed = timingWide;

  /// Cursed: narrower than normal.
  static const tight = timingTight;

  /// Story mode: generous windows (and no damage to the hero).
  static const story = timingStory;

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
    this.difficulty = Difficulty.balanced,
    this.seed = 0,
    int? maxHp,
  }) : effects = loadout.against(family),
       hero = HeroStats(
         maxHp: heartsWith(hero.maxHp, loadout.against(family)),
         damage: hero.damage,
       ),
       bossMaxHp = _health(maxHp ?? bossHpForTier(tier), difficulty),
       bossHp = _health(maxHp ?? bossHpForTier(tier), difficulty),
       heroHp = heartsWith(hero.maxHp, loadout.against(family));

  /// Tempo factor in slow mode.
  static const slowTempo = 0.7;

  static int _health(int base, Difficulty difficulty) =>
      max(1, (base * difficultyPresets[difficulty]!.bossHealth).round());

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

  /// Easy, balanced or hard: boss health, timing and tempo.
  final Difficulty difficulty;

  DifficultyPreset get _preset => difficultyPresets[difficulty]!;

  /// Slow mode: everything plays at [slowTempo].
  final bool slowMode;

  /// Seeds the rhythms, so a fight can be replayed in tests.
  final int seed;
  final _generators = <BossFamily, PatternGenerator>{};

  double get tempo =>
      (slowMode ? slowTempo : 1) *
      (effects.slowerBoss ? slowerBossTempo : 1) *
      _preset.tempo;

  final int bossMaxHp;
  int bossHp;
  int heroHp;
  int perfect = 0, good = 0, miss = 0;
  int combo = 0, bestCombo = 0;
  int _freeUsed = 0;

  /// Failed rounds (and, in the lane phase, missed notes) so far: every
  /// time a heart was due, shielded or not.
  int _failures = 0;
  bool _sneakUsed = false;

  /// The last round's accuracy (0..1) and whether it landed (`null` before
  /// the first round).
  double? lastRoundAccuracy;
  bool? lastRoundLanded;

  /// Failed rounds that will still cost no heart (shields).
  int get freeRoundsLeft => effects.freeMisses - _freeUsed;

  /// Story mode keeps its own windows; otherwise the difficulty widens or
  /// narrows them.
  TimingWindows get windows {
    if (storyMode) return TimingWindows.story;
    final base = effects.tightTiming
        ? TimingWindows.tight
        : (effects.wideTiming ? TimingWindows.charmed : TimingWindows.normal);
    final ms = _preset.timingMs;
    return ms == 0
        ? base
        : TimingWindows(
            perfectMs: max(10, base.perfectMs + ms),
            goodMs: max(20, base.goodMs + ms),
          );
  }

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

  /// A round's accuracy, 0..1: Perfect counts 1, Good 1/2, Miss 0 (stray
  /// taps are misses too).
  static double roundAccuracy(List<Hit> hits) => hits.isEmpty
      ? 0
      : hits.fold<double>(
              0,
              (sum, hit) =>
                  sum +
                  switch (hit) {
                    Hit.perfect => 1,
                    Hit.good => 0.5,
                    Hit.miss => 0,
                  },
            ) /
            hits.length;

  /// Applies one judged echo (a round) and returns the hits (for display).
  /// A round of at least [roundsHitPercent] % accuracy lands: its hits
  /// damage the boss. Below that it fails: no damage, and one heart lost
  /// however many misses. In story mode every round lands.
  List<Hit> applyEcho(Pattern pattern, List<int> tapsMs) {
    assert(outcome == DuelOutcome.ongoing);
    final hits = judgeEcho(pattern, tapsMs, windows: windows);
    final accuracy = roundAccuracy(hits);
    final landed = storyMode || accuracy * 100 >= roundsHitPercent;
    lastRoundAccuracy = accuracy;
    lastRoundLanded = landed;
    _apply(hits, damage: landed);
    if (!landed) _heartDue();
    _settle();
    return hits;
  }

  /// A tap that hit nothing (lane phase): breaks the combo, costs no heart.
  void breakCombo() => combo = 0;

  /// Applies notes judged in the lane phase, which has no rounds: every
  /// hit deals damage, and every missed note costs a heart.
  void applyHits(List<Hit> hits) {
    assert(outcome == DuelOutcome.ongoing);
    _apply(hits, damage: true);
    for (final _ in hits.where((h) => h == Hit.miss)) {
      _heartDue();
    }
    _settle();
  }

  /// Counts [hits] and keeps the combo; with [damage], hurts the boss.
  void _apply(List<Hit> hits, {required bool damage}) {
    // Sneak attack: the first hits that land strike half as hard again.
    final sneak = damage && effects.sneakAttack && !_sneakUsed;
    if (sneak) _sneakUsed = true;
    int dealt(int value) => sneak ? value + (value + 1) ~/ 2 : value;
    for (final hit in hits) {
      switch (hit) {
        case Hit.perfect:
          perfect++;
          combo++;
          if (damage) {
            bossHp -= dealt(
              hero.damage * effects.perfectTimes + effects.damage,
            );
          }
        case Hit.good:
          good++;
          combo++;
          if (damage) {
            bossHp -= dealt(hero.damage + effects.damage + effects.goodDamage);
          }
        case Hit.miss:
          miss++;
          combo = 0;
      }
      final heal = effects.comboHeal;
      if (hit != Hit.miss && heal > 0 && combo % heal == 0) {
        heroHp = min(heroHp + 1, hero.maxHp);
      }
      bestCombo = max(bestCombo, combo);
    }
  }

  /// A heart is due (a failed round, or a missed lane note): shields take
  /// the first ones, the Garden Gnome every third. Story mode never loses
  /// hearts, so it can't be lost.
  void _heartDue() {
    if (storyMode) return;
    _failures++;
    if (freeRoundsLeft > 0) {
      _freeUsed++;
    } else if (!(effects.thirdMissFree && _failures % 3 == 0)) {
      heroHp -= 1;
    }
  }

  void _settle() {
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
    super.difficulty,
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
