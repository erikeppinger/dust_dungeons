# Contributing

## Requirements
Flutter (stable, 3.47+), the Android SDK, and Python 3.11+ with Pillow (`pip install pillow`).
`flutter test` runs the art and game data checks, which are Python.

## Ground rules
- **No network, no tracking.** Do not add dependencies that use the internet, collect analytics or need Google Play Services.
- **Every UI string** goes into both `lib/l10n/app_en.arb` and `lib/l10n/app_de.arb`.
- **Color is never the only signal.** Pair it with an icon and/or text, and check light, dark and colorblind modes.
- **Update `CHANGELOG.md`** under `[Unreleased]` with every change.

## Game data
Items, bosses, built-in quests and balance numbers are data, not code: see
[`game/README.md`](game/README.md). After changing them, run `python tool/build_game_data.py`.
It checks them and regenerates `lib/game/` and the game's texts in the ARB files. Don't edit
those generated parts by hand.

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
in light and dark mode. Check the installed `versionName`, because a failed build silently leaves the old APK in place.

**Notification changes** need a check with real notifications on the device: tests use a fake service, so they cannot
catch platform problems. Two bugs were caught this way in 0.4.0: the release build stripped the icon, and the
emulator's "GMT" time zone was unknown. Use *Settings → Send a test notification*, and set the daily summary a few
minutes ahead to see a scheduled one fire (`adb shell dumpsys alarm` shows what is pending).

## Commit messages
[Conventional Commits](https://www.conventionalcommits.org): `feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`.

## Art
Pixel art lives in `assets/art` as PNG files with palettes and follows the [art guide](docs/ART_GUIDE.md):
sizes, palettes, drawing rules and licensing. After changing art, regenerate and commit
`lib/app/art/art_data.dart` (needs Python with Pillow):

```bash
python tool/build_art.py
```

How it works is described in [docs/design/art-assets.md](docs/design/art-assets.md).

## Code layout
See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).
