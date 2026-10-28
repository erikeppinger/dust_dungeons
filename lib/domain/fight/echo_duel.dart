import 'dart:math';

import 'boss.dart';

/// Result of one expected beat in the player's echo.
enum Hit { perfect, good, miss }

/// Timing windows for judging taps, in milliseconds either side of a beat.
class TimingWindows {
  const TimingWindows({required this.perfectMs, required this.goodMs});

  static const normal = TimingWindows(perfectMs: 60, goodMs: 120);

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
  PatternGenerator(this.style, {required this.tier, int seed = 0})
    : _random = Random(seed);

  final BossStyle style;
  final int tier;
  final Random _random;

  int get beatMs => (60000 / (style.baseBpm + 8 * (tier - 1))).round();

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
    required this.hero,
    this.storyMode = false,
    int seed = 0,
  }) : bossMaxHp = bossHpForTier(tier),
       bossHp = bossHpForTier(tier),
       heroHp = hero.maxHp,
       _generator = PatternGenerator(
         bossStyles[family]!,
         tier: tier,
         seed: seed,
       );

  final BossFamily family;
  final int tier;
  final HeroStats hero;
  final bool storyMode;
  final PatternGenerator _generator;

  final int bossMaxHp;
  int bossHp;
  int heroHp;
  int perfect = 0, good = 0, miss = 0;
  int combo = 0, bestCombo = 0;

  TimingWindows get windows =>
      storyMode ? TimingWindows.story : TimingWindows.normal;

  /// Phase 1 below half the boss's health: longer, syncopated patterns.
  int get phase => bossHp * 2 <= bossMaxHp ? 1 : 0;

  DuelOutcome get outcome => bossHp <= 0
      ? DuelOutcome.won
      : (heroHp <= 0 ? DuelOutcome.lost : DuelOutcome.ongoing);

  /// Accuracy so far, 0..1 (perfect = 1, good = 0.5).
  double get accuracy {
    final total = perfect + good + miss;
    return total == 0 ? 0 : (perfect + good * 0.5) / total;
  }

  Pattern nextPattern() => _generator.next(phase: phase);

  /// Applies one judged echo and returns the hits (for display).
  List<Hit> applyEcho(Pattern pattern, List<int> tapsMs) {
    assert(outcome == DuelOutcome.ongoing);
    final hits = judgeEcho(pattern, tapsMs, windows: windows);
    for (final hit in hits) {
      switch (hit) {
        case Hit.perfect:
          perfect++;
          combo++;
          bossHp -= hero.damage * 2;
        case Hit.good:
          good++;
          combo++;
          bossHp -= hero.damage;
        case Hit.miss:
          miss++;
          combo = 0;
          if (!storyMode) heroHp -= 1;
      }
      bestCombo = max(bestCombo, combo);
    }
    // Story mode cannot be lost (misses never hurt the hero); they only
    // break the combo and slow the cleaning meter.
    bossHp = max(bossHp, 0);
    heroHp = max(heroHp, 0);
    return hits;
  }
}
