import 'package:flutter/material.dart';

/// Colors used for chores and categories, available via
/// `Theme.of(context).extension<ChorePalette>()`.
///
/// Color is never the only signal: every chore also shows an icon and a label.
@immutable
class ChorePalette extends ThemeExtension<ChorePalette> {
  const ChorePalette({required this.colors, required this.isColorblindSafe});

  /// Vibrant default palette.
  static const vibrant = ChorePalette(
    isColorblindSafe: false,
    colors: [
      Color(0xFFE53935), // red
      Color(0xFFFB8C00), // orange
      Color(0xFFFDD835), // yellow
      Color(0xFF43A047), // green
      Color(0xFF00ACC1), // cyan
      Color(0xFF1E88E5), // blue
      Color(0xFF8E24AA), // purple
      Color(0xFFD81B60), // pink
    ],
  );

  /// Okabe-Ito palette, distinguishable with protanopia, deuteranopia and
  /// tritanopia. Black is replaced by grey so it stays visible in dark mode.
  static const okabeIto = ChorePalette(
    isColorblindSafe: true,
    colors: [
      Color(0xFFE69F00), // orange
      Color(0xFF56B4E9), // sky blue
      Color(0xFF009E73), // bluish green
      Color(0xFFF0E442), // yellow
      Color(0xFF0072B2), // blue
      Color(0xFFD55E00), // vermillion
      Color(0xFFCC79A7), // reddish purple
      Color(0xFF999999), // grey
    ],
  );

  final List<Color> colors;
  final bool isColorblindSafe;

  /// Stable color for a chore's color key; wraps around the palette.
  Color colorFor(int colorKey) => colors[colorKey % colors.length];

  /// Text/icon color with sufficient contrast on top of [colorFor].
  Color onColorFor(int colorKey) =>
      ThemeData.estimateBrightnessForColor(colorFor(colorKey)) ==
          Brightness.dark
      ? Colors.white
      : Colors.black;

  @override
  ChorePalette copyWith({List<Color>? colors, bool? isColorblindSafe}) =>
      ChorePalette(
        colors: colors ?? this.colors,
        isColorblindSafe: isColorblindSafe ?? this.isColorblindSafe,
      );

  @override
  ChorePalette lerp(ChorePalette? other, double t) {
    if (other == null || other.colors.length != colors.length) return this;
    return ChorePalette(
      colors: [
        for (var i = 0; i < colors.length; i++)
          Color.lerp(colors[i], other.colors[i], t)!,
      ],
      isColorblindSafe: t < 0.5 ? isColorblindSafe : other.isColorblindSafe,
    );
  }
}
