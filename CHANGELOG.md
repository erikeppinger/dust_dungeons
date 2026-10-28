# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
Build numbers (`+N` in `pubspec.yaml`) increase with every release build.

## [Unreleased]

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
[0.0.1]: #
