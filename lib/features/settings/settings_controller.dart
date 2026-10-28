import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/app_settings.dart';
import '../../data/providers.dart';

export '../../data/models/app_settings.dart';

/// Settings loaded from the database before the first frame (see `main.dart`).
final initialSettingsProvider = Provider<AppSettings>(
  (ref) => const AppSettings(),
);

class SettingsController extends Notifier<AppSettings> {
  @override
  AppSettings build() => ref.read(initialSettingsProvider);

  void setThemeMode(ThemeMode mode) => _set(state.copyWith(themeMode: mode));

  void setColorblindSafe(bool value) =>
      _set(state.copyWith(colorblindSafe: value));

  void setLocale(Locale? locale) => _set(state.copyWith(locale: () => locale));

  /// Applies any change, e.g. `update((s) => s.copyWith(weeklyRecap: false))`.
  void update(AppSettings Function(AppSettings) change) => _set(change(state));

  void _set(AppSettings settings) {
    state = settings;
    // The UI updates immediately; a failed write is reported, not swallowed.
    unawaited(
      ref
          .read(settingsRepositoryProvider)
          .save(settings)
          .catchError(
            (Object error, StackTrace stack) => FlutterError.reportError(
              FlutterErrorDetails(exception: error, stack: stack),
            ),
          ),
    );
  }
}

final settingsProvider = NotifierProvider<SettingsController, AppSettings>(
  SettingsController.new,
);
