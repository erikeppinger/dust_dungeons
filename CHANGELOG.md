# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
Build numbers (`+N` in `pubspec.yaml`) increase with every release build.

## [Unreleased]

## [0.7.0] - 2026-10-29
### Added
- **Soft screen-time budget** (Settings → Screen time, off by default):
  - A daily budget for the apps you choose. Quests earn 1 minute per 5 points (with a daily cap), and the
    Armory sells +15 and +30 minute vouchers.
  - A bar on the Quests tab, and a page with today's breakdown, use per app and the last 7 days.
  - Reminders, never blocking: a warning at 10 minutes left, a notification when used up (checked about
    every 15 minutes), and yesterday's result in the daily summary.
  - Tired: after a day over budget, the hero starts fights with one heart less.
  - Uses Android's usage access; only daily totals of the chosen apps are kept, on the device.
- Database schema v6 (daily screen-time totals) with tested migrations.

## [0.6.1] - 2026-10-28
### Added
- **A new quest map every week.** The map is generated from the week number, so it stays the same Monday
  to Sunday and changes when the Overlord's week resets. Any past week can be redrawn exactly as it was.
  - Lakes, forests, hills, mountains and dunes move around.
  - The camp, the five lairs and the castle are placed fresh each week.
  - The road finds its way around water and mountains, crossing on bridges where it must.
- **Your realm (Hall of Fame):** every week since your first chore, joined into one world.
  - Each week is a window onto the same endless land: lakes and forests run on across the seams, each
    castle's road leads on to the next week's camp, and the ground blends where the season changes.
  - Month: a strip of weeks to scroll through, starting at this week, with your hero and the bosses you beat.
  - Year: all weeks small, four to a row. Tap one to open it in the strip.
  - Counts weeks explored, Crowns of the Week and lairs cleared, all from the fight history the app already
    stores.
- **Seasonal looks:** snow from December to February, autumn colors from September to November, and meadow
  for the rest of the year. About one week in five turns into a desert instead.

## [0.6.0] - 2026-10-28
### Changed
- **Game-themed names, like a pen-and-paper adventure:**
  - Tabs: Quests, Quest Log, Arena, Hall of Fame (Settings stays). In German: Quests, Questbuch, Arena,
    Ruhmeshalle.
  - Quest sections: Today's quests, Overdue quests, Side quests, Completed today.
  - In the Arena: Boss of the Week, The Lair, Hall of Trophies, Armory (shop) and Wardrobe (customize).
- German texts now consistently say "Kampfmarke"/"Marke" for fight tokens.

### Added
- **Quest map:** the Boss of the Week card shows the week's road to the Overlord as a 16-bit style
  overworld: grass, forests, hills, lakes and desert, all drawn pixel by pixel in code.
  - Fog hides what lies ahead. Each win clears the way to the next lair and shows the boss you beat there.
  - The Overlord's castle appears with the fifth win, and its banner turns green once it's beaten.
  - Your hero walks the road as a small sprite in your Wardrobe colors and hat.
  - TalkBack reads it as "3 of 5 wins this week".
- **Introduction on first start:** welcome with language choice and the privacy promise, pick the chores
  that apply (unticked ones are archived), then the colorblind palette and reminders. Skippable, and it can
  be shown again under Settings → About. Installs that already have history skip it.
- Points count up when they change (instantly with the system's "remove animations"), and completing a
  chore gives a short vibration.
- TalkBack reads each chore tile as one item ("Dusting, due today, 17 points") with a hint that
  long-press edits it.
- An automated accessibility audit covers 15 screens, checking:
  - Android tap-target size, labeled buttons and text contrast, in light and dark mode with both palettes
  - layout at 200 % font size in English and German

### Fixed
- Boss cards on the World tab overflowed on phones about 390 dp wide. Each pair of cards now grows with
  its content.
- The repeat and boss menus in the chore editor ran off the screen.
- Chore tiles, the points header and the level card overflowed with large system fonts.
- Color swatches in the editor are now 48 dp tap targets.

## [0.5.2] - 2026-10-28
### Added
- **Weekly Chore Overlord:** appears after 5 won boss fights in a week (Mon–Sun) and stays until beaten or
  the week ends. Its fights need no token.
  - Phases 1 and 2 are echo phases that borrow the rhythms of the bosses you beat that week.
  - Phase 3 is a new lane phase: notes fall down three lanes, each with its own shape.
  - Beating it gives the Crown of the Week.
- **Timing calibration** (Boss fights settings): tap along to 8 beats. The measured delay is taken off
  every tap, so Bluetooth headphones or a slow screen don't spoil the timing.
- **Slow mode:** fights play at 70 % tempo.

### Fixed
- "Fight again" kept the boss but dropped your gear.

## [0.5.1] - 2026-10-28
### Added
- **All eight bosses are playable:** Laundry Hydra, Sink Kraken, Porcelain Golem, Trash Titan, Pillow
  Phantom and Window Wraith join Dust Bunny King and Clutter Imp, each with its own silhouette and rhythm.
- **Boss picker in the chore editor:** choose which boss a chore's tokens are for (built-in chores keep
  their default unless changed).
- **Shop (World → Shop):** spend points. Spending never lowers level or XP.
  - Gear, always active once bought: Sponge Shield (first miss each fight costs no heart), Turbo Mop
    (perfect hits clean 50% more), Metronome Charm (more forgiving timing), Rubber Gloves (+1 heart).
  - Second Wind: continue once after losing a fight.
  - Hats for the hero (cap, bandana, wizard hat, crown), worn via Customize; locked ones link to the shop.
- The hero card shows hearts including gear; a ready Sponge Shield is shown during fights.
- Database schema v5 (shop inventory) with tested migrations from v1–v4.

## [0.5.0] - 2026-10-28
### Added
- **Boss fights (World tab).** Every completed chore earns a fight token for its boss family. Fights are
  optional and can be played any time.
  - The echo duel: the boss plays a rhythm, and you tap it back on a big pad after a count-in click.
    Perfect (±60 ms), Good (±120 ms) and Miss are shown with shapes and text, not only color. Two phases
    per boss, with longer patterns in the second.
  - Two playable bosses: **Dust Bunny King** (dusting, floors) and **Clutter Imp** (your own chores). The
    six other bosses already collect tokens and arrive in 0.5.1.
  - Boss tiers rise with your wins; your level makes the hero a little stronger.
  - Winning gives trophies (shown on the trophy shelf with wins and best accuracy), never points.
  - Story mode (can't lose, wider timing), sound and vibration, all on the new "Boss fights" settings page.
    Sound and vibration are on by default.
  - Leaving a fight asks first and pauses it meanwhile. Leaving, or the app going to the background, uses
    up the token. A double tap can't start two fights.
- **Customizable hero:** skin, hair and cape colors (more items come with the shop).
- Database schema v4 (fight history, boss family per chore) with tested migrations from v1–v3. Past
  completions count as tokens.
- Fight sounds generated by our own script (`tool/generate_sounds.py`), no third-party audio.

### Removed
- The "coming soon" placeholder screen (every tab is real now).

## [0.4.1] - 2026-10-28
### Changed
- Settings is now an overview with one entry per category (Manage chores, Appearance, Notifications,
  Language, About). Each entry shows the current state and opens its own page.

### Added
- The About page shows the installed app version (via `package_info_plus`, which only reads it locally).

### Fixed
- Settings page titles follow a language change made on the page itself.

## [0.4.0] - 2026-10-28
### Added
- Local notifications (off by default; turning them on asks for Android's permission):
  - Daily summary at a chosen time: how many chores are due and which ones, overdue first.
  - Per-chore reminders on due days at a time set in the chore editor (and daily while overdue).
  - Weekly recap (Sundays 18:00) and monthly recap (1st, 10:00) of chores done and points earned.
  - "Send a test notification" in Settings. Tapping a notification opens Today, or Stats for recaps.
- Notifications are planned a week ahead and rebuilt after every change. They survive reboots and
  app updates, use inexact timing (no exact-alarm permission) and never use the network.
- Database schema v3 (per-chore reminder time) with tested migrations from v1 and v2.

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
[0.7.0]: #
[0.6.1]: #
[0.6.0]: #
[0.5.2]: #
[0.5.1]: #
[0.5.0]: #
[0.4.1]: #
[0.4.0]: #
[0.3.0]: #
[0.2.0]: #
[0.1.0]: #
[0.0.1]: #
