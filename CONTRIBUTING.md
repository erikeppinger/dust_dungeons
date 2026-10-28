# Contributing

## Ground rules
- **No network, no tracking.** Do not add dependencies that use the internet, collect analytics or need Google Play Services.
- **Every UI string** goes into both `lib/l10n/app_en.arb` and `lib/l10n/app_de.arb`.
- **Color is never the only signal.** Pair it with an icon and/or text, and check light, dark and colorblind modes.
- **Update `CHANGELOG.md`** under `[Unreleased]` with every change.

## Generated code
After changing Drift tables or queries, regenerate and commit `*.g.dart`:

```bash
dart run build_runner build
```

For a **schema change**, also bump `schemaVersion`, write the migration step, and then:

```bash
dart run drift_dev schema dump lib/data/db/app_database.dart drift_schemas/
dart run drift_dev schema generate drift_schemas/ test/data/generated_migrations/
```

Then add a case to `test/data/migration_test.dart` that upgrades real old data.

## Before committing
Nothing gets committed until the app has run on an Android emulator or device **and** the changes have been reviewed for bugs, open loops and loose ends (unfinished code paths, TODOs, unused strings or dependencies, docs or changelog out of date).

```bash
dart format lib test integration_test
flutter analyze
flutter test
flutter emulators --launch test_avd
flutter test integration_test -d emulator-5554
flutter build apk --release
```

Then install the APK (`adb install -r build/app/outputs/flutter-apk/app-release.apk`) and check the changed screens by hand
in light and dark mode.

## Commit messages
[Conventional Commits](https://www.conventionalcommits.org): `feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`.

## Code layout
See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).
