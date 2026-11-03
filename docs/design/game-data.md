# Game data catalog — design

**Goal:** items, bosses, built-in quests and balance numbers live in a few data files that a
contributor can edit without reading the code. Adding an item is: draw the icon, add a few lines,
run one command.

**Why now (2026-11-02):** after loot & gear (0.11.0), one item touches five places: the catalog
(`shop.dart`), its effects (`items.dart`), its name and description (`items_text.dart` and both ARB
files), and its icon mapping. A curse, a boss tempo or a loot chance is just as scattered.

## Decisions (2026-11-02)
| Question | Decision |
|---|---|
| Format | **TOML.** Readable, with comments and without indentation traps. Python reads it without an extra library, and editors can check it against a schema. |
| Scope | **Items, bosses, balance and the built-in quests.** |
| Texts | **In the catalog, in English and German.** The tool writes them into the ARB files. Effect lines are generated from the numbers. |
| Difficulty | **Easy, balanced and hard presets, offered in this version.** Each person picks one. |

The approach is the usual "data-driven design" of games, done the same way as the art: the files
are the source, and one tool checks them and generates the Dart (like `tool/build_art.py`).

## 1. Files
```
game/
  items.toml      gear, consumables, hats, screen-time vouchers
  bosses.toml     names, tempos, curses
  quests.toml     the built-in quests
  balance.toml    hero growth, boss health, timing, loot, points, difficulty presets
  keys.lock       every key ever shipped (written by the tool, never by hand)
  schema/         JSON schemas, for checks and autocompletion in editors
  README.md       how to add or change things, in one page
```

### items.toml
Every item is a table named by its key. TOML refuses a key used twice.
```toml
[items.plunger_of_smiting]
slot = "weapon"
dropped_by = "bath"            # or: price = 200 for the Armory
name = { en = "Plunger of Smiting", de = "Pümpel des Schmetterns" }
flavor = { en = "It has seen things.", de = "Er hat einiges gesehen." }   # optional
effects = { perfect_times = 3 }
against.bath = { perfect_times = 4 }

[items.mop_of_doom]
slot = "weapon"
two_handed = true
dropped_by = "overlord"
name = { en = "Two-Handed Mop of Doom", de = "Zweihändiger Mopp des Verderbens" }
effects = { perfect_times = 3, good_damage = 1 }

[items.snack_break]
kind = "consumable"
price = 40
before_fight = true
name = { en = "Snack Break", de = "Snackpause" }
effects = { hearts = 2 }
```
- **Kinds:** `gear` (the default when there's a `slot`), `consumable`, `hat`, `voucher`.
- **Effects:** the existing vocabulary: `hearts`, `damage`, `good_damage`, `perfect_times`,
  `free_misses`, `wide_timing`, `combo_heal`, `sneak_attack`, `slower_boss`, `third_miss_free`,
  `full_revive`, `loot_bonus`.
- **`against.<boss>`:** the values there replace the general ones in fights against that boss. This
  one rule covers every item today: the helm, the duster, the plunger and the boots.
- **Special uses** stay named in code: Second Wind revives, soap lifts curses, vouchers add minutes.
  The catalog only says `use = "revive" | "lift_curse" | "screen_minutes"`, plus `minutes = 15`.

### bosses.toml
```toml
[bosses.bath]
name = { en = "Porcelain Golem", de = "Porzellan-Golem" }
fed_by = { en = "bathroom, toilet", de = "Bad, Toilette" }
tempo = { bpm = 84, offbeat = 0.05, eighth = 0.1 }
curse = { kind = "tight_timing", name = { en = "Soap in the Eyes", de = "Seife im Auge" } }
```
- **`trophy`** is optional; without it the trophy is "<name> trophy", as today.
- **Bosses are tuned here, not added here:** each boss's art is still drawn in code until the pixel
  redraw, and its key is stored in the database. So a new boss still needs code, and the README
  says so.

### quests.toml
```toml
[quests.dusting]
title = { en = "Dusting", de = "Staub wischen" }
icon = "auto_awesome"          # a key from the quest icon picker
color = 6
points = 15
repeat = { type = "after_done", every = 7 }
boss = "dust"
```
- **A new quest here** appears on every phone after the update, as today, and existing rows are
  never touched.
- **The tool checks** that the icon is one of the picker's and the color is in the palette.

### balance.toml
```toml
[hero]
hearts = { base = 4, per_two_levels = 1, min = 5, max = 12 }
damage = { base = 1, per_levels = 4, max = 4 }

[bosses]
tier_wins = [3, 8]             # wins for tier 2 and 3
health = { base = 10, per_tier = 6, overlord_times = 2 }
overlord_wins_needed = 5

[timing]                       # ms either side of a beat: perfect, good
normal = [60, 120]
wide = [80, 160]
tight = [45, 95]
story = [100, 200]

[loot]
chance_by_tier = [20, 30, 40]
sure_after_dry_wins = 4

[points]                       # quests, not fights: difficulty never changes these
on_time_bonus_percent = 10
streak_bonus_percent_per_day = 2
max_streak_bonus_days = 10

[difficulty.easy]
boss_health = 0.75
timing_ms = 20                 # added to both windows
tempo = 0.9

[difficulty.balanced]
boss_health = 1.0
timing_ms = 0
tempo = 1.0

[difficulty.hard]
boss_health = 1.25
timing_ms = -10
tempo = 1.08
```

## 2. The tool: `tool/build_game_data.py`
- **Checks**, with errors that name the file, the key and the field:
  - every value against the schema (types, allowed slots, kinds, bosses, effects)
  - every item has an icon at `assets/art/items/<key>.png`; every quest icon is a picker icon
  - every boss drops something; an item can't have both a price and a boss
  - both languages for every text
  - **no key disappears:** every key in `keys.lock` must still exist. An item that should go away
    gets `retired = true` instead: it leaves the Armory and the loot tables, and people who own
    it keep it.
- **Generates:**
  - `lib/game/game_data.dart`: the catalog as constants, read by the domain code
  - `lib/game/game_texts.dart`: `itemName(l10n, key)`, `bossName(…)`, `questTitle(…)` and so on
  - the texts in both ARB files. Each generated entry is marked in its `@` metadata
    (`"description": "generated from game/items.toml"`), so the tool replaces exactly its own
    entries and leaves hand-written ones alone.
  - `keys.lock`, with new keys added
- **Check mode:** `--check` writes nothing and fails if the generated files are out of date. Tests
  and CI run it, so a hand edit to the generated code can't slip through.
- **Icons:** `art.json` gets a folder rule (`"items/*": 16×16, items palette`), so a new icon needs
  no line there.

## 3. Generated descriptions
- **Effect lines from the numbers:** "+1 heart · Perfect ×3 · against Porcelain Golem: Perfect ×4".
  Each effect has one hand-written phrase in the ARB files (about a dozen), with placeholders.
- **A balance change needs no text change** and no new translation, and the text can't drift from
  what the item really does.
- **`flavor`** is an optional line of fun on top ("It has seen things.").
- **Hats and vouchers** keep a written description; they have no effects.

## 4. Difficulty presets
- **Per person,** in Settings → Boss fights, next to story mode and slow mode: Easy, Balanced (the
  default), Hard.
- **What it changes:** boss health, timing windows and tempo, all from `balance.toml`.
- **What it doesn't change:**
  - points, XP, streaks, the leaderboard and screen time
  - loot chances, which stay the same for everyone
  - curses
- **With story mode:** story mode still can't be lost and uses its own windows. Difficulty then only
  changes the health and the tempo.
- **Shown** on the fight's start screen ("Hard") and in the fight's header.
- **Data:** `profiles.difficulty` (text, default `balanced`), schema v10. In backups the phone's person
  row wins, as for story mode.

## 5. What stays code
- **Effects:** what each kind of effect does in a fight (`EchoDuel`). A new item made of existing
  effects needs no Dart. A new kind of effect needs code, a phrase and a schema entry, and the
  README says so.
- **Drawing:** bosses, the hero and the hats, until the pixel redraw.
- **Special uses:** reviving, lifting curses, screen-time minutes.

## 6. Contributor flow
Adding a piece of gear:
1. Draw `assets/art/items/<key>.png` (16×16, items palette; see the art guide).
2. Add `[items.<key>]` to `game/items.toml`.
3. Run `python tool/build_game_data.py` (it also runs the art build), then `flutter test`.

`game/README.md` explains this on one page, with the effect vocabulary as a table. `CONTRIBUTING.md`
links to it.

## 7. Order of work
1. **Tool skeleton:** `balance.toml`, schema, check mode, `keys.lock`. The numbers move out of the
   code with no change in behaviour.
2. **Items:** `items.toml` replaces the catalog in `shop.dart`, `effectsOf` and `items_text.dart`, with
   effect phrases and the ARB sync.
3. **Bosses and curses:** `bosses.toml`.
4. **Quests:** `quests.toml` replaces `default_chores.dart`, `seedFamilies` and the title switch.
5. **Difficulty:** schema v10, the setting, the start screen.
6. **Docs:** `game/README.md`, CONTRIBUTING, ARCHITECTURE, the art guide.

Steps 1–4 change no behaviour, so the existing tests prove them. A test also compares the generated
catalog with today's values before the old code is deleted.

## Tests
- **Tool:** a broken file for every check (unknown effect, missing icon, missing German text, a
  removed key, an item with both a price and a boss) fails with a clear message.
- **Check mode** in the test run: generated files are up to date.
- **Same game:** the generated items, bosses, quests and numbers equal 0.11.0's.
- **Texts:** every item, boss and quest has its name in both languages; the effect lines for all
  items in English and German.
- **Difficulty:** health, windows and tempo per preset; points are unchanged; story mode combined
  with each preset.
- **Migration v9 → v10** with real data: everyone starts on Balanced.
- **Emulator:** add a test item through the catalog only, see it in the Armory; play on Easy and Hard.

## Not in this version
- **A translation platform** (such as Weblate). If one comes, the catalog keeps only English and the
  other languages come from the platform's ARB files.
- **Adding bosses without code** (needs the pixel redraw).
- **Editing the catalog inside the app.**

## As built (changes to the plan)
- **Generated ARB keys** start with `game` (`gameItemTurboMop`, `gameBossDust`, `gameQuestDusting`).
  The old hand-written keys for these texts are gone.
- **Hand-written texts with placeholders stay in ARB:** the voucher names ("Screen time +15 min"),
  the generic trophy ("… trophy") and the Overlord's "5 wins in one week", which now takes its number
  from `balance.toml`.
- **The tool's tests** are Python unit tests (`tool/test_build_game_data.py`): one broken file per
  check. `test/game_data_test.dart` runs them together with the check mode, so `flutter test` covers
  them.
- **Quest points** must be a multiple of 5 (the editor's slider steps).
- **0.11.0's numbers** are unchanged. The existing effect, loot and curse tests ran on the generated
  data before anything else changed.

## Version
**0.12.0**, decided 2026-11-02. The beta moves to 0.13.0.
