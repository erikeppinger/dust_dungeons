# Architecture

```
lib/
├─ main.dart             entry point (ProviderScope)
├─ app/                  MaterialApp, navigation shell, theme
│  └─ theme/             Material 3 theme + ChorePalette (vibrant / Okabe-Ito)
├─ core/                 shared widgets and helpers
├─ data/                 (0.1+) Drift database, tables, migrations, repositories
├─ domain/               (0.1+) pure Dart: models, points engine, recurrence engine
├─ features/<feature>/   screens + Riverpod controllers per feature
└─ l10n/                 ARB source files (generated Dart files are git-ignored)
```

## Principles
- **`domain/` is pure Dart** with no Flutter imports, so it can be unit-tested in isolation.
- **State:** Riverpod `Notifier`s per feature, and widgets only read providers.
- **Persistence:** local SQLite via Drift (from 0.1.0). Points are an append-only ledger, and "due" dates are computed rather than stored.
- **Theming:** chore colors come from the `ChorePalette` theme extension, never hard-coded colors.
- **Localization:** `AppLocalizations.of(context)`, generated from `lib/l10n/*.arb` on `flutter pub get`.
- **Privacy:** the main `AndroidManifest.xml` removes `INTERNET` from all merged manifests.
