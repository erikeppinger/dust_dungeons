import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// User-facing app settings.
///
/// Held in memory for now; persisted in the local database from 0.1.0.
@immutable
class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.colorblindSafe = false,
    this.locale,
  });

  final ThemeMode themeMode;
  final bool colorblindSafe;

  /// `null` follows the device language.
  final Locale? locale;

  AppSettings copyWith({
    ThemeMode? themeMode,
    bool? colorblindSafe,
    Locale? Function()? locale,
  }) => AppSettings(
    themeMode: themeMode ?? this.themeMode,
    colorblindSafe: colorblindSafe ?? this.colorblindSafe,
    locale: locale != null ? locale() : this.locale,
  );
}

class SettingsController extends Notifier<AppSettings> {
  @override
  AppSettings build() => const AppSettings();

  void setThemeMode(ThemeMode mode) => state = state.copyWith(themeMode: mode);

  void setColorblindSafe(bool value) =>
      state = state.copyWith(colorblindSafe: value);

  void setLocale(Locale? locale) =>
      state = state.copyWith(locale: () => locale);
}

final settingsProvider = NotifierProvider<SettingsController, AppSettings>(
  SettingsController.new,
);
