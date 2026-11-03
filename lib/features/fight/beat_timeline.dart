import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../app/art/art.dart';
import '../../domain/fight/echo_duel.dart';
import 'fight_controller.dart';

/// Where [ms] lies on a timeline [width] wide that spans one count-in pulse
/// before the phrase and the whole phrase: `-beatMs` is at 0, the phrase's
/// end ([Pattern.lengthMs]) at [width].
double timelineX(int ms, Pattern pattern, double width) =>
    width * (ms + pattern.beatMs) / (pattern.lengthMs + pattern.beatMs);

/// The dots' size: 16 normally, smaller when beats sit close together, so
/// neighbors keep a gap of at least 4.
double timelineDot(Pattern pattern, double width) {
  var gap = double.infinity;
  for (var i = 1; i < pattern.beatsMs.length; i++) {
    gap = min(
      gap,
      timelineX(pattern.beatsMs[i], pattern, width) -
          timelineX(pattern.beatsMs[i - 1], pattern, width),
    );
  }
  return (gap - 4).clamp(10, 16).toDouble();
}

/// The boss's rhythm on a timeline: dots at their real times, a playhead
/// sweeping across during the call and the echo, and afterwards each
/// judgement (by shape) with ticks where the player actually tapped. The
/// status line above says the same in words.
class BeatTimeline extends StatefulWidget {
  const BeatTimeline({super.key, required this.controller});

  final FightController controller;

  @override
  State<BeatTimeline> createState() => _BeatTimelineState();
}

class _BeatTimelineState extends State<BeatTimeline>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((_) => setState(() {}));
    widget.controller.addListener(_sync);
    _sync();
  }

  /// Runs the ticker only while the playhead moves.
  void _sync() {
    final moving = widget.controller.playheadMs != null;
    if (moving && !_ticker.isActive) _ticker.start();
    if (!moving && _ticker.isActive) _ticker.stop();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_sync);
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final pattern = c.pattern;
    return ExcludeSemantics(
      child: SizedBox(
        key: const ValueKey('beat-timeline'),
        height: 64,
        width: double.infinity,
        child: pattern == null
            ? null
            : CustomPaint(
                painter: _TimelinePainter(
                  pattern: pattern,
                  stage: c.stage,
                  playheadMs: c.playheadMs,
                  litBeat: c.litBeat,
                  tapCount: c.tapCount,
                  hits: c.lastHits,
                  taps: c.lastHits.isEmpty ? const [] : c.taps,
                  stepped: MediaQuery.disableAnimationsOf(context),
                  scheme: Theme.of(context).colorScheme,
                ),
              ),
      ),
    );
  }
}

class _TimelinePainter extends CustomPainter {
  _TimelinePainter({
    required this.pattern,
    required this.stage,
    required this.playheadMs,
    required this.litBeat,
    required this.tapCount,
    required this.hits,
    required this.taps,
    required this.stepped,
    required this.scheme,
  });

  final Pattern pattern;
  final FightStage stage;
  final int? playheadMs;
  final int litBeat;
  final int tapCount;
  final List<Hit> hits;
  final List<int> taps;

  /// Reduce motion: the playhead jumps from pulse to pulse.
  final bool stepped;
  final ColorScheme scheme;

  /// Room at both ends for a lit dot.
  static const _margin = 14.0;
  static const _trackY = 24.0;

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width - 2 * _margin;
    double x(int ms) => _margin + timelineX(ms, pattern, width);
    final dot = timelineDot(pattern, width);
    final line = Paint()
      ..color = scheme.outlineVariant
      ..strokeWidth = 2;

    // The track, the beat grid and the count-in mark.
    canvas.drawLine(
      Offset(x(0), _trackY),
      Offset(x(pattern.lengthMs), _trackY),
      line,
    );
    for (var ms = 0; ms <= pattern.lengthMs; ms += pattern.beatMs) {
      canvas.drawLine(
        Offset(x(ms), _trackY - 4),
        Offset(x(ms), _trackY + 4),
        line,
      );
    }
    final countIn = Paint()..color = scheme.outline;
    canvas.drawCircle(Offset(x(-pattern.beatMs), _trackY), 3, countIn);

    // The dots, or the judgements once a round is judged.
    final judged = hits.isNotEmpty;
    for (final (i, beat) in pattern.beatsMs.indexed) {
      final center = Offset(x(beat), _trackY);
      if (judged) {
        if (i < hits.length) _hit(canvas, center, hits[i], dot + 6);
        continue;
      }
      final lit = stage == FightStage.call && i == litBeat;
      final filled = stage == FightStage.call
          ? i <= litBeat
          : stage == FightStage.echo && i < tapCount;
      final r = (lit ? dot * 1.4 : dot) / 2;
      if (filled) {
        canvas.drawCircle(
          center,
          r,
          Paint()
            ..color = stage == FightStage.call
                ? scheme.onSurface
                : scheme.primary,
        );
      } else {
        canvas.drawCircle(center, r, Paint()..color = scheme.surface);
      }
      canvas.drawCircle(
        center,
        r - 1,
        Paint()
          ..color = scheme.outline
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    // Where the player tapped, below the track.
    final tick = Paint()
      ..color = scheme.onSurface
      ..strokeWidth = 2;
    final min = -pattern.beatMs;
    for (final t in taps) {
      final ms = t.clamp(min, pattern.lengthMs);
      canvas.drawLine(
        Offset(x(ms), _trackY + dot / 2 + 8),
        Offset(x(ms), _trackY + dot / 2 + 18),
        tick,
      );
    }

    // The playhead.
    if (playheadMs case final at?) {
      var ms = at.clamp(min, pattern.lengthMs);
      if (stepped) {
        ms =
            ((ms + pattern.beatMs) ~/ pattern.beatMs) * pattern.beatMs -
            pattern.beatMs;
      }
      canvas.drawRect(
        Rect.fromCenter(center: Offset(x(ms), _trackY), width: 4, height: 40),
        Paint()..color = scheme.primary,
      );
    }
  }

  /// A judgement told by its shape: ✓ perfect, ◎ good, ✗ miss, as pixel
  /// icons by whole pixels.
  void _hit(Canvas canvas, Offset center, Hit hit, double size) {
    final sprite = switch (hit) {
      Hit.perfect => Sprites.uiCheckCircle,
      Hit.good => Sprites.uiTarget,
      Hit.miss => Sprites.uiCrossCircle,
    };
    final cell = max(1, (size / sprite.width).round()).toDouble();
    canvas
      ..save()
      ..translate(
        (center.dx - cell * sprite.width / 2).roundToDouble(),
        (center.dy - cell * sprite.height / 2).roundToDouble(),
      )
      ..scale(cell);
    sprite.paint(canvas, [hit == Hit.miss ? scheme.error : scheme.primary]);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_TimelinePainter old) => true;
}
