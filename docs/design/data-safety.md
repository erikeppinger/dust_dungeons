# Data safety (0.8.0)

**Problem:** everything lives in one database on the phone. Uninstalling, a broken phone or a
factory reset loses all chores, history, points and trophies. There is no cloud and there won't
be one.

**Goal:** the user can save a backup file, bring it back (also on a new phone), and let the app
write a backup every day to a folder of their choice, which can be one a sync app like Syncthing
or Nextcloud already syncs.

## Decisions (2026-10-29)
| Question | Decision |
|---|---|
| Format | **A copy of the SQLite database** (a snapshot taken with `VACUUM INTO`). It's exact and needs no serializer to maintain, and older backups open through the schema migrations the app already tests. |
| Import | **Merge into the current data.** Importing adds what the backup has and the phone doesn't; it never deletes. Importing the same file twice changes nothing. |
| Safety | Before every import the app takes its own snapshot, so the last import can be **undone**. |
| Automatic backups | **Daily, keep the last 7**, written to a folder the user picks. |
| Android's own backup | **Left on** (Android's default): phone-to-phone transfer, and the user's Google backup if they enabled it in Android. PRIVACY.md says so. |

## What's in a backup
The whole database: chores, completions, the point ledger, fights, inventory, screen-time days,
profiles and settings. Not included is the screen-time snapshot the background check reads; the
app writes that again on start.

File names:
- **manual export:** `homework-chores-backup-2026-10-29.sqlite`. The user picks where to save it.
- **automatic:** `homework-chores-auto-2026-10-29.sqlite` in the chosen folder.

Only files matching the automatic pattern are ever deleted (the oldest beyond 7), never anything
else in the folder.

## Reading a backup
1. **Copy:** the picked file is copied into the app's cache, so nothing reads the original twice.
2. **Check it's ours:** it must be a SQLite file (`PRAGMA integrity_check` is `ok`), its
   `user_version` must be 1 or higher, and it must have the `chores` and `completions` tables.
   Otherwise: "This isn't a Homework & Chores backup."
3. **Too new:** a `user_version` above the app's schema version gets "This backup is from a newer
   version of the app. Update the app first."
4. **Older is fine:** the copy is opened as an `AppDatabase`, which runs the normal migrations on
   it. The copy changes, never the user's file.

## Merge rules
IDs are local numbers, so rows are matched by what they mean, and each backup ID is mapped to a
local ID as rows are matched or inserted.

| Table | Same row if … | If it's new |
|---|---|---|
| Profiles | same name (case-insensitive), or the user says "that's me" (see below) | inserted |
| Chores | built-in: same `seedKey`. User chores: same title (case-insensitive, trimmed) | inserted with the backup's schedule, icon, color and archived state |
| Completions | same chore, profile and `completedAt` | inserted. A completion undone in either copy ends up undone. |
| Point ledger | entries tied to a completion: follow that completion. Others (spending): same profile, reason, delta and `createdAt` | inserted |
| Fights | same profile, boss family and `startedAt` | inserted |
| Inventory | same profile and item | the larger count is kept (gear is 1 anyway) |
| Screen days | same profile and day | per column, the larger value is kept |
| Settings | — | not merged, except with **"Also use the backup's settings"** (on by default when the device has no history yet, i.e. a new device) |

When a chore matches, the device's version of it wins (title, schedule, reminder) and the backup
only adds history to it. With **"Also use the backup's settings"** it is the other way round: the
matching chore takes everything from the backup (schedule, times of day, reminder, points, icon,
color, who it's for, and whether it's archived). Since 0.17.0; before, a restore onto a new device
kept the built-in quests' default times and brought archived ones back.

**"That's me" (0.17.0).** A new device starts with a person called "Me", and the backup's person
has another name, so matching by name alone made two people. When the backup has people this
device doesn't know by name, and the person using the app isn't in the backup under their own
name, the preview asks: "Are you ("Me") one of the people in this backup?" with one choice per
new person and "No, add them as new people". The chosen person's history goes to the current
person, who takes the backup's name, hero look and fight settings; nothing they had is removed.
On a device without history the backup's last player is preselected. The counts in the preview
follow the choices.

**First start (0.17.0).** The welcome screen has "Restore a backup", which runs the same import and
then ends the introduction.

**Why this is safe:**
- Points stay consistent, because the balance is the sum of the ledger and XP is the sum of
  completions. Each history entry arrives at most once.
- Merging two phones adds both histories together.
- Restoring onto a fresh install brings everything back.
- Restoring an older backup of the same phone adds nothing new.

**Known limit:** consumables (e.g. potions) are a count rather than a history, so after merging
two phones the count is the larger of the two, not the sum. Points spent on them stay booked.
This rarely matters, and the alternative of storing purchases as history is a schema change for
later.

Before anything is written, the import screen shows what would change, for example "Adds 3 chores,
214 completions, 12 fights. Your current data stays." The user then confirms with **Import**.

## Undo
The safety snapshot is taken right before the merge. **Undo last import** (in Settings → Backup,
until the next import) copies it back. That happens inside the open database: it attaches the
snapshot and replaces every table in one transaction, so there's no restart and no file swap.

## Automatic backups
- **Choosing the folder:** the user picks it with Android's folder picker (Storage Access
  Framework, `ACTION_OPEN_DOCUMENT_TREE`). The app keeps the permission and needs **no storage
  permission**.
- **When:** the app writes a backup when it opens or goes to the background, at most once a day.
  If the app isn't used, nothing changes, so nothing needs saving.
- **Status:** the Settings → Backup page shows "Last backup: today, 08:12". If the folder is gone
  or the permission was revoked, it shows a warning and a button to choose again. The app does
  not nag with notifications.

## Platform side
A small `backup` MethodChannel in Kotlin, like screen time's, so no new dependency is needed
(F-Droid friendly):
- `createDocument(name, path)`: the "Save as" dialog, then copies the file there
- `openDocument()`: the file picker; copies the chosen file to the cache and returns its path
- `pickFolder()`: the folder picker; persists the permission and returns the folder URI
- `writeToFolder(uri, name, path)`, `pruneFolder(uri, prefix, keep)` and `folderOk(uri)`

The Dart side (snapshot, checks, merge, undo, schedule) sits behind a `BackupService` interface,
so widget tests use a fake. The merge engine is plain Dart over two `AppDatabase`s and is tested
with in-memory databases.

## Tests
- **Merge:**
  - restoring onto a fresh install
  - merging two phones (balances add up)
  - importing the same backup twice changes nothing
  - an older backup of the same phone adds nothing
  - a completion undone in the backup gets undone locally
  - spends, fights, inventory and screen days follow their rules
  - user chores with the same title match
- **Old backups:** a v1…v5 database (from the schema dumps in `drift_schemas/`) imports into v6.
- **Bad files:** a random file, a non-app SQLite file, and a backup from a newer schema version.
- **Undo:** an import followed by undo leaves the data exactly as before.
- **UI:** the preview text, confirming, the settings toggle, and the folder status (widget tests
  with a fake service).
- **On the emulator:** export, import on a fresh install, auto backup to a folder, and losing the
  folder permission.

## As built
- **Kotlin:** `Backup.kt` uses `DocumentsContract` directly, with no AndroidX dependency. The
  pickers return through `MainActivity.onActivityResult`, and copies run off the main thread.
- **Where the settings live:** the folder and the time of the last automatic backup are in the
  settings table, under keys a merge never takes over (`deviceOnlySettings`). The automatic
  backup reads them straight from the database, not from the stream.
- **Busy state:** the page isn't "busy" while the import preview dialog is open; preparing the
  preview and running the import are separate busy steps.
- **App files:** export copies, the import copy and the safety snapshot live in
  `files/backup/`. Export and import copies are deleted after use. The safety snapshot stays until
  it's undone or the next import replaces it.

## Order of work
1. ✅ Snapshot (`VACUUM INTO`), backup-file checks and the merge engine, with tests.
2. ✅ Native channel: save, open, pick a folder, write and prune.
3. ✅ Settings → Backup page: export, import with preview, undo, and the automatic-backup folder and status.
4. ✅ Automatic schedule and PRIVACY.md. The emulator check comes before the commit.
