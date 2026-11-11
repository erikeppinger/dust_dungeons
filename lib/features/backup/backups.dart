import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/widgets.dart' show AppLifecycleListener;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../data/backup/backup_file.dart';
import '../../data/backup/merge.dart';
import '../../data/db/app_database.dart';
import '../../data/providers.dart';
import '../../domain/dates.dart';
import '../settings/settings_controller.dart';
import 'backup_service.dart';

/// Automatic backups kept in the chosen folder.
const autoBackupsKept = 7;
const autoBackupPrefix = 'homework-chores-auto-';
const exportPrefix = 'homework-chores-backup-';

const _folderKey = backupFolderSetting;
const _lastAutoKey = backupLastAutoSetting;

String _dateName(DateTime day) =>
    '${day.year.toString().padLeft(4, '0')}-'
    '${day.month.toString().padLeft(2, '0')}-'
    '${day.day.toString().padLeft(2, '0')}';

/// Where automatic backups go, and when the last one was written. Kept in
/// the settings table under keys a merge never takes over
/// ([deviceOnlySettings]).
class BackupState {
  const BackupState({this.folder, this.lastAuto});

  final String? folder;
  final DateTime? lastAuto;
}

final backupStateProvider = StreamProvider<BackupState>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.settings)
        ..where((s) => s.key.isIn(const [_folderKey, _lastAutoKey])))
      .watch()
      .map((rows) {
        final values = {for (final r in rows) r.key: r.value};
        return BackupState(
          folder: values[_folderKey],
          lastAuto: DateTime.tryParse(values[_lastAutoKey] ?? ''),
        );
      });
});

/// The chosen folder's name; `null` when it's gone or access was revoked.
final backupFolderNameProvider = FutureProvider<String?>((ref) async {
  final folder = (await ref.watch(backupStateProvider.future)).folder;
  if (folder == null) return null;
  return ref.watch(backupServiceProvider).folderName(folder);
});

/// The app's own backup files: export copies, imports and the safety
/// snapshot that undoes the last import. Overridden in tests.
final backupDirectoryProvider = Provider<Future<Directory>>((ref) async {
  final dir = Directory(
    '${(await getApplicationSupportDirectory()).path}/backup',
  );
  await dir.create(recursive: true);
  return dir;
});

/// Whether the last import can be undone.
final undoImportAvailableProvider = FutureProvider<bool>((ref) async {
  ref.watch(backupStateProvider); // re-checked after every import or undo
  final dir = await ref.watch(backupDirectoryProvider);
  return File('${dir.path}/before-import.sqlite').existsSync();
});

/// An opened backup waiting for the user to confirm the import.
class PendingImport {
  PendingImport._(
    this._backups,
    this._source,
    this._path,
    this.report, {
    required this.hasHistory,
    required this.newPeople,
    required this.me,
    required this.suggestedMe,
  });

  final Backups _backups;
  final AppDatabase _source;
  final String _path;

  /// What importing would add, with [suggestedMe] and the settings as
  /// suggested ([hasHistory]).
  final MergeReport report;

  /// This device already has history (otherwise it's a new device, and the
  /// backup's settings are suggested).
  final bool hasHistory;

  /// People in the backup that this device doesn't know by name.
  final List<Profile> newPeople;

  /// Who is using the app here, if one of [newPeople] can be them (they
  /// aren't in the backup under their own name); else `null`.
  final Profile? me;

  /// The one of [newPeople] suggested to be [me]: on a new device, who used
  /// the app last in the backup. Else `null`.
  final Profile? suggestedMe;

  Map<int, int> _sameAs(Profile? isMe) => {
    if (isMe != null && me != null) isMe.id: me!.id,
  };

  /// What importing would add with these choices; writes nothing.
  Future<MergeReport> preview({
    required bool useSettings,
    required Profile? isMe,
  }) => mergeBackup(
    _backups._db,
    _source,
    preview: true,
    useSettings: useSettings,
    sameAs: _sameAs(isMe),
  );

  /// Merges the backup in; a safety snapshot taken first allows undo.
  /// [isMe] is the one of [newPeople] who is [me], if any.
  Future<MergeReport> confirm({
    required bool useSettings,
    Profile? isMe,
  }) async {
    try {
      return await _backups._import(
        _source,
        useSettings: useSettings,
        sameAs: _sameAs(isMe),
      );
    } finally {
      await cancel();
    }
  }

  /// Closes the backup and deletes the copy.
  Future<void> cancel() async {
    await _source.close();
    final file = File(_path);
    if (file.existsSync()) file.deleteSync();
  }
}

/// Export, import, undo and automatic backups; see
/// docs/design/data-safety.md.
class Backups {
  Backups(this._ref);

  final Ref _ref;

  AppDatabase get _db => _ref.read(databaseProvider);
  BackupService get _service => _ref.read(backupServiceProvider);
  Future<Directory> get _dir => _ref.read(backupDirectoryProvider);

  Future<String> _snapshot(String name) async {
    final path = '${(await _dir).path}/$name';
    await writeSnapshot(_db, path);
    return path;
  }

  /// Saves a backup where the user chooses; `false` if they cancelled.
  Future<bool> export() async {
    final name = '$exportPrefix${_dateName(DateTime.now())}.sqlite';
    final path = await _snapshot(name);
    try {
      return await _service.saveAs(name, path);
    } finally {
      File(path).deleteSync();
    }
  }

  /// Lets the user pick a backup and previews the import; `null` if they
  /// cancelled. Throws [BackupException] for files that can't be imported.
  Future<PendingImport?> open() async {
    final path = await _service.open('${(await _dir).path}/import.sqlite');
    if (path == null) return null;
    try {
      checkBackup(path, currentSchema: _db.schemaVersion);
    } on BackupException {
      File(path).deleteSync();
      rethrow;
    }
    // Opening runs the migrations on the copy, so older backups merge
    // like current ones.
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    final source = AppDatabase(NativeDatabase(File(path)));
    try {
      final history = await (_db.select(_db.completions)..limit(1)).get();
      final hasHistory = history.isNotEmpty;
      final people = await newPeople(_db, source);
      // Whoever uses the app here can be one of the backup's new people,
      // unless the backup has them under their own name already.
      final current =
          await (_db.select(
                _db.profiles,
              )..where((p) => p.id.equals(_ref.read(currentProfileIdProvider))))
              .getSingleOrNull();
      final theirs = await source.select(source.profiles).get();
      final me =
          current == null ||
              people.isEmpty ||
              theirs.any(
                (p) =>
                    p.name.trim().toLowerCase() ==
                    current.name.trim().toLowerCase(),
              )
          ? null
          : current;
      // A new device: the backup's last player is who sits here now.
      Profile? suggestedMe;
      if (me != null && !hasHistory) {
        final last = await (source.select(
          source.settings,
        )..where((s) => s.key.equals(currentProfileSetting))).getSingleOrNull();
        final lastId = int.tryParse(last?.value ?? '');
        final active = people.where((p) => p.archivedAt == null);
        suggestedMe =
            people.where((p) => p.id == lastId).firstOrNull ??
            active.firstOrNull ??
            people.first;
      }
      final report = await mergeBackup(
        _db,
        source,
        preview: true,
        useSettings: !hasHistory,
        sameAs: {if (suggestedMe != null) suggestedMe.id: me!.id},
      );
      return PendingImport._(
        this,
        source,
        path,
        report,
        hasHistory: hasHistory,
        newPeople: people,
        me: me,
        suggestedMe: suggestedMe,
      );
    } catch (_) {
      await source.close();
      File(path).deleteSync();
      rethrow;
    }
  }

  Future<String> get _safetyPath async =>
      '${(await _dir).path}/before-import.sqlite';

  Future<MergeReport> _import(
    AppDatabase source, {
    required bool useSettings,
    required Map<int, int> sameAs,
  }) async {
    await writeSnapshot(_db, await _safetyPath);
    final report = await mergeBackup(
      _db,
      source,
      useSettings: useSettings,
      sameAs: sameAs,
    );
    if (report.settings > 0) {
      await _ref.read(settingsProvider.notifier).reload();
    }
    _ref.invalidate(undoImportAvailableProvider);
    return report;
  }

  /// Puts the data back as it was before the last import.
  Future<void> undoImport() async {
    final safety = File(await _safetyPath);
    if (!safety.existsSync()) return;
    await restoreSnapshot(_db, safety.path);
    safety.deleteSync();
    await _ref.read(settingsProvider.notifier).reload();
    _ref.invalidate(undoImportAvailableProvider);
  }

  /// Lets the user pick the folder for automatic backups and writes the
  /// first one right away; `false` if they cancelled.
  Future<bool> chooseFolder() async {
    final folder = await _service.pickFolder();
    if (folder == null) return false;
    await _put(_folderKey, folder);
    _ref.invalidate(backupFolderNameProvider);
    await autoBackup(force: true);
    return true;
  }

  /// Stops automatic backups (the files already written stay).
  Future<void> stopAutoBackups() async {
    await (_db.delete(
      _db.settings,
    )..where((s) => s.key.isIn(const [_folderKey, _lastAutoKey]))).go();
  }

  /// Writes today's automatic backup unless one exists already ([force]
  /// writes anyway) and removes the oldest beyond [autoBackupsKept]. Does
  /// nothing without a folder; throws if the folder can't be written.
  Future<void> autoBackup({bool force = false}) async {
    // Straight from the database: the stream may not have caught up with
    // a folder chosen a moment ago.
    final values = {
      for (final row in await (_db.select(
        _db.settings,
      )..where((s) => s.key.isIn(const [_folderKey, _lastAutoKey]))).get())
        row.key: row.value,
    };
    final folder = values[_folderKey];
    if (folder == null) return;
    final now = DateTime.now();
    final last = DateTime.tryParse(values[_lastAutoKey] ?? '');
    if (!force && last != null && dayOf(last) == dayOf(now)) return;
    final name = '$autoBackupPrefix${_dateName(now)}.sqlite';
    final path = await _snapshot(name);
    try {
      await _service.writeToFolder(folder, name, path);
      await _service.pruneFolder(folder, autoBackupPrefix, autoBackupsKept);
    } finally {
      File(path).deleteSync();
    }
    await _put(_lastAutoKey, now.toIso8601String());
  }

  Future<void> _put(String key, String value) => _db
      .into(_db.settings)
      .insertOnConflictUpdate(SettingsCompanion.insert(key: key, value: value));
}

final backupsProvider = Provider<Backups>(Backups.new);

/// The last automatic backup failed (folder gone, no access, disk full).
class AutoBackupError extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool failed) => state = failed;
}

final autoBackupErrorProvider = NotifierProvider<AutoBackupError, bool>(
  AutoBackupError.new,
);

/// Writes the daily automatic backup when the app starts and whenever it
/// goes to the background. Returns a function that stops it.
void Function() scheduleAutoBackups(ProviderContainer container) {
  var running = false;
  Future<void> run() async {
    if (running) return;
    running = true;
    try {
      await container.read(backupsProvider).autoBackup();
      container.read(autoBackupErrorProvider.notifier).set(false);
    } catch (_) {
      // Shown on the Backup page; the next start tries again.
      container.read(autoBackupErrorProvider.notifier).set(true);
    } finally {
      running = false;
    }
  }

  unawaited(run());
  final listener = AppLifecycleListener(onPause: () => unawaited(run()));
  return listener.dispose;
}
