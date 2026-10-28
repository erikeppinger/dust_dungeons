import 'package:flutter_test/flutter_test.dart';
import 'package:homework_and_chores/domain/fight/boss.dart';
import 'package:homework_and_chores/domain/fight/echo_duel.dart';
import 'package:homework_and_chores/domain/fight/lanes.dart';
import 'package:homework_and_chores/features/fight/fight_controller.dart';
import 'package:homework_and_chores/features/fight/fight_sounds.dart';

Duration ms(int n) => Duration(milliseconds: n);

/// testWidgets runs on fake time: pump() advances timers and `clock`.
void main() {
  FightController controller(void Function(DuelOutcome) onFinished) =>
      FightController(
        duel: EchoDuel(
          family: BossFamily.dust,
          tier: 1,
          hero: const HeroStats(maxHp: 5, damage: 1),
          seed: 42,
        ),
        sounds: SilentFightSounds(),
        haptics: false,
        onFinished: onFinished,
      );

  /// Plays one call/echo round, tapping each beat at [offsetMs] from its time.
  Future<void> playRound(
    WidgetTester tester,
    FightController c, {
    int offsetMs = 0,
  }) async {
    expect(c.stage, FightStage.call);
    final p = c.pattern!;
    await tester.pump(ms(p.lengthMs));
    expect(c.stage, FightStage.echo);
    // The count-in click; the first beat is due one pulse later.
    var now = -p.beatMs;
    for (final beat in p.beatsMs) {
      await tester.pump(ms(beat + offsetMs - now));
      now = beat + offsetMs;
      c.tap();
    }
    await tester.pump(
      ms(p.beatsMs.last + c.duel.windows.goodMs + 150 + c.latencyMs - now),
    );
    expect(c.stage, FightStage.judged);
  }

  testWidgets('perfect timing wins and reports the outcome once', (
    tester,
  ) async {
    final outcomes = <DuelOutcome>[];
    final c = controller(outcomes.add)..start();
    expect(c.stage, FightStage.intro);
    await tester.pump(ms(FightController.introMs));
    while (c.stage != FightStage.finished) {
      await playRound(tester, c);
      expect(c.lastHits, everyElement(Hit.perfect));
      await tester.pump(ms(FightController.judgedMs));
    }
    expect(outcomes, [DuelOutcome.won]);
    expect(c.duel.miss, 0);
    c.dispose();
  });

  testWidgets('late taps are judged as good, not perfect', (tester) async {
    final c = controller((_) {})..start();
    await tester.pump(ms(FightController.introMs));
    await playRound(tester, c, offsetMs: 90);
    expect(c.lastHits, everyElement(Hit.good));
    c.dispose();
  });

  testWidgets('taps outside the echo are ignored; silence loses', (
    tester,
  ) async {
    final outcomes = <DuelOutcome>[];
    final c = controller(outcomes.add)..start();
    c.tap(); // during the intro
    await tester.pump(ms(FightController.introMs));
    c.tap(); // during the call
    expect(c.tapCount, 0);
    while (c.stage != FightStage.finished) {
      await tester.pump(ms(200));
    }
    expect(outcomes, [DuelOutcome.lost]);
    c.dispose();
  });

  testWidgets('pausing drops the round without damage; resume restarts', (
    tester,
  ) async {
    final c = controller((_) {})..start();
    await tester.pump(ms(FightController.introMs));
    c.pause();
    await tester.pump(const Duration(seconds: 30));
    expect(c.duel.heroHp, c.duel.hero.maxHp, reason: 'nothing was judged');
    c.resume();
    expect(c.stage, FightStage.intro);
    await tester.pump(ms(FightController.introMs));
    expect(c.stage, FightStage.call);
    c.dispose();
  });

  testWidgets('stop cancels the fight', (tester) async {
    final outcomes = <DuelOutcome>[];
    final c = controller(outcomes.add)..start();
    c.stop();
    await tester.pump(const Duration(minutes: 1));
    expect(c.stage, FightStage.intro);
    expect(outcomes, isEmpty);
    c.dispose();
  });

  testWidgets('a calibrated delay is taken off every tap', (tester) async {
    final c = FightController(
      duel: EchoDuel(
        family: BossFamily.dust,
        tier: 1,
        hero: const HeroStats(maxHp: 5, damage: 1),
        seed: 42,
      ),
      sounds: SilentFightSounds(),
      haptics: false,
      latencyMs: 250,
      onFinished: (_) {},
    )..start();
    await tester.pump(ms(FightController.introMs));
    await playRound(tester, c, offsetMs: 250);
    expect(c.lastHits, everyElement(Hit.perfect));
    await tester.pump(ms(FightController.judgedMs));
    // Late on top of the delay: the round waits for the last tap.
    await playRound(tester, c, offsetMs: 340);
    expect(c.lastHits, everyElement(Hit.good));
    c.dispose();
  });

  group('Overlord lane phase', () {
    FightController overlord(void Function(DuelOutcome) onFinished) {
      final duel = OverlordDuel(
        tier: 1,
        hero: const HeroStats(maxHp: 5, damage: 1),
        motifs: const [BossFamily.dust],
        seed: 5,
      );
      duel.bossHp = duel.bossMaxHp ~/ 3; // straight into the last phase
      return FightController(
        duel: duel,
        sounds: SilentFightSounds(),
        haptics: false,
        onFinished: onFinished,
      );
    }

    testWidgets('hitting every note on time wins', (tester) async {
      final outcomes = <DuelOutcome>[];
      final c = overlord(outcomes.add)..start();
      await tester.pump(ms(FightController.introMs));
      expect(c.stage, FightStage.lanes);
      while (c.stage == FightStage.lanes) {
        final j = c.laneJudge!;
        final next = [
          for (var i = 0; i < j.notes.length; i++)
            if (j.results[i] == null) j.notes[i],
        ].reduce((a, b) => a.atMs <= b.atMs ? a : b);
        await tester.pump(ms(next.atMs - c.laneElapsedMs));
        c.tapLane(next.lane);
        expect(c.lastLaneHit, Hit.perfect);
      }
      expect(c.duel.miss, 0);
      await tester.pump(ms(FightController.judgedMs));
      expect(outcomes, [DuelOutcome.won]);
      c.dispose();
    });

    testWidgets('notes that fall past the line cost hearts', (tester) async {
      final outcomes = <DuelOutcome>[];
      final c = overlord(outcomes.add)..start();
      await tester.pump(ms(FightController.introMs));
      c.tapLane(1); // a stray tap: no damage
      expect(c.duel.heroHp, 5);
      while (c.stage != FightStage.finished) {
        await tester.pump(ms(100));
      }
      expect(outcomes, [DuelOutcome.lost]);
      expect(c.duel.miss, greaterThanOrEqualTo(5));
      c.dispose();
    });

    testWidgets('pausing drops the notes; resume writes new ones', (
      tester,
    ) async {
      final c = overlord((_) {})..start();
      await tester.pump(ms(FightController.introMs));
      c.pause();
      await tester.pump(const Duration(seconds: 30));
      expect(c.duel.heroHp, 5, reason: 'nothing was judged while paused');
      c.resume();
      await tester.pump(ms(FightController.introMs));
      expect(c.stage, FightStage.lanes);
      expect(c.laneJudge!.results, everyElement(isNull));
      expect(c.laneJudge!.notes.first.lane, inInclusiveRange(0, laneCount - 1));
      c.dispose();
    });
  });
}
