import 'dart:math';

import 'package:flutter/material.dart';

import '../../domain/fight/boss.dart';
import '../../l10n/app_localizations.dart';

/// How a boss looks right now.
enum BossMood { idle, hit, defeated }

String bossName(AppLocalizations l10n, BossFamily family) => switch (family) {
  BossFamily.dust => l10n.bossDust,
  BossFamily.laundry => l10n.bossLaundry,
  BossFamily.kitchen => l10n.bossKitchen,
  BossFamily.bath => l10n.bossBath,
  BossFamily.trash => l10n.bossTrash,
  BossFamily.bedroom => l10n.bossBedroom,
  BossFamily.outside => l10n.bossOutside,
  BossFamily.clutter => l10n.bossClutter,
};

/// Which chores feed a family's tokens, in a few words.
String bossSource(AppLocalizations l10n, BossFamily family) => switch (family) {
  BossFamily.dust => l10n.bossSourceDust,
  BossFamily.laundry => l10n.bossSourceLaundry,
  BossFamily.kitchen => l10n.bossSourceKitchen,
  BossFamily.bath => l10n.bossSourceBath,
  BossFamily.trash => l10n.bossSourceTrash,
  BossFamily.bedroom => l10n.bossSourceBedroom,
  BossFamily.outside => l10n.bossSourceOutside,
  BossFamily.clutter => l10n.bossSourceClutter,
};

String trophyName(AppLocalizations l10n, BossFamily family) => switch (family) {
  BossFamily.dust => l10n.trophyDust,
  BossFamily.clutter => l10n.trophyClutter,
  _ => l10n.trophyGeneric(bossName(l10n, family)),
};

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
    switch (family) {
      case BossFamily.dust:
        _dust(canvas, fill, lightFill);
      case BossFamily.clutter:
        _clutter(canvas, fill);
      default:
        _blob(canvas, fill, lightFill);
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

  void _blob(Canvas c, Paint fill, Paint light) {
    // Each family gets its own silhouette from a few parameters.
    final i = family.index;
    final path = Path();
    const n = 9;
    for (var k = 0; k <= n * 2; k++) {
      final a = pi * 2 * k / (n * 2);
      final r = 40 + (k.isEven ? 6 + i % 3 * 3 : -2.0);
      final p = Offset(60 + cos(a) * r, 68 + sin(a) * r * 0.9);
      k == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    path.close();
    c.drawPath(path, fill);
    c.drawCircle(const Offset(60, 90), 12, light);
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
