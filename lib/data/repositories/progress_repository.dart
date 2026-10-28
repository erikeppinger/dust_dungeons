import 'package:drift/drift.dart';

import '../../domain/points.dart';
import '../db/app_database.dart';

/// Result of completing a chore, needed to offer an undo.
class CompletionResult {
  const CompletionResult({required this.completionId, required this.points});

  final int completionId;
  final int points;
}

/// Completions and the point ledger.
class ProgressRepository {
  ProgressRepository(this._db, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final AppDatabase _db;
  final DateTime Function() _clock;

  /// Records a completion and awards its points in one transaction.
  Future<CompletionResult> complete({
    required int choreId,
    required int profileId,
  }) => _db.transaction(() async {
    final chore = await (_db.select(
      _db.chores,
    )..where((c) => c.id.equals(choreId))).getSingle();
    final points = pointsForCompletion(basePoints: chore.basePoints);
    final now = _clock();
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
    return CompletionResult(completionId: completionId, points: points);
  });

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
