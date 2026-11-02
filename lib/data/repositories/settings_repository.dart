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
  static const _fightSound = 'fightSound';
  static const _fightHaptics = 'fightHaptics';
  static const _fightLatencyMs = 'fightLatencyMs';
  static const _onboardingDone = 'onboardingDone';
  static const _screenTime = 'screenTime';
  static const _screenBaseMinutes = 'screenBaseMinutes';
  static const _screenEarnCap = 'screenEarnCap';
  static const _screenApps = 'screenApps';
  static const _screenWarn = 'screenWarn';
  static const _screenOver = 'screenOver';
  static const _screenSummary = 'screenSummary';
  static const _curses = 'curses';

  Future<AppSettings> load() async {
    final rows = await _db.select(_db.settings).get();
    final map = {for (final r in rows) r.key: r.value};
    const defaults = AppSettings();
    bool flag(String key, bool fallback) =>
        map[key] == null ? fallback : map[key] == 'true';
    final languageCode = map[_locale];
    // Installs from before the introduction existed skip it once they have
    // completed a chore.
    final onboardingDone = map[_onboardingDone] == null
        ? await (_db.select(_db.completions)..limit(1)).getSingleOrNull() !=
              null
        : map[_onboardingDone] == 'true';
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
      fightSound: flag(_fightSound, defaults.fightSound),
      fightHaptics: flag(_fightHaptics, defaults.fightHaptics),
      fightLatencyMs:
          int.tryParse(map[_fightLatencyMs] ?? '') ?? defaults.fightLatencyMs,
      onboardingDone: onboardingDone,
      screenTime: flag(_screenTime, defaults.screenTime),
      screenBaseMinutes:
          int.tryParse(map[_screenBaseMinutes] ?? '') ??
          defaults.screenBaseMinutes,
      screenEarnCap:
          int.tryParse(map[_screenEarnCap] ?? '') ?? defaults.screenEarnCap,
      screenApps: (map[_screenApps] ?? '')
          .split('\n')
          .where((p) => p.isNotEmpty)
          .toList(),
      screenWarn: flag(_screenWarn, defaults.screenWarn),
      screenOver: flag(_screenOver, defaults.screenOver),
      screenSummary: flag(_screenSummary, defaults.screenSummary),
      curses: flag(_curses, defaults.curses),
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
    await _put(_fightSound, '${settings.fightSound}');
    await _put(_fightHaptics, '${settings.fightHaptics}');
    await _put(_fightLatencyMs, '${settings.fightLatencyMs}');
    await _put(_onboardingDone, '${settings.onboardingDone}');
    await _put(_screenTime, '${settings.screenTime}');
    await _put(_screenBaseMinutes, '${settings.screenBaseMinutes}');
    await _put(_screenEarnCap, '${settings.screenEarnCap}');
    await _put(_screenApps, settings.screenApps.join('\n'));
    await _put(_screenWarn, '${settings.screenWarn}');
    await _put(_screenOver, '${settings.screenOver}');
    await _put(_screenSummary, '${settings.screenSummary}');
    await _put(_curses, '${settings.curses}');
  });

  Future<void> _put(String key, String value) => _db
      .into(_db.settings)
      .insertOnConflictUpdate(SettingsCompanion.insert(key: key, value: value));
}
