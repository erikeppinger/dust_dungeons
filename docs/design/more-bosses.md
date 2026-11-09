# More bosses — design

**Goal:** more bosses, so fights stay entertaining. The project owner decided on **both** directions
(2026-11-08, see [weekly-overlords.md](weekly-overlords.md), section 5):
1. **New chore bosses** for groups of chores that have no boss of their own yet.
2. **Stronger forms** of the existing bosses as you beat them more often.

**Why:**
- **Eight bosses wear out:** someone who does the same chores every week meets the same two or
  three bosses all the time. Dusting always means the Dust Bunny King.
- **Some chores don't fit:** homework, pets, the garden and cooking land with `clutter` (your own
  quests) or `outside`. A boss that matches the chore is half the fun.
- **Tiers are only a number:** after 3 and 8 wins a boss reaches tier 2 and 3. It gets tougher
  but looks the same, so a boss beaten 20 times feels no different from the first fight.

## Decisions (2026-11-08)
| Question | Decision |
|---|---|
| Order | **All at once:** the four new bosses and the forms in one version. |
| New bosses | **All four:** homework, pets, garden, cooking. |
| New built-in quests | **Archived as suggestions,** with a question in onboarding. |
| Sleeping bosses | **As proposed:** bosses no active chore feeds sleep in a row at the end of the Arena. |
| Forms | **Tiers 2 and 3** only. |
| Form traits | **Yes,** small rhythm changes per form. |
| Version | **Before the beta:** 0.16.0; the beta moves to 0.17.0. |

## How it works today
- **Families:** `BossFamily` (`lib/domain/fight/boss.dart`) has eight chore bosses and the
  Overlord. The values are stored by name in `chores.boss_family`, `fights.family` and
  `profiles.curse_family`, so they can only be added, never renamed or removed.
- **Which boss a chore feeds:**
  - A chore can choose its boss in the chore editor (`boss_family`).
  - If it doesn't, `Chore.family` falls back to the built-in quest's boss (`seedFamilies`, from
    `game/quests.toml`). Your own quests fall back to `clutter`.
  - The fallback is read live. So **changing a built-in quest's boss in `quests.toml` moves its
    past completions too**, and with them the tokens: `FightProgress` counts tokens as completions
    minus fights started, per boss.
- **Built-in quests** missing on a phone are added on every start (`_ensureDefaults`). A new
  built-in quest appears on every phone after an update.
- **Tiers:** `tierForWins` with `bosses.tier_wins = [3, 8]`. A tier adds health
  (`health_per_tier`) and tempo (8 BPM per tier in `beatMsFor`), and raises the loot chance.
- **Per boss:** a name, which chores feed it, an optional trophy, a tempo (BPM, offbeat and eighth
  chances), a curse, a 48×48 strip of four frames (`assets/art/bosses/<family>.png`), and loot that
  only it drops.
- **The Arena** shows the chore bosses two per row, then the trophy shelf. **The Overlord**
  borrows the rhythms of the bosses beaten that week and appears after 5 wins, whichever bosses
  they were.

## Part A: new chore bosses

### Candidates
| Key | Boss | Fed by | How it plays | Curse | Loot idea |
|---|---|---|---|---|---|
| `homework` | **Paper Pile Lich** / Papierstapel-Lich | homework, studying, reading | Steady, long rhythms: few eighths, more beats | Smudged Notes: tight timing | Highlighter Wand (weapon) |
| `pets` | **Fur Ball Beast** / Fellknäuel-Biest | feeding, walking, litter, cages | Bouncy: many offbeats | Shedding: a heart | Squeaky Toy Charm (charm) |
| `garden` | **Weed Wyrm** / Unkraut-Lindwurm | weeding, mowing, watering outside | Slow and heavy, rare bursts of eighths | Thorny Gloves: weapon slot off | Hedge Shears (two-handed) |
| `cooking` | **Pot Gremlin** / Topf-Gremlin | cooking, meal prep, baking | Fast, many eighths | Burnt Fingers: weapon slot off | Oven-Mitt Shield (shield) |

The names and texts are suggestions. Every name is written as an English and German pair, as
always.

### The built-in quests
- **Existing quests keep their boss.** Moving `water_plants` from `outside` to `garden` in
  `quests.toml` would move every past completion with it, and could leave `outside` in debt for
  tokens that were already spent. So:
  - **New built-in quests** feed the new bosses: for example "Do homework", "Feed the pets",
    "Walk the dog", "Weed the garden", "Cook a meal".
  - **Existing chores** can be moved by hand in the chore editor, as today. From then on they feed
    the new boss, and their earlier completions stay with the old one. The editor's boss picker
    lists the new bosses.
- **New built-in quests start archived.** Not every home has pets or a garden. They wait under
  Manage chores → Archived ("Suggested quests"), and one tap brings a quest in. New installs ask
  once in onboarding: "Do you have pets? A garden? Homework?"
  - The alternative is to add them like every built-in quest so far: active on every phone, to be
    archived where they don't fit. Decision 3.

### In the Arena
- **Twelve bosses** don't fit two per row on one screen. Bosses with **no active chore** feeding
  them **sleep**: they're listed small in one row at the end ("Sleeping: …"), with their art in its
  defeated pose. Tapping one explains which chores wake it.
- Bosses that have tokens come first, in the usual order.
- The quest map, the realm and the trophy shelf need no change: they show whichever bosses were
  beaten.

### The Overlord
- Nothing changes: it still appears after 5 wins and borrows the rhythms of the bosses beaten
  that week, new ones included.

### Data and code
- `BossFamily` gets the new values at the end. Then `game/schema/bosses.json`, `game/bosses.toml`
  (name, fed by, tempo, curse, optional trophy), the loot in `game/items.toml`, new quests in
  `game/quests.toml`, and `choreFamilies`.
- **Art:** one strip of four frames per boss, plus a main and a light color (each with a shade) in
  `bosses.gpl`. Each also needs a distinct silhouette, so color is never the only signal.
- **No database change:** the families are stored as text.
- **Older app versions** can't read a backup with a new boss (an unknown enum name). Backups
  already refuse newer schemas, but this is the same schema. So a backup with new bosses should
  bump the schema version, so older versions refuse it cleanly instead of crashing. A schema
  version bump with an empty migration is enough.

## Part B: stronger forms

### When a boss changes form
- **The forms follow the tiers:** tier 1 is the boss as it is, tier 2 (3 wins) its second form,
  tier 3 (8 wins) its third. So the existing rule and data stay. Each person sees their own
  progress, because tiers come from that person's wins.
- **Optional, more tiers:** a tier 4 after 15 wins and a tier 5 after 25, so dedicated players
  keep meeting new forms. That's more art and more balancing. Decision 5.

### What a form changes
- **Look:** an overlay drawn on top of the boss, using the same idea as the Overlord's parts:
  - `assets/art/bosses/forms/<family>_<tier>.png`, a strip of four frames, transparent where the
    boss shows through. For example, the Dust Bunny King's crown becomes an emperor's crown with a
    cape; the Sink Kraken grows a captain's hat and more tentacles.
  - **Darker colors:** each boss's four colors are key colors, swapped for a darker or more vivid
    scheme per form, the same way as the Overlord's schemes (`overlordColors`).
- **Name:** whole pairs per form in `bosses.toml`, for example:
  - Dust Bunny King → **Dust Bunny Emperor** (Staubhasen-Kaiser) → **Dust Bunny Overlord of the Rug**
    (Staubhasen-Herrscher des Teppichs)
  - Pairs, not "Mighty" + name, because German adjectives would need the boss's gender
    ("Mächtiger König", "Mächtige Hydra").
- **Trait:** a small rhythm change per form, like the Overlord's traits (`BossTrait`,
  renamed to `BossTrait` and shared): for example tier 2 adds offbeats, tier 3 one more beat. They
  stack on the tier's existing health and tempo. Decision 6.
- **Trophy:** the trophy shelf names the highest form beaten ("Dust Bunny Emperor beaten") and the
  trophy turns from bronze to silver to gold. The trophy art gets three color variants.
- **Unchanged:** curse, loot table, which chores feed it, difficulty, story mode and slow mode.

### Where forms show
- Arena boss cards, fight start screen, fight screen, result screen ("A new form: Dust Bunny
  Emperor!"), the chore editor's boss picker (the base form), the quest map's lairs and the realm
  (the form at the time of the fight: tiers are stored in `fights.tier`, so no new column).

### Data and code
- `game/bosses.toml`: per boss `forms = [{ name, scheme, trait }, …]` for tiers 2 and 3.
  `tool/build_game_data.py` checks that every boss has every form and its overlay file.
- `BossArt` takes a `tier` and paints the overlay and the scheme. `bossName` takes the tier too.
- The Overlord has its weekly looks and gets no forms.

## Order and size
1. **Forms for the eight bosses** first: it improves every fight right away, needs no new quests,
   and is about 16 overlays, 16 schemes and 16 name pairs.
2. **Then the new bosses,** two at a time (homework and pets first). Each new boss also gets its
   two forms. Each needs a strip, two overlays, loot, quests and texts.

## Tests
- **Forms:** the tier picks the form; names exist in English and German for every boss and form;
  every overlay exists with four frames; traits stack on the tier's tempo and health.
- **New bosses:** tokens from new built-in quests; moving a chore to a new boss leaves its earlier
  completions with the old one; the new bosses' loot drops only from them.
- **Arena:** sleeping bosses (no active chore) sit in the last row and wake up when a chore feeds
  them.
- **Backups:** a backup with new bosses is refused cleanly by the version before.
- **Emulator:** every form in a fight (hit, defeated), the Arena with sleeping bosses, the chore
  editor's picker, German at 200 %.

## As built (changes to the plan)
- **Names and loot:** Paper Pile Lich (Highlighter Wand), Fur Ball Beast (Squeaky Toy), Weed Wyrm
  (Two-Handed Hedge Shears), Pot Gremlin (Oven-Mitt Shield). The pets curse is "Fur Everywhere".
- **12 suggested quests,** three per new boss. `water_plants` (indoor plants) stays with `outside`.
- **Manage quests** lists the suggestions in their own section, "Suggestions", below Archived.
- **Onboarding:** the chores page ends with "Anything else at home?" and four check boxes
  (homework and reading, pets, a garden, cooking). Skipping onboarding brings in nothing.
- **Sleeping:** a boss with no tokens and no active quest (any person's) feeding it. Clutter sleeps
  too when there are no own quests. The dialog's button brings in that boss's suggestions; a boss
  without suggestions only explains.
- **Forms' look:** the overlays are headgear (a band, spikes, a crown or horns, placed on the top of
  the boss's main mass in every frame) and, at tier 3, embers along the upper outline. The colors
  carry most of the change.
- **The new-form message** shows the next form's art and name on the result screen after the win
  that reaches tier 2 or 3.
- **Trophies:** bronze for tier 1, silver for tier 2, gold for tier 3. The Overlord's crown and
  holiday trophies stay gold.
- **The palette limit** went up from 62 to 81 colors (more characters in the generated sprite
  rows): the bosses palette has 63 now.
- **Schema 12** has no migration step: it only marks backups with the new bosses.
- `OverlordTrait` became `BossTrait`, shared by Overlord bodies and boss forms.

## Version
**0.16.0**, decided 2026-11-08. The beta moves to 0.17.0.
