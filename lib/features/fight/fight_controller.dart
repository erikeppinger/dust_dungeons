import 'dart:async';
import 'dart:math';

import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';

import '../../domain/fight/echo_duel.dart';
import '../../domain/fight/lanes.dart';
import 'fight_sounds.dart';

/// Where a fight is in its loop: intro → (call → echo → judged)* → finished.
/// The Overlord's last phase replaces call and echo with [lanes].
enum FightStage { intro, call, echo, judged, lanes, finished }

/// Drives one echo duel in real time: plays the boss's call, collects the
/// player's taps and judges them. Uses `clock` so tests can control time.
class FightController extends ChangeNotifier {
  FightController({
    required this.duel,
    required this.sounds,
    this.sound = true,
    this.haptics = true,
    this.latencyMs = 0,
    required this.onFinished,
  });

  final EchoDuel duel;
  final FightSounds sounds;
  final bool sound;
  final bool haptics;

  /// The player's calibrated delay: subtracted from every tap.
  final int latencyMs;

  /// Called once with the final outcome (won or lost).
  final void Function(DuelOutcome) onFinished;

  static const introMs = 1500;
  static const judgedMs = 1000;

  /// Bars of lane notes written at a time.
  static const laneBars = 2;

  FightStage stage = FightStage.intro;
  Pattern? pattern;

  /// Beat lit during the call (`-1`: none).
  int litBeat = -1;

  /// Taps so far in the current echo.
  int tapCount = 0;

  /// Hits of the last judged echo (for display).
  List<Hit> lastHits = const [];

  /// The lane phase's notes and judgements (`null` before it starts).
  LaneJudge? laneJudge;

  /// The last judgement in the lane phase (for display).
  Hit? lastLaneHit;

  final _timers = <Timer>[];
  final _taps = <int>[];
  DateTime? _echoStart;
  DateTime? _laneStart;
  bool _disposed = false;

  void start() => _after(introMs, _next);

  /// The next round: lanes in the Overlord's last phase, else call and echo.
  void _next() => duel.lanePhase ? _lanes() : _call();

  void _after(int ms, VoidCallback action) => _timers.add(
    Timer(Duration(milliseconds: ms), () {
      if (!_disposed) action();
    }),
  );

  void _cue(Cue cue, {bool vibrate = false}) {
    if (sound) unawaited(sounds.play(cue));
    if (haptics && vibrate) beatHaptic();
  }

  void _set(FightStage next) {
    stage = next;
    notifyListeners();
  }

  void _call() {
    final p = pattern = duel.nextPattern();
    litBeat = -1;
    lastHits = const [];
    _set(FightStage.call);
    for (final (i, beat) in p.beatsMs.indexed) {
      _after(beat, () {
        litBeat = i;
        _cue(Cue.bossBeat, vibrate: true);
        notifyListeners();
      });
    }
    _after(p.lengthMs, _echo);
  }

  /// One count-in click, then the player echoes: the first beat is due one
  /// pulse after the click.
  void _echo() {
    final p = pattern!;
    _taps.clear();
    tapCount = 0;
    litBeat = -1;
    _echoStart = clock.now().add(Duration(milliseconds: p.beatMs));
    _cue(Cue.count);
    _set(FightStage.echo);
    // Judged once the last beat's window has passed, allowing for the
    // player's calibrated delay.
    _after(
      p.beatMs + p.beatsMs.last + duel.windows.goodMs + 150 + max(0, latencyMs),
      _judge,
    );
  }

  /// A tap on the pad; ignored outside the echo.
  void tap() {
    final start = _echoStart;
    if (stage != FightStage.echo || start == null) return;
    _taps.add(clock.now().difference(start).inMilliseconds - latencyMs);
    tapCount++;
    _cue(Cue.tap, vibrate: true);
    notifyListeners();
  }

  void _judge() {
    lastHits = duel.applyEcho(pattern!, List.of(_taps));
    _cue(lastHits.contains(Hit.miss) ? Cue.miss : Cue.perfect);
    _set(FightStage.judged);
    if (duel.outcome == DuelOutcome.ongoing) {
      _after(judgedMs, _next);
    } else {
      _after(judgedMs, _finish);
    }
  }

  /// How long a lane note is visible before it reaches the line.
  int get fallMs => 4 * duel.lanes!.beatMs;

  /// Ms since the lane phase started (`0` outside it).
  int get laneElapsedMs {
    final start = _laneStart;
    return start == null ? 0 : clock.now().difference(start).inMilliseconds;
  }

  /// Starts the lane phase: notes fall in from the top, written a few bars
  /// ahead, until the fight ends.
  void _lanes() {
    laneJudge = LaneJudge(windows: duel.windows);
    lastLaneHit = null;
    lastHits = const [];
    _laneStart = clock.now();
    _set(FightStage.lanes);
    _laneBars(fallMs);
    _timers.add(
      Timer.periodic(const Duration(milliseconds: 40), (_) => _expireNotes()),
    );
  }

  void _laneBars(int fromMs) {
    final lanes = duel.lanes!;
    final notes = lanes.bars(fromMs, laneBars);
    laneJudge!.add(notes);
    final now = laneElapsedMs;
    for (final note in notes) {
      _after(note.atMs - now, () => _cue(Cue.count, vibrate: true));
    }
    // Write the next bars before their first note becomes visible.
    final end = fromMs + lanes.barsMs(laneBars);
    _after(end - fallMs - now, () => _laneBars(end));
  }

  /// A tap on [lane] during the lane phase.
  void tapLane(int lane) {
    final judge = laneJudge;
    if (stage != FightStage.lanes || judge == null) return;
    final hit = judge.tap(lane, laneElapsedMs - latencyMs);
    if (hit == null) {
      duel.breakCombo();
    } else {
      duel.applyHits([hit]);
      lastLaneHit = hit;
    }
    _cue(Cue.tap, vibrate: true);
    _afterLaneJudgement();
  }

  void _expireNotes() {
    final missed = laneJudge!.expire(laneElapsedMs - latencyMs);
    if (missed == 0) return;
    duel.applyHits(List.filled(missed, Hit.miss));
    lastLaneHit = Hit.miss;
    _cue(Cue.miss);
    _afterLaneJudgement();
  }

  void _afterLaneJudgement() {
    if (duel.outcome == DuelOutcome.ongoing) {
      notifyListeners();
      return;
    }
    stop();
    lastHits = [?lastLaneHit];
    _set(FightStage.judged);
    _after(judgedMs, _finish);
  }

  void _finish() {
    _cue(duel.outcome == DuelOutcome.won ? Cue.win : Cue.lose);
    _set(FightStage.finished);
    onFinished(duel.outcome);
  }

  /// Pauses (e.g. while the leave dialog is open). The round in progress is
  /// dropped without judging it, so pausing never costs health.
  void pause() => stop();

  /// Continues after [pause] (or after a Second Wind revived a lost duel)
  /// with a short "get ready" and a fresh round.
  void resume() {
    if (duel.outcome != DuelOutcome.ongoing) return;
    stop();
    lastHits = const [];
    litBeat = -1;
    _set(FightStage.intro);
    _after(introMs, _next);
  }

  /// Stops all timers (leaving the fight).
  void stop() {
    for (final t in _timers) {
      t.cancel();
    }
    _timers.clear();
  }

  @override
  void dispose() {
    _disposed = true;
    stop();
    super.dispose();
  }
}
