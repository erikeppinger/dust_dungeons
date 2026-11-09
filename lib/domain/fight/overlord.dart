import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../game/game_data.dart';
import '../dates.dart';
import 'boss.dart';
import 'effects.dart';

/// From which Monday how many of each part list are in use
/// (game/overlords.toml). A new era starts the weekly order over.
class OverlordEra {
  const OverlordEra(
    this.year,
    this.month,
    this.day, {
    required this.parts,
    required this.names,
    required this.titles,
  });

  final int year, month, day;

  /// Counts of bodies, faces, headgear, items, extras and schemes.
  final List<int> parts;
  final int names, titles;

  DateTime get monday => DateTime(year, month, day);
}

/// A holiday Overlord: its day and the parts it wears.
class OverlordHoliday {
  const OverlordHoliday({
    this.month = 0,
    this.day = 0,
    this.easter = false,
    this.hanukkah = false,
    this.dates = const [],
    required this.hat,
    required this.item,
    required this.extra,
    required this.scheme,
    this.boon = Effects.none,
  });

  final int month, day;

  /// What beating it gives for [overlordBoonDays] days.
  final Effects boon;

  /// Easter Sunday instead of a fixed day.
  final bool easter;

  /// The first day of Hanukkah (25 Kislev) instead of a fixed day.
  final bool hanukkah;

  /// Every date (year, month, day), for holidays that follow the moon.
  final List<(int, int, int)> dates;
  final String hat, item, extra, scheme;

  /// The holiday's days in [year]: usually one, none past the end of a
  /// table of [dates], two in a year where a moon holiday comes round
  /// twice.
  List<DateTime> inYear(int year) {
    if (dates.isNotEmpty) {
      return [
        for (final (y, m, d) in dates)
          if (y == year) DateTime(y, m, d),
      ];
    }
    if (easter) return [easterSunday(year)];
    if (hanukkah) return [hanukkahStart(year)];
    return [DateTime(year, month, day)];
  }
}

/// Easter Sunday in the Gregorian calendar (the anonymous algorithm).
DateTime easterSunday(int year) {
  final a = year % 19, b = year ~/ 100, c = year % 100;
  final d = b ~/ 4, e = b % 4, f = (b + 8) ~/ 25, g = (b - f + 1) ~/ 3;
  final h = (19 * a + b - d - g + 15) % 30;
  final i = c ~/ 4, k = c % 4;
  final l = (32 + 2 * e + 2 * i - h - k) % 7;
  final m = (a + 11 * h + 22 * l) ~/ 451;
  final month = (h + l - 7 * m + 114) ~/ 31;
  final day = (h + l - 7 * m + 114) % 31 + 1;
  return DateTime(year, month, day);
}

/// The first full day of Hanukkah (25 Kislev) in Gregorian [year], from
/// the arithmetic Hebrew calendar (Reingold and Dershowitz, "Calendrical
/// Calculations"). The candles are first lit the evening before.
DateTime hanukkahStart(int year) {
  int elapsed(int y) {
    final months = (235 * y - 234) ~/ 19;
    final parts = 12084 + 13753 * months;
    final day = 29 * months + parts ~/ 25920;
    return (3 * (day + 1)) % 7 < 3 ? day + 1 : day;
  }

  int newYear(int y) {
    final n0 = elapsed(y - 1), n1 = elapsed(y), n2 = elapsed(y + 1);
    final correction = n2 - n1 == 356 ? 2 : (n1 - n0 == 382 ? 1 : 0);
    // The Hebrew calendar's epoch as a day number (1 = 1 January, year 1).
    return -1373427 + n1 + correction;
  }

  final hebrewYear = year + 3761;
  final length = newYear(hebrewYear + 1) - newYear(hebrewYear);
  final heshvan = length % 10 == 5 ? 30 : 29;
  final fixed = newYear(hebrewYear) + 30 + heshvan + 24;
  final utc = DateTime.utc(1).add(Duration(days: fixed - 1));
  return DateTime(utc.year, utc.month, utc.day);
}

/// The enabled holiday whose day falls in the week (Monday to Sunday) of
/// [day], if any. When several share the week they take turns, one per
/// year, in the order of game/overlords.toml.
String? holidayOfWeek(DateTime day, Set<String> enabled) {
  final monday = weekStartOf(day);
  final candidates = [
    for (final MapEntry(:key, :value) in overlordHolidays.entries)
      if (enabled.contains(key) &&
          [
            for (final year in [monday.year, monday.year + 1])
              ...value.inYear(year),
          ].any((d) => weekStartOf(d) == monday))
        key,
  ];
  return candidates.isEmpty
      ? null
      : candidates[monday.year % candidates.length];
}

/// One Overlord's look and name: the parts it's built from, its color
/// scheme, the numbers of its name and title, and its holiday. Stored with
/// every Overlord fight as [key].
@immutable
class OverlordLook {
  const OverlordLook({
    required this.body,
    required this.face,
    required this.hat,
    required this.item,
    required this.extra,
    required this.scheme,
    this.name = 0,
    this.title = 0,
    this.holiday,
  });

  /// The Overlord before 0.15.0, and the one shown where no week applies.
  static const classic = OverlordLook(
    body: 'robe',
    face: 'grin',
    hat: 'crown',
    item: 'plunger',
    extra: 'none',
    scheme: 'violet',
  );

  /// The week's Overlord for the week of [day]. [holidays] are the holidays
  /// turned on in the settings: in such a week the holiday's parts replace
  /// headgear, item, extra and colors. [seed] is the phone's own random
  /// number (`AppSettings.overlordSeed`): it shifts where the phone's
  /// sequence starts, so phones meet different Overlords, while the rules of
  /// the sequence (no repeats, every part changes) stay the same.
  factory OverlordLook.forWeek(
    DateTime day, {
    Set<String> holidays = const {},
    int seed = 0,
  }) {
    final monday = weekStartOf(day);
    final era = overlordEras.lastWhere(
      (e) => !e.monday.isAfter(monday),
      orElse: () => overlordEras.first,
    );
    final week = daysBetween(era.monday, monday) ~/ 7;
    final parts = weekDigits(era.parts, week, seed);
    final names = weekDigits([era.names, era.titles], week, seed);
    final holiday = holidayOfWeek(monday, holidays);
    final h = overlordHolidays[holiday];
    return OverlordLook(
      body: overlordBodies[parts[0]],
      face: overlordFaces[parts[1]],
      hat: h?.hat ?? overlordHats[parts[2]],
      item: h?.item ?? overlordItems[parts[3]],
      extra: h?.extra ?? overlordExtras[parts[4]],
      scheme: h?.scheme ?? overlordSchemeOrder[parts[5]],
      name: names[0],
      title: names[1],
      holiday: holiday,
    );
  }

  /// A stored [key]; [classic] for none or one this version can't read.
  factory OverlordLook.parse(String? key) {
    final p = key?.split('.') ?? const [];
    if (p.length != 9) return classic;
    final look = OverlordLook(
      body: p[0],
      face: p[1],
      hat: p[2],
      item: p[3],
      extra: p[4],
      scheme: p[5],
      name: int.tryParse(p[6]) ?? -1,
      title: int.tryParse(p[7]) ?? -1,
      holiday: p[8].isEmpty ? null : p[8],
    );
    return look._known ? look : classic;
  }

  final String body, face, hat, item, extra, scheme;
  final int name, title;
  final String? holiday;

  String get key => [
    body,
    face,
    hat,
    item,
    extra,
    scheme,
    name,
    title,
    holiday ?? '',
  ].join('.');

  /// How it plays, set by its body.
  BossTrait get trait => overlordTraits[body] ?? const BossTrait();

  bool get _known {
    final h = overlordHolidays[holiday];
    bool part(List<String> all, String key, String? holidayKey) =>
        all.contains(key) || key == holidayKey;
    return overlordBodies.contains(body) &&
        overlordFaces.contains(face) &&
        part(overlordHats, hat, h?.hat) &&
        part(overlordItems, item, h?.item) &&
        part(overlordExtras, extra, h?.extra) &&
        overlordSchemes.containsKey(scheme) &&
        (holiday == null || h != null) &&
        name >= 0 &&
        name < overlordNameCount &&
        title >= 0 &&
        title < overlordTitleCount;
  }

  @override
  bool operator ==(Object other) => other is OverlordLook && other.key == key;

  @override
  int get hashCode => key.hashCode;

  @override
  String toString() => 'OverlordLook($key)';
}

/// The highest name and title numbers there are.
int get overlordNameCount => overlordEras.map((e) => e.names).reduce(max);
int get overlordTitleCount => overlordEras.map((e) => e.titles).reduce(max);

/// Week [week]'s digits, one per list of the sizes in [radix]: combination
/// `(step × week + seed) mod N`, where N is the number of combinations. [weekStep]
/// shares no factor with N, so no combination repeats for N weeks, and each
/// of its digits is between 1 and its size − 2, so every digit changes from
/// one week to the next, carries included.
List<int> weekDigits(List<int> radix, int week, [int seed = 0]) {
  final n = radix.reduce((a, b) => a * b);
  return _digits(radix, (weekStep(radix) * week + seed) % n);
}

List<int> _digits(List<int> radix, int index) {
  final digits = <int>[];
  for (final r in radix) {
    digits.add(index % r);
    index ~/= r;
  }
  return digits;
}

final _steps = <String, int>{};

/// The step between two weeks' combinations for lists of the sizes in
/// [radix] (see [weekDigits]). Searched once from about 0.38 × N, so the
/// digits are mixed and the order doesn't look like counting.
int weekStep(List<int> radix) => _steps.putIfAbsent(radix.join(','), () {
  final n = radix.reduce((a, b) => a * b);
  int gcd(int a, int b) => b == 0 ? a : gcd(b, a % b);
  final start = (n * 0.381966).floor();
  int? coprime;
  for (var i = 0; i < n; i++) {
    final a = (start + i) % n;
    if (a == 0 || gcd(a, n) != 1) continue;
    coprime ??= a;
    final d = _digits(radix, a);
    if ([for (var j = 0; j < d.length; j++) d[j] >= 1 && d[j] <= radix[j] - 2]
        .every((ok) => ok)) {
      return a;
    }
  }
  return coprime ?? 1;
});
