import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homework_and_chores/core/day_clock.dart';
import 'package:homework_and_chores/data/db/app_database.dart';
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

/// Pumps the full app on an in-memory database with a fixed device [locale].
Future<AppDatabase> pumpApp(
  WidgetTester tester, {
  Locale locale = const Locale('en'),
  AppDatabase? db,
}) async {
  // A tap that misses its widget means the test checks nothing: fail loudly.
  WidgetController.hitTestWarningShouldBeFatal = true;
  tester.platformDispatcher.localesTestValue = [locale];
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  final database = db ?? memoryDb();
  final app = await tester.runAsync(
    () => bootstrap(
      database,
      overrides: [todayProvider.overrideWith(FixedToday.new)],
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
