import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homework_and_chores/domain/fight/boss.dart';
import 'package:homework_and_chores/domain/fight/echo_duel.dart';
import 'package:homework_and_chores/features/fight/beat_timeline.dart';
import 'package:homework_and_chores/features/fight/fight_controller.dart';
import 'package:homework_and_chores/features/fight/fight_sounds.dart';

void main() {
  const pattern = Pattern([0, 500, 750, 1500], beatMs: 500);

  test('beats sit at their real times, after one count-in pulse', () {
    // The timeline spans -500 (count-in) to 2000 (the phrase's end).
    expect(timelineX(-500, pattern, 250), 0);
    expect(timelineX(0, pattern, 250), 50);
    expect(timelineX(500, pattern, 250), 100);
    expect(timelineX(750, pattern, 250), 125);
    expect(timelineX(2000, pattern, 250), 250);
  });

  test('dots shrink when beats sit close, keeping a gap', () {
    // The closest beats are 250 ms apart.
    expect(timelineDot(pattern, 1000), 16);
    expect(timelineDot(pattern, 180), 14); // 18 px apart
    expect(timelineDot(pattern, 120), 10); // 12 px apart: the smallest
    expect(timelineDot(const Pattern([0], beatMs: 500), 300), 16);
  });

  testWidgets('draws every stage of a round', (tester) async {
    final c = FightController(
      duel: EchoDuel(
        family: BossFamily.dust,
        tier: 1,
        hero: const HeroStats(maxHp: 5, damage: 1),
        seed: 42,
      ),
      sounds: SilentFightSounds(),
      haptics: false,
      onFinished: (_) {},
    )..start();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: BeatTimeline(controller: c)),
      ),
    );
    c.go();
    await tester.pump(const Duration(milliseconds: FightController.introMs));
    final p = c.pattern!;
    await tester.pump(Duration(milliseconds: p.lengthMs + p.beatMs));
    expect(c.stage, FightStage.echo);
    c.tap();
    await tester.pump(const Duration(seconds: 10));
    expect(c.lastHits, isNotEmpty);
    expect(tester.takeException(), isNull);
    // No ticker left running once the playhead stops.
    expect(tester.binding.transientCallbackCount, 0);
    c.dispose();
  });
}
