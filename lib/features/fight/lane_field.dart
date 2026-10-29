import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../domain/fight/lanes.dart';
import '../../l10n/app_localizations.dart';
import 'fight_controller.dart';

/// The Overlord's lane phase: notes fall down three lanes to a line, and the
/// player taps the lane as a note crosses it. Each lane has its own shape,
/// so color is never needed.
class LaneField extends StatefulWidget {
  const LaneField({super.key, required this.controller});

  final FightController controller;

  @override
  State<LaneField> createState() => _LaneFieldState();
}

class _LaneFieldState extends State<LaneField>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;

  @override
  void initState() {
    super.initState();
    // Repaint every frame while the notes fall.
    _ticker = createTicker((_) => setState(() {}))..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final c = widget.controller;
    final colors = [scheme.primary, scheme.tertiary, scheme.secondary];
    return LayoutBuilder(
      builder: (context, constraints) {
        final laneWidth = constraints.maxWidth / laneCount;
        return Listener(
          key: const ValueKey('lane-field'),
          behavior: HitTestBehavior.opaque,
          // Raw touch-down, no gesture arena: timing is what counts.
          onPointerDown: (e) => c.tapLane(
            (e.localPosition.dx ~/ laneWidth).clamp(0, laneCount - 1),
          ),
          child: Column(
            children: [
              Expanded(
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _LanePainter(
                    judge: c.laneJudge,
                    elapsedMs: c.laneElapsedMs - c.latencyMs,
                    fallMs: c.fallMs,
                    colors: colors,
                    line: scheme.onSurface,
                    divider: scheme.outlineVariant,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (var lane = 0; lane < laneCount; lane++)
                    Expanded(
                      child: Semantics(
                        button: true,
                        label: l10n.fightLaneLabel(lane + 1),
                        child: Container(
                          key: ValueKey('lane-$lane'),
                          height: 76,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: colors[lane].withValues(alpha: 0.25),
                            border: Border.all(color: colors[lane], width: 3),
                            borderRadius: BorderRadius.zero,
                          ),
                          alignment: Alignment.center,
                          child: CustomPaint(
                            size: const Size.square(28),
                            painter: _ShapePainter(lane, colors[lane]),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Lane 0 is a circle, lane 1 a square, lane 2 a triangle.
void _paintShape(Canvas canvas, int lane, Offset center, double r, Paint p) {
  switch (lane) {
    case 0:
      canvas.drawCircle(center, r, p);
    case 1:
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: center, width: r * 1.8, height: r * 1.8),
          Radius.circular(r * 0.25),
        ),
        p,
      );
    default:
      canvas.drawPath(
        Path()
          ..moveTo(center.dx, center.dy - r)
          ..lineTo(center.dx + r, center.dy + r * 0.8)
          ..lineTo(center.dx - r, center.dy + r * 0.8)
          ..close(),
        p,
      );
  }
}

class _ShapePainter extends CustomPainter {
  _ShapePainter(this.lane, this.color);

  final int lane;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) => _paintShape(
    canvas,
    lane,
    size.center(Offset.zero),
    size.width / 2,
    Paint()..color = color,
  );

  @override
  bool shouldRepaint(_ShapePainter old) =>
      old.lane != lane || old.color != color;
}

class _LanePainter extends CustomPainter {
  _LanePainter({
    required this.judge,
    required this.elapsedMs,
    required this.fallMs,
    required this.colors,
    required this.line,
    required this.divider,
  });

  final LaneJudge? judge;
  final int elapsedMs;
  final int fallMs;
  final List<Color> colors;
  final Color line;
  final Color divider;

  @override
  void paint(Canvas canvas, Size size) {
    final laneWidth = size.width / laneCount;
    final hitY = size.height - 16;
    final dividerPaint = Paint()
      ..color = divider
      ..strokeWidth = 1;
    for (var i = 1; i < laneCount; i++) {
      canvas.drawLine(
        Offset(laneWidth * i, 0),
        Offset(laneWidth * i, size.height),
        dividerPaint,
      );
    }
    canvas.drawLine(
      Offset(0, hitY),
      Offset(size.width, hitY),
      Paint()
        ..color = line
        ..strokeWidth = 3,
    );
    final j = judge;
    if (j == null) return;
    final r = (laneWidth * 0.22).clamp(10.0, 26.0);
    for (var i = 0; i < j.notes.length; i++) {
      if (j.results[i] != null) continue;
      final note = j.notes[i];
      final ahead = (note.atMs - elapsedMs) / fallMs;
      if (ahead > 1.05 || ahead < -0.2) continue;
      _paintShape(
        canvas,
        note.lane,
        Offset(laneWidth * (note.lane + 0.5), hitY - ahead * hitY),
        r,
        Paint()..color = colors[note.lane],
      );
    }
  }

  @override
  bool shouldRepaint(_LanePainter old) => true;
}
