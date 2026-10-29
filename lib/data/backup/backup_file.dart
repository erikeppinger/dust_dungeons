import 'dart:io';

import 'package:drift/drift.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

import '../db/app_database.dart';

/// Why a file can't be imported.
enum BackupProblem {
  /// Not a SQLite file, damaged, or not from this app.
  notABackup,

  /// Written by a newer version of the app (higher schema version).
  tooNew,
}

class BackupException implements Exception {
  const BackupException(this.problem);

  final BackupProblem problem;

  @override
  String toString() => 'BackupException(${problem.name})';
}

/// Writes a consistent copy of [db] to [path] (replacing it), while the app
/// keeps using the database. See docs/design/data-safety.md.
Future<void> writeSnapshot(AppDatabase db, String path) async {
  final file = File(path);
  if (file.existsSync()) file.deleteSync();
  await db.customStatement('VACUUM INTO ?', [path]);
}

/// Checks that [path] is a backup this app can read and returns its schema
/// version; throws [BackupException] otherwise. Reads only, never changes
/// the file.
int checkBackup(String path, {required int currentSchema}) {
  final sqlite.Database file;
  try {
    file = sqlite.sqlite3.open(path, mode: sqlite.OpenMode.readOnly);
  } on sqlite.SqliteException {
    throw const BackupException(BackupProblem.notABackup);
  }
  try {
    final ok = file.select('PRAGMA integrity_check').first.values.first;
    if (ok != 'ok') throw const BackupException(BackupProblem.notABackup);
    final tables = {
      for (final row in file.select(
        "SELECT name FROM sqlite_master WHERE type = 'table'",
      ))
        row['name'] as String,
    };
    final version = file.userVersion;
    if (version < 1 || !tables.containsAll(const {'chores', 'completions'})) {
      throw const BackupException(BackupProblem.notABackup);
    }
    if (version > currentSchema) {
      throw const BackupException(BackupProblem.tooNew);
    }
    return version;
  } on sqlite.SqliteException {
    // "file is not a database" surfaces on the first query.
    throw const BackupException(BackupProblem.notABackup);
  } finally {
    file.close();
  }
}

/// Replaces everything in [db] with the snapshot at [path] (written by
/// [writeSnapshot] from this app version), in one transaction: undoes an
/// import without swapping files or restarting.
Future<void> restoreSnapshot(AppDatabase db, String path) async {
  // Children before parents for deleting, the other way round to insert.
  const tables = [
    'point_ledger',
    'completions',
    'fights',
    'inventory',
    'screen_days',
    'settings',
    'chores',
    'profiles',
  ];
  await db.customStatement('ATTACH DATABASE ? AS snapshot', [path]);
  try {
    await db.transaction(() async {
      for (final table in tables) {
        await db.customStatement('DELETE FROM main.$table');
      }
      for (final table in tables.reversed) {
        await db.customStatement(
          'INSERT INTO main.$table SELECT * FROM snapshot.$table',
        );
      }
    });
  } finally {
    await db.customStatement('DETACH DATABASE snapshot');
  }
  // Raw statements don't tell drift's streams; every screen reloads.
  db.notifyUpdates({for (final t in db.allTables) TableUpdate.onTable(t)});
}
