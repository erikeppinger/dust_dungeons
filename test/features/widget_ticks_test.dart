import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homework_and_chores/data/db/app_database.dart';
import 'package:homework_and_chores/data/providers.dart';
import 'package:homework_and_chores/features/home_widget/home_widget_sync.dart';

import '../helpers.dart';

class _Host implements HomeWidgetHost {
  _Host(this.waiting);

  final List<WidgetTick> waiting;

  @override
  Future<List<WidgetTick>> ticks() async => [...waiting];

  @override
  Future<void> dropTicks(List<DateTime> at) async =>
      waiting.removeWhere((t) => at.contains(t.at));

  @override
  Future<Set<String>> placed() async => {};

  @override
  Future<Directory> folder() => throw UnimplementedError();

  @override
  Future<void> refresh() async {}
}

/// Quests ticked off in the list widget (docs/design/scheduling.md).
void main() {
  late AppDatabase db;
  late int me;

  setUp(() async {
    db = memoryDb();
    addTearDown(db.close);
    me = await db.defaultProfileId();
  });

  Future<int> chore(String seedKey) async => (await (db.select(
    db.chores,
  )..where((c) => c.seedKey.equals(seedKey))).getSingle()).id;

  ProviderContainer container(List<WidgetTick> ticks) {
    final c = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        homeWidgetHostProvider.overrideWithValue(_Host(ticks)),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  test('a tick becomes a completion at the time it was made', () async {
    final at = DateTime(2026, 11, 10, 18, 30);
    final ticks = [
      WidgetTick(
        choreId: await chore('dusting'),
        profileId: me,
        at: at,
        onTime: true,
      ),
    ];
    expect(await bookWidgetTicks(container(ticks)), 1);
    expect(ticks, isEmpty, reason: 'booked ticks are forgotten');
    final done = (await db.select(db.completions).get()).single;
    expect(done.completedAt, at);
    expect(done.profileId, me);
    // Points are booked with it, at the same moment.
    final entry = (await db.select(db.pointLedger).get()).single;
    expect(entry.completionId, done.id);
    expect(entry.delta, done.pointsAwarded);
    expect(entry.createdAt, at);
    // Booking again finds nothing.
    expect(await bookWidgetTicks(container(ticks)), 0);
    expect(await db.select(db.completions).get(), hasLength(1));
  });

  test('on time earns the bonus, late does not', () async {
    final dusting = await chore('dusting');
    WidgetTick tick(int minute, {required bool onTime}) => WidgetTick(
      choreId: dusting,
      profileId: me,
      at: DateTime(2026, 11, 10, 9, minute),
      onTime: onTime,
    );
    await bookWidgetTicks(
      container([tick(1, onTime: false), tick(2, onTime: true)]),
    );
    final done = await (db.select(
      db.completions,
    )..orderBy([(c) => OrderingTerm.asc(c.completedAt)])).get();
    expect(done[1].pointsAwarded, greaterThan(done[0].pointsAwarded));
  });

  test('ticks for an archived quest or a removed person are dropped', () async {
    final ironing = await chore('ironing');
    await (db.update(db.chores)..where((c) => c.id.equals(ironing))).write(
      const ChoresCompanion(isArchived: Value(true)),
    );
    final ticks = [
      WidgetTick(
        choreId: ironing,
        profileId: me,
        at: DateTime(2026, 11, 10, 9),
        onTime: false,
      ),
      WidgetTick(
        choreId: await chore('dusting'),
        profileId: me + 99,
        at: DateTime(2026, 11, 10, 10),
        onTime: false,
      ),
      WidgetTick(
        choreId: 123456,
        profileId: me,
        at: DateTime(2026, 11, 10, 11),
        onTime: false,
      ),
    ];
    expect(await bookWidgetTicks(container(ticks)), 0);
    expect(ticks, isEmpty);
    expect(await db.select(db.completions).get(), isEmpty);
  });

  test('several ticks are booked oldest first', () async {
    final ticks = [
      WidgetTick(
        choreId: await chore('dusting'),
        profileId: me,
        at: DateTime(2026, 11, 11, 8),
        onTime: false,
      ),
      WidgetTick(
        choreId: await chore('ironing'),
        profileId: me,
        at: DateTime(2026, 11, 10, 8),
        onTime: false,
      ),
    ];
    expect(await bookWidgetTicks(container(ticks)), 2);
    final done = await (db.select(
      db.completions,
    )..orderBy([(c) => OrderingTerm.asc(c.id)])).get();
    expect(done.map((c) => c.completedAt), [
      DateTime(2026, 11, 10, 8),
      DateTime(2026, 11, 11, 8),
    ]);
  });
}
