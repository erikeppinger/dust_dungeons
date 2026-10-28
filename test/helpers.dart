import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homework_and_chores/core/day_clock.dart';
import 'package:homework_and_chores/data/db/app_database.dart';
import 'package:homework_and_chores/data/repositories/settings_repository.dart';
import 'package:homework_and_chores/features/fight/fight_sounds.dart';
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

/// Pumps the full app on an in-memory database with a fixed device [locale].
Future<AppDatabase> pumpApp(
  WidgetTester tester, {
  Locale locale = const Locale('en'),
  AppDatabase? db,
  FakeNotificationService? notifications,
  bool onboarding = false,
}) async {
  // A tap that misses its widget means the test checks nothing: fail loudly.
  WidgetController.hitTestWarningShouldBeFatal = true;
  tester.platformDispatcher.localesTestValue = [locale];
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  final database = db ?? memoryDb();
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
        fightSoundsProvider.overrideWithValue(SilentFightSounds()),
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
