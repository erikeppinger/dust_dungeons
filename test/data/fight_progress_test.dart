import 'package:flutter_test/flutter_test.dart';
import 'package:homework_and_chores/data/db/app_database.dart';
import 'package:homework_and_chores/data/models/fight_progress.dart';

Chore chore(int id, {String? seedKey, BossFamily? family}) => Chore(
  id: id,
  seedKey: seedKey,
  iconKey: 'star',
  colorKey: 0,
  basePoints: 10,
  isArchived: false,
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
}) => Fight(
  id: ++_id,
  profileId: 1,
  family: family,
  tier: 1,
  storyMode: false,
  startedAt: DateTime(2026, 10, 28),
  result: result,
  perfect: perfect,
  good: good,
  miss: miss,
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
    expect(p.canFight(BossFamily.laundry), isFalse, reason: 'not playable yet');
    expect(p.totalWins, 3);
  });
}
