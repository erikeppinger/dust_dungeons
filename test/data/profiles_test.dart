import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:homework_and_chores/data/backup/merge.dart';
import 'package:homework_and_chores/data/db/app_database.dart';
import 'package:homework_and_chores/data/models/scheduled_chore.dart';
import 'package:homework_and_chores/data/repositories/profile_repository.dart';

import '../helpers.dart';

/// Several people on one phone: docs/design/profiles.md.
void main() {
  final today = DateTime(2026, 10, 28);
  const sam = 1, alex = 2;

  Chore chore(int id, Assignment assignment) => Chore(
    id: id,
    customTitle: 'Chore $id',
    iconKey: 'star',
    colorKey: 0,
    basePoints: 10,
    isArchived: false,
    sortOrder: id,
    createdAt: DateTime(2026, 10, 1),
    repeatType: RepeatType.daily,
    repeatInterval: 1,
    repeatWeekdays: 0,
    repeatStart: DateTime(2026, 10, 1),
    assignment: assignment,
    windowDays: 1,
  );

  group('who sees which quest, and when it is due', () {
    final dishes = chore(1, Assignment.anyone);
    final trash = chore(2, Assignment.one);
    final bed = chore(3, Assignment.each);
    final chores = [dishes, trash, bed];
    final assignees = {
      2: {sam},
      3: {sam, alex},
    };

    List<ScheduledChore> forPerson(
      int? person, {
      Map<(int, int), DateTime> last = const {},
      Map<(int, int), int> done = const {},
    }) => schedule(
      chores: chores,
      assignees: assignees,
      lastDone: last,
      doneToday: done,
      today: today,
      person: person,
    );

    test("anyone's chore done by Sam is done for Alex too", () {
      final list = forPerson(
        alex,
        last: {(1, sam): today},
        done: {(1, sam): 1},
      );
      final s = list.singleWhere((s) => s.chore.id == 1);
      expect(s.isDueToday, isFalse);
      expect(s.isDoneToday, isTrue);
      expect(s.doneBy, {sam});
      expect(s.person, isNull);
    });

    test("one person's chore is invisible to others", () {
      expect(forPerson(alex).map((s) => s.chore.id), isNot(contains(2)));
      expect(forPerson(sam).map((s) => s.chore.id), contains(2));
    });

    test("each person's chore stays due for Alex after Sam did his", () {
      final list = forPerson(
        alex,
        last: {(3, sam): today},
        done: {(3, sam): 1},
      );
      final bedForAlex = list.singleWhere((s) => s.chore.id == 3);
      // Still open for Alex (overdue, since he never did it).
      expect(bedForAlex.isDueToday || bedForAlex.isOverdue, isTrue);
      expect(bedForAlex.isDoneToday, isFalse);
      expect(bedForAlex.person, alex);
    });

    test('a personal chore is overdue only for its person', () {
      final list = forPerson(
        null,
        last: {
          (3, sam): today.subtract(const Duration(days: 3)),
          (3, alex): today,
        },
      );
      final beds = list.where((s) => s.chore.id == 3).toList();
      expect(beds.singleWhere((s) => s.person == sam).isOverdue, isTrue);
      expect(beds.singleWhere((s) => s.person == alex).isOverdue, isFalse);
    });

    test("the household sees anyone's chores once and personal ones per "
        'person', () {
      final list = forPerson(null);
      expect(
        [for (final s in list) (s.chore.id, s.person)],
        [(1, null), (2, sam), (3, sam), (3, alex)],
      );
    });
  });

  group('people', () {
    late AppDatabase db;
    late ProfileRepository repo;

    setUp(() {
      db = memoryDb();
      repo = ProfileRepository(db);
    });
    tearDown(() => db.close());

    Future<int> addChore(String title) => db
        .into(db.chores)
        .insert(
          ChoresCompanion.insert(
            customTitle: Value(title),
            iconKey: 'star',
            colorKey: 0,
            basePoints: 5,
          ),
        );

    Future<Chore> choreOf(int id) =>
        (db.select(db.chores)..where((c) => c.id.equals(id))).getSingle();

    test('names are unique, ignoring case and spaces', () async {
      await repo.add(name: 'Sam');
      expect(await repo.nameTaken(' sam '), isTrue);
      expect(await repo.nameTaken('Alex'), isFalse);
      final me = await db.defaultProfileId();
      expect(await repo.nameTaken('me', exceptId: me), isFalse);
    });

    test('removing someone hands their chores to anyone and keeps their '
        'history; adding the name again brings them back', () async {
      final me = await db.defaultProfileId();
      final sam = await repo.add(name: 'Sam');
      final trash = await addChore('Trash');
      final bed = await addChore('Make bed');
      await repo.assign(trash, Assignment.one, {sam});
      await repo.assign(bed, Assignment.each, {sam, me});
      await db
          .into(db.completions)
          .insert(
            CompletionsCompanion.insert(
              choreId: trash,
              profileId: sam,
              completedAt: today,
              pointsAwarded: 5,
            ),
          );

      await repo.remove(sam);
      expect((await repo.active()).map((p) => p.name), ['Me']);
      expect((await choreOf(trash)).assignment, Assignment.anyone);
      expect((await choreOf(bed)).assignment, Assignment.each);
      final left = await db.select(db.choreAssignees).get();
      expect([for (final a in left) (a.choreId, a.profileId)], [(bed, me)]);
      expect(await db.select(db.completions).get(), hasLength(1));

      expect(await repo.add(name: 'sam'), sam);
      expect((await repo.active()).map((p) => p.name), ['Me', 'Sam']);
    });

    test('the last person cannot be removed', () async {
      final me = await db.defaultProfileId();
      expect(() => repo.remove(me), throwsStateError);
    });

    test("one person's chore keeps a single assignee; nobody means "
        'anyone', () async {
      final me = await db.defaultProfileId();
      final sam = await repo.add(name: 'Sam');
      final trash = await addChore('Trash');
      await repo.assign(trash, Assignment.one, {sam, me});
      expect(await db.select(db.choreAssignees).get(), hasLength(1));
      await repo.assign(trash, Assignment.each, {});
      expect((await choreOf(trash)).assignment, Assignment.anyone);
    });
  });

  test('backups bring people with their hero, and chore assignments', () async {
    final phone = memoryDb();
    final here = memoryDb();
    addTearDown(phone.close);
    addTearDown(here.close);
    final phoneRepo = ProfileRepository(phone);
    final sam = await phoneRepo.add(name: 'Sam', avatarCape: 3);
    await phoneRepo.update(
      sam,
      const ProfilesCompanion(storyMode: Value(true)),
    );
    final trash = await phone
        .into(phone.chores)
        .insert(
          ChoresCompanion.insert(
            customTitle: const Value('Trash'),
            iconKey: 'delete',
            colorKey: 0,
            basePoints: 5,
          ),
        );
    await phoneRepo.assign(trash, Assignment.one, {sam});

    final report = await mergeBackup(here, phone);
    expect(report.profiles, 1);
    expect(report.assignees, 1);
    final samHere = (await ProfileRepository(
      here,
    ).active()).singleWhere((p) => p.name == 'Sam');
    expect((samHere.avatarCape, samHere.storyMode), (3, true));
    final trashHere = (await here.select(here.chores).get()).singleWhere(
      (c) => c.customTitle == 'Trash',
    );
    expect(trashHere.assignment, Assignment.one);
    final assigned = await here.select(here.choreAssignees).getSingle();
    expect(assigned.profileId, samHere.id);
    expect((await mergeBackup(here, phone)).isEmpty, isTrue);
  });
}
