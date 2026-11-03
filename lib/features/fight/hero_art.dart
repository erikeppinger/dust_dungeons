import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../app/art/art.dart';
import '../../domain/fight/items.dart';
import '../../domain/fight/shop.dart';

/// Free avatar choices (more come with the shop in 0.5.1).
const avatarSkins = [
  Color(0xFFFFE0BD),
  Color(0xFFFFCC80),
  Color(0xFFE0A370),
  Color(0xFFB07A4F),
  Color(0xFF7A4E2D),
];
const avatarHair = [
  Color(0xFF5D4037),
  Color(0xFF212121),
  Color(0xFFFBC02D),
  Color(0xFFD84315),
  Color(0xFF9E9E9E),
  Color(0xFF7B1FA2),
];
const avatarCapes = [
  Color(0xFF00897B),
  Color(0xFF1E88E5),
  Color(0xFFE53935),
  Color(0xFF8E24AA),
  Color(0xFFFB8C00),
  Color(0xFF43A047),
];

Color _pick(List<Color> colors, int index) =>
    colors[index.clamp(0, colors.length - 1)];

/// The player's hero: the pixel sprite `assets/art/hero/hero.png` in the
/// Wardrobe's colors, wearing [gear] and the [hat] look (worn head gear
/// covers the hat). Scaled by whole pixels from 32 up; smaller sizes scale
/// down evenly.
class HeroArt extends StatelessWidget {
  const HeroArt({
    super.key,
    required this.skin,
    required this.hair,
    required this.cape,
    this.hat = 0,
    this.gear = const {},
    this.size = 88,
    this.semanticLabel,
  });

  final int skin, hair, cape;

  /// 0 = none, else the `look` of a hat item.
  final int hat;

  /// The worn gear: slot → item key.
  final Map<GearSlot, String> gear;
  final double size;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final night = Theme.of(context).brightness == Brightness.dark;
    final picture = CustomPaint(
      size: Size.square(size),
      painter: _HeroPainter(heroColors(skin: skin, hair: hair, cape: cape), [
        for (final key in wearLayers(gear, hat))
          ?Sprites.all['hero/wear/$key']?.$1.first,
      ], (night ? itemsNight : itemsDay).colors),
    );
    return semanticLabel == null
        ? ExcludeSemantics(child: picture)
        : Semantics(label: semanticLabel, image: true, child: picture);
  }
}

/// The hero palette with its key colors swapped for the Wardrobe's: skin,
/// hair and cape, each with a darker shade.
List<Color> heroColors({
  required int skin,
  required int hair,
  required int cape,
}) {
  Color shade(Color c) => Color.lerp(c, const Color(0xFF000000), 0.25)!;
  final s = _pick(avatarSkins, skin);
  final h = _pick(avatarHair, hair);
  final c = _pick(avatarCapes, cape);
  return [
    for (final (i, color) in hero.colors.indexed)
      switch (i) {
        1 => s,
        2 => shade(s),
        3 => h,
        4 => shade(h),
        5 => c,
        6 => shade(c),
        _ => color,
      },
  ];
}

class _HeroPainter extends CustomPainter {
  _HeroPainter(this.colors, this.wear, this.itemColors);

  final List<Color> colors;
  final List<Sprite> wear;
  final List<Color> itemColors;

  @override
  void paint(Canvas canvas, Size size) {
    const base = Sprites.hero;
    // Whole pixels from 32 up, centered; smaller heroes scale down evenly.
    final cell = size.width >= base.width
        ? (size.width / base.width).floorToDouble()
        : size.width / base.width;
    final offset = (size.width - cell * base.width) / 2;
    canvas
      ..translate(offset.roundToDouble(), offset.roundToDouble())
      ..scale(cell);
    base.paint(canvas, colors);
    for (final layer in wear) {
      layer.paint(canvas, itemColors);
    }
  }

  @override
  bool shouldRepaint(_HeroPainter old) =>
      !listEquals(old.colors, colors) ||
      !listEquals(old.wear, wear) ||
      !listEquals(old.itemColors, itemColors);
}
