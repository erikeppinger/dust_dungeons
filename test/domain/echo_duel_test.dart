import 'package:flutter_test/flutter_test.dart';
import 'package:homework_and_chores/game/game_data.dart';
import 'package:homework_and_chores/domain/fight/boss.dart';
import 'package:homework_and_chores/domain/fight/difficulty.dart';
import 'package:homework_and_chores/domain/fight/echo_duel.dart';
import 'package:homework_and_chores/domain/fight/items.dart';
import 'package:homework_and_chores/domain/fight/shop.dart';

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

  group('gear', () {
    EchoDuel geared(Loadout loadout, {BossFamily family = BossFamily.dust}) =>
        EchoDuel(
          family: family,
          tier: 1,
          hero: const HeroStats(maxHp: 5, damage: 1),
          loadout: loadout,
        );

    Loadout wearing(List<ShopItem> items, {Curse? curse}) =>
        Loadout(gear: {for (final i in items) i.slot!: i}, curse: curse);

    /// Cleaning done by one echo: all perfect, or all good (taps 100 ms late).
    int perfectEcho(Loadout l, {BossFamily family = BossFamily.dust}) {
      final d = geared(l, family: family)..applyEcho(pattern, pattern.beatsMs);
      return d.bossMaxHp - d.bossHp;
    }

    int goodEcho(Loadout l) {
      final d = geared(l)
        ..applyEcho(pattern, [for (final b in pattern.beatsMs) b + 100]);
      return d.bossMaxHp - d.bossHp;
    }

    const oneMiss = [0, 500, 750];

    test('Sponge Shield forgives the first miss of the fight only', () {
      final d = geared(wearing([spongeShieldItem]));
      expect(d.freeMissesLeft, 1);
      d.applyEcho(pattern, oneMiss);
      expect(d.heroHp, 5);
      expect(d.freeMissesLeft, 0);
      d.applyEcho(pattern, oneMiss);
      expect(d.heroHp, 4);
    });

    test('Trash-Can Lid forgives two misses', () {
      final d = geared(wearing([trashCanLidItem]));
      d
        ..applyEcho(pattern, oneMiss)
        ..applyEcho(pattern, oneMiss)
        ..applyEcho(pattern, oneMiss);
      expect(d.heroHp, 4);
    });

    test('Turbo Mop: perfect hits deal triple damage', () {
      expect(perfectEcho(Loadout.none), 8);
      expect(perfectEcho(wearing([turboMopItem])), 12);
    });

    test('Plunger: ×3, and ×4 against the bath boss', () {
      expect(perfectEcho(wearing([plungerOfSmitingItem])), 12);
      expect(
        perfectEcho(wearing([plungerOfSmitingItem]), family: BossFamily.bath),
        16,
      );
    });

    test('Spatula and Coffee add to good hits only', () {
      expect(goodEcho(Loadout.none), 4);
      expect(goodEcho(wearing([spatulaOfFlippingItem])), 8);
      expect(perfectEcho(wearing([spatulaOfFlippingItem])), 8);
      expect(
        goodEcho(
          const Loadout(
            gear: {GearSlot.weapon: spatulaOfFlippingItem},
            consumables: [coffeeOfHasteItem],
          ),
        ),
        12,
      );
    });

    test('Mop of Doom: ×3 perfect and +1 on good hits', () {
      expect(perfectEcho(wearing([mopOfDoomItem])), 12);
      expect(goodEcho(wearing([mopOfDoomItem])), 8);
    });

    test('Feather Duster: +1 damage on every hit against dust only', () {
      expect(perfectEcho(wearing([featherDusterItem])), 12);
      expect(
        perfectEcho(wearing([featherDusterItem]), family: BossFamily.kitchen),
        8,
      );
    });

    test('Fuzzy Slippers: the first echo deals half as much again', () {
      final good = [for (final b in pattern.beatsMs) b + 100];
      final d = geared(wearing([fuzzySlippersItem]))..applyEcho(pattern, good);
      expect(d.bossMaxHp - d.bossHp, 8); // 1 + 1 per good hit
      d.applyEcho(pattern, good);
      expect(d.bossMaxHp - d.bossHp, 12);
      expect(
        perfectEcho(wearing([fuzzySlippersItem])),
        12,
      ); // 2 + 1 per perfect
    });

    test('Metronome Charm widens the windows; a curse tightens them', () {
      final d = geared(wearing([metronomeCharmItem]));
      expect(d.windows.goodMs, greaterThan(TimingWindows.normal.goodMs));
      expect(d.applyEcho(pattern, const [150, 500, 750, 1000]).first, Hit.good);
      final cursed = geared(
        wearing([metronomeCharmItem], curse: curseOf(BossFamily.dust)),
      );
      expect(cursed.windows, TimingWindows.tight);
    });

    test('hearts from gear, boots against bath and outside only', () {
      expect(geared(wearing([rubberGlovesItem])).hero.maxHp, 6);
      expect(geared(wearing([hiVisVestItem, colanderOfClarityItem])).heroHp, 8);
      expect(geared(wearing([rubberBootsItem])).hero.maxHp, 5);
      expect(
        geared(
          wearing([rubberBootsItem]),
          family: BossFamily.outside,
        ).hero.maxHp,
        7,
      );
      expect(geared(wearing([laundryBasketHelmItem])).hero.maxHp, 6);
      expect(
        geared(
          wearing([laundryBasketHelmItem]),
          family: BossFamily.laundry,
        ).hero.maxHp,
        7,
      );
      expect(
        geared(const Loadout(consumables: [snackBreakItem])).hero.maxHp,
        7,
      );
    });

    test('a heart curse never leaves fewer than three hearts', () {
      final curse = curseOf(BossFamily.laundry);
      expect(geared(wearing([], curse: curse)).hero.maxHp, 4);
      expect(heartsWith(3, curse.effects), 3);
      expect(heartsWith(2, curse.effects), 2);
    });

    test('a slot curse switches that item off', () {
      final curse = curseOf(BossFamily.kitchen); // weapon off
      expect(perfectEcho(wearing([turboMopItem], curse: curse)), 8);
      final bedHead = curseOf(BossFamily.bedroom); // head off
      expect(
        geared(wearing([colanderOfClarityItem], curse: bedHead)).hero.maxHp,
        5,
      );
    });

    test('Garden Gnome: every third miss costs no heart', () {
      final d = geared(wearing([gardenGnomeItem]));
      for (var i = 0; i < 3; i++) {
        d.applyEcho(pattern, oneMiss);
      }
      expect(d.heroHp, 3);
    });

    test('combo heal: a heart back after 10 hits in a row, up to the max', () {
      final d = EchoDuel(
        family: BossFamily.kitchen,
        tier: 3,
        hero: const HeroStats(maxHp: 5, damage: 1),
        loadout: wearing([capeOfCleanSweepItem]),
      );
      expect(d.heroHp, 7);
      d.applyEcho(pattern, oneMiss); // 3 hits, 1 miss
      expect(d.heroHp, 6);
      d
        ..applyEcho(pattern, pattern.beatsMs)
        ..applyEcho(pattern, pattern.beatsMs)
        ..applyEcho(pattern, pattern.beatsMs); // 12 in a row
      expect(d.heroHp, 7);
    });

    test('Lost Remote slows the boss by 10 %', () {
      expect(geared(wearing([lostRemoteItem])).tempo, closeTo(0.9, 1e-9));
    });

    test('a fully geared level-1 hero still needs two echoes', () {
      // Tier-1 patterns have at most three beats in the first phase.
      const tierOne = Pattern([0, 500, 1000], beatMs: 500);
      final d = geared(
        const Loadout(
          gear: {
            GearSlot.head: laundryBasketHelmItem,
            GearSlot.body: capeOfCleanSweepItem,
            GearSlot.weapon: mopOfDoomItem,
            GearSlot.feet: fuzzySlippersItem,
            GearSlot.charm: gardenGnomeItem,
          },
          consumables: [coffeeOfHasteItem, snackBreakItem],
        ),
      )..applyEcho(tierOne, tierOne.beatsMs);
      expect(d.outcome, DuelOutcome.ongoing);
    });

    test('Apron of Holding: Second Wind brings back all hearts', () {
      final d = geared(wearing([apronOfHoldingItem]));
      while (d.outcome == DuelOutcome.ongoing) {
        d.applyEcho(d.nextPattern(), const []);
      }
      d.revive();
      expect(d.heroHp, 6);
    });

    test('Second Wind revives a lost fight with half the hearts', () {
      final d = geared(Loadout.none);
      while (d.outcome == DuelOutcome.ongoing) {
        d.applyEcho(d.nextPattern(), const []);
      }
      expect(d.outcome, DuelOutcome.lost);
      d.revive();
      expect(d.outcome, DuelOutcome.ongoing);
      expect(d.heroHp, 3);
    });
  });

  group('difficulty', () {
    EchoDuel at(Difficulty d, {bool story = false}) => EchoDuel(
      family: BossFamily.dust,
      tier: 1,
      hero: const HeroStats(maxHp: 5, damage: 1),
      difficulty: d,
      storyMode: story,
    );

    test('changes boss health, timing and tempo', () {
      final easy = at(Difficulty.easy);
      final balanced = at(Difficulty.balanced);
      final hard = at(Difficulty.hard);
      expect([easy, balanced, hard].map((d) => d.bossMaxHp), [12, 16, 20]);
      expect(balanced.windows, TimingWindows.normal);
      expect(easy.windows.goodMs, TimingWindows.normal.goodMs + 20);
      expect(hard.windows.perfectMs, TimingWindows.normal.perfectMs - 10);
      expect(easy.tempo, closeTo(0.9, 1e-9));
      expect(hard.tempo, closeTo(1.08, 1e-9));
    });

    test('story mode keeps its windows; health and tempo still change', () {
      final d = at(Difficulty.hard, story: true);
      expect(d.windows, TimingWindows.story);
      expect(d.bossMaxHp, 20);
    });

    test('the Overlord scales too', () {
      final d = OverlordDuel(
        tier: 1,
        hero: const HeroStats(maxHp: 5, damage: 1),
        motifs: const [],
        difficulty: Difficulty.easy,
      );
      expect(d.bossMaxHp, 24);
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
