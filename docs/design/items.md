# Loot & gear — design

The idea came from the card game Munchkin (2026-11-02): gear in slots, big items with drawbacks,
loot from beaten monsters, and curses. The names and rules here are our own; no names come from
the game.

## Decisions (2026-11-02)
| Question | Decision |
|---|---|
| Equipping | **Slots, one item each.** You own many items but wear one per slot, so picking gear for a boss is part of the game. |
| Getting items | **Armory and boss loot.** Common items cost points; beaten bosses sometimes drop rarer, boss-themed ones. |
| Curses | **Mild and removable.** A lost fight can leave one curse, which lasts at most one fight. They can be turned off. |
| On the hero | **Icons now.** Items get pixel icons; they're drawn on the hero with its pixel redraw (art step 5). |

## Today
- **Gear (Armory):** Sponge Shield (first miss costs no heart), Turbo Mop (Perfect hits deal 3× instead
  of 2×), Metronome Charm (wider timing windows), Rubber Gloves (+1 heart).
- **Everything owned works:** `Loadout` is four yes/no flags, all on once bought.
- **Also in the Armory:** Second Wind (continue a lost fight), four hats (looks only), screen-time vouchers.

## The one rule
**Items change fights and looks, never points, XP, streaks or screen time.** The leaderboard counts
quest points only, so gear can't buy a better rank, and nobody is behind on quests because of luck.

## 1. Slots
| Slot | What goes there |
|---|---|
| **Head** | helmets and hats that do something |
| **Body** | aprons, vests: mostly hearts |
| **Weapon** | mops, spatulas, plungers: damage |
| **Shield** | lids and sponges: free misses |
| **Feet** | slippers and boots |
| **Charm** | small lucky things |

- **One item per slot.** Owned items wait in the bag.
- **Two-handed weapons** fill Weapon and Shield. Equipping one takes the shield off; equipping a shield
  takes it off.
- **Hats stay looks.** The four Armory hats aren't gear and don't use the Head slot. When the hero is
  redrawn, a Head item hides the hat in the picture.
- **Per person:** each person has their own bag and slots, like their hero.

## 2. Items
Effects come from a small set, so they're easy to explain and test:
**+hearts**, **+damage** (on every hit), **Perfect ×3**, **free misses**, **wider timing**,
**heal on combo** (+1 heart after a number of hits in a row, up to the maximum),
**sneak attack** (the first echo deals double damage), **slower boss** (tempo −10 %), and
**against a boss** (an effect that only works against one family).

### Armory (points)
| Item | Slot | Price | Effect |
|---|---|---|---|
| Sponge Shield | Shield | 150 | 1 free miss (as today) |
| Turbo Mop | Weapon | 300 | Perfect ×3 (as today) |
| Metronome Charm | Charm | 100 | Wider timing (as today) |
| Rubber Gloves | Body | 200 | +1 heart (as today) |
| Colander of Clarity | Head | 150 | +1 heart |
| Spatula of Flipping | Weapon | 200 | +1 damage on Good hits |
| Hi-Vis Vest | Body | 350 | +2 hearts |
| Rubber Boots | Feet | 120 | +2 hearts against the bath and outside bosses |
| Lucky Odd Sock | Charm | 150 | Better loot chances (+15 points of percent) |

### Loot (one per boss, two from the Overlord)
| Boss | Item | Slot | Effect |
|---|---|---|---|
| Dust | Feather Duster of Fury | Weapon | Heal 1 heart after 10 hits in a row; +1 damage against dust |
| Laundry | Laundry-Basket Helm | Head | +1 heart; +2 against laundry |
| Kitchen | Apron of Holding | Body | +1 heart; Second Wind brings back all hearts, not half |
| Bath | Plunger of Smiting | Weapon | Perfect ×3; ×4 against bath |
| Trash | Trash-Can Lid | Shield | 2 free misses |
| Bedroom | Fuzzy Slippers of Sneaking | Feet | Sneak attack |
| Outside | Garden Gnome | Charm | Every 3rd miss costs no heart |
| Clutter | Lost Remote | Charm | Slower boss |
| Overlord | Two-Handed Mop of Doom | Weapon, two-handed | Perfect ×3 and +1 damage on Good hits; no shield |
| Overlord | Cape of the Clean Sweep | Body | +2 hearts; heal 1 heart after 10 hits in a row |

### Consumables (Armory)
| Item | Price | Effect |
|---|---|---|
| Second Wind | 60 | Continue a lost fight (as today) |
| Coffee of Haste | 50 | This fight: +1 damage on Good hits |
| Snack Break | 40 | This fight: +2 hearts |
| Soap of Uncursing | 30 | Lifts your curse |

- **Before the fight:** Coffee and Snack are picked on the fight's start screen, at most one of each.
- **Second Wind** stays where it is, after a lost fight.

### Names in German
Sieb der Klarheit, Pfannenwender des Wendens, Warnweste, Gummistiefel, Glückssocke ohne Partner,
Staubwedel des Zorns, Wäschekorb-Helm, Schürze der Vorräte, Pümpel des Schmetterns, Mülltonnendeckel,
Flauschpantoffeln des Schleichens, Gartenzwerg, Verschollene Fernbedienung, Zweihändiger Mopp des
Verderbens, Umhang des Großputzes, Kaffee der Eile, Snackpause, Seife der Entfluchung.
These are first drafts; they're settled when the ARB files are written.

## 3. Loot
- **When:** after a won fight, the boss may drop its item.
  - **Chances:** 20 % at tier 1, 30 % at tier 2, 40 % at tier 3. The Lucky Odd Sock adds 15.
  - **The Overlord** always drops something.
- **No long bad luck:** after 4 wins without loot, the 5th win drops for sure.
- **What drops:** an item from that boss's table that the person doesn't own yet. With all of them
  owned, it's a Coffee of Haste or a Snack Break instead.
- **Story mode wins drop loot too.** Story mode is there for accessibility, and it shouldn't cost rewards.
- **Shown on the result screen:** "Loot! Plunger of Smiting", with the icon, its effect, and an
  "Equip" button.
- **Same result in tests:** the roll is seeded by the fight's id.

## 4. Curses
- **When:** losing a fight (not story mode, and not a fight the app lost track of) leaves that boss's
  curse.
- **One at a time:** a new curse replaces the old one; they never stack.
- **How long:** it works in the next fight only, won or lost, and is gone after it.
- **Lift it earlier:** do any quest of the cursing boss's family ("Do a laundry quest to dry your
  socks"), or use Soap of Uncursing.
- **Effects:** one of three, never more:
  - **−1 heart** (never below 3)
  - **tight timing** (windows narrower than normal; the Metronome Charm doesn't help)
  - **one slot off** (that item does nothing)

| Boss | Curse | Effect |
|---|---|---|
| Dust | Sneezing Fit | Tight timing |
| Laundry | Wet Socks | −1 heart |
| Kitchen | Greasy Fingers | Weapon off |
| Bath | Soap in the Eyes | Tight timing |
| Trash | Stinky Cloud | −1 heart |
| Bedroom | Bed Head | Head off |
| Outside | Muddy Boots | Feet off |
| Clutter | Stubbed Toe | −1 heart |
| Overlord | Overlord's Grudge | −1 heart |

- **Can be turned off:** Settings → Fights → "Curses after a lost fight", on by default. For the
  whole household.
- **Shown:** a badge on the World screen with the curse, its effect and how to lift it; the start
  screen of the next fight; and a "Lifts curse" note on quest tiles of that family. Always as text
  and icon, never color alone.

## 5. Where it shows
- **Armory:** sections Gear, Consumables, Looks, Screen time. Each item shows its slot, its effect, and
  "Owned" or "Equipped". Loot items appear as "?" with "Dropped by the laundry boss" until found.
- **Gear (new, from the World screen and the fight's start screen):** six slot tiles. Tapping one lists the
  owned items for that slot with their effects; tapping an item equips it.
- **Fight start screen:** the equipped gear in one row, the curse if any, the consumables to pick, and a
  hint when an owned item is good against this boss ("Plunger of Smiting: ×4 here").
- **Fight:** free misses left and the combo heal show next to the hearts; the curse's icon too.
- **Trophy shelf:** the collection, "12 / 19 items", with the loot still missing as "?".

## 6. Balance
- **Today's numbers:** a hero has 5–12 hearts and deals 1–4 damage; bosses have 16, 22 or 28 health
  (twice that for the Overlord).
- **Gear matters most early:** at level 1, full gear is about the same as 6–8 levels. At high levels,
  bosses already fall fast.
- **Checked by tests:** a fully geared level-1 hero still needs at least 2 echoes against a tier-1 boss (the floor is set while tuning),
  and a fight with every curse effect can still be won without a miss.
- **Tuned on the emulator** before the version is done; prices may move.

## Data (schema v9)
- **`equipped`** (profileId, slot, itemKey): the worn item per slot. Owned items stay in `inventory`.
- **`curses`** (profileId, family, since): at most one row per person.
- **`fights.loot`** (text, nullable): the item a win dropped. It feeds the bad-luck counter and the
  fight history.
- **Setting:** `curses` (bool, default on).
- **Migration:** each person's owned gear is equipped. The four old items sit in four different slots,
  so nobody loses an effect they have today.
- **Backups:**
  - `equipped`: matched by person and slot, the phone's choice wins.
  - `curses`: the phone's row wins.
  - `fights.loot`: travels with its fight row.
  - `inventory` merges as today.

## Code
- **`domain/fight/items.dart`:** the item catalog (key, slot, source, price, effects), loot tables,
  curses.
- **`Loadout`:** built from the equipped items, the picked consumables and the curse. It becomes a
  sum of effects instead of four flags. `EchoDuel` reads only from it.
- **`domain/fight/loot.dart`:** the drop roll and bad-luck counter, as pure functions.
- **Art:** one 16×16 pixel icon per item in `assets/art/items/`, `ui` palette group, built by
  `build_art.py` like the other sprites.

## Tests
- **Effects:** each effect alone and combined, in `EchoDuel`: hearts, damage, Perfect ×3/×4, free misses,
  combo heal at the maximum, sneak attack, slower boss, against-a-boss only against that boss.
- **Slots:** two-handed weapons and shields push each other out; one item per slot.
- **Loot:** chances by tier and with the sock; the 5th win always drops; no duplicates; story mode drops.
- **Curses:** set on a loss only (not story mode); replaced, not stacked; gone after the next fight; lifted
  by a quest of the family and by soap; off by setting; never below 3 hearts.
- **Migration v8 → v9** with real data: owned gear ends up equipped.
- **Backup merge** of `equipped`, `curses` and `fights.loot`.
- **Screens:** Gear, Armory, fight start and result, in English and German, at 200 % font size and
  with TalkBack labels.
- **Emulator:** buy, equip, win loot, lose to get cursed, lift the curse with a quest.

## Not in this version
- **Sets** (a bonus for wearing items that belong together).
- **Items on the hero picture:** with the pixel hero (art step 5).
- **Trading items between people.**

## Version
**0.11.0**, decided 2026-11-02. The beta moves to 0.12.0.
