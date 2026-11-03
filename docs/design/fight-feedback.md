# Fight feedback — design

**Goal:** three points from the first testers (2026-11-03):
1. A visual indicator for the rhythm rounds.
2. Bought and looted gear visible on the hero.
3. A separate start button before the boss plays its rhythm.

**Why:**
- **Indicator:** the beat dots are evenly spaced, so they show *how many* beats come, not *when*.
  Without sound, or for someone who reads rhythm better than they hear it, there is nothing
  to follow.
- **Start button:** a round starts 1 s after the last one was judged. A child who looks up at the
  hearts or the result misses the boss's call.
- **Gear on the hero:** gear only shows as icons on the Gear screen. The hero looks the same with
  or without it, which takes away half the fun of loot.

## Decisions (2026-11-03)
| Question | Decision |
|---|---|
| Indicator | **Timeline with a playhead.** The dots sit at their real times, and a line sweeps across during the boss's call and again during your echo. |
| Start button | **Before every round,** including the Overlord's lane phase. |
| Gear on the hero | **A pixel hero with gear layers** (art step 5, hero only). Every gear item and hat gets an on-hero sprite, and the hero appears on the fight screen too. |

## 1. Start button
- **New stage:** `FightStage.ready`, between rounds: after the intro, after each judgement while
  the fight goes on, and after a pause or a Second Wind (`resume()`).
- **Where:** the button takes the pad's place, the same size and in the same spot, so the thumb
  is already where the echo is played.
  - It reads "Show rhythm" ("Rhythmus zeigen").
  - Before the Overlord's lane phase it reads "Start" ("Los").
- **After the tap:** the call starts after a short 400 ms lead, so the finger can come off the
  screen.
  - A double tap is safe, because the pad ignores taps during the call, as it does now.
- **No pressure:** the fight waits as long as needed. Waiting changes nothing that's judged or
  stored.
  - Leaving the app still abandons the fight, as it does now.
- **The judgement stays visible** while the button waits. Nothing is pushed off screen, so you can
  read your hits before going on.
- **Accessibility:** it's a real button with its label, so TalkBack users get control over when a
  round starts, which they didn't have before.
- **Always on,** with no setting.

## 2. Timeline with a playhead
```
Boss plays:   ●    ●  ●       ●            dots placed by time, lit when played
              ─────┃──────────────          playhead sweeps from 0 to the phrase's length
Your turn: ·  ◉    ◉  ○       ○            · = the count-in, one pulse before
              ──────────┃─────────          filled = tapped
Judged:       ✓    ◎  ✗       ✓            icon + text as now, at each dot
              ╵   ╵       ╵    ╵            ticks: where you actually tapped
```
- **Track:** the same width for every pattern, spanning one phrase (`Pattern.lengthMs`). Dots sit
  at `beatsMs[i] / lengthMs`.
  - Faint pulse ticks under the track show the beat grid, so off-beats read as "in between".
- **Playhead:**
  - **Call:** runs from 0 to the phrase's end, in step with the boss's beats.
  - **Echo:** starts one pulse early, at the count-in mark, so the first due beat is reached
    exactly when the first tap is due.
  - **Smooth motion:** driven by a `Ticker` from the controller's start time, not by stepping a
    timer, so it doesn't drift.
- **Echo:** dots fill in the order of your taps, as now: filled with an outline versus hollow,
  never color alone.
- **Judged:** the icons and words stay (✓ Perfect, ◎ Good, ✗ Miss), now under their dots. A
  small tick marks each actual tap, so "early" and "late" are visible.
  - The ticks are visual only. TalkBack keeps the existing spoken result.
- **What it changes about the game:** you could tap along with the playhead instead of
  remembering, since the dots stay visible during the echo. This is accepted:
  - the boss's call still sets the rhythm
  - fast tiers and off-beats are still hard to read in time
  - it helps exactly the players who asked for it
- **Calibration:** taps are still corrected by the calibrated delay. The playhead shows the true
  beat times.
- **Reduce motion:** with the system's "remove animations" on, the playhead jumps from pulse to
  pulse instead of sliding.
- **Space:**
  - Up to 8 beats, with half-pulse off-beats, on a phone 320 dp wide: dots are 16 dp, with at
    least 4 dp between them. Below that, dots shrink to 12 dp.
  - Tested at 200 % font size, where the track keeps its width and the labels wrap.
- **The Overlord's lane phase** keeps its falling notes. It already has an indicator.

## 3. Pixel hero with gear layers
### Art
```
assets/art/hero/base.png          32×32, the hero, palette group hero
assets/art/hero/wear/<key>.png    32×32 layer per gear item and hat, palette group items
```
- **Same canvas:** every layer is 32×32 on the base's canvas, transparent where the item isn't.
  So layers line up without offsets.
- **The base** uses key colors from a new `hero` palette group: `skin`, `skin_shade`, `hair`,
  `hair_shade`, `cape`, `cape_shade`, plus fixed outline, eye and clothes colors.
  - At runtime the key colors are replaced by the person's Wardrobe colors. The shades are
    derived by darkening.
  - Each (sprite, palette) pair is cached, as with season tiles.
  - The Wardrobe keeps its 5 skins, 6 hair colors and 6 capes. Nothing stored changes.
- **Wear layers** use the items palettes, day and night like the icons, so a layer matches its
  icon.
- **A rule** `"hero/wear/*"` in `art.json`, as with `items/*`.
- **I draw** the base, the 4 hats and the 19 gear layers in the style of the item icons.
  - The bosses stay vector for now; they're a separate step.

### Drawing order
Back to front:
1. cape (part of the base)
2. body
3. feet
4. charm, at the belt
5. shield
6. the hat or head gear: **worn head gear covers the hat**, and the hat comes back when it's taken off
7. weapon

- **Two-handed weapons** are drawn held across both hands; the shield is off anyway.
- **The order is in code** (`wearLayers(loadout, hat)`): one function, with tests.

### Where the hero shows
- **Same widget everywhere:** `HeroArt` keeps its API and gains `wear`, so every place that shows
  the hero now shows the gear:
  - the map
  - People
  - the Wardrobe
  - the Armory list
  - the Gear screen
- **The Gear screen** shows a larger hero at 4×, next to the slots. Changing an item changes the
  hero at once.
- **The fight screen:** the hero at 2× next to the hearts. It does a short bounce on a hit and a
  shake on a miss.
  - With reduce motion on, it holds still.
- **The Armory's preview:** a gear item's tile shows the hero wearing it, as the hats do today.
- **Integer scaling only**, as all sprites, so pixels stay sharp.

### Game data
- **No new fields.** A layer is found by the item's key, the same way as its icon.
- **`build_game_data.py`** checks that every gear item and hat that isn't retired has
  `hero/wear/<key>.png`, and says so by name.
  - The README's "Adding a piece of gear" gains this drawing as a step.
- **A new hat** still needs its `look` number, but no longer any code in `hero_art.dart`: the
  layer is enough.

## Tests
- **Controller:**
  - The fight waits in `ready` after the intro, after each judgement and after `resume()`.
  - The call starts only after the start button.
  - A pad tap in `ready` does nothing.
- **Timeline:** dot positions are proportional to the beat times, the playhead's position at a
  given clock time is right, and the count-in mark comes one pulse before.
- **Wear layers:** the drawing order, head gear covering the hat, two-handed weapons, and that
  unknown or retired keys are skipped.
- **Art:** the art test covers the new sprites, and `--check` fails on a missing layer.
- **Emulator:**
  - a whole fight with the button, light and dark
  - the playhead with sound off
  - 200 % font size, in German
  - TalkBack on the start button
  - the hero with full gear and a two-handed weapon on every screen

## As built (changes to the plan)
- **No "get ready" before the first button:** the fight opens on the start button. After the
  tap, a 400 ms "get ready" leads into the call (it was 1.5 s without the button).
- **The button** stacks the icon and one word per line, shrunk to fit, so "Rhythmus zeigen" never
  breaks mid-word at 200 %.
- **Dots** go down to 10 dp when beats sit close, not 12.
- **The judgement's words** stay in the status line ("Perfect 1 · Good 0 · Miss 1"). The timeline
  shows the icons only, because words under close dots would overlap.
- **Not done:**
  - The map's tiny hero stays drawn in code, without gear: 32×32 doesn't fit a 16-pixel tile.
  - The Armory's gear tiles keep their icons. A hero in each tile would be too small to tell
    the items apart.
- **The Arena card's hero** is 96 dp (3×) and the fight's 64 dp (2×). Below 32 dp (the Wardrobe's
  hat chips) the hero scales down evenly.
- **The layers' colors** match their icons (the cape and the apron were changed for that).

## Also in 0.13.0: the rest of the art (2026-11-03)
So that everything looks the same, the last vector and font art was redrawn as pixel art:
- **Bosses:** 48×48 strips of four frames, ported from the old shapes, so each boss keeps its
  silhouette. The fight's boss bobs on its beats.
- **Quest icons:** 45 icons plus a fallback, 12×12 in the mask palette. The keys stay the same, so
  stored quests keep their icons.
- **Trophy:** pixel art, in the ui palette.
- **Level coin:** a blank coin with the level stamped on it in 3×5 pixel digits, up to 99. From
  100 on, it shows the plain coin.
- **UI icons:** the remaining Material icons were redrawn too, 12×12 in the mask palette
  (`assets/art/ui/`), including Flutter's back arrow and the segmented buttons' check mark (set in
  the theme). Only the platform's own controls (switches, checkboxes, dropdown arrows) stay as
  they are.
- **Three quest icons** were redrawn after the testers' look, from options shown first: recycling
  (a bottle into a bin), the fridge (with a spray bottle) and folding laundry (a T-shirt). All
  icons are centered automatically.
- **Clutter Gremlin:** the English name "Clutter Imp" read as "lmp" in the app's font.

## Version
**0.13.0**, decided 2026-11-03. The beta moves to 0.14.0.

Order of work:
1. Start button.
2. Timeline.
3. Hero base sprite and palette swap.
4. Wear layers.
5. The hero on the fight and Gear screens.
