import 'package:drift/drift.dart';

import '../../domain/dates.dart';
import '../../domain/fight/items.dart';
import '../../domain/points.dart';
import '../../domain/progress.dart';
import '../db/app_database.dart';

/// Result of completing a chore, needed to offer an undo.
class CompletionResult {
  const CompletionResult({required this.completionId, required this.points});

  final int completionId;
  final PointsBreakdown points;
}

/// Completions and the point ledger.
class ProgressRepository {
  ProgressRepository(this._db, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final AppDatabase _db;
  final DateTime Function() _clock;

  /// Records a completion and awards its points (with bonuses) in one
  /// transaction. [onTime]: the chore was due today and not overdue.
  Future<CompletionResult> complete({
    required int choreId,
    required int profileId,
    bool onTime = false,
    DateTime? at,
  }) => _db.transaction(() async {
    final chore = await (_db.select(
      _db.chores,
    )..where((c) => c.id.equals(choreId))).getSingle();
    // [at]: done earlier and booked now (ticked in the home screen widget).
    final now = at ?? _clock();
    final breakdown = pointsFor(
      basePoints: chore.basePoints,
      onTime: onTime,
      streakDays: await _streakBefore(profileId, now),
    );
    final points = breakdown.total;
    final completionId = await _db
        .into(_db.completions)
        .insert(
          CompletionsCompanion.insert(
            choreId: choreId,
            profileId: profileId,
            completedAt: now,
            pointsAwarded: points,
          ),
        );
    await _db
        .into(_db.pointLedger)
        .insert(
          PointLedgerCompanion.insert(
            profileId: profileId,
            delta: points,
            reason: LedgerReason.completion,
            completionId: Value(completionId),
            createdAt: now,
          ),
        );
    await _liftCurse(profileId, chore.family);
    return CompletionResult(completionId: completionId, points: breakdown);
  });

  /// A quest of the cursing boss's family lifts the curse (undoing the quest
  /// doesn't bring it back).
  Future<void> _liftCurse(int profileId, BossFamily questFamily) async {
    final profile = await (_db.select(
      _db.profiles,
    )..where((p) => p.id.equals(profileId))).getSingle();
    final family = profile.curseFamily;
    if (family == null || !questLifts(curseOf(family), questFamily)) return;
    await (_db.update(_db.profiles)..where((p) => p.id.equals(profileId)))
        .write(const ProfilesCompanion(curseFamily: Value(null)));
  }

  /// Streak ending yesterday, looking back only as far as the bonus cap.
  Future<int> _streakBefore(int profileId, DateTime now) async {
    final today = dayOf(now);
    final rows =
        await (_db.select(_db.completions)..where(
              (c) =>
                  c.profileId.equals(profileId) &
                  c.undoneAt.isNull() &
                  c.completedAt.isBiggerOrEqualValue(
                    addDays(today, -maxStreakBonusDays - 1),
                  ) &
                  c.completedAt.isSmallerThanValue(today),
            ))
            .get();
    return streakBefore({for (final c in rows) dayOf(c.completedAt)}, today);
  }

  /// Reverts a completion: marks it undone and books the points back.
  /// Returns `false` if it was already undone, so double taps are harmless.
  Future<bool> undo(int completionId) => _db.transaction(() async {
    final completion = await (_db.select(
      _db.completions,
    )..where((c) => c.id.equals(completionId))).getSingle();
    if (completion.undoneAt != null) return false;
    final now = _clock();
    await (_db.update(_db.completions)..where((c) => c.id.equals(completionId)))
        .write(CompletionsCompanion(undoneAt: Value(now)));
    await _db
        .into(_db.pointLedger)
        .insert(
          PointLedgerCompanion.insert(
            profileId: completion.profileId,
            delta: -completion.pointsAwarded,
            reason: LedgerReason.undo,
            completionId: Value(completionId),
            createdAt: now,
          ),
        );
    return true;
  });

  /// Current point balance of a profile.
  Stream<int> watchBalance(int profileId) {
    final sum = _db.pointLedger.delta.sum();
    final query = _db.selectOnly(_db.pointLedger)
      ..addColumns([sum])
      ..where(_db.pointLedger.profileId.equals(profileId));
    return query.watchSingle().map((row) => row.read(sum) ?? 0);
  }

  /// Latest completion (not undone) per chore id.
  Stream<Map<int, DateTime>> watchLastDone(int profileId) {
    // Max over epoch seconds: comparing stored ISO strings with different UTC
    // offsets (around DST changes) would not be chronological.
    final last = _db.completions.completedAt.unixepoch.max();
    final query = _db.selectOnly(_db.completions)
      ..addColumns([_db.completions.choreId, last])
      ..where(
        _db.completions.profileId.equals(profileId) &
            _db.completions.undoneAt.isNull(),
      )
      ..groupBy([_db.completions.choreId]);
    return query.watch().map(
      (rows) => {
        for (final row in rows)
          row.read(_db.completions.choreId)!:
              DateTime.fromMillisecondsSinceEpoch(row.read(last)! * 1000),
      },
    );
  }

  /// Latest completion (not undone) per (chore id, profile id), for every
  /// person: anyone's chores are due from the household's latest, personal
  /// ones from their person's.
  Stream<Map<(int, int), DateTime>> watchLastDoneByPerson() {
    final last = _db.completions.completedAt.unixepoch.max();
    final query = _db.selectOnly(_db.completions)
      ..addColumns([_db.completions.choreId, _db.completions.profileId, last])
      ..where(_db.completions.undoneAt.isNull())
      ..groupBy([_db.completions.choreId, _db.completions.profileId]);
    return query.watch().map(
      (rows) => {
        for (final row in rows)
          (
            row.read(_db.completions.choreId)!,
            row.read(_db.completions.profileId)!,
          ): DateTime.fromMillisecondsSinceEpoch(
            row.read(last)! * 1000,
          ),
      },
    );
  }

  /// Completions (not undone) since [since] per (chore id, profile id).
  Stream<Map<(int, int), int>> watchCountsByPerson(DateTime since) {
    final count = _db.completions.id.count();
    final query = _db.selectOnly(_db.completions)
      ..addColumns([_db.completions.choreId, _db.completions.profileId, count])
      ..where(
        _db.completions.undoneAt.isNull() &
            _db.completions.completedAt.isBiggerOrEqualValue(since),
      )
      ..groupBy([_db.completions.choreId, _db.completions.profileId]);
    return query.watch().map(
      (rows) => {
        for (final row in rows)
          (
            row.read(_db.completions.choreId)!,
            row.read(_db.completions.profileId)!,
          ): row.read(
            count,
          )!,
      },
    );
  }

  /// All completions (not undone) of [profileId], or of everyone for
  /// `null`, oldest first.
  Stream<List<Completion>> watchAllCompletions(int? profileId) =>
      (_db.select(_db.completions)
            ..where(
              (c) =>
                  (profileId == null
                      ? const Constant(true)
                      : c.profileId.equals(profileId)) &
                  c.undoneAt.isNull(),
            )
            ..orderBy([(c) => OrderingTerm.asc(c.completedAt)]))
          .watch();

  /// Completions (not undone) with `from <= completedAt < to`, oldest first.
  Stream<List<Completion>> watchCompletionsBetween(
    int profileId,
    DateTime from,
    DateTime to,
  ) =>
      (_db.select(_db.completions)
            ..where(
              (c) =>
                  c.profileId.equals(profileId) &
                  c.undoneAt.isNull() &
                  c.completedAt.isBiggerOrEqualValue(from) &
                  c.completedAt.isSmallerThanValue(to),
            )
            ..orderBy([(c) => OrderingTerm.asc(c.completedAt)]))
          .watch();

  /// How often each chore was done (and not undone) since [since], by chore id.
  Stream<Map<int, int>> watchCompletionCounts(int profileId, DateTime since) {
    final count = _db.completions.id.count();
    final query = _db.selectOnly(_db.completions)
      ..addColumns([_db.completions.choreId, count])
      ..where(
        _db.completions.profileId.equals(profileId) &
            _db.completions.undoneAt.isNull() &
            _db.completions.completedAt.isBiggerOrEqualValue(since),
      )
      ..groupBy([_db.completions.choreId]);
    return query.watch().map(
      (rows) => {
        for (final row in rows)
          row.read(_db.completions.choreId)!: row.read(count)!,
      },
    );
  }
}
