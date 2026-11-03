# Dust & Dungeons

A household chores app that is also a small pixel-art adventure. Chores are quests: doing them earns
points, XP and fight tokens. Spend tokens on rhythm duels against household bosses, collect their loot,
and dress your hero in the gear you win or buy.

> The app still shows its working title, *Homework & Chores*. The rename to Dust & Dungeons comes with
> the beta (0.14.0), see [the beta plan](docs/design/beta.md).

**Local only.** No account, no server, no network, no telemetry, no ads. All data stays on your device.

> Status: 0.13.0, before the beta. Android first. Source: <https://github.com/erikeppinger/dust_dungeons>

## Features
- **Quests:** 21 built-in chores plus your own, with flexible schedules (daily, weekly, monthly,
  monthly on a weekday, every N days after the last time, day ranges, times of day)
- **Progress:** points with on-time bonuses, XP and levels, streaks, a quest log by week and month
- **Several people on one phone:** chores for anyone, one person or each person, and a weekly
  leaderboard
- **Boss fights:** eight household bosses fed by their chores, plus a weekly Chore Overlord. Each is a
  rhythm duel: the boss plays a rhythm, you tap it back. A start button before every round, a timeline
  with a playhead, story mode, slow mode, Easy / Balanced / Hard and timing calibration
- **Loot and gear:** six gear slots, an Armory, boss loot, consumables and mild curses. The hero wears
  what it has on
- **A weekly quest map** that grows into your realm in the Hall of Fame
- **Screen time** (optional): chores earn screen-time minutes
- **Reminders and summaries** as local notifications, and three home screen widgets
- **Backups:** export, import that merges, and daily automatic backups to a folder you choose
- **16-bit look:** pixel art throughout, day and night themes, a colorblind-safe palette, German and
  English, and screen reader and large-font support

See [CHANGELOG.md](CHANGELOG.md) for what has changed and [docs/DEV_PLAN.md](docs/DEV_PLAN.md) for the
plan and roadmap.

## Test builds
Test APKs for Android are on the [releases page](https://github.com/erikeppinger/dust_dungeons/releases)
(from version tags) and under [Actions](https://github.com/erikeppinger/dust_dungeons/actions)
(from every push, for 30 days). Download the APK on the phone and open it. There is no iPhone
version yet.

## Building

Requires Flutter (stable, 3.47+), the Android SDK, and Python 3.11+ with Pillow (`pip install pillow`).
The tests run the art and game data checks, which are Python.

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

## Contributing
- **Code:** [CONTRIBUTING.md](CONTRIBUTING.md) and [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
- **Items, bosses, quests and balance:** [game/README.md](game/README.md), with no Dart needed
- **Art:** [docs/ART_GUIDE.md](docs/ART_GUIDE.md)

## Credits
- **Idea for the app:** Daniele Pasquale Funaro
- Art and sounds: see [ASSETS_LICENSES.md](ASSETS_LICENSES.md) and [assets/art/CREDITS.md](assets/art/CREDITS.md)

## Versioning
[Semantic Versioning](https://semver.org) as `MAJOR.MINOR.PATCH+BUILD` in `pubspec.yaml`. Bump with
`tool\bump_version.ps1 -Part patch|minor|major|build`.

## License
[GPL-3.0](LICENSE). Asset licenses are listed in [ASSETS_LICENSES.md](ASSETS_LICENSES.md).
