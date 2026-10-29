# Profiles (0.9.0)

**Goal:** a household shares one phone. Each person has their own points, level, streak, hero,
fights and Armory. Chores can belong to the household, to one person, or to each of several
people. The Hall of Fame compares everyone's week.

## What exists already
Every completion, ledger entry, fight, inventory item and screen-time day carries a `profileId`
(since 0.1), and the data providers already filter by `currentProfileIdProvider`. That provider
is fixed at startup to the first profile, "Me". Backup import already matches profiles by name and
adds missing ones. So most of the per-person split is there; what's missing is choosing the
person, assigning chores, and the household-wide parts.

## Decisions (2026-10-29)
| Question | Decision |
|---|---|
| Chores and people | Per chore: **anyone** (done once for the household; whoever does it gets the points), **one person**, or **each of** chosen people (everyone does their own). |
| Switching | **Free**: tap the avatar in the top bar and pick a person. No PINs. The app remembers the last person. |
| Screen time | **Only with a single profile.** Usage is measured per phone, so with several people screen time is turned off (and can't be turned on). |
| Hall of Fame | A **leaderboard** of the week, shown when there are two or more people. |

## Data (schema v7)
- **`profiles`** gets:
  - `avatarSkin`, `avatarHair`, `avatarCape`, `avatarHat`, moved out of settings so every hero looks
    different
  - `storyMode` and `slowMode`, so a child can fight with easier settings than an adult
  - `archivedAt`: removing a person hides them but keeps their history (for backups and the
    leaderboard's past weeks)
- **`chores.assignment`**: a text enum `anyone | one | each`, default `anyone`.
- **New `chore_assignees (choreId, profileId)`**, keyed on both columns: the person for `one`, or
  the people for `each`.
- **Migration v6 → v7:** every chore becomes `anyone`. The avatar and the story/slow mode settings
  are copied to the first profile and removed from settings.
- **Settings stay per device:**
  - look, language, notifications, fight sound, vibration and timing calibration
  - the new `currentProfile` key, which a backup merge never takes over (added to `deviceOnlySettings`)

## Who sees which quest, and when it's due
| Assignment | On whose Quests tab | Due from … | Points to |
|---|---|---|---|
| anyone | everyone's | the latest completion **by anyone** | whoever completes it |
| one | the assignee's only | the assignee's completions | the assignee (others don't see it) |
| each | every chosen person's | **that person's own** completions | that person |

- An **anyone** chore that someone did today shows as done for everyone, with who did it
  ("✓ Sam"). Others can still tap it, as with any repeatable chore today.
- **Overdue** follows the same rule: an anyone chore is overdue for the household, a personal one
  for its person.
- **Streaks, XP, level, balance, fight tokens, the weekly Overlord and the quest map's hero** stay
  per person, from that person's own completions.
- **The Quest Log** shows the current person's quests by default, with a filter for "everyone".
- **Manage chores** lists all chores, each with a small "anyone / name / names" label.

## Switching and people
- **Top bar:** the current person's avatar head sits on the right of the main tabs' app bar. Tap it
  for a sheet listing everyone (avatar, name, level) plus "Manage people". TalkBack reads "Switch
  person, current: Sam".
- **Settings → People:**
  - add a person: name, color, avatar
  - rename, change color or avatar
  - remove a person, after confirming, as long as one person remains
  - Names must be unique, ignoring case, because backups match people by name.
- **Removing a person:**
  - chores only they were assigned (`one`) become `anyone`
  - they're taken out of `each` chores, and an `each` chore with nobody left becomes `anyone`
  - their history stays in the database
- **Switching** changes every per-person screen at once, because all of those providers watch the
  current profile. The undo in the "quest done" snackbar is tied to the person who completed it,
  not to whoever is current when it's tapped.

## Screen time with several people
- **The setting:** while there's more than one person, the screen-time switch is disabled, with the
  note "Screen time works with one person on this phone".
- **Adding a second person while screen time is on:** a confirmation dialog says screen time will
  turn off. Confirming turns it off: the background check stops, and the saved days stay.
- **Effects:** Tired, the Quests bar and the vouchers in the Armory all follow the setting, so they
  disappear.

## Leaderboard (Hall of Fame)
- **When it shows:** with two or more people, as a card at the top of the Hall of Fame named "This
  week". It covers Monday to Sunday, like the Overlord.
- **Rows:** everyone ranked by **points earned this week** (completions only; spending doesn't
  lower it). Each row shows rank, avatar, name, points and quests done.
- **Ties** share a rank. The leader gets a pixel crown.
- **Last week's winner** is shown underneath, as one line.
- **Accessibility:** ranks are also given as text ("1st"), never only by color or position.

## Notifications
- Reminders and the daily summary cover the whole household, because the phone is shared. With
  two or more people, a person's own chores are named, as in "Trash (Sam)".
- The weekly recap names the week's leader.

## Backups
- **Profiles:** the merge already matches people by name. A new profile now arrives with its
  avatar and fight modes.
- **Assignees:** the union of both sides' rows for a matched chore. The chore's assignment kind
  follows the existing rule that the phone's version of a chore wins.
- **`currentProfile`** is never merged.

## Tests
- **Due logic:**
  - an anyone chore done by Sam isn't due for Alex
  - a chore Sam does for himself doesn't affect Alex
  - an each chore stays due for Alex after Sam did his
  - one chores are invisible to others
  - overdue, done-today and "✓ name" follow the rules above
- **Switching:** balance, level, streak, Arena, Armory and avatar change with the person, and the
  choice survives a restart.
- **Removing a person:** assignments are cleaned up, history is kept, and the last person can't
  be removed.
- **Migration v6 → v7** with real data: avatar and modes move to the profile, and chores become anyone.
- **Screen time:** turns off when a second person is added, and can't be turned back on.
- **Leaderboard:** ranking, ties, the week boundary, and that spending doesn't count.
- **Backups:** merging profiles with avatars, and assignees.
- **Accessibility audit:** the People page, the switcher sheet and the leaderboard card.
- **On the emulator:** two people, an anyone/one/each chore each, switching, the leaderboard, and
  screen time turning off.

## As built (changes to the plan)
- **People page:** only name, rename and remove. A person's hero is edited in the Wardrobe after
  switching to them. The planned color choice was left out: nothing uses a person's color yet.
- **Weekly recap:** it doesn't name the leader. It's scheduled days ahead, so it would name
  whoever leads now; the streak is left out of it for the same reason. Recaps count the
  household's quests.
- **Screen time:** gated by one rule, "on and a single person" (`screenTimeActiveProvider`),
  so it also stays off if a backup's settings switch it back on.
- **Quest Log filter:** "Everyone's quests" covers today and coming days. Past days show the
  current person's history.
- **Leaderboard crown:** a new sprite (`icons/crown.png`), added through the art pipeline.

## Order of work
1. Schema v7, migration and the profile repository. Current profile as a persisted notifier.
2. Assignment model, due logic and the Quests tab (visibility, "✓ name").
3. Switcher in the top bar and Settings → People. Avatar and fight modes per person.
4. Chore editor: assignment picker. Manage chores labels. Quest Log filter.
5. Screen-time gating, then the leaderboard.
6. Notifications naming, backup merge, docs and the emulator check.

## Open points
- **Onboarding:** it still creates one person named "Me". A "Who uses this app?" page could ask for
  names on first start; it could also come later.
- **Rotating assignments** (e.g. trash duty changing weekly) were left out; `chore_assignees`
  could carry an order for them later.
