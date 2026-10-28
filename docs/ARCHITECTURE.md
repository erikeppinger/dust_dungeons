# Architecture

```
lib/
├─ main.dart             entry point (ProviderScope)
├─ app/                  MaterialApp, navigation shell, theme
│  └─ theme/             Material 3 theme + ChorePalette (vibrant / Okabe-Ito)
├─ core/                 shared widgets, day clock (midnight/resume aware)
├─ data/
│  ├─ db/                Drift tables + AppDatabase (schema version, migrations, seeding)
│  ├─ models/            plain data classes (AppSettings)
│  ├─ repositories/      chores, progress (completions + point ledger), settings
│  └─ providers.dart     Riverpod providers wiring database → repositories → UI streams
├─ domain/               pure Dart: dates, recurrence engine, points & bonuses, streaks & levels, chore catalog
├─ features/<feature>/   screens + Riverpod controllers per feature
└─ l10n/                 ARB source files (generated Dart files are git-ignored)
```

## Principles
- **`domain/` is pure Dart** with no Flutter imports, so it can be unit-tested in isolation.
- **State:** Riverpod `Notifier`s per feature, and widgets only read providers.
- **Persistence:** local SQLite via Drift. Points are an append-only ledger: undo marks the completion `undoneAt` and books a negative entry instead of deleting anything. "Due" dates (0.2) will be computed rather than stored.
- **Layering:** `features` → `data` → `domain`. `data` never imports `features`.
- **Built-in chores** are identified by a stable `seedKey` and get localized titles. Missing ones are inserted on every start (`insertOrIgnore`), so new built-ins arrive with updates without touching user edits.
- **Schedules:** `Recurrence` (domain) computes due dates. Fixed schedules split time into cycles that start at each occurrence, and one completion covers its cycle. "N days after last done" floats with the last completion. Nothing about "due" is stored: it is derived from the schedule, the last completion and today (`ScheduledChore`).
- **Points:** `pointsFor()` (domain) is the single rule. The repository applies it when a chore is completed, and the Today tiles use it to preview. The awarded total is stored per completion, and undo books exactly that back. XP is the sum of all awarded points, so spending (0.5) will not lower the level.
- **Schema changes:** bump `schemaVersion` in `app_database.dart`, add a migration step, run `dart run build_runner build`, dump the new schema (`dart run drift_dev schema dump lib/data/db/app_database.dart drift_schemas/`), regenerate test helpers (`dart run drift_dev schema generate drift_schemas/ test/data/generated_migrations/`) and extend `test/data/migration_test.dart`. Generated files and schema dumps are committed.
- **Theming:** chore colors come from the `ChorePalette` theme extension, never hard-coded colors.
- **Localization:** `AppLocalizations.of(context)`, generated from `lib/l10n/*.arb` on `flutter pub get`.
- **Privacy:** the main `AndroidManifest.xml` removes `INTERNET` from all merged manifests.
