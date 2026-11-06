# Round rules — design

**Goal:** two points from the testers (2026-11-06):
1. Against the bosses, a wrong tap no longer costs a heart. A heart is lost only after a round
   (one attack) with less than 50 % accuracy.
2. A round damages the boss only if it reaches 50 % accuracy or more.

**Why:**
- **Fewer hearts lost:** today every missed beat and every stray tap costs a heart. One shaky
  round of a long pattern can cost three or four hearts, which feels harsh for children.
- **Rounds that count:** today a round with mostly misses still chips at the boss. With the 50 %
  line, a round is either an attack that lands or one that fails, which is easy to understand.

## Decisions (2026-11-06)
| Question | Decision |
|---|---|
| Which fights | **All echo rounds:** the eight bosses and the Overlord's two echo phases. The Overlord's lane phase has no rounds and stays note by note. |
| Round accuracy | **Perfect 1, Good ½, Miss 0**, like the accuracy shown after a fight. A round needs **50 % or more**. |
| Shields and the Garden Gnome | **They protect failed rounds** instead of misses. |
| Story mode | **Every hit still counts** (no 50 % line), and no hearts are lost, as before. |

## 1. A round
- **Accuracy:** (Perfect + ½ × Good) ÷ the number of judgements. Stray taps count as a miss each,
  as they do now. So tapping wildly can't reach 50 %.
- **A landed round (50 % or more):**
  - Each Perfect and Good deals its damage as now: gear, Perfect multiplier and sneak attack.
    Misses deal nothing.
  - No heart is lost, even if the round had misses.
- **A failed round (under 50 %):**
  - No damage at all.
  - **One heart** is lost, however many misses there were.
- **Combo and heals:** unchanged. A miss still breaks the combo, and combo heals still count hits
  in a row.
- **Statistics:** Perfect, Good and Miss are still counted per beat, for the result screen and
  the best accuracy.

Examples (4 beats):

| Round | Accuracy | Result |
|---|---|---|
| ✓ ✓ ✓ ✗ | 75 % | hits, no heart lost |
| ◎ ◎ ◎ ◎ | 50 % | hits |
| ✓ ✓ ✗ ✗ | 50 % | hits |
| ✓ ◎ ✗ ✗ | 38 % | fails: no damage, 1 heart |
| ✓ ✓ ✓ ✓ + 4 stray taps | 50 % | hits |

## 2. Gear
- **Sponge Shield / Trash-Can Lid** (`free_misses`): the first 1 / 2 **failed rounds** of a fight
  cost no heart.
- **Garden Gnome** (`third_miss_free`): every third **failed round** costs no heart.
- **In the lane phase** each missed note still costs a heart, so there a missed note counts as
  a failed round for the shields and the Gnome. This keeps one rule: they protect a heart loss.
- **Everything else** is unchanged: Perfect multiplier, extra damage, combo heal, sneak attack
  (now only on a round that lands), slower boss and loot chance.
- **The effect names in `game/items.toml` stay the same** (keys are stored), and only their
  phrases change: "forgives your first failed round in every fight" / "every third failed round
  costs no heart". The fight's footer reads "1 free round" instead of "1 free miss".

## 3. In the fight
- **The judgement line** adds the round's accuracy and what it did:
  - "Perfect 2 · Good 1 · Miss 1 · 62 % hit" when the round lands
  - "Perfect 1 · Good 0 · Miss 3 · 25 % failed" when it fails
  - German: "… · 62 % Treffer" / "… · 25 % daneben"
- **On the timeline**, a landed round's judgement marks stay as they are. A failed round
  additionally shows a crossed line through the track, so it's visible by shape, not only by
  color.
- **The boss** shows its hit pose only after a landed round. **The hero** hops after a landed
  round and shakes after a failed one.
- **Story mode** shows the accuracy too, but never "failed".

## 4. Balance
- Boss health, tiers, timing and difficulty stay the same. A fight now needs rounds that land,
  so a careless player deals less damage, and a careful one loses fewer hearts. Checked on the
  emulator on Easy, Balanced and Hard.
- The tool's numbers (`game/balance.toml`) get one new value: `rounds.hit_accuracy = 0.5`, so
  the line can be tuned without code.

## Tests
- **The round rules:** landed and failed rounds, exactly 50 %, stray taps, one heart per failed
  round whatever the misses, no damage under 50 %, sneak attack only on a landed round, story mode.
- **Shields:** free failed rounds in echo phases, free missed notes in the lane phase, the Gnome
  on every third failure.
- **Existing tests:** fight tests that count hearts per miss change to rounds.
- **Emulator:** fights on all three difficulties, a shield and the Gnome, the Overlord, story mode,
  German at 200 %.

## Version
**0.14.0**, decided 2026-11-06. The beta moves to 0.15.0.
