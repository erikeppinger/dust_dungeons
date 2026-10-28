import 'package:flutter/material.dart';

import '../models/app_settings.dart';
import '../db/app_database.dart';

/// Persists [AppSettings] in the key/value settings table.
class SettingsRepository {
  SettingsRepository(this._db);

  final AppDatabase _db;

  static const _themeMode = 'themeMode';
  static const _colorblindSafe = 'colorblindSafe';
  static const _locale = 'locale';

  Future<AppSettings> load() async {
    final rows = await _db.select(_db.settings).get();
    final map = {for (final r in rows) r.key: r.value};
    final languageCode = map[_locale];
    return AppSettings(
      themeMode: ThemeMode.values.firstWhere(
        (m) => m.name == map[_themeMode],
        orElse: () => ThemeMode.system,
      ),
      colorblindSafe: map[_colorblindSafe] == 'true',
      locale: languageCode == null ? null : Locale(languageCode),
    );
  }

  Future<void> save(AppSettings settings) => _db.transaction(() async {
    await _put(_themeMode, settings.themeMode.name);
    await _put(_colorblindSafe, settings.colorblindSafe.toString());
    final locale = settings.locale;
    if (locale == null) {
      await (_db.delete(
        _db.settings,
      )..where((s) => s.key.equals(_locale))).go();
    } else {
      await _put(_locale, locale.languageCode);
    }
  });

  Future<void> _put(String key, String value) => _db
      .into(_db.settings)
      .insertOnConflictUpdate(SettingsCompanion.insert(key: key, value: value));
}
