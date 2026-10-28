# Design draft: Soft screen-time budget

> Status: **core decisions made** (§9) · 2026-10-29
> "Soft" means reminders, never blocking: no accessibility service, no overlay, nothing that stops an app.

---

## 1. Goal

Chores earn screen time. You set yourself a daily budget for the apps that eat your time (games, social,
video). Every finished quest adds a few minutes, and the Armory sells extra minutes for points. The app
tells you when time is running low and when it's used up. Going over makes the hero tired in the Arena
the next day.

**Principles**
1. **Self-control, not surveillance.** It's your own phone and your own budget, with no PIN and no lock.
   You can always switch it off.
2. **Soft.** Reminders and a playful game effect, never a blocked app.
3. **Private.** Usage is read on the phone and never leaves it, like everything else in the app. Only daily
   totals of the chosen apps are kept, with no per-app timeline.
4. **Chores feed it, not the other way round.** Screen time never gives points or XP.

---

## 2. What counts

- **Chosen apps only.** You pick them from a list of installed apps (icon and name). Messaging, maps or
  school apps simply stay unticked. This app never counts.
- **Used time** = the time the chosen apps were in the foreground today, from local midnight.
- Android keeps detailed usage for about a week, so each finished day's total is saved (§6).

---

## 3. The budget

```
today's budget = base budget                       (setting, default 60 min, 0–240 in 15-min steps)
               + minutes earned by quests today    (automatic, see below)
               + vouchers used today               (bought in the Armory)
left           = budget − used today
```

**Earned automatically:** every chore point adds 1/5 of a minute, so a 17-point chore earns 3 minutes,
rounded down per day. The earned minutes are capped at a daily maximum (setting, default 30 min). The
minutes are derived from the day's completions, like tokens, so undoing a chore takes its minutes back.
Points and XP are untouched.

**Vouchers (Armory, consumable):**

| Item | Price |
|---|---|
| Screen time +15 min | 40 points |
| Screen time +30 min | 75 points |

They're bought ahead and used on the screen-time page ("Use voucher"). Used minutes count for today only.
Unused vouchers keep. As with every purchase, spending points never lowers level or XP.

Minutes don't carry over to the next day; each day starts fresh from the base budget.

---

## 4. When time runs low or out

| Moment | What happens |
|---|---|
| 10 minutes left | Notification: "10 minutes of screen time left today." |
| Budget used up | Notification: "Screen time used up. 3 quests left today would earn about 12 more minutes." At most one an hour while over. |
| Daily summary | The existing morning notification adds yesterday's result: "Screen time yesterday: 74 of 90 min." |
| Next day in the Arena | **Tired:** if yesterday went over budget, the hero starts today's fights with one heart less (never below one). A "Tired" note shows on the hero card. It clears after a day within budget. |

Each notification type has its own switch, and they use their own "Screen time" channel, so Android's
per-channel settings work too.

---

## 5. Screens

- **Quests tab:** a slim bar under the points header, shown only when screen time is on:
  "33 min left · 85 today". It turns into a warning style when 10 minutes or less are left.
  Tapping it opens the screen-time page.
- **Screen-time page** (from the bar, and under Settings → Screen time):
  - today: budget made of base, quests and vouchers, then used and left, with a ring or bar
  - "Use voucher" button when you own vouchers
  - today per chosen app, most used first
  - the last 7 days as bars, with over-budget days marked by an icon as well as color
  - settings: on/off, base budget, daily cap for earned minutes, chosen apps, and a switch for each
    notification
- **First time:** a short explanation, then a button to Android's usage-access screen. When you come back,
  the app checks the permission and opens the app picker.
- **Armory:** a "Screen time" group with the two vouchers.
- **Arena:** a "Tired" chip on the hero card and one heart less in fights, with an explanation on tap.

---

## 6. Technical plan

- **Permission:** `android.permission.PACKAGE_USAGE_STATS` ("usage access"). It's granted by the user in
  the system settings (`Settings.ACTION_USAGE_ACCESS_SETTINGS`), not through a dialog. The app checks it
  through `AppOpsManager`.
- **Listing apps:** a manifest `<queries>` entry for launcher activities (`MAIN`/`LAUNCHER`). This avoids
  `QUERY_ALL_PACKAGES`, which Google Play restricts.
- **Native code:** about 200 lines of Kotlin behind a `MethodChannel("screen_time")`, with no new Flutter
  plugin:
  - `hasAccess()` and `openAccessSettings()`
  - `launcherApps()`, which returns the package, label and icon (PNG bytes) of each launcher app
  - `usage(packages, from, to)`, which returns foreground time per package from
    `UsageStatsManager.queryEvents`
- **Background checks:** `androidx.work` `PeriodicWorkRequest` every 15 minutes, which is Android's
  minimum. The worker is native Kotlin, so no Dart runs in the background.
  - The app writes a small **budget snapshot** to `SharedPreferences` whenever something changes: date,
    today's budget, chosen packages, the localized notification texts, and the switches.
  - The worker reads today's usage, compares it with the snapshot (on a new day: the base budget only),
    and posts the warning or over-budget notification.
  - This means notifications can come up to 15 minutes late. That's acceptable for a soft budget.
- **Storage (schema v6):** a `ScreenDays` table (day, used minutes, budget minutes). When the app runs, it
  saves each finished day's totals there. These drive the 7-day history, the Tired effect and the daily
  summary, so Android dropping old usage after about a week loses nothing. 0.8.0's export includes it.
- **Settings (key/value):** enabled, base minutes, earned cap, chosen packages, and the notification
  switches.
- **Vouchers:** two new consumables in `shop.dart`. Using one books its minutes to today, stored with the
  day.
- **Tired:** `HeroStats` gets −1 max HP when yesterday's `ScreenDays` row is over budget. It applies in the
  fight and on the hero card, like gear.
- **Tests:**
  - pure Dart for the budget maths: earned minutes, cap, vouchers, undo and day boundaries
  - Tired
  - the snapshot format
  - widget tests with a fake screen-time channel
  - on the emulator, a real check of usage access and the worker

---

## 7. Privacy and stores

- Nothing new leaves the phone; the app still has no INTERNET permission.
- `PRIVACY.md` will name usage access and exactly what is stored (daily totals of the chosen apps).
- **F-Droid:** fine. `androidx.work` is Apache-2.0, and there are no trackers.
- **Google Play (later):** usage access is sensitive. Before a Play release, check Play's current policy for
  `PACKAGE_USAGE_STATS` and fill in the declaration. Using `<queries>` instead of `QUERY_ALL_PACKAGES`
  keeps the app on the safe side.

---

## 8. Limits (honest)

- Anyone holding the phone can switch it off or revoke usage access; it's self-control by design.
- Notifications can be up to 15 minutes late, and Doze can delay them further.
- Usage on other devices (tablet, TV, PC) isn't counted.
- Profiles (0.9.0) will bring per-person budgets only for people who share this phone. On a shared phone,
  usage can't be told apart by person.

---

## 9. Decisions (2026-10-29)

| Question | Decision |
|---|---|
| Whose screen time | **Self-control**: your own budget, no PIN |
| Earning | **Both**: minutes per chore point (with a daily cap) plus vouchers in the Armory |
| Which apps | **Chosen apps** only |
| When over | **Warning** at 10 min left, **notification** when used up, line in the **daily summary**, **Tired** in the Arena |

**Roadmap (decided):** built as **0.7.0**, in both steps below. Data safety moves to 0.8.0, profiles to 0.9.0 and the beta to 0.10.0.

---

## 10. Milestone proposal

| Step | Content |
|---|---|
| **Screen time 1** | Usage access, app picker, budget with earned minutes, Quests bar, screen-time page, background worker with warning and over-budget notifications, schema v6 |
| **Screen time 2** | Armory vouchers, Tired in the Arena, 7-day history, daily-summary line, `PRIVACY.md` |
