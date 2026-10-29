import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// The 16-bit look: frames like game menus, pixel icons and segmented bars.
/// One "pixel" is [pixelUnit] logical pixels.
const pixelUnit = 2.0;

/// The bundled pixel font (Press Start 2P, SIL Open Font License), used for
/// headings only: body text stays in the system font for readability.
const pixelFont = 'PressStart2P';

/// Colors of the pixel frames, available via
/// `Theme.of(context).extension<PixelColors>()`.
@immutable
class PixelColors extends ThemeExtension<PixelColors> {
  const PixelColors({
    required this.frame,
    required this.coin,
    required this.coinShade,
    required this.heart,
    required this.heartEmpty,
  });

  /// The dark outline around panels, buttons and bars.
  final Color frame;
  final Color coin, coinShade;
  final Color heart, heartEmpty;

  static PixelColors of(BuildContext context) =>
      Theme.of(context).extension<PixelColors>()!;

  @override
  PixelColors copyWith({
    Color? frame,
    Color? coin,
    Color? coinShade,
    Color? heart,
    Color? heartEmpty,
  }) => PixelColors(
    frame: frame ?? this.frame,
    coin: coin ?? this.coin,
    coinShade: coinShade ?? this.coinShade,
    heart: heart ?? this.heart,
    heartEmpty: heartEmpty ?? this.heartEmpty,
  );

  @override
  PixelColors lerp(PixelColors? other, double t) {
    if (other == null) return this;
    return PixelColors(
      frame: Color.lerp(frame, other.frame, t)!,
      coin: Color.lerp(coin, other.coin, t)!,
      coinShade: Color.lerp(coinShade, other.coinShade, t)!,
      heart: Color.lerp(heart, other.heart, t)!,
      heartEmpty: Color.lerp(heartEmpty, other.heartEmpty, t)!,
    );
  }
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

/// A small pixel-art picture from rows of characters. `#` takes the icon
/// color (from [IconTheme] unless [color] is given), `.` is empty, and other
/// characters are looked up in [colors].
class PixelIcon extends StatelessWidget {
  const PixelIcon(
    this.rows, {
    super.key,
    this.size,
    this.color,
    this.colors = const {},
    this.semanticLabel,
  });

  final List<String> rows;
  final double? size;
  final Color? color;
  final Map<String, Color> colors;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final icon = IconTheme.of(context);
    final size = this.size ?? icon.size ?? 24;
    final picture = CustomPaint(
      size: Size.square(size),
      painter: _PixelPainter(
        rows,
        color ?? icon.color ?? Theme.of(context).colorScheme.onSurface,
        colors,
      ),
    );
    return semanticLabel == null
        ? ExcludeSemantics(child: picture)
        : Semantics(label: semanticLabel, image: true, child: picture);
  }
}

class _PixelPainter extends CustomPainter {
  _PixelPainter(this.rows, this.color, this.colors);

  final List<String> rows;
  final Color color;
  final Map<String, Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final n = rows.fold(0, (w, r) => max(w, r.length));
    // Whole pixels, centered: no blurry half pixels.
    final cell = max(1, (size.width / n).floorToDouble()).toDouble();
    final dx = ((size.width - cell * n) / 2).roundToDouble();
    final dy = ((size.height - cell * rows.length) / 2).roundToDouble();
    final paint = Paint()..isAntiAlias = false;
    for (var y = 0; y < rows.length; y++) {
      final row = rows[y];
      for (var x = 0; x < row.length; x++) {
        final ch = row[x];
        if (ch == '.') continue;
        final c = ch == '#' ? color : colors[ch];
        if (c == null) continue;
        paint.color = c;
        canvas.drawRect(
          Rect.fromLTWH(dx + x * cell, dy + y * cell, cell, cell),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_PixelPainter old) =>
      old.rows != rows || old.color != color || !mapEquals(old.colors, colors);
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

/// The pixel pictures used across the app, 12×12.
abstract final class PixelArt {
  static const quests = [
    '..########..',
    '.#........#.',
    '.##########.',
    '..#......#..',
    '..#.####.#..',
    '..#......#..',
    '..#.####.#..',
    '..#......#..',
    '..#.###..#..',
    '.##########.',
    '.#........#.',
    '..########..',
  ];

  static const questLog = [
    '............',
    '.####..####.',
    '#....##....#',
    '#.##.##.##.#',
    '#....##....#',
    '#.##.##.##.#',
    '#....##....#',
    '#.##.##.##.#',
    '#....##....#',
    '#....##....#',
    '.####..####.',
    '............',
  ];

  static const arena = [
    '.##########.',
    '#..........#',
    '#.###..###.#',
    '#.###..###.#',
    '#..........#',
    '#.###..###.#',
    '.#.##..##.#.',
    '.#........#.',
    '..#......#..',
    '...#....#...',
    '....#..#....',
    '.....##.....',
  ];

  static const hallOfFame = [
    '.##########.',
    '###......###',
    '#.#......#.#',
    '#.#......#.#',
    '.##......##.',
    '..#......#..',
    '...#....#...',
    '....#..#....',
    '.....##.....',
    '.....##.....',
    '...######...',
    '...######...',
  ];

  static const settings = [
    '.....##.....',
    '..#.####.#..',
    '.##########.',
    '..###..###..',
    '.###....###.',
    '####....####',
    '####....####',
    '.###....###.',
    '..###..###..',
    '.##########.',
    '..#.####.#..',
    '.....##.....',
  ];

  /// `k` outline, `y` gold, `d` shade, `w` shine.
  static const coin = [
    '...kkkkkk...',
    '.kkyyyyyykk.',
    '.kywwyyyyyk.',
    'kywyyddyyydk',
    'kywyydyyyydk',
    'kyyyydyyyydk',
    'kyyyydyyyydk',
    'kyyyydyyyydk',
    'kyyyddddyydk',
    '.kyyyyyyddk.',
    '.kkddddddkk.',
    '...kkkkkk...',
  ];

  /// `k` outline, `r` fill, `w` shine.
  static const heart = [
    '............',
    '.kkk....kkk.',
    'krrrk..krrrk',
    'krwrrkkrrrrk',
    'krwrrrrrrrrk',
    'krrrrrrrrrrk',
    '.krrrrrrrrk.',
    '..krrrrrrk..',
    '...krrrrk...',
    '....krrk....',
    '.....kk.....',
    '............',
  ];

  static const heartEmpty = [
    '............',
    '.kkk....kkk.',
    'keeek..keeek',
    'keeeekkeeeek',
    'keeeeeeeeeek',
    'keeeeeeeeeek',
    '.keeeeeeeek.',
    '..keeeeeek..',
    '...keeeek...',
    '....keek....',
    '.....kk.....',
    '............',
  ];
}

/// A coin icon in the theme's gold.
class PixelCoin extends StatelessWidget {
  const PixelCoin({super.key, this.size = 24});

  final double size;

  @override
  Widget build(BuildContext context) {
    final c = PixelColors.of(context);
    return PixelIcon(
      PixelArt.coin,
      size: size,
      colors: {
        'k': c.frame,
        'y': c.coin,
        'd': c.coinShade,
        'w': const Color(0xFFFFF4C2),
      },
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
    final c = PixelColors.of(context);
    return PixelIcon(
      full ? PixelArt.heart : PixelArt.heartEmpty,
      size: size,
      colors: {
        'k': c.frame,
        'r': c.heart,
        'e': c.heartEmpty,
        'w': const Color(0xFFFFD6D0),
      },
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
