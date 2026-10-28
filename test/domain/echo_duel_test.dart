import 'package:flutter_test/flutter_test.dart';
import 'package:homework_and_chores/domain/fight/boss.dart';
import 'package:homework_and_chores/domain/fight/echo_duel.dart';

const pattern = Pattern([0, 500, 750, 1000], beatMs: 500);

void main() {
  group('judging', () {
    test('exact taps are perfect', () {
      expect(judgeEcho(pattern, [0, 500, 750, 1000]), [
        Hit.perfect,
        Hit.perfect,
        Hit.perfect,
        Hit.perfect,
      ]);
    });

    test('window edges', () {
      expect(judgeEcho(pattern, [60, 620, 871, 1000]), [
        Hit.perfect, // 60 ms
        Hit.good, // 120 ms
        Hit.miss, // 121 ms: outside
        Hit.perfect,
        Hit.miss, // the unmatched tap at 871
      ]);
    });

    test('a missing tap is a miss, taps are matched in any order', () {
      expect(judgeEcho(pattern, [1010, 0, 740]), [
        Hit.perfect,
        Hit.miss,
        Hit.perfect,
        Hit.perfect,
      ]);
    });

    test('hammering the pad does not pay off', () {
      final taps = [for (var t = 0; t <= 1000; t += 50) t];
      final hits = judgeEcho(pattern, taps);
      expect(hits.where((h) => h == Hit.perfect), hasLength(4));
      expect(hits.where((h) => h == Hit.miss), hasLength(taps.length - 4));
    });

    test('one tap cannot count for two beats', () {
      const close = Pattern([0, 100], beatMs: 400);
      expect(judgeEcho(close, [50]), [Hit.perfect, Hit.miss]);
    });

    test('story mode windows are wider', () {
      expect(
        judgeEcho(pattern, [
          180,
          500,
          750,
          1000,
        ], windows: TimingWindows.story).first,
        Hit.good,
      );
    });
  });

  group('patterns', () {
    test('deterministic for a seed and start at 0', () {
      final a = PatternGenerator(
        bossStyles[BossFamily.dust]!,
        tier: 1,
        seed: 7,
      );
      final b = PatternGenerator(
        bossStyles[BossFamily.dust]!,
        tier: 1,
        seed: 7,
      );
      for (var i = 0; i < 20; i++) {
        final pa = a.next(phase: i % 2);
        final pb = b.next(phase: i % 2);
        expect(pa.beatsMs, pb.beatsMs);
        expect(pa.beatsMs.first, 0);
      }
    });

    test('beats are increasing and lengths grow with tier and phase', () {
      for (final family in BossFamily.values) {
        for (var tier = 1; tier <= 3; tier++) {
          final gen = PatternGenerator(
            bossStyles[family]!,
            tier: tier,
            seed: 3,
          );
          for (var phase = 0; phase < 2; phase++) {
            final p = gen.next(phase: phase);
            final minBeats = 2 + tier - 1 + phase;
            expect(p.beatsMs.length, inInclusiveRange(minBeats, minBeats + 1));
            for (var i = 1; i < p.beatsMs.length; i++) {
              expect(p.beatsMs[i], greaterThan(p.beatsMs[i - 1]));
            }
          }
        }
      }
    });

    test('the dust boss never syncopates', () {
      final gen = PatternGenerator(bossStyles[BossFamily.dust]!, tier: 3);
      for (var i = 0; i < 50; i++) {
        final p = gen.next(phase: 1);
        final eighth = p.beatMs ~/ 2;
        expect(p.beatsMs.every((b) => b % eighth == 0), isTrue);
      }
    });
  });

  group('duel', () {
    EchoDuel duel({bool story = false}) => EchoDuel(
      family: BossFamily.dust,
      tier: 1,
      hero: const HeroStats(maxHp: 5, damage: 1),
      storyMode: story,
    );

    test('perfect echoes win; stats and combo are tracked', () {
      final d = duel();
      while (d.outcome == DuelOutcome.ongoing) {
        final p = d.nextPattern();
        d.applyEcho(p, p.beatsMs);
      }
      expect(d.outcome, DuelOutcome.won);
      expect(d.bossHp, 0);
      expect(d.miss, 0);
      expect(d.bestCombo, d.perfect);
      expect(d.accuracy, 1);
      expect(d.heroHp, 5);
    });

    test('silence loses', () {
      final d = duel();
      while (d.outcome == DuelOutcome.ongoing) {
        d.applyEcho(d.nextPattern(), const []);
      }
      expect(d.outcome, DuelOutcome.lost);
      expect(d.heroHp, 0);
    });

    test('story mode cannot be lost', () {
      final d = duel(story: true);
      for (var i = 0; i < 30; i++) {
        d.applyEcho(d.nextPattern(), const []);
      }
      expect(d.outcome, DuelOutcome.ongoing);
      expect(d.heroHp, d.hero.maxHp);
    });

    test('phase 2 starts at half health', () {
      final d = duel();
      expect(d.phase, 0);
      d.bossHp = d.bossMaxHp ~/ 2;
      expect(d.phase, 1);
    });
  });

  group('progression', () {
    test('tiers by wins and boss health by tier', () {
      expect([0, 2, 3, 7, 8].map(tierForWins), [1, 1, 2, 2, 3]);
      expect([1, 2, 3].map(bossHpForTier), [16, 22, 28]);
    });

    test('hero grows slowly with level and is capped', () {
      expect(HeroStats.forLevel(1).maxHp, 5);
      expect(HeroStats.forLevel(1).damage, 1);
      expect(HeroStats.forLevel(8).damage, 3);
      expect(HeroStats.forLevel(100).maxHp, 12);
      expect(HeroStats.forLevel(100).damage, 4);
    });

    test('every built-in chore has a family and every family a style', () {
      expect(bossStyles.keys.toSet(), BossFamily.values.toSet());
      expect(familyOfSeed(null), BossFamily.clutter);
      expect(familyOfSeed('mopping'), BossFamily.dust);
    });
  });
}
