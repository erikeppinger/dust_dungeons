import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';

import '../../domain/fight/echo_duel.dart';
import 'fight_sounds.dart';

/// Where a fight is in its loop: intro → (call → echo → judged)* → finished.
enum FightStage { intro, call, echo, judged, finished }

/// Drives one echo duel in real time: plays the boss's call, collects the
/// player's taps and judges them. Uses `clock` so tests can control time.
class FightController extends ChangeNotifier {
  FightController({
    required this.duel,
    required this.sounds,
    this.sound = true,
    this.haptics = true,
    required this.onFinished,
  });

  final EchoDuel duel;
  final FightSounds sounds;
  final bool sound;
  final bool haptics;

  /// Called once with the final outcome (won or lost).
  final void Function(DuelOutcome) onFinished;

  static const introMs = 1500;
  static const judgedMs = 1000;

  FightStage stage = FightStage.intro;
  Pattern? pattern;

  /// Beat lit during the call (`-1`: none).
  int litBeat = -1;

  /// Taps so far in the current echo.
  int tapCount = 0;

  /// Hits of the last judged echo (for display).
  List<Hit> lastHits = const [];

  final _timers = <Timer>[];
  final _taps = <int>[];
  DateTime? _echoStart;
  bool _disposed = false;

  void start() => _after(introMs, _call);

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
    _after(p.beatMs + p.beatsMs.last + duel.windows.goodMs + 150, _judge);
  }

  /// A tap on the pad; ignored outside the echo.
  void tap() {
    final start = _echoStart;
    if (stage != FightStage.echo || start == null) return;
    _taps.add(clock.now().difference(start).inMilliseconds);
    tapCount++;
    _cue(Cue.tap, vibrate: true);
    notifyListeners();
  }

  void _judge() {
    lastHits = duel.applyEcho(pattern!, List.of(_taps));
    _cue(lastHits.contains(Hit.miss) ? Cue.miss : Cue.perfect);
    _set(FightStage.judged);
    if (duel.outcome == DuelOutcome.ongoing) {
      _after(judgedMs, _call);
    } else {
      _after(judgedMs, _finish);
    }
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
    _after(introMs, _call);
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
