import 'package:flutter/material.dart';

import '../db/app_database.dart';
import '../models/app_settings.dart';

/// Persists [AppSettings] in the key/value settings table.
class SettingsRepository {
  SettingsRepository(this._db);

  final AppDatabase _db;

  static const _themeMode = 'themeMode';
  static const _colorblindSafe = 'colorblindSafe';
  static const _locale = 'locale';
  static const _notificationsEnabled = 'notificationsEnabled';
  static const _dailySummary = 'dailySummary';
  static const _dailySummaryMinutes = 'dailySummaryMinutes';
  static const _choreReminders = 'choreReminders';
  static const _weeklyRecap = 'weeklyRecap';
  static const _monthlyRecap = 'monthlyRecap';

  Future<AppSettings> load() async {
    final rows = await _db.select(_db.settings).get();
    final map = {for (final r in rows) r.key: r.value};
    const defaults = AppSettings();
    bool flag(String key, bool fallback) =>
        map[key] == null ? fallback : map[key] == 'true';
    final languageCode = map[_locale];
    return AppSettings(
      themeMode: ThemeMode.values.firstWhere(
        (m) => m.name == map[_themeMode],
        orElse: () => defaults.themeMode,
      ),
      colorblindSafe: flag(_colorblindSafe, defaults.colorblindSafe),
      locale: languageCode == null ? null : Locale(languageCode),
      notificationsEnabled: flag(
        _notificationsEnabled,
        defaults.notificationsEnabled,
      ),
      dailySummary: flag(_dailySummary, defaults.dailySummary),
      dailySummaryMinutes:
          int.tryParse(map[_dailySummaryMinutes] ?? '') ??
          defaults.dailySummaryMinutes,
      choreReminders: flag(_choreReminders, defaults.choreReminders),
      weeklyRecap: flag(_weeklyRecap, defaults.weeklyRecap),
      monthlyRecap: flag(_monthlyRecap, defaults.monthlyRecap),
    );
  }

  Future<void> save(AppSettings settings) => _db.transaction(() async {
    await _put(_themeMode, settings.themeMode.name);
    await _put(_colorblindSafe, '${settings.colorblindSafe}');
    final locale = settings.locale;
    if (locale == null) {
      await (_db.delete(
        _db.settings,
      )..where((s) => s.key.equals(_locale))).go();
    } else {
      await _put(_locale, locale.languageCode);
    }
    await _put(_notificationsEnabled, '${settings.notificationsEnabled}');
    await _put(_dailySummary, '${settings.dailySummary}');
    await _put(_dailySummaryMinutes, '${settings.dailySummaryMinutes}');
    await _put(_choreReminders, '${settings.choreReminders}');
    await _put(_weeklyRecap, '${settings.weeklyRecap}');
    await _put(_monthlyRecap, '${settings.monthlyRecap}');
  });

  Future<void> _put(String key, String value) => _db
      .into(_db.settings)
      .insertOnConflictUpdate(SettingsCompanion.insert(key: key, value: value));
}
