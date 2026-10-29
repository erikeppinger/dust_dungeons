import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

final backupServiceProvider = Provider<BackupService>(
  (ref) => PlatformBackupService(),
);
