import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homework_and_chores/app/art/art.dart';
import 'package:homework_and_chores/domain/dates.dart';
import 'package:homework_and_chores/domain/fight/overlord.dart';
import 'package:homework_and_chores/features/fight/boss_art.dart';
import 'package:homework_and_chores/features/fight/overlord_art.dart';
import 'package:homework_and_chores/game/game_data.dart';
import 'package:homework_and_chores/l10n/app_localizations.dart';

/// WCAG contrast ratio of two colors.
double contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  return (la > lb ? la + 0.05 : lb + 0.05) / (la > lb ? lb + 0.05 : la + 0.05);
}

void main() {
  test('every part has its frames', () {
    final kinds = {
      'body': (overlordBodies, 1),
      'face': (overlordFaces, 3),
      'hat': (
        [...overlordHats, for (final h in overlordHolidays.values) h.hat],
        1,
      ),
      'item': (
        [...overlordItems, for (final h in overlordHolidays.values) h.item],
        1,
      ),
      'extra': (
        [...overlordExtras, for (final h in overlordHolidays.values) h.extra],
        2,
      ),
    };
    kinds.forEach((kind, entry) {
      final (keys, frames) = entry;
      for (final key in keys) {
        final sprite = Sprites.all['bosses/overlord/$kind/$key'];
        expect(sprite, isNotNull, reason: '$kind $key');
        expect(sprite!.$1, hasLength(frames), reason: '$kind $key');
        expect(sprite.$2, 'bosses');
      }
    });
  });

  test('every scheme: the face stands out from the body', () {
    overlordSchemes.forEach((key, colors) {
      final (main, light) = colors;
      expect(contrast(Color(main), Color(light)), greaterThan(2), reason: key);
    });
  });

  test('the scheme replaces only the key colors', () {
    final colors = overlordColors('crimson');
    expect(colors, hasLength(bosses.colors.length));
    final changed = [
      for (var i = 0; i < colors.length; i++)
        if (colors[i] != bosses.colors[i]) i,
    ];
    expect(changed, hasLength(4));
  });

  testWidgets('every week and holiday draws in every mood', (tester) async {
    final looks = [
      for (var w = 0; w < 60; w++)
        OverlordLook.forWeek(addDays(DateTime(2026, 1, 5), 7 * w)),
      for (final h in overlordHolidays.keys) holidayLook(h),
    ];
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Wrap(
          children: [
            for (final look in looks)
              for (final mood in BossMood.values)
                OverlordArt(look: look, size: 24, mood: mood, bob: true),
          ],
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.byType(OverlordArt), findsNWidgets(looks.length * 3));
  });

  testWidgets('names in English and German', (tester) async {
    late AppLocalizations en, de;
    await tester.pumpWidget(
      Localizations(
        locale: const Locale('en'),
        delegates: AppLocalizations.localizationsDelegates,
        child: Builder(
          builder: (context) {
            en = AppLocalizations.of(context);
            return const SizedBox();
          },
        ),
      ),
    );
    await tester.pumpWidget(
      Localizations(
        locale: const Locale('de'),
        delegates: AppLocalizations.localizationsDelegates,
        child: Builder(
          builder: (context) {
            de = AppLocalizations.of(context);
            return const SizedBox();
          },
        ),
      ),
    );
    const look = OverlordLook(
      body: 'armor',
      face: 'grin',
      hat: 'crown',
      item: 'fork',
      extra: 'none',
      scheme: 'violet',
    );
    expect(overlordName(en, look), 'Grimeclaw of the Sticky Floor');
    expect(overlordName(de, look), 'Schmierklaue vom klebrigen Boden');
    expect(overlordTraitLine(en, look), 'Heavy: Slower, but longer rhythms.');
    expect(overlordName(en, holidayLook('christmas')), 'Tinsel Tyrant');
    expect(overlordName(de, holidayLook('new_year')), 'Graf Countdown');
  });
}
