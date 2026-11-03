import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../art/art.dart';

/// The 16-bit look: frames like game menus, pixel icons and segmented bars.
/// One "pixel" is [pixelUnit] logical pixels.
const pixelUnit = 2.0;

/// The bundled pixel font (Press Start 2P, SIL Open Font License), used for
/// headings only: body text stays in the system font for readability.
const pixelFont = 'PressStart2P';

/// The day or night UI palette (from `assets/art/palettes/ui_*.gpl`),
/// available via `PixelColors.of(context)`: the frame color for panels and
/// bars, and the colors the coin and hearts are painted in.
@immutable
class PixelColors extends ThemeExtension<PixelColors> {
  const PixelColors(this.palette);

  final UiPalette palette;

  /// The dark outline around panels, buttons and bars.
  Color get frame => palette.frame;

  static PixelColors of(BuildContext context) =>
      Theme.of(context).extension<PixelColors>()!;

  @override
  PixelColors copyWith({UiPalette? palette}) =>
      PixelColors(palette ?? this.palette);

  // Palettes swap whole: sprites are painted with one or the other.
  @override
  PixelColors lerp(PixelColors? other, double t) =>
      other == null || t < 0.5 ? this : other;
}

/// A pixel frame: an outline with the corner pixels cut off, a light edge
/// at the top and left and a shaded edge at the bottom and right, so the
/// panel or button looks raised. The edges are drawn as translucent white and
/// black, so they suit any fill color.
class PixelBorder extends OutlinedBorder {
  const PixelBorder({super.side, this.depth = 1, this.bevel = true});

  /// Thickness of the shaded bottom edge, in pixels.
  final int depth;

  /// Whether to draw the light and shaded edges inside the outline.
  final bool bevel;

  double get _p => side.style == BorderStyle.none ? pixelUnit : side.width;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(_p);

  @override
  PixelBorder copyWith({BorderSide? side, int? depth, bool? bevel}) =>
      PixelBorder(
        side: side ?? this.side,
        depth: depth ?? this.depth,
        bevel: bevel ?? this.bevel,
      );

  @override
  ShapeBorder scale(double t) => copyWith(side: side.scale(t));

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) => a is PixelBorder
      ? copyWith(side: BorderSide.lerp(a.side, side, t))
      : null;

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) => b is PixelBorder
      ? copyWith(side: BorderSide.lerp(side, b.side, t))
      : null;

  /// The rectangle with one pixel cut from each corner.
  static Path _notched(Rect r, double p) => Path()
    ..moveTo(r.left + p, r.top)
    ..lineTo(r.right - p, r.top)
    ..lineTo(r.right - p, r.top + p)
    ..lineTo(r.right, r.top + p)
    ..lineTo(r.right, r.bottom - p)
    ..lineTo(r.right - p, r.bottom - p)
    ..lineTo(r.right - p, r.bottom)
    ..lineTo(r.left + p, r.bottom)
    ..lineTo(r.left + p, r.bottom - p)
    ..lineTo(r.left, r.bottom - p)
    ..lineTo(r.left, r.top + p)
    ..lineTo(r.left + p, r.top + p)
    ..close();

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      _notched(rect, _p);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      Path()..addRect(rect.deflate(_p));

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final p = _p;
    if (rect.width < 4 * p || rect.height < 4 * p) return;
    if (bevel) {
      final inner = rect.deflate(p);
      final light = Paint()..color = const Color(0x40FFFFFF);
      final shade = Paint()..color = const Color(0x33000000);
      final d = p * depth;
      canvas
        ..drawRect(
          Rect.fromLTWH(inner.left, inner.top, inner.width - p, p),
          light,
        )
        ..drawRect(
          Rect.fromLTWH(inner.left, inner.top + p, p, inner.height - p - d),
          light,
        )
        ..drawRect(
          Rect.fromLTWH(inner.left, inner.bottom - d, inner.width, d),
          shade,
        )
        ..drawRect(
          Rect.fromLTWH(inner.right - p, inner.top, p, inner.height - d),
          shade,
        );
    }
    if (side.style == BorderStyle.none) return;
    final outline = Path.combine(
      PathOperation.difference,
      _notched(rect, p),
      Path()..addRect(rect.deflate(p)),
    );
    canvas.drawPath(outline, Paint()..color = side.color);
  }

  @override
  bool operator ==(Object other) =>
      other is PixelBorder &&
      other.side == side &&
      other.depth == depth &&
      other.bevel == bevel;

  @override
  int get hashCode => Object.hash(side, depth, bevel);
}

/// A pixel-art sprite from `assets/art`, scaled by whole pixels and
/// centered. Without a [palette] the sprite is a mask painted in one color:
/// [color], or the [IconTheme]'s (for tab icons).
class PixelIcon extends StatelessWidget {
  const PixelIcon(
    this.sprite, {
    super.key,
    this.size,
    this.color,
    this.palette,
    this.semanticLabel,
  });

  final Sprite sprite;
  final double? size;
  final Color? color;
  final List<Color>? palette;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final icon = IconTheme.of(context);
    final size = this.size ?? icon.size ?? 24;
    final picture = CustomPaint(
      size: Size.square(size),
      painter: _PixelPainter(
        sprite,
        palette ??
            [color ?? icon.color ?? Theme.of(context).colorScheme.onSurface],
      ),
    );
    return semanticLabel == null
        ? ExcludeSemantics(child: picture)
        : Semantics(label: semanticLabel, image: true, child: picture);
  }
}

class _PixelPainter extends CustomPainter {
  _PixelPainter(this.sprite, this.palette);

  final Sprite sprite;
  final List<Color> palette;

  @override
  void paint(Canvas canvas, Size size) {
    final n = max(sprite.width, sprite.height);
    // Whole pixels, centered: no blurry half pixels.
    final cell = max(1, (size.width / n).floorToDouble()).toDouble();
    canvas
      ..translate(
        ((size.width - cell * sprite.width) / 2).roundToDouble(),
        ((size.height - cell * sprite.height) / 2).roundToDouble(),
      )
      ..scale(cell);
    sprite.paint(canvas, palette);
  }

  @override
  bool shouldRepaint(_PixelPainter old) =>
      !identical(old.sprite, sprite) || !listEquals(old.palette, palette);
}

/// A segmented bar like a game's health bar: [segments] blocks inside a
/// frame, filled up to [value] (0–1).
class PixelBar extends StatelessWidget {
  const PixelBar({
    super.key,
    required this.value,
    this.segments = 10,
    this.height = 14,
    this.color,
    this.trackColor,
    this.semanticsLabel,
    this.semanticsValue,
  });

  final double value;
  final int segments;
  final double height;
  final Color? color, trackColor;
  final String? semanticsLabel, semanticsValue;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fill = color ?? scheme.primary;
    return Semantics(
      label: semanticsLabel,
      value: semanticsValue ?? '${(value.clamp(0, 1) * 100).round()} %',
      child: CustomPaint(
        size: Size.fromHeight(height),
        painter: _BarPainter(
          value: value.clamp(0, 1).toDouble(),
          segments: segments,
          frame: PixelColors.of(context).frame,
          fill: fill,
          track: trackColor ?? scheme.surfaceContainerHighest,
        ),
      ),
    );
  }
}

class _BarPainter extends CustomPainter {
  _BarPainter({
    required this.value,
    required this.segments,
    required this.frame,
    required this.fill,
    required this.track,
  });

  final double value;
  final int segments;
  final Color frame, fill, track;

  @override
  void paint(Canvas canvas, Size size) {
    const p = pixelUnit;
    final rect = Offset.zero & size;
    final paint = Paint()..isAntiAlias = false;
    canvas.drawPath(PixelBorder._notched(rect, p), paint..color = frame);
    final inner = rect.deflate(p);
    canvas.drawRect(inner, paint..color = track);
    // Segments with a one-pixel gap; a partly filled segment fills partly.
    final width = (inner.width - p * (segments + 1)) / segments;
    if (width <= 0) return;
    final filled = value * segments;
    for (var i = 0; i < segments; i++) {
      final part = (filled - i).clamp(0.0, 1.0);
      if (part <= 0) break;
      final left = inner.left + p + i * (width + p);
      final seg = Rect.fromLTWH(
        left,
        inner.top + p,
        (width * part).roundToDouble().clamp(p, width),
        inner.height - 2 * p,
      );
      canvas.drawRect(seg, paint..color = fill);
      // A light top row gives each block a little shine.
      canvas.drawRect(
        Rect.fromLTWH(seg.left, seg.top, seg.width, p),
        paint..color = const Color(0x4DFFFFFF),
      );
    }
  }

  @override
  bool shouldRepaint(_BarPainter old) =>
      old.value != value ||
      old.segments != segments ||
      old.frame != frame ||
      old.fill != fill ||
      old.track != track;
}

/// A coin icon in the theme's gold.
class PixelCoin extends StatelessWidget {
  const PixelCoin({super.key, this.size = 24});

  final double size;

  @override
  Widget build(BuildContext context) {
    return PixelIcon(
      Sprites.coin,
      size: size,
      palette: PixelColors.of(context).palette.colors,
    );
  }
}

/// The level coin: a coin with [level] stamped on it in pixel digits (up
/// to 99; higher levels show the plain coin mark).
class LevelCoin extends StatelessWidget {
  const LevelCoin({super.key, required this.level, this.size = 36});

  final int level;
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(
      size: Size.square(size),
      painter: _LevelCoinPainter(level, PixelColors.of(context).palette),
    ),
  );
}

/// Digits 0–9, 3×5 pixels each, row by row.
const _digitRows = [
  ['111', '101', '101', '101', '111'],
  ['010', '110', '010', '010', '111'],
  ['111', '001', '111', '100', '111'],
  ['111', '001', '111', '001', '111'],
  ['101', '101', '111', '001', '001'],
  ['111', '100', '111', '001', '111'],
  ['111', '100', '111', '101', '111'],
  ['111', '001', '010', '010', '010'],
  ['111', '101', '111', '101', '111'],
  ['111', '101', '111', '001', '111'],
];

class _LevelCoinPainter extends CustomPainter {
  _LevelCoinPainter(this.level, this.palette);

  final int level;
  final UiPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final plain = level < 1 || level > 99;
    final sprite = plain ? Sprites.coin : Sprites.coinBlank;
    final cell = max(1, (size.width / sprite.width).floorToDouble()).toDouble();
    final offset = ((size.width - cell * sprite.width) / 2).roundToDouble();
    canvas
      ..translate(offset, offset)
      ..scale(cell);
    sprite.paint(canvas, palette.colors);
    if (plain) return;
    final digits = '$level'.split('').map(int.parse).toList();
    // One digit in the middle, two side by side with a pixel between.
    var x = digits.length == 1 ? 4 : 2;
    final ink = Paint()
      ..color = palette.coinShade
      ..isAntiAlias = false;
    for (final d in digits) {
      for (final (y, row) in _digitRows[d].indexed) {
        for (var i = 0; i < 3; i++) {
          if (row[i] == '1') {
            canvas.drawRect(
              Rect.fromLTWH((x + i).toDouble(), (3 + y).toDouble(), 1, 1),
              ink,
            );
          }
        }
      }
      x += 4;
    }
  }

  @override
  bool shouldRepaint(_LevelCoinPainter old) =>
      old.level != level || old.palette != palette;
}

/// The streak flame, in its own red and gold.
class PixelFlame extends StatelessWidget {
  const PixelFlame({super.key, this.size = 24});

  final double size;

  @override
  Widget build(BuildContext context) => PixelIcon(
    Sprites.flame,
    size: size,
    palette: PixelColors.of(context).palette.colors,
  );
}

/// A trophy cup in the theme's gold.
class PixelTrophy extends StatelessWidget {
  const PixelTrophy({super.key, this.size = 24, this.semanticLabel});

  final double size;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return PixelIcon(
      Sprites.trophy,
      size: size,
      palette: PixelColors.of(context).palette.colors,
      semanticLabel: semanticLabel,
    );
  }
}

/// A full or empty heart.
class PixelHeart extends StatelessWidget {
  const PixelHeart({super.key, required this.full, this.size = 24});

  final bool full;
  final double size;

  @override
  Widget build(BuildContext context) {
    return PixelIcon(
      full ? Sprites.heart : Sprites.heartEmpty,
      size: size,
      palette: PixelColors.of(context).palette.colors,
    );
  }
}

/// "LV 4" in a small framed badge.
class LevelBadge extends StatelessWidget {
  const LevelBadge({super.key, required this.level, required this.label});

  final int level;

  /// Spoken instead of the badge text ("Level 4").
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: scheme.secondaryContainer,
          shape: PixelBorder(
            side: BorderSide(color: PixelColors.of(context).frame, width: 2),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 7, 8, 6),
          child: Text(
            'LV $level',
            style: theme.textTheme.labelLarge?.copyWith(
              fontFamily: pixelFont,
              fontSize: 10,
              color: scheme.onSecondaryContainer,
            ),
          ),
        ),
      ),
    );
  }
}

/// Clips [child] to a pixel frame's shape and draws the frame over it, for
/// pictures such as the quest map.
class PixelFrame extends StatelessWidget {
  const PixelFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final shape = PixelBorder(
      side: BorderSide(color: PixelColors.of(context).frame, width: pixelUnit),
      bevel: false,
    );
    return Container(
      foregroundDecoration: ShapeDecoration(shape: shape),
      child: ClipPath(
        clipper: ShapeBorderClipper(shape: shape),
        child: child,
      ),
    );
  }
}
