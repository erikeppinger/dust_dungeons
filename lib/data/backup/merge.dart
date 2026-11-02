import 'dart:math';

import 'package:drift/drift.dart';

import '../db/app_database.dart';

/// What merging a backup adds (or would add, for a preview).
class MergeReport {
  int profiles = 0;
  int chores = 0;

  /// People added to chores' assignments.
  int assignees = 0;
  int completions = 0;

  /// Completions undone in the backup that were still counted here.
  int undone = 0;
  int ledger = 0;
  int fights = 0;
  int inventory = 0;

  /// Worn gear, for people who wear nothing here yet.
  int equipped = 0;
  int screenDays = 0;
  int settings = 0;

  /// Nothing would change.
  bool get isEmpty =>
      profiles +
          chores +
          assignees +
          completions +
          undone +
          ledger +
          fights +
          inventory +
          equipped +
          screenDays +
          settings ==
      0;
}

/// Settings that belong to this phone, never taken from a backup: where
/// automatic backups go, when the last one ran, and the measured audio
/// latency of this device.
const deviceOnlySettings = {
  backupFolderSetting,
  backupLastAutoSetting,
  currentProfileSetting,
  'fightLatencyMs',
};

/// Who was using the app last on this phone.
const currentProfileSetting = 'currentProfile';

/// Settings keys of the automatic backup (see `Backups`).
const backupFolderSetting = 'backupFolder';
const backupLastAutoSetting = 'backupLastAuto';

class _Preview implements Exception {
  const _Preview();
}

/// Adds the history in [source] (an opened backup) to [target], following
/// the rules in docs/design/data-safety.md: rows are matched by meaning,
/// never deleted, and merging the same backup twice changes nothing. With
/// [preview] nothing is written; the report says what would change.
/// [useSettings] also takes the backup's settings (except
/// [deviceOnlySettings]).
Future<MergeReport> mergeBackup(
  AppDatabase target,
  AppDatabase source, {
  bool preview = false,
  bool useSettings = false,
}) async {
  final report = MergeReport();
  try {
    await target.transaction(() async {
      await _merge(target, source, report, useSettings: useSettings);
      // Rolls the transaction back: the same code computes the preview.
      if (preview) throw const _Preview();
    });
  } on _Preview {
    // Expected.
  }
  return report;
}

int _ms(DateTime t) => t.millisecondsSinceEpoch;

String _title(String? title) => (title ?? '').trim().toLowerCase();

Future<void> _merge(
  AppDatabase t,
  AppDatabase s,
  MergeReport report, {
  required bool useSettings,
}) async {
  // Profiles, by name.
  final profileIds = <int, int>{};
  final localProfiles = await t.select(t.profiles).get();
  for (final p in await s.select(s.profiles).get()) {
    final match = localProfiles
        .where((l) => _title(l.name) == _title(p.name))
        .firstOrNull;
    if (match != null) {
      profileIds[p.id] = match.id;
    } else {
      profileIds[p.id] = await t
          .into(t.profiles)
          .insert(p.toCompanion(false).copyWith(id: const Value.absent()));
      report.profiles++;
    }
  }

  // Chores: built-ins by seed key, the user's own by title.
  final choreIds = <int, int>{};
  final localChores = await t.select(t.chores).get();
  for (final c in await s.select(s.chores).get()) {
    final match = localChores
        .where(
          (l) => c.seedKey != null
              ? l.seedKey == c.seedKey
              : l.seedKey == null &&
                    _title(l.customTitle) == _title(c.customTitle),
        )
        .firstOrNull;
    if (match != null) {
      choreIds[c.id] = match.id;
    } else {
      choreIds[c.id] = await t
          .into(t.chores)
          .insert(c.toCompanion(false).copyWith(id: const Value.absent()));
      report.chores++;
    }
  }

  // Assignees: the union, for chores that are personal here (the phone's
  // version of a chore wins, so an anyone's chore stays anyone's).
  final personal = {
    for (final c in await t.select(t.chores).get())
      if (c.assignment != Assignment.anyone) c.id,
  };
  final localAssignees = {
    for (final a in await t.select(t.choreAssignees).get())
      (a.choreId, a.profileId),
  };
  for (final a in await s.select(s.choreAssignees).get()) {
    final key = (choreIds[a.choreId]!, profileIds[a.profileId]!);
    if (!personal.contains(key.$1) || localAssignees.contains(key)) continue;
    await t
        .into(t.choreAssignees)
        .insert(
          ChoreAssigneesCompanion.insert(choreId: key.$1, profileId: key.$2),
        );
    localAssignees.add(key);
    report.assignees++;
  }

  // Completions: same chore, profile and moment. Rows that share all three
  // are matched one to one, in id order, so none collapse.
  final completionIds = <int, int>{};
  final localCompletions = <(int, int, int), List<Completion>>{};
  for (final c in await (t.select(
    t.completions,
  )..orderBy([(c) => OrderingTerm.asc(c.id)])).get()) {
    localCompletions
        .putIfAbsent((c.choreId, c.profileId, _ms(c.completedAt)), () => [])
        .add(c);
  }
  for (final c in await (s.select(
    s.completions,
  )..orderBy([(c) => OrderingTerm.asc(c.id)])).get()) {
    final chore = choreIds[c.choreId]!;
    final profile = profileIds[c.profileId]!;
    final candidates = localCompletions[(chore, profile, _ms(c.completedAt))];
    final match = candidates == null || candidates.isEmpty
        ? null
        : candidates.removeAt(0);
    if (match != null) {
      completionIds[c.id] = match.id;
      // Undone in the backup: undone here too (its undo entry follows in
      // the ledger).
      if (c.undoneAt != null && match.undoneAt == null) {
        await (t.update(t.completions)..where((x) => x.id.equals(match.id)))
            .write(CompletionsCompanion(undoneAt: Value(c.undoneAt)));
        report.undone++;
      }
    } else {
      completionIds[c.id] = await t
          .into(t.completions)
          .insert(
            c
                .toCompanion(false)
                .copyWith(
                  id: const Value.absent(),
                  choreId: Value(chore),
                  profileId: Value(profile),
                ),
          );
      report.completions++;
    }
  }

  // Point ledger: same profile, reason, amount, moment and completion,
  // counted, so two equal entries (two potions bought in one second) stay
  // two.
  final localLedger = <Object, int>{};
  for (final e in await t.select(t.pointLedger).get()) {
    final key = (
      e.profileId,
      e.reason,
      e.delta,
      _ms(e.createdAt),
      e.completionId,
    );
    localLedger[key] = (localLedger[key] ?? 0) + 1;
  }
  for (final e in await s.select(s.pointLedger).get()) {
    final profile = profileIds[e.profileId]!;
    final completion = e.completionId == null
        ? null
        : completionIds[e.completionId];
    final key = (profile, e.reason, e.delta, _ms(e.createdAt), completion);
    final have = localLedger[key] ?? 0;
    if (have > 0) {
      localLedger[key] = have - 1;
      continue;
    }
    await t
        .into(t.pointLedger)
        .insert(
          e
              .toCompanion(false)
              .copyWith(
                id: const Value.absent(),
                profileId: Value(profile),
                completionId: Value(completion),
              ),
        );
    report.ledger++;
  }

  // Fights: same profile, boss and start.
  final localFights = {
    for (final f in await t.select(t.fights).get())
      (f.profileId, f.family, _ms(f.startedAt)),
  };
  for (final f in await s.select(s.fights).get()) {
    final profile = profileIds[f.profileId]!;
    if (localFights.contains((profile, f.family, _ms(f.startedAt)))) continue;
    await t
        .into(t.fights)
        .insert(
          f
              .toCompanion(false)
              .copyWith(id: const Value.absent(), profileId: Value(profile)),
        );
    report.fights++;
  }

  // Inventory: a count, not a history; the larger one wins.
  final localItems = {
    for (final i in await t.select(t.inventory).get())
      (i.profileId, i.itemKey): i.count,
  };
  for (final i in await s.select(s.inventory).get()) {
    final profile = profileIds[i.profileId]!;
    final have = localItems[(profile, i.itemKey)];
    if (have != null && have >= i.count) continue;
    await t
        .into(t.inventory)
        .insertOnConflictUpdate(
          i.toCompanion(false).copyWith(profileId: Value(profile)),
        );
    report.inventory++;
  }

  // Worn gear: the phone's choice wins, so only people who wear nothing
  // here take what they wore in the backup (items they own by now).
  final wearing = {
    for (final e in await t.select(t.equipped).get()) e.profileId,
  };
  final ownedHere = {
    for (final i in await t.select(t.inventory).get())
      if (i.count > 0) (i.profileId, i.itemKey),
  };
  for (final e in await s.select(s.equipped).get()) {
    final profile = profileIds[e.profileId]!;
    if (wearing.contains(profile) ||
        !ownedHere.contains((profile, e.itemKey))) {
      continue;
    }
    await t
        .into(t.equipped)
        .insert(
          e.toCompanion(false).copyWith(profileId: Value(profile)),
          mode: InsertMode.insertOrIgnore,
        );
    report.equipped++;
  }

  // Screen days: per column, the larger value.
  final localDays = {
    for (final d in await t.select(t.screenDays).get())
      (d.profileId, _ms(d.day)): d,
  };
  for (final d in await s.select(s.screenDays).get()) {
    final profile = profileIds[d.profileId]!;
    final have = localDays[(profile, _ms(d.day))];
    final merged = ScreenDaysCompanion.insert(
      profileId: profile,
      day: d.day,
      usedMinutes: Value(max(d.usedMinutes, have?.usedMinutes ?? 0)),
      budgetMinutes: Value(max(d.budgetMinutes, have?.budgetMinutes ?? 0)),
      voucherMinutes: Value(max(d.voucherMinutes, have?.voucherMinutes ?? 0)),
    );
    if (have != null &&
        have.usedMinutes >= d.usedMinutes &&
        have.budgetMinutes >= d.budgetMinutes &&
        have.voucherMinutes >= d.voucherMinutes) {
      continue;
    }
    await t.into(t.screenDays).insertOnConflictUpdate(merged);
    report.screenDays++;
  }

  if (!useSettings) return;
  final localSettings = {
    for (final e in await t.select(t.settings).get()) e.key: e.value,
  };
  for (final e in await s.select(s.settings).get()) {
    if (deviceOnlySettings.contains(e.key)) continue;
    if (localSettings[e.key] == e.value) continue;
    await t.into(t.settings).insertOnConflictUpdate(e);
    report.settings++;
  }
}
