# Better schedules — design

From tester feedback (2026-11-02):
- the two "every few days" options are confusing
- monthly on a weekday ("1st Monday in the month")
- a time window, both as a range of days and as a time of day

The home screen widget from the same feedback is part of this version too (section 5).

## Today
- **Repeat options:** anytime, once, every N days (a fixed rhythm), weekly on set days, monthly on a
  day of the month, and N days after last done (floating).
- **Due:** a quest is due on exactly one day. "On time" (the +20 % bonus) means done on that day,
  and from the next day it's overdue.
- **Reminder:** an optional time of day on due days.

## 1. Clearer names
| Now (EN / DE) | New (EN / DE) |
|---|---|
| Every few days / Alle paar Tage | **Every N days, fixed rhythm** / **Alle N Tage, fester Rhythmus** |
| Some days after last done / Einige Tage nach dem letzten Mal | **N days after it's done** / **N Tage nach dem Erledigen** |

- **Number in the name:** "N" is the number chosen ("Every 3 days, fixed rhythm").
- **Example line:** under the choice, the editor shows the next dates, e.g. "Next: Thu 5 Nov, Sun 8 Nov,
  Wed 11 Nov", or "3 days after it's done: if done today, next on Thu 5 Nov".

The example makes the difference visible instead of explaining it in words.

## 2. Monthly on a weekday
- **Two monthly modes:** **on a date** (as now, "on the 15th") and **on a weekday**, "on the
  1st / 2nd / 3rd / 4th / last Monday … Sunday".
- **Every N months** works for both modes.
- **Data:** `chores.repeatMonthWeek` (1–4, or −1 for the last, nullable). The weekday reuses
  `repeatWeekdays` with a single bit set. `null` keeps the date mode, so existing quests don't change.

## 3. Range of days ("Zeitraum")
"Sometime between the 1st and the 10th", or "sometime this week".
- **Days to do it:** each quest gets a number of days, which can be **1 day** (as now), **2–7 days**,
  or **until the next time**.
- **From the due day:** a window of 10 days on a monthly quest due on the 1st runs from the 1st
  to the 10th.
- **While the window is open:** the quest is open and counts as **on time**, so the bonus applies on
  any day of the window. The tile says "Due until Tue 10 Nov".
- **After the last day:** it's overdue, as today after the due day.
- **"Until the next time":** the window ends the day before the next occurrence.
  - For floating quests ("N days after it's done"), that's N days.
  - A window is never longer than that, so two windows of the same quest never overlap.
- **Weekly on several days:** each day opens its own window, capped before the next chosen day.
- **Data:** `chores.windowDays` (default 1). "Until the next time" is stored as 0 and computed.
- **Anytime and once:** these quests don't get a window. "Once" could later take a window ("by Friday").

## 4. Time of day ("Uhrzeit")
"Between 6 and 8 pm".
- **Times:** each quest can get a start and end time, `windowFrom` and `windowTo` in minutes after
  midnight (nullable).
- **During the time:** the quest shows its times on the tile ("18:00–20:00").
  - **Before the start:** it's listed under "Later today" with its start time.
  - **During the times:** it's under "Today's quests".
  - **After the end:** it's overdue for today, with a note instead of a due label ("Time's up
    (18:00–20:00)").
- **Doing it outside the times still counts.** Points and tokens come as usual. Only the **on-time
  bonus** needs the times (and the day window, if there is one).
- **Reminder:** the existing reminder can be set to "at the start", the default when times are set.
  It can also be its own time as now.
- **Several days:** both kinds of window work together. "Between the 1st and 10th, between 6 and 8
  pm" means on any of those days, in that time.

## 5. Home screen widgets
Three widgets in Android's widget picker, so people choose the look by placing the one they like.
They can also place more than one. The styles came from tester feedback ("text only looks stale",
2026-11-02):
- **Quest board:** rows of quest tiles (icon in the quest's color) with badges: "! 2 days late",
  "▶ today", the start time, "→ Thu".
- **Quest path:** the next four quests as a board-game path, joined by arrows. Labels sit under the
  tiles, and late tiles get a red frame.
- **Next quest:** the next quest large (status, points), then small tiles for the following ones.

**How it works:**
- **The app draws the pictures:** a native widget can't use the pixel font or the icon font. Each
  placed style is drawn as a PNG, by day and at night, for today and the next 6 days, into the
  app's private files.
- **Android picks the picture** for the current day and mode, so the widgets stay right after
  midnight without the app.
- **When it redraws:** whenever quests change, and when the app comes back to the front (a widget
  may have been placed, or the mode changed). Otherwise about every 30 minutes.
- **No wasted work:** nothing is drawn when no widget is placed. A freshly placed widget says "Tap
  to show your quests" until the app has drawn it.
- **Ticking quests off** works in the "All quests" widget (below), not in the three picture
  widgets: a picture has no rows to tap.

### All quests (0.17.0)
A fourth widget, **All quests**, lists every active quest of the current person and scrolls. The
three above stop at what is due (at most 8); this one has no limit.

- **Order:** late, open today, later today, due this week (weekday), due later ("→ 11/27", within
  a year), then quests without a schedule ("Anytime").
- **A real list, made of pictures:** the list itself is Android's (`ListView` with a
  `RemoteViewsService`), so it scrolls. Each row is a picture the app drew, like the other
  widgets, to keep the pixel font and icons. The app writes a heading (`list-<day|night>-head.png`),
  each different row once (`list-<day|night>-row-<n>.png`; most rows are the same all week), and
  per day which rows to show with a text for screen readers (`list-<date>.json`).
- **Day and night:** every picture carries the panel color behind it. Right after the phone
  switches mode, the old pictures stay readable until the next refresh brings the matching ones.
- **Tapping the heading** or the empty text opens the app.

### Ticking off in the widget (0.17.0)
Tapping a quest that is open (late, due today, or anytime) ticks it off. The row turns faded and
crossed out, and its badge says "✓ Undo": tapping it again takes the tick back, for a slip of the
finger. Quests due on a later day can't be ticked; their tap does nothing.

- **The widget only remembers.** Booking a quest means points, the on-time bonus, the streak,
  fight tokens and curses, all of which live in the app's database and its Dart code. The widget
  keeps a list of ticks instead (`widget_ticks.json`: quest, person, day, time, on time or not).
- **The app books them** when it is next opened or comes back to the front, before it draws the
  widgets again: each tick becomes a normal completion **at the time it was ticked**, oldest
  first. Ticks for a quest that was archived or a person who was removed meanwhile are dropped.
- **On time** is decided at the tap: the quest is due today and, if it has a time of day, the tap
  is within it.
- **Undo** in the widget works until the app has booked the tick. After that the quest is done
  like any other and can be undone in the app's history.
- **Limits:** until the app is opened, the coin count in the heading doesn't move, and the next
  day's list is still the one drawn before the tick (a daily quest ticked yesterday shows as late
  until the app has booked it). Opening the app sets both right.

## On time, in one rule
A completion is on time if it's on a day inside the open window and, when times are set, inside the
times. That's the only rule the points formula needs (`onTime` in `pointsFor`). Streaks don't change:
they count days with any completion.

## Where it shows
- **Quests tab:** the due label shows the window's last day ("Due until …"), the times, or "Time's up".
  Sections stay the same; "Later today" is a new group only when times are set.
- **Quest Log:**
  - Week view: a quest is listed on every day of its window, with "(window)" on the days after the first.
  - Month view: the window counts once, on its first day.
- **Notifications:**
  - The summary counts quests whose window is open today.
  - A reminder only comes while the window is open and the quest isn't done.
  - The "overdue" count uses the window's end.
- **Leaderboard, fights and screen time:** unchanged. On-time bonuses follow the new rule.

## Data (schema v8)
- **Chores:** `repeatMonthWeek` (int, nullable), `windowDays` (int, default 1), `windowFrom` and
  `windowTo` (int, nullable).
- **Migration:** existing quests keep their behaviour: date mode, a 1-day window, no times.
- **Backups:** these are chore columns, and the phone's chore wins when matched, so the merge needs no
  new rule.

## Tests
- **Recurrence, the most important part:**
  - next due day and window end for every repeat type with windows of 1, 3, 7 days and "until next"
  - the cap before the next occurrence
  - the 1st/2nd/3rd/4th/last weekday in months of every length
  - leap years and DST changes
- **On time:** inside and outside the day window and the times; the edges, such as the last day, the
  end minute and midnight.
- **Sections:** later today / due / time's up / overdue.
- **Notifications:** reminders only while open; the summary counts.
- **Editor:** the example dates for each repeat type in English and German; 200 % font size.
- **Migration v7 → v8** with real data. On the emulator, a quest of each kind over a simulated day.

## As built (changes to the plan)
- **Reminders:** they keep their own time. There's no separate "at the start" mode; with times set,
  the reminder can simply be set to the start time.
- **Times past today's end with days still left** show under "Side quests" as "Tomorrow
  18:00–20:00". "Time's up" is only for the window's last day.
- **Quest Log:** days after a window's first day show the quest with "Still open"; the month view
  counts it only on its first day.
- **Widget symbols:** "▶" and the arrows are drawn as shapes, not text. The phone's font may not have
  them, and Android then shows an emoji instead.
- **Widget date formats:** the sync loads them itself before drawing, because Flutter may not have
  loaded them yet at startup.

## Version
**0.10.0**, decided 2026-11-02. The beta moves to 0.11.0.
