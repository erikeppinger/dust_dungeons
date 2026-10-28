import 'package:flutter_test/flutter_test.dart';
import 'package:homework_and_chores/domain/fight/boss.dart';
import 'package:homework_and_chores/domain/fight/calibration.dart';
import 'package:homework_and_chores/domain/fight/echo_duel.dart';
import 'package:homework_and_chores/domain/fight/lanes.dart';

void main() {
  group('lane notes', () {
    test('deterministic for a seed, on the eighth grid, inside the bars', () {
      List<LaneNote> write() =>
          LaneGenerator(beatMs: 600, tier: 2, seed: 7).bars(1000, 2);
      final a = write(), b = write();
      expect(a.map((n) => (n.lane, n.atMs)), b.map((n) => (n.lane, n.atMs)));
      expect(a, isNotEmpty);
      for (final n in a) {
        expect(n.lane, inInclusiveRange(0, laneCount - 1));
        expect((n.atMs - 1000) % 300, 0);
        expect(
          n.atMs,
          lessThan(1000 + LaneGenerator(beatMs: 600, tier: 2).barsMs(2)),
        );
      }
    });

    test('higher tiers write more notes', () {
      int count(int tier) =>
          LaneGenerator(beatMs: 600, tier: tier, seed: 3).bars(0, 40).length;
      expect(count(3), greaterThan(count(1)));
    });
  });

  group('lane judge', () {
    LaneJudge judge() => LaneJudge(windows: TimingWindows.normal)
      ..add(const [LaneNote(0, 1000), LaneNote(1, 1000), LaneNote(0, 1500)]);

    test('a tap takes the nearest open note of its own lane', () {
      final j = judge();
      expect(j.tap(0, 1040), Hit.perfect);
      expect(j.tap(0, 1420), Hit.good, reason: 'the 1000 note is taken');
      expect(j.tap(2, 1000), isNull, reason: 'nothing in lane 2');
      expect(j.tap(1, 1200), isNull, reason: 'outside the good window');
      expect(j.results, [Hit.perfect, null, Hit.good]);
    });

    test('notes nobody tapped expire as misses once', () {
      final j = judge();
      expect(j.expire(1120), 0, reason: 'still inside the window');
      expect(j.expire(1121), 2);
      expect(j.expire(1121), 0);
      expect(j.results, [Hit.miss, Hit.miss, null]);
      expect(j.tap(0, 1000), isNull, reason: 'a missed note cannot be hit');
    });
  });

  group('Overlord', () {
    OverlordDuel duel({List<BossFamily> motifs = const []}) => OverlordDuel(
      tier: 1,
      hero: const HeroStats(maxHp: 5, damage: 1),
      motifs: motifs,
      seed: 1,
    );

    test('three phases by thirds of its double health, lanes last', () {
      final d = duel();
      expect(d.bossMaxHp, overlordHpForTier(1));
      expect(d.bossMaxHp, 2 * bossHpForTier(1));
      expect(d.phaseCount, 3);
      expect((d.phase, d.lanePhase), (0, false));
      d.bossHp = d.bossMaxHp * 2 ~/ 3;
      expect((d.phase, d.lanePhase), (1, false));
      d.bossHp = d.bossMaxHp ~/ 3;
      expect((d.phase, d.lanePhase), (2, true));
    });

    test('echo rounds borrow the beaten bosses\' rhythms in turn', () {
      final d = duel(motifs: [BossFamily.bath, BossFamily.outside]);
      int pulse(BossFamily f) => beatMsFor(bossStyles[f]!, 1, 1);
      expect(
        [for (var i = 0; i < 4; i++) d.nextPattern().beatMs],
        [
          pulse(BossFamily.bath),
          pulse(BossFamily.outside),
          pulse(BossFamily.bath),
          pulse(BossFamily.outside),
        ],
      );
    });

    test('lane hits damage it like echo hits; strays only break the combo', () {
      final d = duel();
      d.applyHits([Hit.perfect, Hit.good]);
      expect(d.bossHp, d.bossMaxHp - 3);
      expect(d.combo, 2);
      d.breakCombo();
      expect(d.combo, 0);
      expect(d.heroHp, 5);
    });

    test('regular bosses keep two phases and no lanes', () {
      final d = EchoDuel(
        family: BossFamily.dust,
        tier: 1,
        hero: const HeroStats(maxHp: 5, damage: 1),
      );
      expect(d.phaseCount, 2);
      d.bossHp = 1;
      expect(d.lanePhase, isFalse);
    });
  });

  test('slow mode plays at 70 % tempo', () {
    EchoDuel duel({required bool slow}) => EchoDuel(
      family: BossFamily.dust,
      tier: 1,
      hero: const HeroStats(maxHp: 5, damage: 1),
      slowMode: slow,
    );
    final normal = duel(slow: false).nextPattern().beatMs;
    final slow = duel(slow: true).nextPattern().beatMs;
    expect(slow, (normal / EchoDuel.slowTempo).round());
  });

  group('calibration', () {
    const beats = [0, 600, 1200, 1800, 2400];

    test('the median delay of taps near a beat', () {
      expect(calibrationOffset(beats, [40, 650, 1230, 1860, 2445]), 45);
      expect(calibrationOffset(beats, [-20, 580, 1190, 1785]), -18);
    });

    test('taps far from every beat are ignored', () {
      expect(calibrationOffset(beats, [40, 300, 650, 1230, 1860]), 45);
    });

    test('too few usable taps give no result', () {
      expect(calibrationOffset(beats, [40, 650, 1230]), isNull);
      expect(calibrationOffset(beats, []), isNull);
    });
  });
}
