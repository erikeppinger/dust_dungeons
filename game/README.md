# Game data

The items, bosses, built-in quests and balance numbers of the game live here, as
[TOML](https://toml.io) files. You can change most of the game without touching the code:
edit a file, run one command, test.

| File | What's in it |
|---|---|
| `items.toml` | Gear, consumables, hats and screen-time vouchers |
| `bosses.toml` | Boss names, which quests feed them, their tempo and their curse |
| `quests.toml` | The built-in quests every phone gets |
| `balance.toml` | Hero growth, boss health, timing, the round rule, loot chances, points, difficulty presets |
| `keys.lock` | Every key ever shipped. Written by the tool; don't edit it |
| `schema/` | What each file may contain. Editors use it for checks and autocompletion |

## After a change
```bash
python tool/build_game_data.py
flutter test
```
The tool checks everything and names the file, the key and the field when something is wrong.
Then it writes the Dart code (`lib/game/`) and the texts (`lib/l10n/*.arb`). It also runs the art
build. You need Python 3.11+ and Pillow (`pip install pillow`).

**Editor:** with the *Even Better TOML* extension (VS Code), the `#:schema` line at the top of each
file gives you autocompletion and checks as you type.

## Adding a piece of gear
1. Draw the icon: `assets/art/items/<key>.png`, 16×16, in `assets/art/palettes/items_day.gpl` (see
   [the art guide](../docs/ART_GUIDE.md)).
2. Add it to `items.toml`:
   ```toml
   [items.golden_spatula]
   slot = "weapon"            # head, body, weapon, shield, feet, charm
   price = 250                # or: dropped_by = "kitchen"
   name = { en = "Golden Spatula", de = "Goldener Pfannenwender" }
   flavor = { en = "Shiny.", de = "Glänzend." }   # optional
   effects = { good_damage = 1, combo_heal = 12 }
   against.kitchen = { good_damage = 2 }          # optional
   ```
3. Draw its look on the hero: `assets/art/hero/wear/<key>.png`, 32×32 on the hero's canvas
   (`assets/art/hero/hero.png`), transparent where the item isn't, in the items palette.
4. Run the tool and the tests.

The description in the app is written from the effects ("+1 damage on good hits · heals a heart after
12 hits in a row · against Sink Kraken: +2 damage on good hits"). So it's always right, and balance
changes need no new text.

## Effects
| Effect | Value | What it does |
|---|---|---|
| `hearts` | 1–5 | Extra hearts |
| `damage` | 1–5 | Extra damage on every hit |
| `good_damage` | 1–5 | Extra damage on Good hits |
| `perfect_times` | 3–6 | A Perfect hit deals this many times the hero's damage (normally 2) |
| `free_misses` | 1–5 | The first failed rounds of a fight cost no heart (in the lane phase: missed notes) |
| `wide_timing` | true | Wider timing windows |
| `combo_heal` | 3–50 | Heals a heart after this many hits in a row |
| `sneak_attack` | true | The first round that lands deals 50 % more |
| `slower_boss` | true | The boss plays 10 % slower |
| `third_miss_free` | true | Every third failed round costs no heart (in the lane phase: missed note) |
| `full_revive` | true | Second Wind brings back all hearts |
| `loot_bonus` | 1–50 | Percentage points added to the loot chance |

- **Against one boss:** values under `against.<boss>` replace the general ones in fights against
  that boss.
- **Several items** add up. For `perfect_times` the best one counts, and for `combo_heal` the
  shortest.
- **A new kind of effect** needs code: the field in `lib/domain/fight/effects.dart`, what it does in
  `EchoDuel`, a phrase in the ARB files and in `lib/features/world/items_text.dart`, and an entry
  in `schema/items.json` and in the tool's `EFFECTS`.

## Other kinds of items
- **Consumables:** `kind = "consumable"` with a `price`. Either `before_fight = true` with
  `effects` (picked on a fight's start screen), or a `use` handled in code (`revive`, `lift_curse`)
  with a written `description`.
- **Hats:** `kind = "hat"`, `price` and `look`. `look` is the number stored for the hero, so never
  change it. A new hat also needs its look on the hero in `assets/art/hero/wear/`.
- **Vouchers:** `kind = "voucher"`, `price` and `minutes`. Their name says the minutes.

## Keys are forever
Item, boss and quest keys are stored in people's databases, so a key can't be renamed or removed.
The tool refuses that, using `keys.lock`.
- **To take an item out:** set `retired = true`. It leaves the Armory and the loot tables, and people
  who own it keep it.
- **A quest edited here** only changes new installs. Phones that already have it keep their own
  version.

## Bosses
`bosses.toml` changes names, tempos and curses. Adding a boss still needs code (its drawing and its
place in `BossFamily`).

## Balance and difficulty
`balance.toml` holds the numbers. Each person picks a difficulty in Settings → Boss fights:
- **What a preset changes:** boss health, timing and tempo.
- **What it never changes:** points, loot or curses.
