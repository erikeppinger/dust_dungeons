import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homework_and_chores/app/art/art.dart';
import 'package:homework_and_chores/app/theme/app_theme.dart';
import 'package:homework_and_chores/app/theme/pixel.dart';
import 'package:homework_and_chores/domain/fight/boss.dart';
import 'package:homework_and_chores/features/chores/chore_icons.dart';

void main() {
  test('every boss has a strip: idle, bob, hit, defeated', () {
    for (final family in BossFamily.values) {
      final (frames, palette) = Sprites.all['bosses/${family.name}']!;
      expect(frames, hasLength(4), reason: family.name);
      expect(palette, 'bosses');
      for (final f in frames) {
        expect((f.width, f.height), (48, 48), reason: family.name);
      }
    }
  });

  test('quest icons are 12×12 masks; unknown keys get the fallback', () {
    for (final MapEntry(:key, :value) in choreIcons.entries) {
      expect((value.width, value.height), (12, 12), reason: key);
    }
    expect(choreIcon('from_a_newer_version'), Sprites.questTaskAlt);
  });

  testWidgets('the level coin draws one, two and three-digit levels', (
    tester,
  ) async {
    for (final level in [5, 42, 150]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(
            brightness: Brightness.light,
            colorblindSafe: false,
          ),
          home: Center(child: LevelCoin(level: level)),
        ),
      );
      expect(tester.takeException(), isNull, reason: '$level');
    }
  });
}
