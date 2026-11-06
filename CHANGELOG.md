# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
Build numbers (`+N` in `pubspec.yaml`) increase with every release build.

## [Unreleased]

## [0.14.0] - 2026-11-06
From the testers ([design](docs/design/round-rules.md)).

### Changed
- **Rounds instead of single misses:** a round (one echo) has an accuracy (Perfect 1, Good ½,
  Miss 0; stray taps count as misses).
  - At 50 % or more it lands: its hits damage the boss, and no heart is lost, even with misses.
  - Under 50 % it fails: no damage, and exactly one heart is lost, however many misses.
  - This applies to the eight bosses and the Overlord's echo phases. The lane phase stays note
    by note.
  - Story mode: every hit still counts, and no hearts are lost.
- The judgement line adds the round's accuracy and the outcome ("62 % hit" / "25 % failed").
  A failed round's track is dashed, and the boss and hero react to the round's outcome.
- **Sponge Shield, Trash-Can Lid and Garden Gnome** protect failed rounds instead of misses (in
  the lane phase, missed notes). Their descriptions say so.
- **Fuzzy Slippers:** the sneak attack waits for the first round that lands.
- The 50 % line is `rounds.hit_percent` in `game/balance.toml`.
- Roadmap: the beta moves to 0.15.0.

## [0.13.2] - 2026-11-03
The app is unchanged.

### Fixed
- Test APKs from GitHub are signed with the shared test key, so they install over earlier test
  versions. 0.13.1's APK was signed with GitHub's own key: Gradle on the build machine didn't use the
  key file it was given. The build now names the key file directly (`TEST_KEYSTORE`) and fails if the
  APK has any other key.
- CI uses the current versions of GitHub's actions (checkout, setup-java, setup-python,
  upload-artifact).

## [0.13.1] - 2026-11-03
The app is unchanged from 0.13.0; this is the first test release published on GitHub.

### Added
- **CI on GitHub** (`.github/workflows/build.yml`): every push is formatted, analyzed and tested,
  and builds a test APK (an Actions artifact, kept 30 days). It also checks that the APK requests no
  internet permission. A `v*` tag publishes the APK as a GitHub pre-release. With the
  `DEBUG_KEYSTORE_BASE64` secret, test APKs share one signing key and install over each other.

### Changed
- The history on GitHub uses the GitHub noreply address as the commit email.
- Docs brought up to date: the README (name, features, Python needed for the tests), the asset
  licenses (the pixel font, all pixel art, the notification icon), CONTRIBUTING, the architecture,
  the art guide and the beta plan (GitHub repository and app ID `io.github.erikeppinger.dust_dungeons`).
- README credits Daniele Pasquale Funaro for the idea for the app; the store listings will too.

## [0.13.0] - 2026-11-03
From the first testers' feedback ([design](docs/design/fight-feedback.md)).

### Added
- **Start button before every round:** the fight waits for "Show rhythm" before the boss plays,
  and for "Start" before the Overlord's lanes. It sits where the pad is, and the last judgement
  stays readable while it waits.
- **Rhythm timeline:** the beats sit at their real times on a line, with the beat grid and the
  count-in, and a playhead sweeps across during the boss's call and during your echo. After a
  round, each beat shows its judgement by shape, and ticks show where you tapped. With "remove
  animations" on, the playhead moves pulse by pulse.
- **Pixel hero that wears its gear:** the hero is now a 32×32 sprite in the Wardrobe's colors, and
  every gear item and hat has its look on the hero. Worn head gear covers the hat. The hero shows
  its gear in the Arena, the Wardrobe, People, the top bar and on the Gear screen, and stands
  beside the hearts in fights, hopping after a clean round and shaking after a miss.
- `build_game_data.py` checks that every gear item and hat has its look at
  `assets/art/hero/wear/<key>.png`.
- **All art is pixel art now:**
  - **Bosses:** the nine bosses are 48×48 sprites, redrawn from their old shapes. Each has four
    frames: idle, a bob, hit and defeated. In fights the boss bounces on the beats of its call.
  - **Quest icons:** the 45 quest icons are 12×12 pixel icons in the quest's color, in the
    quest list, the editor, the plan, the stats and the home widget.
  - **Trophy:** the trophy for a won fight and in the Hall of Fame is pixel art.
  - **Level coin:** the coin beside your level shows the level number.
  - **UI symbols:** every icon in the app is a 12×12 pixel icon now, from settings and buttons to
    the fight's ✓/◎/✗ marks, the back arrow and the segmented buttons' check mark.
  - **Streak flame** in red and gold; quests completed show a plain check.
- Outlined buttons, chips and segmented buttons have the same light and shaded edge as the
  other pixel boxes.

### Changed
- A new hat needs no code any more: its drawing in `assets/art/hero/wear/` is enough.
- Art: `hero` and `bosses` palette groups, and folder rules can give their sprites a name
  `prefix`.
- Bosses and trophies are shown at whole-pixel sizes (the fight's boss is 144 dp, not 170).
- The clutter boss is now called **Clutter Gremlin** in English: "Imp" read as "lmp" in the app's
  font. The German name stays Krempel-Kobold.
- Roadmap: the beta moves to 0.14.0.

## [0.12.0] - 2026-11-03
### Added
- **Game data catalog** ([design](docs/design/game-data.md), [how to](game/README.md)): items,
  bosses, built-in quests and balance numbers live in TOML files under `game/`.
  - `tool/build_game_data.py` checks them and writes the Dart catalog and the texts in both
    languages. Its check mode runs in the tests.
  - The checks cover the schema, icons, both languages, and keys that must never disappear
    (`game/keys.lock`). Every check names the file, key and field.
  - Adding a piece of gear is now: draw the icon, add a few lines to `game/items.toml`, run the
    tool.
  - JSON schemas give editors autocompletion.
- **Item descriptions are written from their effects**, so they always say what the item does.
- **Difficulty per person:** Easy, Balanced or Hard in Settings → Boss fights. It changes boss
  health, timing and tempo. Points, loot and curses stay the same. Shown on the start screen and
  in the fight's header.

### Changed
- New item icons need no line in `assets/art/art.json` (`items/*` rule).
- Schema v10 (`profiles.difficulty`); everyone starts on Balanced.
- Roadmap: the beta moves to 0.13.0.
- The Armory lists loot by boss, and item effects in a steadier order (hearts, Perfect,
  damage, …).
- The gear collection ("7 of 19 items found") only counts retired items for people who have them.

### Fixed
- **The Overlord's result screen crashed** ("Null check operator") after every finished Overlord
  fight, won or lost: it asked for the Overlord's fight tokens, which it never has. This bug has
  been there since 0.6.1.
- **Fights could crash the app** when sounds started and stopped very quickly (fast tapping). Fight
  sounds now use Android's low-latency SoundPool as intended, instead of MediaPlayer.

## [0.11.0] - 2026-11-02
### Added
- **Loot & gear** ([design](docs/design/items.md)):
  - **Six gear slots** (head, body, weapon, shield, feet, charm), one item each, on the new **Gear**
    screen. A two-handed weapon also takes the shield slot.
  - **Five new Armory items**, among them the Colander of Clarity, the Hi-Vis Vest and the
    Spatula of Flipping. Rubber Boots and others work better against some bosses.
  - **Boss loot:** each boss can drop its own item after a win (more often at higher tiers). The
    Overlord drops one every time. After four wins without loot, the fifth always drops. Story
    mode wins drop loot too. The Armory shows loot not found yet as "???".
  - **New consumables:** Coffee of Haste and Snack Break, picked on the new start screen before
    a fight, and Soap of Uncursing.
  - **Mild curses:** losing a fight leaves the boss's curse for the next fight only: one heart
    fewer, stricter timing, or one slot that does nothing. A quest of that boss's kind (marked
    "Lifts curse") or soap lifts it early. Settings → Boss fights can turn curses off.
  - **Start screen before each fight:** your gear, a waiting curse, consumables to pick, and
    hints like "Plunger of Smiting: strong here".
  - Every fight item has a pixel icon.
  - Items change fights only, never points, XP, streaks or screen time.

### Changed
- Gear no longer works just by owning it: each person wears one item per slot. The four items
  from before sit in four different slots, so after the update they are all worn as before.
- Schema v9 (`equipped`, `profiles.curseFamily`, `fights.loot`). Backups bring worn gear along
  for people who wear nothing yet.
- Roadmap: the beta moves to 0.12.0.

## [0.10.0] - 2026-11-02
### Added
- **Better schedules** ([design](docs/design/scheduling.md)):
  - **Clearer names:** "Every … days, fixed rhythm" and "… days after it's done", with the next dates
    shown as an example under the choice.
  - **Monthly on a weekday:** the 1st–4th or last Monday … Sunday, also every N months.
  - **Time to do it:** a quest can stay open for 2–7 days, or until the next time, and counts as on
    time on each of those days ("Due until Tue, 10 Nov").
  - **Times of day:** a quest can be meant for e.g. 18:00–20:00. Before that it's under "Later
    today", after it "Time's up". Doing it outside the times still counts, just without the on-time
    bonus.
  - The Quest Log lists a window on each of its days, and notifications summarize open windows.
- **Three home screen widgets** to choose from in Android's widget picker. Each shows the current
  person's quests with their icons, in the 16-bit look by day and at night:
  - **Quest board:** rows of quest tiles with badges ("! 2 days late", "▶ today", "18:00", "→ Thu").
  - **Quest path:** the next quests as a board-game path, joined by arrows.
  - **Next quest:** the next quest large, the following ones small.
  - The app draws the pictures for the coming week, so the widgets stay right after midnight
    without the app. Only the widgets that are placed get drawn. Tap a widget to open the app.
  - No extra permission and no extra library.
- Database schema v8 (monthly weekday, window days, times) with tested migration.

### Fixed
- Upgrading from a very old database (schema v1) failed once newer schedule columns existed: the v2
  step now writes only its own columns.
### Fixed
- **Vibration in fights didn't work on many phones.** It went through Android's touch feedback,
  which phones turn off with "vibration on touch" or keep very faint. The beat now pulses the
  vibration motor directly (35 ms, following the phone's media vibration setting).
### Changed
- Chores are called **quests** everywhere in the app, to fit the theme: "Add quest", "Edit quest",
  "Manage quests", quest reminders, and the notifications ("Aufgabe" became "Quest" in German).
  The app name and the Chore Overlord keep their names.

## [0.9.0] - 2026-10-29
### Added
- **Several people on one phone** ([design](docs/design/profiles.md)):
  - **Switching:** tap the hero in the top bar. The app remembers the last person.
  - **Settings → People:** add, rename and remove people. A removed person's history stays, and
    adding the name again brings them back.
  - **Per person:** points, level, streak, hero look, Armory, fights, the Overlord and the quest
    map. Story mode and slow mode are also per person.
  - **Who a quest is for:** **anyone** (done once for the household, with "✓ name" on the tile),
    **one person** (only they see it), or **each** of chosen people (everyone does their own).
  - **Quest Log:** an "Everyone's quests" filter.
  - **Hall of Fame:** a **"This week" leaderboard** by points earned, with a crown for the leader
    and last week's winner.
  - **Notifications** cover the whole household, and name a person's own quests as in "Trash (Sam)".
    Recaps count everyone's quests.
  - **Backups** carry people with their heroes, and quest assignments.
- Database schema v7 (people's heroes and fight modes, quest assignments) with tested migration.

### Changed
- Screen time works with one person only (usage is measured per phone). Adding a second person
  turns it off, after a note.
- The generated art file is now `lib/app/art/art_data.dart`, because `build_runner` deletes
  `*.g.dart` files it didn't write.

## [0.8.0] - 2026-10-29
### Added
- **Backups** (Settings → Backup, [design](docs/design/data-safety.md)):
  - **Save a backup** anywhere with Android's file picker. A backup is a copy of the app's database.
  - **Import a backup** from this or another phone. It **merges**: history that's missing here is
    added, nothing is deleted, and importing the same file twice changes nothing. A preview shows
    what will be added. On a new phone, the backup's settings are taken over too.
  - **Undo last import.**
  - **Automatic backups**, daily to a folder you choose, keeping the last 7. A warning shows if the
    folder can no longer be reached.
  - Files that aren't backups, and backups from a newer app version, are refused with a clear message.
  - No storage permission is needed.

## [0.7.2] - 2026-10-29
### Changed
- **Pixel art is now in files.** Icons, map tiles, landmarks and the launcher shield are PNGs with
  named palettes in `assets/art`, so artists can work on them without touching code
  ([art guide](docs/ART_GUIDE.md)).
  - The map's seasons and the day/night coin and hearts are palette swaps of one drawing.
  - `tool/build_art.py` checks the art (sizes, palette colors, transparency) and generates the Dart
    code the app draws from; a test catches a forgotten run.
  - Grass, water and sand use four hand-checkable variants instead of random details.
  - Debug builds have an art gallery (Settings → About) showing every sprite on day and night.

## [0.7.1] - 2026-10-29
### Changed
- **16-bit look.** The whole app now looks like a 16-bit game:
  - Two palettes: parchment by day (light mode) and the dungeon at night (dark mode); the colorblind-safe
    palette keeps its blue accent in both.
  - Headings in a pixel font (Press Start 2P, SIL Open Font License, bundled); body text stays in the
    system font for readability.
  - Panels, buttons, chips and dialogs get pixel frames with a light and a shaded edge.
  - Points show a gold coin, the level an "LV" badge; XP, screen time and fights use segmented bars,
    and the hero's health is a row of pixel hearts.
  - Pixel-art tab icons, and fights always use the night palette.
- New launcher icon and splash screen: a pixel shield with a gold check (no more Flutter logo).

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
[0.10.0]: #
[0.9.0]: #
[0.8.0]: #
[0.7.2]: #
[0.7.1]: #
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
