import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homework_and_chores/data/backup/backup_file.dart';
import 'package:homework_and_chores/data/backup/merge.dart';
import 'package:homework_and_chores/data/db/app_database.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

import '../helpers.dart';
import 'generated_migrations/schema_v1.dart' as v1;
import 'generated_migrations/schema_v5.dart' as v5;

/// Merging backups: docs/design/data-safety.md.
void main() {
  late Directory tmp;

  setUp(() => tmp = Directory.systemTemp.createTempSync('backup_test'));
  tearDown(() => tmp.deleteSync(recursive: true));

  /// A database in a file under [tmp], closed by the test's teardown.
  AppDatabase fileDb(String path) {
    final db = AppDatabase(NativeDatabase(File(path)));
    addTearDown(db.close);
    return db;
  }

  AppDatabase memory() {
    final db = memoryDb();
    addTearDown(db.close);
    return db;
  }

  Future<int> choreId(AppDatabase db, String seedKey) async =>
      (await (db.select(
        db.chores,
      )..where((c) => c.seedKey.equals(seedKey))).getSingle()).id;

  /// Completes a chore the way the app does: a completion plus its ledger
  /// entry.
  Future<int> complete(
    AppDatabase db,
    String seedKey,
    DateTime at, {
    int points = 10,
  }) async {
    final profile = await db.defaultProfileId();
    final id = await db
        .into(db.completions)
        .insert(
          CompletionsCompanion.insert(
            choreId: await choreId(db, seedKey),
            profileId: profile,
            completedAt: at,
            pointsAwarded: points,
          ),
        );
    await db
        .into(db.pointLedger)
        .insert(
          PointLedgerCompanion.insert(
            profileId: profile,
            delta: points,
            reason: LedgerReason.completion,
            completionId: Value(id),
            createdAt: at,
          ),
        );
    return id;
  }

  Future<void> undo(AppDatabase db, int completionId, DateTime at) async {
    final c = await (db.select(
      db.completions,
    )..where((c) => c.id.equals(completionId))).getSingle();
    await (db.update(db.completions)..where((x) => x.id.equals(c.id))).write(
      CompletionsCompanion(undoneAt: Value(at)),
    );
    await db
        .into(db.pointLedger)
        .insert(
          PointLedgerCompanion.insert(
            profileId: c.profileId,
            delta: -c.pointsAwarded,
            reason: LedgerReason.undo,
            completionId: Value(c.id),
            createdAt: at,
          ),
        );
  }

  Future<void> spend(AppDatabase db, int points, DateTime at) async => db
      .into(db.pointLedger)
      .insert(
        PointLedgerCompanion.insert(
          profileId: await db.defaultProfileId(),
          delta: -points,
          reason: LedgerReason.spend,
          createdAt: at,
        ),
      );

  Future<int> balance(AppDatabase db) async =>
      (await db.select(db.pointLedger).get()).fold<int>(
        0,
        (sum, e) => sum + e.delta,
      );

  Future<int> countCompletions(AppDatabase db) async =>
      (await db.select(db.completions).get()).length;

  final monday = DateTime(2026, 10, 26, 9);

  test('restoring onto a fresh install brings everything back', () async {
    final phone = memory();
    final profile = await phone.defaultProfileId();
    await complete(phone, 'dusting', monday);
    await complete(phone, 'dishes', monday.add(const Duration(hours: 2)));
    await spend(phone, 5, monday.add(const Duration(hours: 3)));
    await phone
        .into(phone.chores)
        .insert(
          ChoresCompanion.insert(
            customTitle: const Value('Feed the cat'),
            iconKey: 'pets',
            colorKey: 2,
            basePoints: 5,
          ),
        );
    await phone
        .into(phone.fights)
        .insert(
          FightsCompanion.insert(
            profileId: profile,
            family: BossFamily.dust,
            tier: 1,
            startedAt: monday,
            result: const Value(FightResult.won),
          ),
        );
    await phone
        .into(phone.inventory)
        .insert(
          InventoryCompanion.insert(
            profileId: profile,
            itemKey: 'potion',
            count: 2,
          ),
        );
    await phone
        .into(phone.screenDays)
        .insert(
          ScreenDaysCompanion.insert(
            profileId: profile,
            day: DateTime(2026, 10, 26),
            usedMinutes: const Value(42),
            budgetMinutes: const Value(60),
          ),
        );
    for (final (key, value) in [
      ('themeMode', 'dark'),
      ('fightLatencyMs', '120'),
    ]) {
      await phone
          .into(phone.settings)
          .insert(SettingsCompanion.insert(key: key, value: value));
    }

    final fresh = memory();
    final report = await mergeBackup(fresh, phone, useSettings: true);

    expect(report.completions, 2);
    expect(report.ledger, 3);
    expect(report.chores, 1); // the cat; built-ins match by seed key
    expect(report.fights, 1);
    expect(report.inventory, 1);
    expect(report.screenDays, 1);
    expect(report.settings, 1); // the latency belongs to the old phone
    expect(await balance(fresh), await balance(phone));
    expect(await countCompletions(fresh), 2);
    final theme = await (fresh.select(
      fresh.settings,
    )..where((s) => s.key.equals('themeMode'))).getSingleOrNull();
    expect(theme?.value, 'dark');
    final latency = await (fresh.select(
      fresh.settings,
    )..where((s) => s.key.equals('fightLatencyMs'))).getSingleOrNull();
    expect(latency, isNull);
  });

  test('merging the same backup twice changes nothing', () async {
    final phone = memory();
    await complete(phone, 'dusting', monday);
    await spend(phone, 5, monday.add(const Duration(hours: 1)));
    final here = memory();
    await mergeBackup(here, phone);
    final again = await mergeBackup(here, phone);
    expect(again.isEmpty, isTrue);
    expect(await balance(here), 5);
  });

  test('two phones: histories and balances add up', () async {
    final a = memory();
    final b = memory();
    await complete(a, 'dusting', monday, points: 15);
    await complete(b, 'dishes', monday.add(const Duration(hours: 1)));
    await complete(b, 'dusting', monday, points: 15); // the same moment
    final report = await mergeBackup(a, b);
    // Dusting at the same moment by the same profile is the same event.
    expect(report.completions, 1);
    expect(await countCompletions(a), 2);
    expect(await balance(a), 25);
  });

  test('an older backup of this phone adds nothing', () async {
    final phone = fileDb('${tmp.path}/phone.sqlite');
    await complete(phone, 'dusting', monday);
    final backup = '${tmp.path}/backup.sqlite';
    await writeSnapshot(phone, backup);
    await complete(phone, 'dishes', monday.add(const Duration(days: 1)));
    final report = await mergeBackup(phone, fileDb(backup));
    expect(report.isEmpty, isTrue);
    expect(await countCompletions(phone), 2);
  });

  test('a completion undone in the backup is undone here too', () async {
    final phone = memory();
    final id = await complete(phone, 'dusting', monday);
    final here = memory();
    await mergeBackup(here, phone);
    await undo(phone, id, monday.add(const Duration(minutes: 1)));
    final report = await mergeBackup(here, phone);
    expect(report.undone, 1);
    expect(report.ledger, 1);
    expect(await balance(here), 0);
    final c = await here.select(here.completions).getSingle();
    expect(c.undoneAt, isNotNull);
  });

  test('two equal purchases in one second stay two', () async {
    final phone = memory();
    await complete(phone, 'dusting', monday, points: 50);
    final at = monday.add(const Duration(hours: 1));
    await spend(phone, 10, at);
    await spend(phone, 10, at);
    final here = memory();
    await mergeBackup(here, phone);
    expect(await balance(here), 30);
    expect((await mergeBackup(here, phone)).isEmpty, isTrue);
  });

  test("the user's own chores match by title", () async {
    Future<void> addChore(AppDatabase db, String title) => db
        .into(db.chores)
        .insert(
          ChoresCompanion.insert(
            customTitle: Value(title),
            iconKey: 'star',
            colorKey: 1,
            basePoints: 5,
          ),
        );
    final phone = memory();
    await addChore(phone, 'Feed the cat');
    final here = memory();
    await addChore(here, '  feed the CAT ');
    expect((await mergeBackup(here, phone)).chores, 0);
  });

  test('inventory and screen days keep the larger values', () async {
    final phone = memory();
    final here = memory();
    for (final (db, potions, used, budget) in [
      (phone, 3, 30, 90),
      (here, 1, 50, 60),
    ]) {
      final profile = await db.defaultProfileId();
      await db
          .into(db.inventory)
          .insert(
            InventoryCompanion.insert(
              profileId: profile,
              itemKey: 'potion',
              count: potions,
            ),
          );
      await db
          .into(db.screenDays)
          .insert(
            ScreenDaysCompanion.insert(
              profileId: profile,
              day: DateTime(2026, 10, 26),
              usedMinutes: Value(used),
              budgetMinutes: Value(budget),
            ),
          );
    }
    await mergeBackup(here, phone);
    expect((await here.select(here.inventory).getSingle()).count, 3);
    final day = await here.select(here.screenDays).getSingle();
    expect((day.usedMinutes, day.budgetMinutes), (50, 90));
  });

  test('a preview reports but writes nothing', () async {
    final phone = memory();
    await complete(phone, 'dusting', monday);
    final here = memory();
    final report = await mergeBackup(here, phone, preview: true);
    expect(report.completions, 1);
    expect(await countCompletions(here), 0);
    expect((await mergeBackup(here, phone)).completions, 1);
  });

  group('checking files', () {
    test('a snapshot of this app is a backup', () async {
      final phone = memory();
      final path = '${tmp.path}/b.sqlite';
      await writeSnapshot(phone, path);
      expect(checkBackup(path, currentSchema: 7), 7);
    });

    test('a random file is not a backup', () {
      final path = '${tmp.path}/notes.txt';
      File(path).writeAsStringSync('shopping list: milk, eggs');
      expect(
        () => checkBackup(path, currentSchema: 7),
        throwsA(
          isA<BackupException>().having(
            (e) => e.problem,
            'problem',
            BackupProblem.notABackup,
          ),
        ),
      );
    });

    test("another app's database is not a backup", () {
      final path = '${tmp.path}/other.sqlite';
      sqlite.sqlite3.open(path)
        ..execute('CREATE TABLE notes (id INTEGER PRIMARY KEY, text TEXT)')
        ..userVersion = 3
        ..close();
      expect(
        () => checkBackup(path, currentSchema: 7),
        throwsA(
          isA<BackupException>().having(
            (e) => e.problem,
            'problem',
            BackupProblem.notABackup,
          ),
        ),
      );
    });

    test('a backup from a newer app version is refused', () async {
      final path = '${tmp.path}/new.sqlite';
      await writeSnapshot(memory(), path);
      sqlite.sqlite3.open(path)
        ..userVersion = 8
        ..close();
      expect(
        () => checkBackup(path, currentSchema: 7),
        throwsA(
          isA<BackupException>().having(
            (e) => e.problem,
            'problem',
            BackupProblem.tooNew,
          ),
        ),
      );
    });
  });

  for (final version in [1, 5]) {
    test('a backup from schema v$version is migrated and merged', () async {
      final path = '${tmp.path}/v$version.sqlite';
      final old = version == 1
          ? v1.DatabaseAtV1(NativeDatabase(File(path))) as GeneratedDatabase
          : v5.DatabaseAtV5(NativeDatabase(File(path)));
      await old.customStatement("INSERT INTO profiles (name) VALUES ('Me')");
      await old.customStatement(
        'INSERT INTO chores (seed_key, icon_key, color_key, base_points, '
        "sort_order) VALUES ('dusting', 'auto_awesome', 6, 15, 0)",
      );
      await old.customStatement(
        'INSERT INTO completions (chore_id, profile_id, completed_at, '
        "points_awarded) VALUES (1, 1, '2026-10-20T09:00:00.000', 15)",
      );
      await old.customStatement(
        'INSERT INTO point_ledger (profile_id, delta, reason, '
        'completion_id, created_at) '
        "VALUES (1, 15, 'completion', 1, '2026-10-20T09:00:00.000')",
      );
      await old.close();

      expect(checkBackup(path, currentSchema: 7), version);
      final here = memory();
      final report = await mergeBackup(here, fileDb(path));
      expect(report.completions, 1);
      expect(await balance(here), 15);
    });
  }

  test('undoing an import restores the data exactly', () async {
    final here = fileDb('${tmp.path}/here.sqlite');
    await complete(here, 'dusting', monday);
    final before = await here.select(here.completions).get();
    final ledgerBefore = await here.select(here.pointLedger).get();
    final safety = '${tmp.path}/safety.sqlite';
    await writeSnapshot(here, safety);

    final phone = memory();
    await complete(phone, 'dishes', monday.add(const Duration(hours: 1)));
    await phone
        .into(phone.chores)
        .insert(
          ChoresCompanion.insert(
            customTitle: const Value('Feed the cat'),
            iconKey: 'pets',
            colorKey: 2,
            basePoints: 5,
          ),
        );
    await mergeBackup(here, phone);
    expect(await countCompletions(here), 2);

    await restoreSnapshot(here, safety);
    expect(await here.select(here.completions).get(), before);
    expect(await here.select(here.pointLedger).get(), ledgerBefore);
    final titles = (await here.select(here.chores).get()).map(
      (c) => c.customTitle,
    );
    expect(titles, isNot(contains('Feed the cat')));
  });
}
