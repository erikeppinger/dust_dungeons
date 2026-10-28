# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
Build numbers (`+N` in `pubspec.yaml`) increase with every release build.

## [Unreleased]

## [0.3.0] - 2026-10-28
### Added
- Point bonuses: +10% for doing a scheduled chore on its due day, +2% per streak day (up to +20%).
  Tiles show the points you would get now, including the bonus.
- XP and levels (each level needs 100 XP more than the last); level and streak chips on Today;
  a "Level N reached!" message on level-up.
- Day streaks: current and best; a streak survives until a whole day passes without chores.
- Stats tab: level progress, streaks, chores done, points today / 7 days / 30 days / all time,
  a 7-day bar chart, the most done chores of the last 30 days and how points work.

### Fixed
- The Undo snackbar stayed on screen until dismissed; it now disappears after 5 seconds.
- Intermittent release build failures inside Dropbox: generated folders now live outside Dropbox
  behind junctions (`tool/dropbox_ignore.ps1`).
- A quick double tap can no longer complete a second chore that moves under your finger
  (the tap guard now applies to all tiles, not per chore).

## [0.2.0] - 2026-10-28
### Added
- Schedules for chores: once, every N days, weekly on chosen weekdays (every N weeks), monthly on a day
  (clamped to short months), N days after last done, or no schedule. Edited in the chore editor.
- Built-in chores come with sensible default rhythms, staggered so not everything is due on day one.
- Today screen sections: Overdue, Due today, Done today, Later & anytime, with a due/overdue line on every tile.
- Plan tab: week list (today + 6 days) and month calendar with done/due counts per day; tap a day for details.
- "Manage chores" shows each chore's schedule.
- Database schema v2 with a tested migration from 0.1 (existing chores, history and points are kept).

## [0.1.0] - 2026-10-28
### Added
- Local SQLite database (Drift) with profiles, chores, completions, a point ledger and settings.
- 21 built-in chores (de/en) with colorful icons; new built-ins are added automatically on updates.
- Today screen: chore grid with point balance; tap to complete (double taps count once), snackbar with **Undo**, ✓ "done today" badge.
- Add, edit and archive/restore chores (name, icon, color, points), and a "Manage chores" screen in Settings.
- Settings (theme, colorblind palette, language) are now saved.
- Error message instead of a blank screen if the database cannot be opened.
- Chore names support umlauts, ß, accents, other scripts and emoji (tested in the database and on device).
- Calm glow at scroll edges instead of Android's stretch effect, which distorted text.
- Database, catalog and widget tests; on-device integration test covers the new flows.

## [0.0.1] - 2026-10-28
### Added
- Flutter project for Android with placeholder application ID `io.github.changeme.homework_and_chores`.
- App shell with bottom navigation: Today, Plan, World, Stats, Settings (placeholder screens).
- Light, dark and system theme modes (Material 3), edge-to-edge so the system bars follow the theme.
- Chore color palettes: vibrant default and colorblind-safe Okabe-Ito, switchable in Settings.
- German and English localization (ARB files) with an in-app language override.
- Settings screen (theme, colorblind palette, language, privacy/license info). Settings are not saved yet.
- Release manifest strips the `INTERNET` permission, including from any library.
- Strict analyzer and lint rules.
- Widget tests for navigation, localization, theme and palette switching.
- On-device integration test (`integration_test/`), required to pass on the emulator before every commit.
- `tool/dropbox_ignore.ps1` to keep build folders out of Dropbox sync.
- `tool/bump_version.ps1` to bump the version and roll the changelog.
- Project docs: README, GPL-3.0 LICENSE, PRIVACY, ASSETS_LICENSES, CONTRIBUTING, docs/DEV_PLAN.md, docs/ARCHITECTURE.md.

[Unreleased]: #
[0.3.0]: #
[0.2.0]: #
[0.1.0]: #
[0.0.1]: #
