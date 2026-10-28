# Homework & Chores *(working title)*

A gamified household chores app. Do chores, earn points, and spend them on goals that add up to a bigger
progression. The genre is still to be decided.

**Local only.** No account, no server, no network, no telemetry, no ads. All data stays on your device.

> Status: early development (`0.0.x`). Android first.

## Planned features
- Built-in chores (dusting, sweeping, dishes, laundry …) plus your own
- Daily / weekly / monthly / custom repeats, with a week and month overview
- Points, XP, streaks and goals
- Reminders and weekly/monthly summaries (local notifications)
- Colorful chore icons with a colorblind-safe palette
- Light / dark mode, German and English

See [docs/DEV_PLAN.md](docs/DEV_PLAN.md) for the full plan and roadmap, and [CHANGELOG.md](CHANGELOG.md) for what has changed.

## Building

Requires Flutter (stable, 3.47+) and the Android SDK.

```bash
flutter pub get
flutter test
flutter build apk --release
```

### Working inside Dropbox
Generated folders (`build/`, `.dart_tool/`, Gradle caches …) must live outside Dropbox: Dropbox placeholder files
break Gradle builds. The script moves them to `%LOCALAPPDATA%` and leaves ignored junctions in their place.
After cloning, and after every `flutter clean`, run:

```powershell
powershell -ExecutionPolicy Bypass -File tool\dropbox_ignore.ps1
```

## Versioning
[Semantic Versioning](https://semver.org) as `MAJOR.MINOR.PATCH+BUILD` in `pubspec.yaml`. Bump with
`tool\bump_version.ps1 -Part patch|minor|major|build`.

## License
[GPL-3.0](LICENSE). Asset licenses are listed in [ASSETS_LICENSES.md](ASSETS_LICENSES.md).
