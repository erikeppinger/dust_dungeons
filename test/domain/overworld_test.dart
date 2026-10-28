import 'dart:collection';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:homework_and_chores/domain/dates.dart';
import 'package:homework_and_chores/domain/fight/boss.dart';
import 'package:homework_and_chores/domain/fight/overworld.dart';

/// Whether [to] can be reached from [from] walking only on the road.
bool connected(Set<Point<int>> road, Point<int> from, Point<int> to) {
  final seen = {from};
  final queue = Queue.of([from]);
  while (queue.isNotEmpty) {
    final p = queue.removeFirst();
    if (p == to) return true;
    for (final d in const [
      Point(1, 0),
      Point(-1, 0),
      Point(0, 1),
      Point(0, -1),
    ]) {
      final n = p + d;
      if (road.contains(n) && seen.add(n)) queue.add(n);
    }
  }
  return false;
}

void main() {
  test('ISO weeks start on Monday; week 1 holds the first Thursday', () {
    expect(isoWeek(DateTime(2026, 10, 28)), (2026, 44));
    expect(isoWeek(DateTime(2026, 10, 26)), (2026, 44), reason: 'Monday');
    expect(isoWeek(DateTime(2026, 11, 1)), (2026, 44), reason: 'Sunday');
    expect(isoWeek(DateTime(2026, 11, 2)), (2026, 45));
    expect(isoWeek(DateTime(2027, 1, 1)), (2026, 53), reason: 'a Friday');
    expect(isoWeek(DateTime(2025, 12, 29)), (2026, 1), reason: 'a Monday');
  });

  test('the same all week, new on Monday', () {
    final wednesday = WeekMap.forWeek(DateTime(2026, 10, 28));
    final sunday = WeekMap.forWeek(DateTime(2026, 11, 1, 23, 59));
    final monday = WeekMap.forWeek(DateTime(2026, 11, 2));
    expect(sunday.terrain, wednesday.terrain);
    expect(sunday.route, wednesday.route);
    expect(monday.terrain, isNot(wednesday.terrain));
  });

  test('themes follow the seasons, with some desert weeks', () {
    MapTheme themeOf(DateTime d) => WeekMap.forWeek(d).theme;
    final weeks = [
      for (var i = 0; i < 52; i++) addDays(DateTime(2026, 1, 5), 7 * i),
    ];
    for (final monday in weeks) {
      final theme = themeOf(monday);
      final expected = switch (monday.month) {
        12 || 1 || 2 => MapTheme.snow,
        9 || 10 || 11 => MapTheme.autumn,
        _ => MapTheme.meadow,
      };
      expect(theme, anyOf(expected, MapTheme.desert), reason: '$monday');
    }
    expect(weeks.map(themeOf).toSet(), containsAll(MapTheme.values));
  });

  test('five years of weeks all give a playable road', () {
    final layouts = <String>{};
    var crowdedWeeks = 0;
    for (var i = 0; i < 52 * 5; i++) {
      final day = addDays(DateTime(2026, 1, 5), 7 * i);
      final map = WeekMap.forWeek(day);
      final route = map.route;
      expect(route, hasLength(overlordWinsNeeded + 2));
      expect(map.terrain, hasLength(mapRows));
      expect(map.terrain.every((row) => row.length == mapCols), isTrue);
      expect(route.first.x, lessThanOrEqualTo(1), reason: 'camp on the left');
      expect(route.last.x, greaterThanOrEqualTo(14), reason: 'castle right');
      expect(route.toSet(), hasLength(route.length), reason: 'distinct stops');
      for (final stop in route) {
        expect(
          'GFS'.contains(map.at(stop.x, stop.y)),
          isTrue,
          reason: 'stop on walkable land in week $day',
        );
      }
      for (final tile in map.road) {
        expect(
          'WMH'.contains(map.at(tile.x, tile.y)),
          isFalse,
          reason: 'the road never runs through water or mountains ($day)',
        );
      }
      for (var s = 0; s < route.length - 1; s++) {
        expect(
          connected(map.road, route[s], route[s + 1]),
          isTrue,
          reason: 'stop $s to ${s + 1} in week $day',
        );
      }
      // Legs share the road; side-by-side stretches (2x2 blocks, drawn as
      // a small plaza) only where the terrain leaves no other way.
      final blocks = map.road.where(
        (t) => [
          t + const Point(1, 0),
          t + const Point(0, 1),
          t + const Point(1, 1),
        ].every(map.road.contains),
      );
      if (blocks.isNotEmpty) crowdedWeeks++;
      layouts.add(map.terrain.join());
    }
    expect(layouts.length, greaterThan(250), reason: 'weeks look different');
    expect(crowdedWeeks, lessThan(52), reason: 'at most one week in five');
  });

  test('joined weeks: each castle leads on to the next camp', () {
    final weeks = joinWeeks([
      for (var i = 0; i < 52; i++)
        WeekMap.forWeek(addDays(DateTime(2026, 1, 5), 7 * i)),
    ]);
    for (var i = 0; i < weeks.length - 1; i++) {
      final a = weeks[i], b = weeks[i + 1];
      // Both weeks' roads in one coordinate space.
      final road = {
        ...a.road,
        for (final p in b.road) Point(p.x + mapCols, p.y),
      };
      final camp = b.route.first;
      expect(
        connected(road, a.route.last, Point(camp.x + mapCols, camp.y)),
        isTrue,
        reason: 'week ${a.monday} to the next',
      );
      expect(a.route, WeekMap.forWeek(a.monday).route, reason: 'same stops');
    }
  });

  test('the terrain runs on across the seam between weeks', () {
    // Neighbouring weeks are windows on one world: their touching columns
    // agree far more often than unrelated weeks would.
    var same = 0, total = 0;
    for (var i = 0; i < 52; i++) {
      final a = WeekMap.forWeek(addDays(DateTime(2026, 1, 5), 7 * i));
      final b = WeekMap.forWeek(addDays(DateTime(2026, 1, 12), 7 * i));
      for (var y = 0; y < mapRows; y++) {
        final left = a.at(mapCols - 1, y), right = b.at(0, y);
        if ('WB'.contains(left) == 'WB'.contains(right)) same++;
        total++;
      }
    }
    expect(same / total, greaterThan(0.85));
  });
}
