import 'dart:math';

import 'echo_duel.dart';

/// Number of lanes in the Overlord's lane phase.
const laneCount = 3;

/// A note in the lane phase: tap [lane] when it reaches the line at [atMs]
/// (ms from the start of the lane phase).
class LaneNote {
  const LaneNote(this.lane, this.atMs);

  final int lane;
  final int atMs;
}

/// Writes lane notes bar by bar: deterministic for a seed. Every pulse
/// likely gets a note, higher tiers add notes between the pulses.
class LaneGenerator {
  LaneGenerator({
    required this.beatMs,
    required this.tier,
    this.extraChance = 0,
    int seed = 0,
  }) : _random = Random(seed);

  final int beatMs;
  final int tier;

  /// Added chance of a note between two pulses (an Overlord's trait).
  final double extraChance;
  final Random _random;

  /// Notes for [count] bars of four pulses, starting at [fromMs].
  List<LaneNote> bars(int fromMs, int count) {
    final notes = <LaneNote>[];
    for (var slot = 0; slot < count * 8; slot++) {
      final chance = slot.isEven
          ? 0.55 + 0.1 * tier
          : 0.08 * tier + extraChance;
      if (_random.nextDouble() >= chance) continue;
      notes.add(
        LaneNote(_random.nextInt(laneCount), fromMs + slot * beatMs ~/ 2),
      );
    }
    return notes;
  }

  /// Length of [count] bars in ms.
  int barsMs(int count) => count * 4 * beatMs;
}

/// Judges taps in the lane phase. A tap takes the nearest open note of its
/// lane inside the good window; notes nobody tapped become misses once
/// their window has passed.
class LaneJudge {
  LaneJudge({required this.windows});

  final TimingWindows windows;
  final List<LaneNote> notes = [];

  /// Judgement per note, `null` while it is still open.
  final List<Hit?> results = [];

  void add(Iterable<LaneNote> more) {
    for (final note in more) {
      notes.add(note);
      results.add(null);
    }
  }

  /// Judges a tap on [lane] at [atMs]; `null` if it matched no note.
  Hit? tap(int lane, int atMs) {
    var best = -1;
    var bestDistance = windows.goodMs + 1;
    for (var i = 0; i < notes.length; i++) {
      if (results[i] != null || notes[i].lane != lane) continue;
      final distance = (notes[i].atMs - atMs).abs();
      if (distance < bestDistance) {
        best = i;
        bestDistance = distance;
      }
    }
    if (best < 0) return null;
    return results[best] = bestDistance <= windows.perfectMs
        ? Hit.perfect
        : Hit.good;
  }

  /// Marks the notes whose window ended before [nowMs] as missed and returns
  /// how many there were.
  int expire(int nowMs) {
    var missed = 0;
    for (var i = 0; i < notes.length; i++) {
      if (results[i] == null && notes[i].atMs + windows.goodMs < nowMs) {
        results[i] = Hit.miss;
        missed++;
      }
    }
    return missed;
  }
}
