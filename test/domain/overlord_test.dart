import 'package:flutter_test/flutter_test.dart';
import 'package:homework_and_chores/domain/dates.dart';
import 'package:homework_and_chores/domain/fight/boss.dart';
import 'package:homework_and_chores/domain/fight/echo_duel.dart';
import 'package:homework_and_chores/domain/fight/overlord.dart';
import 'package:homework_and_chores/game/game_data.dart';

void main() {
  final era = overlordEras.first;
  final radix = era.parts;

  group('the weekly look', () {
    test('is the same all week and changes on Monday', () {
      final monday = DateTime(2026, 11, 9);
      final look = OverlordLook.forWeek(monday);
      for (var d = 1; d < 7; d++) {
        expect(OverlordLook.forWeek(addDays(monday, d)), look);
      }
      expect(OverlordLook.forWeek(addDays(monday, 7)), isNot(look));
    });

    test('changes every part from one week to the next', () {
      var monday = era.monday;
      var last = OverlordLook.forWeek(monday);
      for (var w = 1; w < 2000; w++) {
        monday = addDays(monday, 7);
        final look = OverlordLook.forWeek(monday);
        expect(look.body, isNot(last.body), reason: '$monday');
        expect(look.face, isNot(last.face), reason: '$monday');
        expect(look.hat, isNot(last.hat), reason: '$monday');
        expect(look.item, isNot(last.item), reason: '$monday');
        expect(look.extra, isNot(last.extra), reason: '$monday');
        expect(look.scheme, isNot(last.scheme), reason: '$monday');
        last = look;
      }
    });

    test('never repeats a combination within the era', () {
      final n = radix.reduce((a, b) => a * b);
      final seen = <String>{};
      for (var w = 0; w < n; w++) {
        expect(seen.add(weekDigits(radix, w).join(',')), isTrue, reason: '$w');
      }
      // And then it starts over.
      expect(weekDigits(radix, n), weekDigits(radix, 0));
    });

    test('the step has mixed digits, each between 1 and size - 2', () {
      final step = weekStep(radix);
      var rest = step;
      final digits = <int>[];
      for (final r in radix) {
        digits.add(rest % r);
        rest ~/= r;
      }
      for (var i = 0; i < radix.length; i++) {
        expect(digits[i], inInclusiveRange(1, radix[i] - 2));
      }
      expect(digits.toSet().length, greaterThan(1));
    });

    test('names and titles change every week and stay in range', () {
      var last = OverlordLook.forWeek(era.monday);
      for (var w = 1; w < 600; w++) {
        final look = OverlordLook.forWeek(addDays(era.monday, 7 * w));
        expect(look.name, inInclusiveRange(0, era.names - 1));
        expect(look.title, inInclusiveRange(0, era.titles - 1));
        expect(look.name, isNot(last.name));
        expect(look.title, isNot(last.title));
        last = look;
      }
    });

    test('the first week of the first era is the classic Overlord', () {
      expect(OverlordLook.forWeek(era.monday), OverlordLook.classic);
    });

    test('weeks before the first era still get a look', () {
      final look = OverlordLook.forWeek(DateTime(2023, 6, 5));
      expect(overlordBodies, contains(look.body));
    });

    test('each phone has its own sequence, with the same rules', () {
      final monday = DateTime(2026, 11, 9);
      final looks = {
        for (final seed in [1, 2, 3, 4, 5, 123456, 987654321])
          OverlordLook.forWeek(monday, seed: seed),
      };
      expect(looks.length, greaterThan(4), reason: 'seeds differ');
      const seed = 424242;
      var last = OverlordLook.forWeek(era.monday, seed: seed);
      for (var w = 1; w < 500; w++) {
        final look = OverlordLook.forWeek(
          addDays(era.monday, 7 * w),
          seed: seed,
        );
        expect(look.body, isNot(last.body));
        expect(look.scheme, isNot(last.scheme));
        expect(look.name, isNot(last.name));
        last = look;
      }
    });

    test('every body has a trait', () {
      for (final body in overlordBodies) {
        expect(overlordTraits, contains(body));
      }
    });
  });

  group('stored looks', () {
    test('round trip through the key', () {
      for (var w = 0; w < 100; w++) {
        final look = OverlordLook.forWeek(
          addDays(era.monday, 7 * w),
          holidays: overlordHolidays.keys.toSet(),
        );
        expect(OverlordLook.parse(look.key), look);
      }
    });

    test('unknown or broken keys show the classic Overlord', () {
      expect(OverlordLook.parse(null), OverlordLook.classic);
      expect(OverlordLook.parse(''), OverlordLook.classic);
      expect(OverlordLook.parse('a.b.c'), OverlordLook.classic);
      final good = OverlordLook.forWeek(DateTime(2026, 11, 9)).key.split('.');
      expect(
        OverlordLook.parse((List.of(good)..[0] = 'dragon').join('.')),
        OverlordLook.classic,
      );
      expect(
        OverlordLook.parse((List.of(good)..[6] = '999').join('.')),
        OverlordLook.classic,
      );
      expect(
        OverlordLook.parse((List.of(good)..[8] = 'not_a_holiday').join('.')),
        OverlordLook.classic,
      );
    });

    test('holiday parts are only valid with their holiday', () {
      final good = OverlordLook.classic.key.split('.');
      expect(
        OverlordLook.parse((List.of(good)..[2] = 'santa').join('.')),
        OverlordLook.classic,
      );
    });
  });

  group('holidays', () {
    test('Easter Sunday', () {
      const table = {
        2024: (3, 31),
        2025: (4, 20),
        2026: (4, 5),
        2027: (3, 28),
        2028: (4, 16),
        2029: (4, 1),
        2030: (4, 21),
        2031: (4, 13),
        2032: (3, 28),
        2033: (4, 17),
        2034: (4, 9),
        2035: (3, 25),
        2036: (4, 13),
        2037: (4, 5),
        2038: (4, 25),
        2039: (4, 10),
        2040: (4, 1),
      };
      table.forEach((year, md) {
        expect(
          easterSunday(year),
          DateTime(year, md.$1, md.$2),
          reason: '$year',
        );
      });
    });

    final all = overlordHolidays.keys.toSet();

    test('fall in the week that contains the day', () {
      expect(holidayOfWeek(DateTime(2026, 12, 21), all), 'christmas');
      expect(holidayOfWeek(DateTime(2026, 12, 27), all), 'christmas');
      expect(holidayOfWeek(DateTime(2026, 12, 28), all), 'new_year');
      expect(holidayOfWeek(DateTime(2027, 1, 3), all), 'new_year');
      expect(holidayOfWeek(DateTime(2027, 1, 4), all), isNull);
      expect(holidayOfWeek(DateTime(2026, 3, 30), all), 'easter');
      expect(holidayOfWeek(DateTime(2026, 4, 5), all), 'easter');
      expect(holidayOfWeek(DateTime(2026, 4, 6), all), isNull);
      expect(holidayOfWeek(DateTime(2027, 2, 14), all), 'valentine');
      expect(holidayOfWeek(DateTime(2026, 10, 26), all), 'halloween');
      // 31 December 2029 is a Monday.
      expect(holidayOfWeek(DateTime(2029, 12, 31), all), 'new_year');
    });

    test('only when turned on', () {
      expect(holidayOfWeek(DateTime(2026, 12, 21), {}), isNull);
      expect(holidayOfWeek(DateTime(2026, 12, 21), {'easter'}), isNull);
      final plain = OverlordLook.forWeek(DateTime(2026, 12, 21));
      final festive = OverlordLook.forWeek(
        DateTime(2026, 12, 21),
        holidays: {'christmas'},
      );
      expect(plain.holiday, isNull);
      expect(festive.holiday, 'christmas');
      expect(festive.hat, 'santa');
      expect(festive.scheme, 'christmas');
      // Body (and trait), face and name stay the week's.
      expect(festive.body, plain.body);
      expect(festive.face, plain.face);
      expect(festive.name, plain.name);
    });

    test('Hanukkah from the Hebrew calendar', () {
      const table = {
        2024: (12, 26),
        2025: (12, 15),
        2026: (12, 5),
        2027: (12, 25),
        2028: (12, 13),
        2029: (12, 2),
        2030: (12, 21),
        2035: (12, 26),
        2040: (11, 30),
      };
      table.forEach((year, md) {
        expect(
          hanukkahStart(year),
          DateTime(year, md.$1, md.$2),
          reason: '$year',
        );
      });
    });

    test('moon holidays come from their tables, twice in some years', () {
      final eid = overlordHolidays['eid_al_fitr']!;
      expect(eid.inYear(2026), [DateTime(2026, 3, 20)]);
      expect(eid.inYear(2033), [DateTime(2033, 1, 2), DateTime(2033, 12, 23)]);
      expect(eid.inYear(2099), isEmpty, reason: 'past the table');
      expect(overlordHolidays['lunar_new_year']!.inYear(2026), [
        DateTime(2026, 2, 17),
      ]);
      expect(overlordHolidays['diwali']!.inYear(2026), [DateTime(2026, 11, 8)]);
    });

    test('every holiday has a day this year and for years to come', () {
      for (final MapEntry(:key, :value) in overlordHolidays.entries) {
        for (var y = 2026; y <= 2035; y++) {
          expect(value.inYear(y), isNotEmpty, reason: '$key $y');
        }
      }
    });

    test('holidays sharing a week take turns by year', () {
      // 2024: Hanukkah starts 26 December, in Christmas week.
      final both = {'christmas', 'hanukkah'};
      expect(holidayOfWeek(DateTime(2024, 12, 23), both), 'christmas');
      // 2027: Hanukkah starts 25 December, again in Christmas week.
      expect(holidayOfWeek(DateTime(2027, 12, 20), both), 'hanukkah');
      // Only one turned on: it always shows.
      expect(holidayOfWeek(DateTime(2024, 12, 23), {'hanukkah'}), 'hanukkah');
      expect(holidayOfWeek(DateTime(2027, 12, 20), {'christmas'}), 'christmas');
    });

    test('every holiday shows at least once in ten years', () {
      final all = overlordHolidays.keys.toSet();
      final seen = <String>{};
      for (var w = 0; w < 52 * 10; w++) {
        final h = holidayOfWeek(addDays(DateTime(2026, 1, 5), 7 * w), all);
        if (h != null) seen.add(h);
      }
      expect(seen, all);
    });
  });

  group('traits', () {
    PatternGenerator generator(int extraBeats) => PatternGenerator(
      bossStyles[BossFamily.dust]!,
      tier: 1,
      extraBeats: extraBeats,
      seed: 3,
    );

    test('extra beats make longer rhythms', () {
      final plain = generator(0).next(phase: 0);
      final longer = generator(1).next(phase: 0);
      expect(longer.beatsMs.length, plain.beatsMs.length + 1);
    });

    test('change the tempo and chances of the borrowed styles', () {
      const heavy = BossTrait(bpm: -8, offbeat: 0.25, eighth: 0.2);
      final style = bossStyles[BossFamily.dust]!;
      final changed = heavy.apply(style);
      expect(changed.baseBpm, style.baseBpm - 8);
      expect(changed.offbeatChance, closeTo(style.offbeatChance + 0.25, 1e-9));
      expect(changed.eighthChance, closeTo(style.eighthChance + 0.2, 1e-9));
    });

    test('the Overlord duel uses its trait', () {
      OverlordDuel duel(BossTrait trait) => OverlordDuel(
        tier: 1,
        hero: HeroStats.forLevel(1),
        motifs: const [BossFamily.dust],
        trait: trait,
      );
      final plain = duel(const BossTrait());
      final heavy = duel(overlordTraits['armor']!);
      expect(
        heavy.nextPattern().beatsMs.length,
        greaterThan(plain.nextPattern().beatsMs.length),
      );
      expect(heavy.lanes.beatMs, greaterThan(plain.lanes.beatMs));
      final coiling = duel(overlordTraits['serpent']!);
      expect(coiling.lanes.extraChance, greaterThan(0));
    });
  });
}
