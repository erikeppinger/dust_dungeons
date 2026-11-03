import 'dart:math';

import 'package:flutter/material.dart';

import '../../domain/fight/boss.dart';
import '../../game/game_texts.dart';
import '../../l10n/app_localizations.dart';

/// How a boss looks right now.
enum BossMood { idle, hit, defeated }

String bossName(AppLocalizations l10n, BossFamily family) =>
    gameBossName(l10n, family);

/// Which chores feed a family's tokens, in a few words.
String bossSource(AppLocalizations l10n, BossFamily family) =>
    family == BossFamily.overlord
    ? l10n.bossSourceOverlord(overlordWinsNeeded)
    : gameBossFedBy(l10n, family) ?? '';

String trophyName(AppLocalizations l10n, BossFamily family) =>
    gameBossTrophy(l10n, family) ?? l10n.trophyGeneric(bossName(l10n, family));

/// Main and light color of each boss. Families also differ in silhouette,
/// so color is never the only way to tell them apart.
(Color, Color) bossColors(BossFamily family) => switch (family) {
  BossFamily.dust => (const Color(0xFFB9A3C4), const Color(0xFFD7C4DE)),
  BossFamily.laundry => (const Color(0xFF00838F), const Color(0xFF4DB6C3)),
  BossFamily.kitchen => (const Color(0xFFF4A259), const Color(0xFFE08A3C)),
  BossFamily.bath => (const Color(0xFF90A4AE), const Color(0xFFCFD8DC)),
  BossFamily.trash => (const Color(0xFF6D7F3F), const Color(0xFF9CAF6A)),
  BossFamily.bedroom => (const Color(0xFF9FA8DA), const Color(0xFFC5CAE9)),
  BossFamily.outside => (const Color(0xFF81D4FA), const Color(0xFFB3E5FC)),
  BossFamily.clutter => (const Color(0xFF78909C), const Color(0xFFB0BEC5)),
  BossFamily.overlord => (const Color(0xFF5E35B1), const Color(0xFFB39DDB)),
};

/// A boss drawn from simple shapes (no image assets).
class BossArt extends StatelessWidget {
  const BossArt({
    super.key,
    required this.family,
    this.size = 64,
    this.mood = BossMood.idle,
    this.semanticLabel,
  });

  final BossFamily family;
  final double size;
  final BossMood mood;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) => Semantics(
    label: semanticLabel ?? bossName(AppLocalizations.of(context), family),
    image: true,
    child: CustomPaint(
      size: Size.square(size),
      painter: _BossPainter(family, mood),
    ),
  );
}

class _BossPainter extends CustomPainter {
  _BossPainter(this.family, this.mood);

  final BossFamily family;
  final BossMood mood;

  @override
  void paint(Canvas canvas, Size size) {
    // Drawn on a 120×120 grid.
    canvas.scale(size.width / 120);
    final (main, light) = bossColors(family);
    final fill = Paint()..color = main;
    final lightFill = Paint()..color = light;
    if (mood == BossMood.defeated) {
      canvas.translate(0, 18);
      canvas.rotate(-0.12);
    }
    if (mood == BossMood.hit) canvas.translate(4, 0);
    switch (family) {
      case BossFamily.dust:
        _dust(canvas, fill, lightFill);
      case BossFamily.clutter:
        _clutter(canvas, fill);
      case BossFamily.laundry:
        _hydra(canvas, fill, lightFill);
      case BossFamily.kitchen:
        _kraken(canvas, fill, lightFill);
      case BossFamily.bath:
        _golem(canvas, fill, lightFill);
      case BossFamily.trash:
        _titan(canvas, fill, lightFill);
      case BossFamily.bedroom:
        _phantom(canvas, fill, lightFill);
      case BossFamily.outside:
        _wraith(canvas, fill, lightFill);
      case BossFamily.overlord:
        _overlord(canvas, fill, lightFill);
    }
    _face(canvas);
  }

  void _dust(Canvas c, Paint fill, Paint light) {
    final tilt = mood == BossMood.hit ? 0.4 : 0.15;
    for (final (x, angle) in [(42.0, -tilt), (78.0, tilt)]) {
      c.save();
      c.translate(x, 30);
      c.rotate(angle);
      c.drawOval(
        Rect.fromCenter(center: Offset.zero, width: 22, height: 56),
        light,
      );
      c.restore();
    }
    c.drawCircle(const Offset(60, 74), 38, fill);
    for (final o in const [
      Offset(30, 62),
      Offset(90, 62),
      Offset(36, 96),
      Offset(84, 96),
    ]) {
      c.drawCircle(o, 14, fill);
    }
    // The crown.
    final crown = Path()
      ..moveTo(40, 40)
      ..lineTo(46, 22)
      ..lineTo(54, 34)
      ..lineTo(60, 18)
      ..lineTo(66, 34)
      ..lineTo(74, 22)
      ..lineTo(80, 40)
      ..close();
    c.drawPath(crown, Paint()..color = const Color(0xFFE6C463));
  }

  void _clutter(Canvas c, Paint fill) {
    final spikes = Path()..moveTo(20, 100);
    const points = [
      Offset(30, 60),
      Offset(42, 76),
      Offset(50, 40),
      Offset(62, 70),
      Offset(72, 34),
      Offset(80, 72),
      Offset(92, 52),
      Offset(100, 100),
    ];
    for (final p in points) {
      spikes.lineTo(p.dx, p.dy);
    }
    spikes.close();
    c.drawPath(spikes, fill);
    void junk(Offset at, Size s, double angle, Color color) {
      c.save();
      c.translate(at.dx, at.dy);
      c.rotate(angle);
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: s.width,
            height: s.height,
          ),
          const Radius.circular(2),
        ),
        Paint()..color = color,
      );
      c.restore();
    }

    junk(
      const Offset(43, 86),
      const Size(18, 12),
      -0.2,
      const Color(0xFFFFCA28),
    );
    junk(
      const Offset(74, 88),
      const Size(20, 10),
      0.18,
      const Color(0xFFEF5350),
    );
  }

  Paint _stroke(Color color, double width) => Paint()
    ..color = color
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;

  /// Laundry Hydra: a laundry basket with three sock-necked heads.
  void _hydra(Canvas c, Paint fill, Paint light) {
    final neck = _stroke(light.color, 11);
    c.drawPath(
      Path()
        ..moveTo(36, 60)
        ..quadraticBezierTo(22, 34, 26, 18),
      neck,
    );
    c.drawPath(
      Path()
        ..moveTo(60, 56)
        ..lineTo(60, 12),
      neck,
    );
    c.drawPath(
      Path()
        ..moveTo(84, 60)
        ..quadraticBezierTo(98, 34, 94, 18),
      neck,
    );
    for (final o in const [Offset(26, 16), Offset(60, 10), Offset(94, 16)]) {
      c.drawOval(Rect.fromCenter(center: o, width: 22, height: 16), fill);
      c.drawCircle(o.translate(-4, -1), 2.5, Paint()..color = Colors.white);
      c.drawCircle(o.translate(4, -1), 2.5, Paint()..color = Colors.white);
    }
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(16, 52, 88, 62),
        const Radius.circular(18),
      ),
      fill,
    );
    // Basket weave.
    final weave = _stroke(light.color, 3);
    for (var y = 92.0; y <= 106; y += 7) {
      c.drawLine(Offset(24, y), Offset(96, y), weave);
    }
  }

  /// Sink Kraken: a dome with curling tentacles and soap bubbles.
  void _kraken(Canvas c, Paint fill, Paint light) {
    final arm = _stroke(light.color, 9);
    for (final (x, dx) in const [
      (26.0, -8.0),
      (46.0, -4.0),
      (74.0, 4.0),
      (94.0, 8.0),
    ]) {
      c.drawPath(
        Path()
          ..moveTo(x, 86)
          ..quadraticBezierTo(x + dx, 104, x + dx * 2, 112),
        arm,
      );
    }
    c.drawPath(
      Path()
        ..moveTo(18, 92)
        ..quadraticBezierTo(18, 26, 60, 26)
        ..quadraticBezierTo(102, 26, 102, 92)
        ..close(),
      fill,
    );
    final bubble = _stroke(const Color(0xFFB3E5FC), 2);
    c.drawCircle(const Offset(104, 30), 6, bubble);
    c.drawCircle(const Offset(112, 18), 4, bubble);
    c.drawCircle(const Offset(14, 40), 5, bubble);
  }

  /// Porcelain Golem: a heavy block with arms and cracks.
  void _golem(Canvas c, Paint fill, Paint light) {
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(26, 34, 68, 76),
        const Radius.circular(14),
      ),
      fill,
    );
    for (final x in const [8.0, 96.0]) {
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, 56, 16, 40),
          const Radius.circular(8),
        ),
        light,
      );
    }
    // A lid on top, slightly open.
    c.save();
    c.translate(60, 30);
    c.rotate(-0.12);
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: 76, height: 12),
        const Radius.circular(6),
      ),
      light,
    );
    c.restore();
    final crack = _stroke(const Color(0xFF546E7A), 2);
    c.drawPath(
      Path()
        ..moveTo(32, 46)
        ..lineTo(38, 54)
        ..lineTo(34, 60),
      crack,
    );
    c.drawPath(
      Path()
        ..moveTo(88, 98)
        ..lineTo(82, 104)
        ..lineTo(86, 108),
      crack,
    );
  }

  /// Trash Titan: a stomping bin with a flapping lid.
  void _titan(Canvas c, Paint fill, Paint light) {
    c.drawPath(
      Path()
        ..moveTo(24, 38)
        ..lineTo(96, 38)
        ..lineTo(88, 108)
        ..lineTo(32, 108)
        ..close(),
      fill,
    );
    c.save();
    c.translate(60, 30);
    c.rotate(mood == BossMood.hit ? -0.35 : -0.15);
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: 84, height: 12),
        const Radius.circular(4),
      ),
      light,
    );
    c.restore();
    final rib = _stroke(light.color, 3);
    for (final x in const [44.0, 60.0, 76.0]) {
      c.drawLine(Offset(x, 90), Offset(x, 104), rib);
    }
    for (final x in const [30.0, 76.0]) {
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, 106, 16, 10),
          const Radius.circular(3),
        ),
        light,
      );
    }
  }

  /// Pillow Phantom: a ghost with a wavy hem and a pillow hat.
  void _phantom(Canvas c, Paint fill, Paint light) {
    final body = Path()
      ..moveTo(22, 106)
      ..lineTo(22, 64)
      ..quadraticBezierTo(22, 28, 60, 28)
      ..quadraticBezierTo(98, 28, 98, 64)
      ..lineTo(98, 106);
    for (var x = 98.0; x > 22; x -= 19) {
      body.quadraticBezierTo(x - 9.5, 116, x - 19, 106);
    }
    body.close();
    c.drawPath(body, fill);
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(30, 12, 60, 24),
        const Radius.circular(12),
      ),
      light,
    );
  }

  /// Window Wraith: a window frame trailing a wisp.
  void _wraith(Canvas c, Paint fill, Paint light) {
    c.drawPath(
      Path()
        ..moveTo(40, 96)
        ..quadraticBezierTo(30, 112, 12, 114)
        ..quadraticBezierTo(36, 106, 50, 92)
        ..close(),
      light,
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(24, 30, 72, 72),
        const Radius.circular(8),
      ),
      fill,
    );
    final frame = _stroke(light.color, 5);
    c.drawLine(const Offset(60, 34), const Offset(60, 52), frame);
    c.drawLine(const Offset(60, 92), const Offset(60, 98), frame);
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(24, 30, 72, 72),
        const Radius.circular(8),
      ),
      frame,
    );
  }

  /// Chore Overlord: a robed ruler with a big crown and a plunger sceptre.
  void _overlord(Canvas c, Paint fill, Paint light) {
    // Sceptre behind the robe.
    c.drawLine(
      const Offset(104, 44),
      const Offset(104, 114),
      _stroke(const Color(0xFF8D6E63), 5),
    );
    c.drawArc(
      Rect.fromCenter(center: const Offset(104, 46), width: 22, height: 20),
      pi,
      pi,
      true,
      Paint()..color = const Color(0xFFE53935),
    );
    c.drawPath(
      Path()
        ..moveTo(34, 62)
        ..lineTo(86, 62)
        ..lineTo(106, 116)
        ..lineTo(14, 116)
        ..close(),
      fill,
    );
    c.drawCircle(const Offset(60, 72), 26, light);
    // A high-collared cape.
    c.drawPath(
      Path()
        ..moveTo(26, 64)
        ..lineTo(34, 92)
        ..lineTo(40, 66)
        ..close(),
      fill,
    );
    c.drawPath(
      Path()
        ..moveTo(94, 64)
        ..lineTo(86, 92)
        ..lineTo(80, 66)
        ..close(),
      fill,
    );
    final crown = Path()
      ..moveTo(34, 52)
      ..lineTo(36, 22)
      ..lineTo(46, 36)
      ..lineTo(53, 14)
      ..lineTo(60, 32)
      ..lineTo(67, 14)
      ..lineTo(74, 36)
      ..lineTo(84, 22)
      ..lineTo(86, 52)
      ..close();
    c.drawPath(crown, Paint()..color = const Color(0xFFE6C463));
    c.drawCircle(
      const Offset(60, 44),
      4,
      Paint()..color = const Color(0xFFE53935),
    );
  }

  void _face(Canvas c) {
    final ink = Paint()
      ..color = const Color(0xFF1A1C18)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final white = Paint()..color = Colors.white;
    final eyeY = family == BossFamily.clutter ? 62.0 : 70.0;
    const left = 48.0, right = 72.0;
    if (mood == BossMood.idle) {
      c.drawCircle(Offset(left, eyeY), 8, white);
      c.drawCircle(Offset(right, eyeY), 8, white);
      final pupil = Paint()..color = const Color(0xFF1A1C18);
      c.drawCircle(Offset(left + 2, eyeY + 1), 4, pupil);
      c.drawCircle(Offset(right - 2, eyeY + 1), 4, pupil);
      c.drawArc(
        // A cheeky grin (lower half of an oval).
        Rect.fromCenter(center: Offset(60, eyeY + 16), width: 22, height: 12),
        0,
        pi,
        false,
        ink,
      );
    } else {
      // Squeezed (hit) or dizzy (defeated) eyes: little crosses.
      for (final x in const [left, right]) {
        c.drawLine(Offset(x - 6, eyeY - 3), Offset(x + 6, eyeY + 3), ink);
        c.drawLine(Offset(x + 6, eyeY - 3), Offset(x - 6, eyeY + 3), ink);
      }
      c.drawArc(
        // A grimace (upper half of an oval).
        Rect.fromCenter(center: Offset(60, eyeY + 22), width: 20, height: 10),
        pi,
        pi,
        false,
        ink,
      );
    }
  }

  @override
  bool shouldRepaint(_BossPainter old) =>
      old.family != family || old.mood != mood;
}
