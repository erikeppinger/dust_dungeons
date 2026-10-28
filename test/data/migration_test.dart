import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homework_and_chores/data/db/app_database.dart';
import 'package:homework_and_chores/domain/default_chores.dart';

import 'generated_migrations/schema.dart';
import 'generated_migrations/schema_v1.dart' as v1;
import 'generated_migrations/schema_v2.dart' as v2;
import 'generated_migrations/schema_v3.dart' as v3;
import 'generated_migrations/schema_v4.dart' as v4;

void main() {
  late SchemaVerifier verifier;

  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  for (final from in [1, 2, 3, 4]) {
    test('v$from -> v5 produces the current schema', () async {
      final schema = await verifier.schemaAt(from);
      final db = AppDatabase(schema.newConnection());
      await verifier.migrateAndValidate(db, 5);
      await db.close();
    });
  }

  test('v1 -> v4 keeps data and gives built-in chores a rhythm', () async {
    final schema = await verifier.schemaAt(1);
    final old = v1.DatabaseAtV1(schema.newConnection());
    await old.customStatement("INSERT INTO profiles (name) VALUES ('Me')");
    await old.customStatement(
      'INSERT INTO chores (seed_key, icon_key, color_key, base_points, '
      "sort_order) VALUES ('dusting', 'auto_awesome', 6, 15, 0)",
    );
    await old.customStatement(
      'INSERT INTO chores (custom_title, icon_key, color_key, base_points, '
      "sort_order, is_archived) VALUES ('Wäsche 🧺', 'star', 2, 10, 99, 1)",
    );
    await old.customStatement(
      'INSERT INTO completions (chore_id, profile_id, completed_at, '
      "points_awarded) VALUES (1, 1, '2026-10-20T09:00:00.000', 15)",
    );
    await old.customStatement(
      'INSERT INTO point_ledger (profile_id, delta, reason, completion_id, '
      "created_at) VALUES (1, 15, 'completion', 1, '2026-10-20T09:00:00.000')",
    );
    await old.close();

    final now = DateTime(2026, 10, 28, 12);
    final db = AppDatabase(schema.newConnection(), clock: () => now);
    addTearDown(db.close);

    final chores = await db.select(db.chores).get();
    final dusting = chores.singleWhere((c) => c.seedKey == 'dusting');
    expect(dusting.repeatType, RepeatType.afterDone);
    expect(dusting.repeatInterval, 7);
    expect(dusting.repeatSetAt, now);

    final custom = chores.singleWhere((c) => c.seedKey == null);
    expect(custom.customTitle, 'Wäsche 🧺');
    expect(custom.isArchived, isTrue);
    expect(custom.repeatType, RepeatType.anytime);

    // Missing built-ins are added on open, existing ones are kept.
    expect(chores, hasLength(defaultChores.length + 1));
    expect(await db.select(db.completions).get(), hasLength(1));
    expect((await db.select(db.pointLedger).get()).single.delta, 15);
  });

  test('v2 -> v4 keeps schedules; reminders start switched off', () async {
    final schema = await verifier.schemaAt(2);
    final old = v2.DatabaseAtV2(schema.newConnection());
    await old.customStatement("INSERT INTO profiles (name) VALUES ('Me')");
    await old.customStatement(
      'INSERT INTO chores (custom_title, icon_key, color_key, base_points, '
      'sort_order, repeat_type, repeat_interval, repeat_weekdays) '
      "VALUES ('Müll', 'delete', 3, 5, 0, 'weekly', 2, 9)",
    );
    await old.close();

    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);
    final chore = (await db.select(db.chores).get()).singleWhere(
      (c) => c.customTitle == 'Müll',
    );
    expect(chore.recurrence.type, RepeatType.weekly);
    expect(chore.recurrence.interval, 2);
    expect(chore.recurrence.weekdays, {DateTime.monday, DateTime.thursday});
    expect(chore.reminderMinutes, isNull);
  });

  test('v3 -> v4: past completions become tokens, no fights yet', () async {
    final schema = await verifier.schemaAt(3);
    final old = v3.DatabaseAtV3(schema.newConnection());
    await old.customStatement("INSERT INTO profiles (name) VALUES ('Me')");
    await old.customStatement(
      'INSERT INTO chores (seed_key, icon_key, color_key, base_points, '
      "sort_order, reminder_minutes) VALUES ('dusting', 'auto_awesome', 6, 15, 0, 540)",
    );
    await old.customStatement(
      'INSERT INTO completions (chore_id, profile_id, completed_at, '
      "points_awarded) VALUES (1, 1, '2026-10-27T09:00:00.000', 15)",
    );
    await old.close();

    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);
    final dusting = (await db.select(db.chores).get()).singleWhere(
      (c) => c.seedKey == 'dusting',
    );
    expect(dusting.bossFamily, isNull);
    expect(dusting.family, BossFamily.dust);
    expect(dusting.reminderMinutes, 540);
    expect(await db.select(db.fights).get(), isEmpty);
    expect(await db.select(db.completions).get(), hasLength(1));
  });

  test(
    'v4 -> v5 keeps fights and points; the inventory starts empty',
    () async {
      final schema = await verifier.schemaAt(4);
      final old = v4.DatabaseAtV4(schema.newConnection());
      await old.customStatement("INSERT INTO profiles (name) VALUES ('Me')");
      await old.customStatement(
        'INSERT INTO fights (profile_id, family, tier, started_at, result) '
        "VALUES (1, 'dust', 1, '2026-10-28T10:00:00.000', 'won')",
      );
      await old.customStatement(
        'INSERT INTO point_ledger (profile_id, delta, reason, created_at) '
        "VALUES (1, 40, 'completion', '2026-10-28T09:00:00.000')",
      );
      await old.close();

      final db = AppDatabase(schema.newConnection());
      addTearDown(db.close);
      expect((await db.select(db.fights).get()).single.result, FightResult.won);
      expect(await db.select(db.inventory).get(), isEmpty);
      expect((await db.select(db.pointLedger).get()).single.delta, 40);
    },
  );
}
