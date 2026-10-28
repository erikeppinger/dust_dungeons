import 'package:flutter/material.dart';

import 'chore_palette.dart';

/// Builds the Material 3 theme for one brightness.
ThemeData buildAppTheme({
  required Brightness brightness,
  required bool colorblindSafe,
}) {
  final scheme = ColorScheme.fromSeed(
    seedColor: colorblindSafe
        ? const Color(0xFF0072B2)
        : const Color(0xFF43A047),
    brightness: brightness,
  );
  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    extensions: [colorblindSafe ? ChorePalette.okabeIto : ChorePalette.vibrant],
  );
}
