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
- **Notifications:** `planNotifications()` is pure: given chores, completions, settings and "now", it returns every notification for the next 7 days, fully worded. `notificationPlanProvider` rebuilds the plan on any change, and `syncNotifications()` applies it through `NotificationService` (one update at a time, newest wins). The platform plugin sits behind that interface, so tests use a fake.
- **Boss fights:** `lib/domain/fight/` holds the rules (families, patterns, judging, health) as pure Dart. `FightProgress` derives tokens, wins and tiers from completions and the `Fights` table, like the point ledger. `FightController` runs a duel in real time on `clock` and timers, and screens only render it. Sounds sit behind `FightSounds` (silent in tests).
- **Shop:** `lib/domain/fight/shop.dart` is the catalog. `ShopRepository.buy` checks the balance, books a `spend` ledger entry and updates `Inventory` in one transaction. XP is derived from completions, so spending never lowers it. Gear becomes a `Loadout` handed to the duel when a fight starts.
- **Weekly Overlord:** a ninth `BossFamily` value fed by no chore (`choreFamilies` lists the others). `FightProgress` derives weekly wins from the fight history. `OverlordDuel` extends `EchoDuel` with a lane phase driven by `FightController`.
- **Accessibility audit:** `test/accessibility_test.dart` runs Flutter's tap-target, label and contrast guidelines on every main screen (light/dark, both palettes) and lays them out at 200 % font size in English and German. New screens should be added there.
- **Onboarding:** `AppSettings.onboardingDone` picks the home route. `SettingsRepository.load` treats a missing flag as done when completions exist (installs from before 0.6).
- **Schema changes:** bump `schemaVersion` in `app_database.dart`, add a migration step, run `dart run build_runner build`, dump the new schema (`dart run drift_dev schema dump lib/data/db/app_database.dart drift_schemas/`), regenerate test helpers (`dart run drift_dev schema generate drift_schemas/ test/data/generated_migrations/`) and extend `test/data/migration_test.dart`. Generated files and schema dumps are committed.
- **Theming:** chore colors come from the `ChorePalette` theme extension, never hard-coded colors.
- **Localization:** `AppLocalizations.of(context)`, generated from `lib/l10n/*.arb` on `flutter pub get`.
- **Privacy:** the main `AndroidManifest.xml` removes `INTERNET` from all merged manifests.
