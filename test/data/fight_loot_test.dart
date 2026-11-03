import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:homework_and_chores/data/db/app_database.dart';
import 'package:homework_and_chores/data/repositories/fight_repository.dart';
import 'package:homework_and_chores/data/repositories/profile_repository.dart';
import 'package:homework_and_chores/data/repositories/progress_repository.dart';
import 'package:homework_and_chores/game/game_data.dart';
import 'package:homework_and_chores/domain/fight/items.dart';
import 'package:homework_and_chores/domain/fight/shop.dart';

import '../helpers.dart';

/// Loot and curses as fights are recorded: docs/design/items.md.
void main() {
  late AppDatabase db;
  late FightRepository fights;
  late int profile;

  setUp(() async {
    db = memoryDb();
    fights = FightRepository(db);
    profile = await db.defaultProfileId();
  });

  tearDown(() => db.close());

  Future<int> start(BossFamily family, {int tier = 1, bool story = false}) =>
      fights.start(
        profileId: profile,
        family: family,
        tier: tier,
        storyMode: story,
      );

  Future<ShopItem?> finish(int id, FightResult result, {bool curses = true}) =>
      fights.finish(
        id,
        result: result,
        perfect: 0,
        good: 0,
        miss: 0,
        curses: curses,
      );

  Future<BossFamily?> curse() async => (await (db.select(
    db.profiles,
  )..where((p) => p.id.equals(profile))).getSingle()).curseFamily;

  Future<Map<String, int>> owned() async => {
    for (final i in await db.select(db.inventory).get()) i.itemKey: i.count,
  };

  test('a lost fight curses; the next fight uses the curse up', () async {
    await finish(await start(BossFamily.laundry), FightResult.lost);
    expect(await curse(), BossFamily.laundry);
    final next = await start(BossFamily.dust);
    expect(await curse(), isNull);
    await finish(next, FightResult.won);
    expect(await curse(), isNull);
  });

  test('a new curse replaces the old one', () async {
    await finish(await start(BossFamily.laundry), FightResult.lost);
    await db
        .into(db.fights)
        .insert(
          FightsCompanion.insert(
            profileId: profile,
            family: BossFamily.trash,
            tier: 1,
            startedAt: DateTime(2026, 11, 2),
          ),
        );
    final id = (await db.select(db.fights).get()).last.id;
    await finish(id, FightResult.lost);
    expect(await curse(), BossFamily.trash);
  });

  test('no curse in story mode, when off, or for abandoned fights', () async {
    await finish(await start(BossFamily.dust, story: true), FightResult.lost);
    expect(await curse(), isNull);
    await finish(await start(BossFamily.dust), FightResult.lost, curses: false);
    expect(await curse(), isNull);
    await finish(await start(BossFamily.dust), FightResult.abandoned);
    expect(await curse(), isNull);
  });

  test('a quest of the cursing family lifts the curse', () async {
    final progress = ProgressRepository(db);
    Future<void> doQuest(String seed) async {
      final chore = (await db.select(db.chores).get()).singleWhere(
        (c) => c.seedKey == seed,
      );
      await progress.complete(choreId: chore.id, profileId: profile);
    }

    await finish(await start(BossFamily.laundry), FightResult.lost);
    await doQuest('dishes');
    expect(await curse(), BossFamily.laundry);
    await doQuest('ironing');
    expect(await curse(), isNull);
  });

  test(
    'the Overlord always drops, into the bag and onto a free slot',
    () async {
      final loot = await finish(
        await start(BossFamily.overlord),
        FightResult.won,
      );
      expect(lootTable(BossFamily.overlord), contains(loot));
      expect(await owned(), {loot!.key: 1});
      final worn = await db.select(db.equipped).getSingle();
      expect(worn.itemKey, loot.key);
      final fight = await db.select(db.fights).getSingle();
      expect(fight.loot, loot.key);
    },
  );

  test('the fifth win without loot always drops', () async {
    ShopItem? last;
    for (var i = 0; i < 5; i++) {
      last = await finish(await start(BossFamily.bath), FightResult.won);
      if (last != null) break;
    }
    expect(last, plungerOfSmitingItem);
  });

  test('a fight is recorded once and drops loot once', () async {
    final id = await start(BossFamily.overlord);
    expect(await finish(id, FightResult.won), isNotNull);
    expect(await finish(id, FightResult.won), isNull);
    expect(await finish(id, FightResult.lost), isNull);
    expect((await owned()).values.fold(0, (a, b) => a + b), 1);
    expect(await curse(), isNull);
  });

  test('losses drop nothing', () async {
    for (var i = 0; i < 6; i++) {
      expect(
        await finish(await start(BossFamily.kitchen), FightResult.lost),
        isNull,
      );
    }
    expect(await owned(), isEmpty);
  });

  test('turning curses off lifts everyone\'s', () async {
    await db.into(db.profiles).insert(ProfilesCompanion.insert(name: 'Sam'));
    await db
        .update(db.profiles)
        .write(const ProfilesCompanion(curseFamily: Value(BossFamily.dust)));
    await ProfileRepository(db).liftAllCurses();
    expect(
      (await db.select(db.profiles).get()).every((p) => p.curseFamily == null),
      isTrue,
    );
  });
}
