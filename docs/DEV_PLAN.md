# Development Plan: Household Chores Gamification App

> Name: **Dust & Dungeons** (decided 2026-11-03; the working title "Homework & Chores" goes with the beta, 0.17.0)
> Status: 0.13.0 released 2026-11-03; next is the beta. This plan dates from 2026-10-28 (core decisions in §16); the roadmap below is kept current.
> Target: Android APK first, then macOS/iOS later. Built with Flutter 3.47 / Dart 3.13.

---

## 1. Vision

You earn points by doing household chores. You spend those points on goals inside the app, and the goals together make up a larger
progression: a world, a story or a collection that grows over time. The genre (city builder, garden, RPG, space colony …)
is **not fixed yet**, so the architecture keeps the *point economy* separate from the *theme* that spends the points.

### Non-negotiable principles
| Principle | What it means in practice |
|---|---|
| **100 % local** | No server, no account, no cloud sync, no analytics, no crash reporting SDKs, no ads |
| **No network** | Release build ships **without** `android.permission.INTERNET` (Flutter only adds it to debug/profile manifests by default; we verify this in CI) |
| **Open source** | Public Git repo, clear license, no proprietary dependencies (no Firebase / Google Play Services) so it can go on **F-Droid** |
| **Accessible** | Light/dark mode, colorblind-safe palette, never color-only information, font scaling, screen reader labels |
| **Traceable** | SemVer versioning, `CHANGELOG.md` updated with every change |

---

## 2. Things missing from the draft (recommended additions)

You asked "anything missing?" These are the gaps I'd close up front, because several of them are hard to add later.

1. **Backup / export / import (critical).** With no cloud, uninstalling or losing the phone deletes everything. Add a JSON (or SQLite file) export and import through the Android file picker (Storage Access Framework, no storage permission needed). Optionally add an automatic backup to a folder you choose.
2. **Several people per household.** Is the app for one person, or does the family share one device with profiles? Profiles on one device are easy if planned now. Syncing between devices without a server is hard; a later option is a manual export/import "household file" or a local Wi-Fi/QR sync.
3. **Effort weighting.** Points should scale with effort (duration, difficulty) and not be the same for every chore. Optionally give a bonus for overdue or disliked chores.
4. **Undo and editing history.** Accidental taps happen. Give an undo snackbar and let users edit past completions.
5. **Streak fairness.** Add a vacation/pause mode, "streak freeze" items and a grace period, so the app motivates instead of punishing.
6. **Localization from day one.** UI in German + English via ARB files. Adding i18n afterwards is painful.
7. **Android notification specifics.** Android 13+ needs a runtime notification permission. Exact alarms need `SCHEDULE_EXACT_ALARM`/`USE_EXACT_ALARM` rules, and Doze/battery optimisation can delay reminders. Plan for inexact daily summaries plus optional exact reminders.
8. **Release signing key.** If you lose the keystore you can never update the app again. Back it up outside the repo and never commit it.
9. **License choice.** GPL-3.0 keeps forks open; MIT/Apache-2.0 is permissive. Decide before the first public commit.
10. **Asset licensing.** Chore icons must be open-licensed (e.g. Material Symbols (Apache-2.0), OpenMoji (CC BY-SA 4.0), Microsoft Fluent Emoji (MIT)) or drawn yourself. Document attribution in `ASSETS_LICENSES.md`.
11. **Database migrations.** The schema will change. Use a versioned DB with tested migrations so updates never wipe user data.
12. **Onboarding.** On first start the user picks a household profile and the chores that apply, and sets notification preferences.
13. **Privacy statement.** A short `PRIVACY.md` ("no data leaves the device") is required for F-Droid/Play listings and builds trust.
14. **Testing + CI.** Unit tests for points and recurrence logic, widget tests and GitHub Actions to build the APK. CI runs on GitHub, never inside the app.
15. **Later nice-to-haves:** home screen widget, haptics/sounds, statistics charts, room/area grouping, achievements/badges.

---

## 3. Dropbox + Flutter + Git setup (do this first)

Dropbox syncing Flutter build output causes file-lock errors, sync conflicts and gigabytes of useless uploads.
"Ignoring" folders is not enough on Windows: every file under the Dropbox folder is a cloud-files placeholder
(a reparse point), and Gradle sometimes cannot read those ("Cannot snapshot …: not a regular file").
This made two release builds fail (0.1.0, 0.3.0).

**Fix (since 0.3.0):** `tool/dropbox_ignore.ps1` moves `build/`, `.dart_tool/`, `android/.gradle`, `android/.kotlin`
and `android/app/.cxx` to `%LOCALAPPDATA%\HomeworkAndChores\generated\` and leaves Dropbox-ignored **directory
junctions** in their place. Paths inside the project stay the same.

```powershell
powershell -ExecutionPolicy Bypass -File tool\dropbox_ignore.ps1
flutter pub get
```

Notes:
- Re-run it after `flutter clean` (which deletes the `build` junction) and on every new machine.
- Always check the installed version (`adb shell dumpsys package … | findstr versionName`) after installing a build: a failed build silently leaves the old APK in place.
- `.git` inside Dropbox works but can corrupt if two machines edit at once. Safest: **GitHub/Codeberg is the source of truth** and Dropbox is only a convenience copy. Never work on the repo from two PCs at the same time.
- `.gitignore` uses the standard Flutter template plus `*.jks`, `*.keystore`, `key.properties`, `*.apk`, `*.aab`.

---

## 4. Tech stack

| Concern | Choice | Why |
|---|---|---|
| Framework | Flutter (stable) | Already installed, Android + macOS/iOS from one codebase |
| State management | **Riverpod** | Testable, no BuildContext coupling, widely used |
| Local database | **Drift** (SQLite) | Typed queries, reactive streams, built-in schema migrations, fully offline |
| Navigation | **go_router** | Declarative and deep-link-ready (for notification taps) |
| Notifications | **flutter_local_notifications** + **timezone** | Local scheduling only, no push service |
| Localization | `flutter_localizations` + `intl` (ARB files) | Official, de/en |
| Theming | Material 3 `ColorScheme` + custom `ThemeExtension` for chore colors | Light/dark/system and colorblind palette switch |
| Icons | Material Symbols + open-licensed SVG set (via `flutter_svg`) | Colorful but license-safe |
| Backup | `file_picker` / SAF + JSON | No storage permission needed |
| Tests | `flutter_test`, `mocktail`, Drift in-memory DB | Fast logic tests |
| Lint | `flutter_lints` (strict) + `dart format` | Consistent code |

**Dependency rule:** before adding any package, check that it has no network calls, no analytics and no Google Play Services.

---

## 5. Repository structure

```
Homework-and-Chores/
├─ android/                  # Flutter-generated
├─ macos/ ios/               # added later (flutter create --platforms=macos,ios .)
├─ assets/
│  ├─ icons/chores/          # SVG chore icons
│  ├─ themes/                # theme/genre packs (later)
│  └─ (images, sounds later)
├─ lib/
│  ├─ main.dart
│  ├─ app/                   # App widget, router, theme, l10n setup
│  ├─ core/                  # shared utils, constants, result types, date helpers
│  ├─ data/
│  │  ├─ db/                 # Drift database, tables, migrations
│  │  └─ repositories/
│  ├─ domain/                # pure Dart: models, points engine, recurrence engine
│  ├─ features/
│  │  ├─ chores/             # list, add/edit, complete
│  │  ├─ schedule/           # today / week / month overview
│  │  ├─ progression/        # goals, rewards, the "world" (genre-agnostic)
│  │  ├─ stats/              # summaries, history
│  │  ├─ notifications/
│  │  ├─ settings/           # theme, colorblind mode, language, backup
│  │  └─ onboarding/
│  └─ l10n/                  # app_de.arb, app_en.arb
├─ test/                     # mirrors lib/
├─ integration_test/
├─ tool/                     # dropbox_ignore.ps1, bump_version script
├─ docs/
│  ├─ DEV_PLAN.md            # this file
│  ├─ ARCHITECTURE.md
│  └─ adr/                   # Architecture Decision Records (one per big decision)
├─ .github/workflows/ci.yml  # analyze, test, build APK, check no INTERNET permission
├─ CHANGELOG.md
├─ README.md
├─ LICENSE
├─ PRIVACY.md
├─ ASSETS_LICENSES.md
├─ CONTRIBUTING.md
├─ analysis_options.yaml
└─ pubspec.yaml
```

Rule: `domain/` is pure Dart with no Flutter imports. That keeps the points and recurrence logic fully unit-testable.

---

## 6. Data model (first draft)

```
Profile        id, name, avatar, color, createdAt
Chore          id, title, iconKey, colorKey, category/room, basePoints,
               effort (1–5), estMinutes, isBuiltIn, isArchived, notes
Schedule       id, choreId, type (once|daily|weekly|monthly|everyNDays|custom),
               interval, weekdays[], dayOfMonth, startDate, endDate?,
               reminderTime?, assignedProfileId?
Completion     id, choreId, profileId, completedAt, pointsAwarded, note
PointLedger    id, profileId, delta, reason (completion|spend|bonus|undo), refId, at
Goal           id, themeId, key, title, cost, prerequisites[], unlockedAt?
Setting        key, value
```

- **Points live in a ledger and are never stored as a single number.** The balance is the sum of the ledger, which makes undo, history and "points earned this week" trivial and auditable.
- **"Due" is computed** from Schedule + last Completion, never stored. This avoids drift bugs.

### Recurrence options
- Once (with due date)
- Daily / every N days
- Weekly on chosen weekdays / every N weeks
- Monthly on day X or "first Monday" style rules
- **Floating** ("every 10 days *after the last time it was done*") is ideal for chores like changing bed sheets
- Optional end date, pause/vacation mode

---

## 7. Gamification design (genre-agnostic)

```
Chores ──complete──▶ Points (ledger) ──spend──▶ Goals ──belong to──▶ Theme / World
            │                                      │
            └──▶ Streaks, Badges, Levels (XP)       └──▶ Visual progression screen
```

- **Two currencies:** **XP** (earned, never lost, drives the player level) and **Coins/Points** (spendable on goals). Spending never makes you "lose progress".
- **Theme interface:** a `ProgressionTheme` defines goals (a node graph with costs and prerequisites), artwork and texts. The first build ships one simple placeholder theme (e.g. "decorate a house room by room"). The final genre can be swapped in without touching chore or points code.
- **Point formula (v1):** `points = basePoints × effortMultiplier + overdueBonus + streakBonus`, with all constants in one config file so tuning is easy.
- **Real-life rewards (optional):** user-defined rewards ("ice cream = 200 points"). This is very popular in families and cheap to build.
- **Anti-frustration:** streak freeze, vacation mode, no negative points by default.

---

## 8. UI / UX

**Main screens (bottom nav):**
1. **Quests** (was Today): due and overdue chores as large colorful tiles, tap to complete, with an undo snackbar
2. **Quest Log** (was Plan): week view and month calendar with due chores and completed markers
3. **Arena** (was World): hero, quest map to the weekly Overlord, bosses, Armory (shop), Wardrobe, Hall of Trophies
4. **Hall of Fame** (was Stats): points per day/week/month, top chores, streaks
5. **Settings:** theme (light/dark/system), colorblind palette, language, notifications, backup/restore, manage chores, about/licenses

**Colors and accessibility**
- Default palette: vibrant category colors.
- Colorblind palette: **Okabe-Ito** (safe for deuteranopia, protanopia and tritanopia).
- Every chore has **icon + label + color**, so color is never the only signal.
- Contrast ≥ 4.5:1 for text in both light and dark modes, plus support for system font scaling and TalkBack semantics.

---

## 9. Default chores (seed data, de/en)

| Chore (DE / EN) | Icon idea | Default rhythm | Base pts |
|---|---|---|---|
| Staub wischen / Dusting | feather duster | weekly | 15 |
| Boden kehren / Sweeping | broom | 2× weekly | 15 |
| Staubsaugen / Vacuuming | vacuum | weekly | 20 |
| Wischen / Mopping | mop + bucket | weekly | 25 |
| Abwasch / Dishes | plate + bubbles | daily | 10 |
| Spülmaschine aus-/einräumen / Dishwasher | dishwasher | daily | 5 |
| Wäsche waschen / Laundry | washing machine | 2× weekly | 10 |
| Wäsche aufhängen / Hang laundry | clothesline | with laundry | 10 |
| Wäsche falten / Fold laundry | folded shirt | with laundry | 10 |
| Bügeln / Ironing | iron | weekly | 20 |
| Bad putzen / Clean bathroom | bathtub | weekly | 30 |
| Toilette putzen / Clean toilet | toilet | weekly | 20 |
| Küche putzen / Clean kitchen | stove | weekly | 25 |
| Müll rausbringen / Take out trash | bin | every 3 days | 5 |
| Altpapier/Gelber Sack / Recycling | recycle | weekly | 5 |
| Betten beziehen / Change bed sheets | bed | every 14 days (floating) | 20 |
| Fenster putzen / Clean windows | window | monthly | 40 |
| Kühlschrank reinigen / Clean fridge | fridge | monthly | 30 |
| Einkaufen / Groceries | cart | weekly | 15 |
| Pflanzen gießen / Water plants | watering can | every 3 days | 5 |
| Aufräumen / Tidy up | box | daily | 10 |

Users can add, edit, archive and re-color chores. Built-in chores can be hidden, not deleted, so seed updates stay safe.

---

## 10. Notifications

- **Daily summary** at a user-chosen time: "3 chores due today, 1 overdue".
- **Per-chore reminder** (optional) at the chore's reminder time.
- **Weekly/monthly recap:** points earned, chores done, streak, goal progress. Shown as a notification plus a recap screen.
- **Quiet hours** and a global on/off switch.
- Tapping a notification deep-links to Today or the recap.
- All notifications are rescheduled on app start, after completing a chore and after reboot (`RECEIVE_BOOT_COMPLETED`).

---

## 11. Versioning and changelog

- **SemVer** in `pubspec.yaml`: `version: MAJOR.MINOR.PATCH+BUILD` (e.g. `0.3.1+7`). `BUILD` (Android `versionCode`) **always increments**.
  - `0.x` = pre-release while features settle, `1.0.0` = first stable public release.
- **`CHANGELOG.md`** follows *Keep a Changelog*, with sections `Added / Changed / Fixed / Removed / Security`. There is always an `[Unreleased]` section on top, and every PR/commit adds a line there.
- **Conventional Commits** (`feat:`, `fix:`, `docs:`, `refactor:`, `chore:`) make changelog writing easy.
- **Git tags** `v0.1.0` and so on for each release, with the APK attached to the GitHub/Codeberg release.
- A `tool/bump_version` script bumps pubspec and moves `[Unreleased]` → `[x.y.z] – date` in one step.
- The in-app *About* screen shows version + build and links to the changelog. Optionally add an in-app "What's new" dialog after updates.

---

## 12. Roadmap / milestones

| Version | Milestone | Content |
|---|---|---|
| **0.0.1** ✅ | Scaffolding | `flutter create --org io.github.changeme --project-name homework_and_chores --platforms=android`, Dropbox ignore, local Git (no remote yet), license, README, CHANGELOG, lint rules, l10n setup, theme skeleton (light/dark) |
| **0.1.0** ✅ | Core chores | Drift DB, seed chores (`lib/domain/default_chores.dart`), chore list, add/edit/archive, icons & colors, complete + undo, settings saved |
| **0.2.0** ✅ | Scheduling | Recurrence engine (with heavy unit tests), Today view, week/month overview, overdue logic |
| **0.3.0** ✅ | Points | Ledger, XP/levels, point formula, streaks, stats screen v1 |
| **0.4.0** ✅ | Notifications | Permission flow, daily summary, per-chore reminders, weekly recap, boot rescheduling |
| **0.5.0** ✅ | Boss fights v1 | Fight tokens, echo duel, 2 playable bosses, World hub, trophy shelf, avatar, story mode, sound + haptics ([design](design/0.5-boss-fights.md)) |
| **0.5.1** ✅ | Bosses & shop | All 8 bosses, gear and avatar shop (spending points) |
| **0.5.2** ✅ | Overlord | Weekly Chore Overlord with lane phase, latency calibration, slow mode |
| **0.6.0** ✅ | Accessibility & polish | Colorblind palette, contrast audit, TalkBack, font scaling, onboarding, animations/haptics |
| **0.7.0** ✅ | Screen time | Soft screen-time budget: chores earn minutes, vouchers in the Armory, reminders, Tired in the Arena ([design](design/screen-time.md)) |
| **0.7.1** ✅ | 16-bit look | Day/night palettes, pixel font headings, framed panels, segmented bars, pixel tab icons, new launcher icon and splash |
| **0.7.2** | Art as files | Pixel art moved from code into PNG files with palettes, palette swap for seasons and avatar, art checker and gallery, [art guide](ART_GUIDE.md) ([design](design/art-assets.md)); hero and bosses redrawn as sprites later |
| **0.8.0** ✅ | Data safety | Export, import that merges, daily auto-backup to a chosen folder, undo of an import ([design](design/data-safety.md)) |
| **0.9.0** ✅ | Profiles | Several people on one device (free switching), chores for anyone / one / each, per-person hero and fights, weekly leaderboard; screen time only with one person ([design](design/profiles.md)) |
| **0.10.0** ✅ | Better schedules | Clearer repeat names with example dates, monthly on a weekday, day ranges and times of day as windows, home screen widget ([design](design/scheduling.md)) |
| **0.11.0** ✅ | Loot & gear | Gear slots (two-handed weapons push out shields), new Armory items, boss loot with a bad-luck guard, mild curses after a lost fight that last one fight at most, consumables; items never change points ([design](design/items.md)) |
| **0.12.0** ✅ | Game data | Items, bosses, built-in quests and balance numbers in TOML files under `game/`, checked and turned into code and texts by `tool/build_game_data.py`; descriptions generated from effects; easy / balanced / hard per person ([design](design/game-data.md)) |
| **0.13.0** ✅ | Fight feedback | A start button before every round, a timeline with a playhead for the rhythm, a pixel hero that wears its gear, also in fights; from the first testers ([design](design/fight-feedback.md)) |
| **0.14.0** ✅ | Round rules | A heart is lost only for a round under 50 % accuracy, and only rounds at 50 % or more damage the boss; shields protect failed rounds; from the testers ([design](design/round-rules.md)) |
| **0.15.0** ✅ | Weekly Overlords | A different Overlord every week from six parts, with a generated name and a trait that changes its rhythms; opt-in holiday Overlords with their own trophies ([design](design/weekly-overlords.md)) |
| **0.16.0** ✅ | More bosses | Four new bosses (homework, pets, garden, cooking) with suggested quests and an onboarding question, stronger forms at tiers 2 and 3 for every chore boss, bronze, silver and gold trophies, sleeping bosses in the Arena ([design](design/more-bosses.md)) |
| **0.17.0** | Beta | Name **Dust & Dungeons**, final app ID, push to GitHub, GitHub Actions CI (analyze, test, APK build, no-INTERNET check), signed release APK, testing on real devices, bug fixing, F-Droid metadata (`fastlane/metadata/android/...`) ([plan](design/beta.md)) |
| **1.0.0** | Release | Icon and logo for Dust & Dungeons, store/F-Droid listing, chosen genre theme |
| later | | macOS/iOS, home screen widget, more themes, device-to-device sync without a server |

---

## 13. Distribution (F-Droid first, Google Play possible later)

**One signing key everywhere.** Android only installs updates whose signature matches the installed app.
- F-Droid: aim for **reproducible builds**. F-Droid then verifies its own build against ours and publishes *our* signed APK, so it isn't re-signed with F-Droid's key.
- Google Play (later): choose **"use my own app signing key"** during Play App Signing setup and upload the same key. Users can then move between stores without reinstalling or losing data.
- Back up the keystore in at least two places outside the repo (never in Git, never only in Dropbox). Losing it locks us out of both stores.

**Google Play checklist (when the time comes)**
- [ ] Developer account ($25 one-time, identity verification)
- [ ] Closed test with ≥ 12 testers for 14 days (required for new personal accounts)
- [ ] Upload **AAB** (`flutter build appbundle`); F-Droid keeps using APKs
- [ ] Privacy policy URL → `PRIVACY.md` on GitHub
- [ ] Data safety form: "no data collected or shared"
- [ ] Content rating questionnaire
- [ ] Target the current required Android API level (keep Flutter updated)
- [ ] Reminders use inexact alarms by default. Play restricts `USE_EXACT_ALARM` to alarm/calendar apps

**Rules that keep both stores open**
- No Google-Play-only libraries (Firebase, Play Services, in-app review/billing). If one is ever wanted, put it in a separate `play` build flavor.
- Package name stays the placeholder only until the first public release, then it's permanent.
- **SQLite build:** `sqlite3` 3.x (used by Drift) downloads hash-pinned prebuilt SQLite binaries from its GitHub releases at build time. F-Droid builds offline from source, so before 0.9 switch the `hooks: user_defines: sqlite3` option in `pubspec.yaml` to compile SQLite from source and verify that build works.
- **Android developer verification:** Google has announced that apps on certified devices, including ones installed from outside Play, will need a registered developer and package name. It starts in some countries in 2026, with a wider rollout later, and F-Droid has publicly opposed it. Check the current status before the first public release, and register the package name if needed.

---

## 14. Known limits (revisit later)

- **Quiet hours** (from §10) are not built yet. All notification times are user-chosen or fixed at sensible hours (summary at the chosen time, recaps 10:00/18:00), so this is low priority.
- **Notification content is decided when planning.** Counts are right as long as nothing changes without the app being opened. Streaks are left out of recaps for this reason.

- **Stats performance:** `ProgressStats` aggregates the whole completion history in Dart on every change. That is fine for the first year (a few thousand rows). If it gets slow, move the sums into SQL. Group by local day carefully: stored timestamps carry UTC offsets.

---

## 15. Definition of done (every feature)

- [ ] Works in light **and** dark mode, and with the colorblind palette
- [ ] Strings in ARB (de + en), with no hard-coded UI text
- [ ] Unit/widget tests for new logic
- [ ] `flutter analyze` clean, `dart format` applied
- [ ] **Runs on the Android emulator** (integration test passes, APK installed and changed screens checked) **before any commit**
- [ ] `CHANGELOG.md` `[Unreleased]` updated
- [ ] No new network-capable or tracking dependency

---

## 16. Decisions

### Decided (2026-10-28)
| Topic | Decision | Consequence |
|---|---|---|
| License | **GPL-3.0** | `LICENSE` file at repo root; dependencies must be GPL-compatible (MIT/BSD/Apache-2.0 are fine) |
| Profiles | **Several profiles on one device, built into the data model from the start** | Every completion and ledger row carries a `profileId` from 0.1. v1 UI shows one default profile, and switching between profiles arrives in 0.8 |
| Hosting | **Local only for now, GitHub later** | Local `git init` with no remote until the APK runs properly. Then push to GitHub and add GitHub Actions CI, Releases and F-Droid. Until then, Dropbox is the only off-device copy (see §3) |
| Language | **German + English from 0.0.1** | `app_de.arb` + `app_en.arb`; every new string goes into both files. The device language decides, with an in-app override |
| Repo name / app ID | **`homework-and-chores`** · placeholder Android ID `io.github.changeme.homework_and_chores` | Swap in the real GitHub user (`applicationId` in `android/app/build.gradle.kts` + Kotlin package) right before the first push. Changing it installs as a separate app, which doesn't matter during dev. Permanent after the first public release |
| Display name | **Working title only** until the genre is chosen (~0.5.0) | The name lives in the ARB files (`appTitle`), so renaming is a one-line change |

### Direction for 0.5 (2026-10-28)
- **Full design: [design/0.5-boss-fights.md](design/0.5-boss-fights.md)** (mechanic, rewards, sound and avatar decided).
- **Boss fights** are the leading genre idea: chore-themed bosses ("Dust Bunny", "Laundry Hydra") plus a weekly
  "Chore Overlord", fought in a short original rhythm/action round (Flame engine, offline, CC0 or own assets).
  Level sets hero strength, and points buy abilities, gear and retries.
- **Fight tokens (decided):** every completed chore grants a token. Fights are optional and can be played whenever
  you like, so logging a chore never requires playing.
- **Screen-time reward (decided, 0.7.0):** the "soft" version (usage access only: budget, earned minutes,
  vouchers and reminders), see [design](design/screen-time.md). Hard blocking (accessibility service +
  overlay) is risky for Google Play and stays deferred.

### Still open
1. **GitHub username**: replaces the `changeme` placeholder in the app ID before the first push
2. **Genre / theme**: confirm boss fights (above) when 0.5 starts
3. **Final display name** (after the genre is chosen)
