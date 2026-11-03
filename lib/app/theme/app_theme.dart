import 'package:flutter/material.dart';

import '../art/art.dart';
import 'chore_palette.dart';
import 'pixel.dart';

/// Builds the 16-bit theme for one brightness: parchment by day, the
/// dungeon at night. Panels, buttons and dialogs get pixel frames, headings
/// the pixel font.
ThemeData buildAppTheme({
  required Brightness brightness,
  required bool colorblindSafe,
}) {
  final dark = brightness == Brightness.dark;
  final scheme = dark ? _night(colorblindSafe) : _day(colorblindSafe);
  final pixels = PixelColors(dark ? uiNight : uiDay);
  final frame = BorderSide(color: pixels.frame, width: pixelUnit);
  final panel = PixelBorder(side: frame);
  final base = ThemeData(colorScheme: scheme, useMaterial3: true);
  final text = _textTheme(base.textTheme);

  return base.copyWith(
    textTheme: text,
    scaffoldBackgroundColor: scheme.surface,
    extensions: [
      colorblindSafe ? ChorePalette.okabeIto : ChorePalette.vibrant,
      pixels,
    ],
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surfaceContainer,
      foregroundColor: scheme.onSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: text.titleLarge?.copyWith(color: scheme.onSurface),
      shape: Border(bottom: frame),
    ),
    // Flutter's own back arrow as a pixel icon (the segments' check mark is
    // set below).
    actionIconTheme: ActionIconThemeData(
      backButtonIconBuilder: (_) => const PixelIcon(Sprites.uiChevronLeft),
    ),
    cardTheme: CardThemeData(
      color: scheme.surfaceContainerLow,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: panel,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: PixelBorder(side: frame, depth: 2),
        elevation: 0,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: PixelBorder(side: frame, depth: 2),
        elevation: 0,
        backgroundColor: scheme.surfaceContainerLow,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(shape: const PixelBorder(), side: frame),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(shape: const PixelBorder(bevel: false)),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: scheme.secondaryContainer,
      foregroundColor: scheme.onSecondaryContainer,
      elevation: 0,
      focusElevation: 0,
      hoverElevation: 0,
      highlightElevation: 0,
      shape: PixelBorder(side: frame, depth: 2),
    ),
    chipTheme: ChipThemeData(
      shape: const PixelBorder(),
      side: frame,
      backgroundColor: scheme.surfaceContainerLow,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surfaceContainer,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      indicatorColor: scheme.secondaryContainer,
      indicatorShape: PixelBorder(side: frame),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: scheme.surfaceContainerLow,
      surfaceTintColor: Colors.transparent,
      shape: PixelBorder(side: frame, depth: 2),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: scheme.surfaceContainerLow,
      surfaceTintColor: Colors.transparent,
      shape: panel,
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: scheme.surfaceContainerLow,
      surfaceTintColor: Colors.transparent,
      shape: panel,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: PixelBorder(side: frame),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.zero),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      selectedIcon: const PixelIcon(Sprites.uiCheck, size: 18),
      style: SegmentedButton.styleFrom(shape: const PixelBorder(), side: frame),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      linearTrackColor: scheme.surfaceContainerHighest,
    ),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant),
  );
}

/// Headings in the pixel font, a size smaller than Material's: the font is
/// wide. Body and labels stay in the system font.
TextTheme _textTheme(TextTheme t) {
  TextStyle? pixel(TextStyle? s, double size) =>
      s?.copyWith(fontFamily: pixelFont, fontSize: size, height: 1.4);
  return t.copyWith(
    displayLarge: pixel(t.displayLarge, 40),
    displayMedium: pixel(t.displayMedium, 32),
    displaySmall: pixel(t.displaySmall, 24),
    headlineLarge: pixel(t.headlineLarge, 24),
    headlineMedium: pixel(t.headlineMedium, 20),
    headlineSmall: pixel(t.headlineSmall, 16),
    titleLarge: pixel(t.titleLarge, 14),
  );
}

/// Day: parchment panels, ink outlines, a forest-green accent and gold.
ColorScheme _day(bool colorblindSafe) => ColorScheme(
  brightness: Brightness.light,
  primary: colorblindSafe ? const Color(0xFF005A8C) : const Color(0xFF2B6E24),
  onPrimary: Colors.white,
  primaryContainer: colorblindSafe
      ? const Color(0xFFC4E2F5)
      : const Color(0xFFCDE6B4),
  onPrimaryContainer: colorblindSafe
      ? const Color(0xFF00304B)
      : const Color(0xFF1B3A12),
  secondary: const Color(0xFF7A4F00),
  onSecondary: Colors.white,
  secondaryContainer: const Color(0xFFF7D774),
  onSecondaryContainer: const Color(0xFF3A2414),
  tertiary: const Color(0xFF8C3A2A),
  onTertiary: Colors.white,
  tertiaryContainer: const Color(0xFFF6CDBF),
  onTertiaryContainer: const Color(0xFF3A1208),
  error: const Color(0xFFB3261E),
  onError: Colors.white,
  errorContainer: const Color(0xFFF9DEDC),
  onErrorContainer: const Color(0xFF410E0B),
  surface: const Color(0xFFF3E5C3),
  onSurface: const Color(0xFF2A1A0E),
  onSurfaceVariant: const Color(0xFF5C4330),
  surfaceDim: const Color(0xFFE0CFA6),
  surfaceBright: const Color(0xFFFFF9E8),
  surfaceContainerLowest: const Color(0xFFFFFBEE),
  surfaceContainerLow: const Color(0xFFFFF6DC),
  surfaceContainer: const Color(0xFFF8EBCB),
  surfaceContainerHigh: const Color(0xFFEEDDB5),
  surfaceContainerHighest: const Color(0xFFE6D2A4),
  outline: const Color(0xFF7A5C40),
  outlineVariant: const Color(0xFFC7AD82),
  shadow: const Color(0xFF3A2414),
  scrim: Colors.black,
  inverseSurface: const Color(0xFF3A2414),
  onInverseSurface: const Color(0xFFFFF6DC),
  inversePrimary: colorblindSafe
      ? const Color(0xFF8CCBF0)
      : const Color(0xFF8FD27A),
  surfaceTint: Colors.transparent,
);

/// Night: the dungeon blue of the map's fog, pale text and torch gold.
ColorScheme _night(bool colorblindSafe) => ColorScheme(
  brightness: Brightness.dark,
  primary: colorblindSafe ? const Color(0xFF56B4E9) : const Color(0xFF7BC95F),
  onPrimary: colorblindSafe ? const Color(0xFF002538) : const Color(0xFF0E2A08),
  primaryContainer: colorblindSafe
      ? const Color(0xFF0B4A6E)
      : const Color(0xFF2E5A22),
  onPrimaryContainer: colorblindSafe
      ? const Color(0xFFC9E9FA)
      : const Color(0xFFCFF5BC),
  secondary: const Color(0xFFF7C948),
  onSecondary: const Color(0xFF2A1E00),
  secondaryContainer: const Color(0xFF5A4410),
  onSecondaryContainer: const Color(0xFFFFE8A6),
  tertiary: const Color(0xFFFF9A8A),
  onTertiary: const Color(0xFF4A0E06),
  tertiaryContainer: const Color(0xFF6E2A1E),
  onTertiaryContainer: const Color(0xFFFFDAD3),
  error: const Color(0xFFFFB4AB),
  onError: const Color(0xFF690005),
  errorContainer: const Color(0xFF93000A),
  onErrorContainer: const Color(0xFFFFDAD6),
  surface: const Color(0xFF1C1A30),
  onSurface: const Color(0xFFF2F0E6),
  onSurfaceVariant: const Color(0xFFC8C4DC),
  surfaceDim: const Color(0xFF15132A),
  surfaceBright: const Color(0xFF3A3760),
  surfaceContainerLowest: const Color(0xFF15132A),
  surfaceContainerLow: const Color(0xFF2B2848),
  surfaceContainer: const Color(0xFF26233F),
  surfaceContainerHigh: const Color(0xFF38355A),
  surfaceContainerHighest: const Color(0xFF4A4570),
  outline: const Color(0xFF8E89B0),
  outlineVariant: const Color(0xFF4A4570),
  shadow: Colors.black,
  scrim: Colors.black,
  inverseSurface: const Color(0xFFF2F0E6),
  onInverseSurface: const Color(0xFF1C1A30),
  inversePrimary: colorblindSafe
      ? const Color(0xFF005A8C)
      : const Color(0xFF2B6E24),
  surfaceTint: Colors.transparent,
);
