import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homework_and_chores/core/day_clock.dart';
import 'package:homework_and_chores/data/db/app_database.dart';
import 'package:homework_and_chores/data/repositories/settings_repository.dart';
import 'package:homework_and_chores/features/backup/backup_service.dart';
import 'package:homework_and_chores/features/backup/backups.dart';
import 'package:homework_and_chores/features/fight/fight_sounds.dart';
import 'package:homework_and_chores/features/screen_time/screen_time_service.dart';
import 'package:homework_and_chores/features/notifications/notification_planner.dart';
import 'package:homework_and_chores/features/notifications/notification_service.dart';
import 'package:homework_and_chores/main.dart';

/// Fresh in-memory database. Synchronous stream closing avoids pending
/// timers at the end of widget tests. Each test intentionally opens its own
/// database, so drift's "created multiple times" warning is silenced.
AppDatabase memoryDb() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  return _memoryDb();
}

AppDatabase _memoryDb() => AppDatabase(
  DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true),
);

/// Today without the midnight timer, so widget tests leave no timers behind.
class FixedToday extends TodayNotifier {
  @override
  DateTime build() => startOfDay(DateTime.now());
}

/// Records what the app asks the notification system to do.
class FakeNotificationService implements NotificationService {
  FakeNotificationService({this.grantPermission = true});

  bool grantPermission;
  int permissionRequests = 0;
  List<PlannedNotification> scheduled = const [];
  final shown = <PlannedNotification>[];
  void Function(NotificationTarget)? onTap;

  @override
  Future<void> init({required void Function(NotificationTarget) onTap}) async =>
      this.onTap = onTap;

  @override
  Future<NotificationTarget?> launchTarget() async => null;

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return grantPermission;
  }

  @override
  Future<bool> permissionGranted() async => grantPermission;

  @override
  Future<void> replaceAll(
    List<PlannedNotification> plan,
    ChannelNames names,
  ) async => scheduled = plan;

  @override
  Future<void> showNow(
    PlannedNotification notification,
    ChannelNames names,
  ) async => shown.add(notification);
}

/// The time without the minute timer, so widget tests leave no timers
/// behind.
class FixedNow extends NowNotifier {
  @override
  DateTime build() => DateTime.now();
}

/// Usage per day and app, an app list and recorded snapshots, instead of
/// Android's usage access.
class FakeScreenTimeService implements ScreenTimeService {
  bool access = true;
  int settingsOpened = 0;
  List<LauncherApp> apps = [
    LauncherApp('com.example.video', 'Video', _pixel),
    LauncherApp('com.example.game', 'Game', _pixel),
    LauncherApp('com.example.chat', 'Chat', _pixel),
  ];

  /// Minutes per app, by local day.
  final usage = <DateTime, Map<String, int>>{};
  final snapshots = <Map<String, Object?>>[];

  @override
  Future<bool> hasAccess() async => access;

  @override
  Future<void> openAccessSettings() async => settingsOpened++;

  @override
  Future<List<LauncherApp>> launcherApps() async => apps;

  @override
  Future<Map<String, int>> usageMinutes(
    Set<String> packages,
    DateTime from,
    DateTime to,
  ) async => {
    for (final e in (usage[startOfDay(from)] ?? const {}).entries)
      if (packages.contains(e.key)) e.key: e.value,
  };

  @override
  Future<void> writeSnapshot(Map<String, Object?> snapshot) async =>
      snapshots.add(snapshot);
}

/// The system's file and folder pickers, in memory: "saved" files and the
/// chosen folder's files are kept as bytes by name.
class FakeBackupService implements BackupService {
  /// What "Save as" stored, by suggested name.
  final saved = <String, List<int>>{};
  bool cancelSave = false;

  /// The file the user "picks" when importing; `null` cancels.
  String? pick;

  /// The folder the user "picks"; `null` cancels.
  String? pickFolderResult = 'content://tree/Backups';

  /// The folder exists and the app may write to it.
  bool folderOk = true;
  final folder = <String, List<int>>{};
  final prunes = <(String, int)>[];

  @override
  Future<bool> saveAs(String name, String path) async {
    if (cancelSave) return false;
    saved[name] = File(path).readAsBytesSync();
    return true;
  }

  @override
  Future<String?> open(String dest) async {
    final source = pick;
    if (source == null) return null;
    File(source).copySync(dest);
    return dest;
  }

  @override
  Future<String?> pickFolder() async => pickFolderResult;

  @override
  Future<String?> folderName(String uri) async =>
      folderOk ? uri.split('/').last : null;

  @override
  Future<void> writeToFolder(String uri, String name, String path) async {
    if (!folderOk) throw const FileSystemException('folder gone');
    folder[name] = File(path).readAsBytesSync();
  }

  @override
  Future<void> pruneFolder(String uri, String prefix, int keep) async =>
      prunes.add((prefix, keep));
}

/// A 1×1 transparent PNG, as an app icon.
final _pixel = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=',
);

/// Pumps the full app on an in-memory database with a fixed device [locale].
Future<AppDatabase> pumpApp(
  WidgetTester tester, {
  Locale locale = const Locale('en'),
  AppDatabase? db,
  FakeNotificationService? notifications,
  FakeScreenTimeService? screenTime,
  FakeBackupService? backup,
  bool onboarding = false,
}) async {
  // A tap that misses its widget means the test checks nothing: fail loudly.
  WidgetController.hitTestWarningShouldBeFatal = true;
  tester.platformDispatcher.localesTestValue = [locale];
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  final database = db ?? memoryDb();
  final backupDir = Directory.systemTemp.createTempSync('backup');
  addTearDown(() => backupDir.deleteSync(recursive: true));
  if (!onboarding) {
    await tester.runAsync(() async {
      final repo = SettingsRepository(database);
      final settings = await repo.load();
      if (!settings.onboardingDone) {
        await repo.save(settings.copyWith(onboardingDone: true));
      }
    });
  }
  final app = await tester.runAsync(
    () => bootstrap(
      database,
      notifications: notifications ?? FakeNotificationService(),
      overrides: [
        todayProvider.overrideWith(FixedToday.new),
        nowProvider.overrideWith(FixedNow.new),
        fightSoundsProvider.overrideWithValue(SilentFightSounds()),
        screenTimeServiceProvider.overrideWithValue(
          screenTime ?? FakeScreenTimeService(),
        ),
        backupServiceProvider.overrideWithValue(backup ?? FakeBackupService()),
        backupDirectoryProvider.overrideWithValue(Future.value(backupDir)),
      ],
    ),
  );
  await tester.pumpWidget(app!);
  await tester.pumpAndSettle();
  addTearDown(() async {
    // Unmount first so providers stop listening, then close the database.
    await tester.pumpWidget(const SizedBox());
    await database.close();
  });
  return database;
}
