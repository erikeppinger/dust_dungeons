import 'package:flutter_test/flutter_test.dart';
import 'package:homework_and_chores/data/db/app_database.dart';
import 'package:homework_and_chores/data/models/fight_progress.dart';
import 'package:homework_and_chores/domain/fight/overlord.dart';
import 'package:homework_and_chores/game/game_data.dart';
import 'package:homework_and_chores/domain/fight/items.dart';

Chore chore(int id, {String? seedKey, BossFamily? family}) => Chore(
  id: id,
  seedKey: seedKey,
  iconKey: 'star',
  colorKey: 0,
  basePoints: 10,
  isArchived: false,
  assignment: Assignment.anyone,
  windowDays: 1,
  sortOrder: id,
  createdAt: DateTime(2026, 10, 1),
  repeatType: RepeatType.anytime,
  repeatInterval: 1,
  repeatWeekdays: 0,
  bossFamily: family,
);

var _id = 0;
Completion done(int choreId) => Completion(
  id: ++_id,
  choreId: choreId,
  profileId: 1,
  completedAt: DateTime(2026, 10, 28),
  pointsAwarded: 10,
);

Fight fight(
  BossFamily family, {
  FightResult? result,
  int perfect = 0,
  int good = 0,
  int miss = 0,
  DateTime? at,
  String? look,
  int tier = 1,
}) => Fight(
  id: ++_id,
  profileId: 1,
  family: family,
  tier: tier,
  storyMode: false,
  startedAt: at ?? DateTime(2026, 10, 28),
  result: result,
  perfect: perfect,
  good: good,
  miss: miss,
  look: look,
);

void main() {
  final chores = [
    chore(1, seedKey: 'dusting'), // dust
    chore(2, seedKey: 'mopping'), // dust
    chore(3), // user chore -> clutter
    chore(4, seedKey: 'dishes', family: BossFamily.clutter), // overridden
    chore(5, seedKey: 'laundry'), // laundry (not playable yet)
  ];

  test('tokens = completions of the family - fights started', () {
    final p = FightProgress(
      completions: [done(1), done(2), done(2), done(3), done(4), done(5)],
      chores: chores,
      fights: [fight(BossFamily.dust, result: FightResult.won)],
    );
    expect(p.tokens(BossFamily.dust), 2);
    expect(p.tokens(BossFamily.clutter), 2);
    expect(p.tokens(BossFamily.laundry), 1);
    expect(p.tokens(BossFamily.kitchen), 0);
    expect(p.totalTokens, 5);
  });

  test('abandoned and running fights still spend their token', () {
    final p = FightProgress(
      completions: [done(1), done(1)],
      chores: chores,
      fights: [
        fight(BossFamily.dust, result: FightResult.abandoned),
        fight(BossFamily.dust), // still running / app killed
      ],
    );
    expect(p.tokens(BossFamily.dust), 0);
  });

  test('an undo after spending is a debt the next completion pays back', () {
    final spent = [fight(BossFamily.dust, result: FightResult.lost)];
    // The completion was undone: none left, one fight started.
    var p = FightProgress(completions: [], chores: chores, fights: spent);
    expect(p.tokens(BossFamily.dust), 0);
    p = FightProgress(completions: [done(1)], chores: chores, fights: spent);
    expect(p.tokens(BossFamily.dust), 0, reason: 'paid the debt');
    p = FightProgress(
      completions: [done(1), done(2)],
      chores: chores,
      fights: spent,
    );
    expect(p.tokens(BossFamily.dust), 1);
  });

  test('wins, tiers, best accuracy and who can be fought', () {
    final p = FightProgress(
      completions: [done(1), done(5)],
      chores: chores,
      fights: [
        for (var i = 0; i < 3; i++)
          fight(
            BossFamily.clutter,
            result: FightResult.won,
            perfect: 8,
            good: 2,
            miss: i,
          ),
        fight(BossFamily.clutter, result: FightResult.lost),
      ],
    );
    expect(p.wins(BossFamily.clutter), 3);
    expect(p.tier(BossFamily.clutter), 2);
    expect(p.tier(BossFamily.dust), 1);
    expect(p.bestAccuracy(BossFamily.clutter), closeTo(0.9, 0.001));
    expect(p.bestAccuracy(BossFamily.dust), isNull);
    expect(p.canFight(BossFamily.dust), isTrue);
    expect(p.canFight(BossFamily.laundry), isTrue);
    expect(p.canFight(BossFamily.kitchen), isFalse, reason: 'no tokens');
    expect(p.totalWins, 3);
  });

  group('weekly Overlord', () {
    // Wednesday; the week runs Mon 26 Oct – Sun 1 Nov 2026.
    final today = DateTime(2026, 10, 28);
    Fight won(BossFamily f, DateTime at) =>
        fight(f, result: FightResult.won, at: at);

    test('counts chore-boss wins from Monday to Sunday only', () {
      final p = FightProgress(
        completions: [],
        chores: chores,
        fights: [
          won(BossFamily.dust, DateTime(2026, 10, 25, 23, 59)), // last week
          won(BossFamily.dust, DateTime(2026, 10, 26)), // Monday
          won(BossFamily.bath, DateTime(2026, 11, 1, 23, 59)), // Sunday
          won(BossFamily.dust, DateTime(2026, 11, 2)), // next week
          fight(BossFamily.trash, result: FightResult.lost, at: today),
        ],
      );
      expect(p.weekWins(today), 2);
      expect(p.weekBeaten(today), [BossFamily.dust, BossFamily.bath]);
      expect(p.overlordReady(today), isFalse);
    });

    test('appears after five wins and is gone for the week once beaten', () {
      final fights = [
        for (final f in [
          BossFamily.dust,
          BossFamily.kitchen,
          BossFamily.dust,
          BossFamily.trash,
          BossFamily.clutter,
        ])
          won(f, today),
      ];
      var p = FightProgress(completions: [], chores: chores, fights: fights);
      expect(p.overlordReady(today), isTrue);
      expect(p.weekBeaten(today), [
        BossFamily.dust,
        BossFamily.kitchen,
        BossFamily.trash,
        BossFamily.clutter,
      ]);
      expect(p.tier(BossFamily.overlord), 1);

      // A lost Overlord fight changes nothing; it stays until beaten.
      fights.add(
        fight(BossFamily.overlord, result: FightResult.lost, at: today),
      );
      p = FightProgress(completions: [], chores: chores, fights: fights);
      expect(p.overlordReady(today), isTrue);

      fights.add(won(BossFamily.overlord, today));
      p = FightProgress(completions: [], chores: chores, fights: fights);
      expect(p.overlordBeaten(today), isTrue);
      expect(p.overlordReady(today), isFalse);
      expect(p.weekWins(today), 5, reason: 'its own win does not count');
      expect(p.wins(BossFamily.overlord), 1);
      expect(
        p.overlordReady(DateTime(2026, 11, 2)),
        isFalse,
        reason: 'a new week starts from zero',
      );
    });

    test('Overlord fights spend no chore tokens', () {
      final p = FightProgress(
        completions: [done(1)],
        chores: chores,
        fights: [fight(BossFamily.overlord, result: FightResult.lost)],
      );
      expect(p.tokens(BossFamily.dust), 1);
      expect(p.totalTokens, 1);
      // The fight's result screen asks for the Overlord's tokens too.
      expect(p.tokens(BossFamily.overlord), 0);
      expect(p.tokens(BossFamily.kitchen), 0);
    });
  });

  test('week history runs from the first activity to this week', () {
    final p = FightProgress(
      completions: [
        Completion(
          id: 900,
          choreId: 1,
          profileId: 1,
          completedAt: DateTime(2026, 10, 14), // a Wednesday, 2 weeks back
          pointsAwarded: 10,
        ),
      ],
      chores: chores,
      fights: [
        fight(
          BossFamily.dust,
          result: FightResult.won,
          at: DateTime(2026, 10, 15),
        ),
        fight(
          BossFamily.trash,
          result: FightResult.lost,
          at: DateTime(2026, 10, 27),
        ),
        fight(
          BossFamily.bath,
          result: FightResult.won,
          at: DateTime(2026, 10, 28),
        ),
      ],
    );
    final weeks = p.weekHistory(DateTime(2026, 10, 28));
    expect(weeks.map((w) => w.monday), [
      DateTime(2026, 10, 12),
      DateTime(2026, 10, 19),
      DateTime(2026, 10, 26),
    ]);
    expect(weeks.map((w) => w.wins), [
      [BossFamily.dust],
      <BossFamily>[],
      [BossFamily.bath],
    ]);
    expect(weeks.every((w) => !w.beaten), isTrue);
    expect(
      FightProgress(
        completions: [],
        chores: chores,
        fights: [],
      ).weekHistory(DateTime(2026, 10, 28)).single.monday,
      DateTime(2026, 10, 26),
      reason: 'without history, just this week',
    );
  });

  group('weekly Overlords', () {
    final monday = DateTime(2026, 12, 21);
    final festive = OverlordLook.forWeek(monday, holidays: {'christmas'});

    test('the beaten Overlord keeps the look it had', () {
      final progress = FightProgress(
        completions: const [],
        chores: const [],
        fights: [
          fight(
            BossFamily.overlord,
            result: FightResult.lost,
            at: monday,
            look: OverlordLook.classic.key,
          ),
          fight(
            BossFamily.overlord,
            result: FightResult.won,
            at: monday.add(const Duration(days: 2)),
            look: festive.key,
          ),
        ],
      );
      expect(progress.beatenOverlord(monday), festive);
      expect(
        progress.beatenOverlord(monday.add(const Duration(days: 7))),
        isNull,
      );
      expect(progress.weekHistory(monday).last.overlord, festive);
      expect(progress.holidayWins, {'christmas': 1});
    });

    test('a holiday win gives its boon for 14 days', () {
      final progress = FightProgress(
        completions: const [],
        chores: const [],
        fights: [
          fight(
            BossFamily.overlord,
            result: FightResult.won,
            at: DateTime(2026, 12, 23, 18),
            look: festive.key,
          ),
        ],
      );
      expect(progress.activeBoons(DateTime(2026, 12, 22)), isEmpty);
      expect(progress.activeBoons(DateTime(2026, 12, 23)), [('christmas', 14)]);
      expect(progress.activeBoons(DateTime(2027, 1, 5)), [('christmas', 1)]);
      expect(progress.activeBoons(DateTime(2027, 1, 6)), isEmpty);
      final boon = overlordHolidays['christmas']!.boon;
      expect(const Loadout().against().hearts, 0);
      expect(Loadout(boon: boon).against().hearts, boon.hearts);
      expect(boon, isNot(Effects.none));
    });

    test('wins from before 0.15.0 show the classic Overlord', () {
      final progress = FightProgress(
        completions: const [],
        chores: const [],
        fights: [fight(BossFamily.overlord, result: FightResult.won)],
      );
      expect(
        progress.beatenOverlord(DateTime(2026, 10, 28)),
        OverlordLook.classic,
      );
      expect(progress.holidayWins, isEmpty);
    });
  });
}
