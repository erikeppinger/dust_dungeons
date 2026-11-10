import 'dart:io';

import 'package:file_selector_platform_interface/file_selector_platform_interface.dart';
import 'package:file_selector_windows/file_selector_windows.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/platform.dart';

/// The Android side of backups: the system's file and folder pickers and
/// copying into what they return. Behind an interface so tests use a fake.
abstract class BackupService {
  /// "Save as" for the file at [path], suggesting [name]; `false` if the
  /// user cancelled.
  Future<bool> saveAs(String name, String path);

  /// Lets the user pick a file and copies it to [dest]; `null` if cancelled.
  Future<String?> open(String dest);

  /// Lets the user pick a folder and keeps access to it; its URI, or `null`.
  Future<String?> pickFolder();

  /// The folder's name, or `null` if it's gone or access was revoked.
  Future<String?> folderName(String folder);

  Future<void> writeToFolder(String folder, String name, String path);

  /// Deletes files starting with [prefix] beyond the newest [keep].
  Future<void> pruneFolder(String folder, String prefix, int keep);
}

class PlatformBackupService implements BackupService {
  static const _channel = MethodChannel('backup');

  @override
  Future<bool> saveAs(String name, String path) async =>
      await _channel.invokeMethod<bool>('saveAs', {
        'name': name,
        'path': path,
      }) ??
      false;

  @override
  Future<String?> open(String dest) =>
      _channel.invokeMethod<String>('open', {'dest': dest});

  @override
  Future<String?> pickFolder() => _channel.invokeMethod<String>('pickFolder');

  @override
  Future<String?> folderName(String folder) =>
      _channel.invokeMethod<String>('folderName', {'folder': folder});

  @override
  Future<void> writeToFolder(String folder, String name, String path) =>
      _channel.invokeMethod<void>('writeToFolder', {
        'folder': folder,
        'name': name,
        'path': path,
      });

  @override
  Future<void> pruneFolder(String folder, String prefix, int keep) =>
      _channel.invokeMethod<void>('pruneFolder', {
        'folder': folder,
        'prefix': prefix,
        'keep': keep,
      });
}

/// Windows: the system's file dialogs and plain files; a folder is its path.
class WindowsBackupService implements BackupService {
  final _dialogs = FileSelectorWindows();

  static const _types = [
    XTypeGroup(label: 'SQLite', extensions: ['sqlite']),
  ];

  @override
  Future<bool> saveAs(String name, String path) async {
    final target = await _dialogs.getSaveLocation(
      acceptedTypeGroups: _types,
      options: SaveDialogOptions(suggestedName: name),
    );
    if (target == null) return false;
    await File(path).copy(target.path);
    return true;
  }

  @override
  Future<String?> open(String dest) async {
    final file = await _dialogs.openFile(acceptedTypeGroups: _types);
    if (file == null) return null;
    await File(file.path).copy(dest);
    return dest;
  }

  @override
  Future<String?> pickFolder() => _dialogs.getDirectoryPath();

  @override
  Future<String?> folderName(String folder) async {
    final dir = Directory(folder);
    if (!dir.existsSync()) return null;
    return dir.uri.pathSegments.lastWhere(
      (s) => s.isNotEmpty,
      orElse: () => folder,
    );
  }

  @override
  Future<void> writeToFolder(String folder, String name, String path) async {
    // Written whole, then renamed: never half a backup under its name.
    final tmp = await File(path).copy('$folder/$name.tmp');
    await tmp.rename('$folder/$name');
  }

  @override
  Future<void> pruneFolder(String folder, String prefix, int keep) async {
    // The names end in the date, so sorting by name is sorting by age.
    final files = [
      await for (final f in Directory(folder).list())
        if (f is File &&
            f.uri.pathSegments.last.startsWith(prefix) &&
            f.path.endsWith('.sqlite'))
          f,
    ]..sort((a, b) => b.path.compareTo(a.path));
    for (final old in files.skip(keep)) {
      await old.delete();
    }
  }
}

final backupServiceProvider = Provider<BackupService>(
  (ref) => isWindowsApp ? WindowsBackupService() : PlatformBackupService(),
);
