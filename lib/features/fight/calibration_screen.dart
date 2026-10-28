import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/fight/calibration.dart';
import '../../l10n/app_localizations.dart';
import '../settings/settings_controller.dart';
import 'fight_sounds.dart';

/// Timing calibration: the player taps along with 8 beats; the median delay
/// is saved and subtracted from every tap in fights.
class CalibrationScreen extends ConsumerStatefulWidget {
  const CalibrationScreen({super.key});

  static Future<void> open(BuildContext context) => Navigator.of(context)
      .push(MaterialPageRoute<void>(builder: (_) => const CalibrationScreen()));

  @override
  ConsumerState<CalibrationScreen> createState() => _CalibrationScreenState();
}

enum _Stage { ready, running, done }

class _CalibrationScreenState extends ConsumerState<CalibrationScreen> {
  /// Silence before the first beat.
  static const leadMs = 1200;

  static final _beats = [
    for (var i = 0; i < calibrationBeats; i++) leadMs + i * calibrationBeatMs,
  ];

  _Stage _stage = _Stage.ready;
  final _timers = <Timer>[];
  final _taps = <int>[];
  DateTime? _start;
  int _lit = -1;

  /// The pad flashes briefly on each beat.
  bool _flash = false;
  int? _result;

  @override
  void dispose() {
    _cancel();
    super.dispose();
  }

  void _cancel() {
    for (final t in _timers) {
      t.cancel();
    }
    _timers.clear();
  }

  void _run() {
    final settings = ref.read(settingsProvider);
    final sounds = ref.read(fightSoundsProvider);
    _cancel();
    _taps.clear();
    _start = clock.now();
    setState(() {
      _stage = _Stage.running;
      _lit = -1;
      _result = null;
    });
    for (final (i, beat) in _beats.indexed) {
      _timers.add(
        Timer(Duration(milliseconds: beat), () {
          if (settings.fightSound) unawaited(sounds.play(Cue.count));
          if (settings.fightHaptics) beatHaptic();
          setState(() {
            _lit = i;
            _flash = true;
          });
          _timers.add(
            Timer(const Duration(milliseconds: 120), () {
              setState(() => _flash = false);
            }),
          );
        }),
      );
    }
    _timers.add(
      Timer(Duration(milliseconds: _beats.last + calibrationBeatMs), () {
        setState(() {
          _stage = _Stage.done;
          _lit = -1;
          _result = calibrationOffset(_beats, _taps);
        });
      }),
    );
  }

  void _tap() {
    final start = _start;
    if (_stage != _Stage.running || start == null) return;
    _taps.add(clock.now().difference(start).inMilliseconds);
  }

  void _save(int ms) {
    ref
        .read(settingsProvider.notifier)
        .update((s) => s.copyWith(fightLatencyMs: ms));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final current = ref.watch(settingsProvider).fightLatencyMs;
    final running = _stage == _Stage.running;
    final result = _result;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.fightSettingCalibrate)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(l10n.calibrateIntro, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 8),
            Text(
              l10n.calibrateCurrent(current),
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < calibrationBeats; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i <= _lit ? scheme.primary : null,
                        border: Border.all(color: scheme.outline, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Center(
              child: Semantics(
                button: true,
                enabled: running,
                label: l10n.calibrateTapAlong,
                child: Listener(
                  key: const ValueKey('calibrate-pad'),
                  behavior: HitTestBehavior.opaque,
                  onPointerDown: running ? (_) => _tap() : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 80),
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: running
                          ? (_flash ? scheme.primary : scheme.primaryContainer)
                          : scheme.surfaceContainerHighest,
                    ),
                    alignment: Alignment.center,
                    child: ExcludeSemantics(
                      child: Text(
                        l10n.calibrateTapAlong,
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_stage == _Stage.done)
              Text(
                result == null
                    ? l10n.calibrateTooFew
                    : l10n.calibrateResult(result),
                key: const ValueKey('calibrate-result'),
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
            const SizedBox(height: 16),
            if (_stage == _Stage.done && result != null)
              FilledButton(
                onPressed: () => _save(result),
                child: Text(l10n.save),
              ),
            if (!running) ...[
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: _run,
                child: Text(
                  _stage == _Stage.ready
                      ? l10n.calibrateStart
                      : l10n.calibrateAgain,
                ),
              ),
            ],
            if (current != 0 && !running)
              TextButton(
                onPressed: () => _save(0),
                child: Text(l10n.calibrateReset),
              ),
          ],
        ),
      ),
    );
  }
}
