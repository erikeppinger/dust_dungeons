import 'dart:math';

import '../dates.dart';
import 'boss.dart';

/// Map width and height in tiles.
const mapCols = 16, mapRows = 10;

/// Looks that follow the seasons; some weeks take the desert instead.
enum MapTheme { meadow, autumn, snow, desert }

/// The Monday that week 0 of the endless world starts on.
final _epoch = DateTime(2024, 1, 1);

/// One week's overworld on the road to the Overlord. Every week is a window
/// onto one endless world: its terrain continues into the weeks before and
/// after, so the weeks join seamlessly side by side (see [joinWeeks]). It is
/// computed from the week alone, so it stays the same all week, changes on
/// Monday, and any past week can be drawn again exactly.
///
/// Terrain letters: G grass, F forest, H hills, M mountains, W water,
/// S sand, B bridge (a road across water).
class WeekMap {
  WeekMap._(this.monday, this.terrain, this.route, this.road, this.theme);

  /// The map for the ISO week (Monday to Sunday) that [day] falls in.
  factory WeekMap.forWeek(DateTime day) =>
      _cache.putIfAbsent(weekStartOf(day), () => _forWeek(weekStartOf(day)));

  /// Generated maps by Monday: the same week is never generated twice.
  static final _cache = <DateTime, WeekMap>{};

  static WeekMap _forWeek(DateTime monday) {
    final (year, week) = isoWeek(monday);
    final random = Random(year * 100 + week);
    final season = switch (monday.month) {
      12 || 1 || 2 => MapTheme.snow,
      9 || 10 || 11 => MapTheme.autumn,
      _ => MapTheme.meadow,
    };
    final theme = random.nextDouble() < 0.2 ? MapTheme.desert : season;
    return _generate(monday, random, theme);
  }

  /// The week's Monday.
  final DateTime monday;
  final List<String> terrain;

  /// Camp, one lair per win needed, then the Overlord's castle.
  final List<Point<int>> route;

  /// Every tile the road covers.
  final Set<Point<int>> road;
  final MapTheme theme;

  String at(int x, int y) => terrain[y][x];

  /// Whether a tile is not water (outside the map counts as land).
  bool isLand(int x, int y) =>
      x < 0 || y < 0 || x >= mapCols || y >= mapRows || at(x, y) != 'W';
}

/// Consecutive weeks joined into one road: each week's castle leads on to
/// the next week's camp, across the seam (with bridges where needed).
List<WeekMap> joinWeeks(List<WeekMap> weeks) {
  final joined = [...weeks];
  for (var i = 0; i < joined.length - 1; i++) {
    final a = joined[i], b = joined[i + 1];
    if (daysBetween(a.monday, b.monday) != 7) continue;
    final tiles = [
      for (var y = 0; y < mapRows; y++)
        [...a.terrain[y].split(''), ...b.terrain[y].split('')],
    ];
    final road = {...a.road, for (final p in b.road) Point(p.x + mapCols, p.y)};
    final camp = b.route.first;
    _connect(tiles, road, a.route.last, Point(camp.x + mapCols, camp.y));
    joined[i] = WeekMap._(
      a.monday,
      [for (final row in tiles) row.sublist(0, mapCols).join()],
      a.route,
      Set.unmodifiable({
        for (final p in road)
          if (p.x < mapCols) p,
      }),
      a.theme,
    );
    joined[i + 1] = WeekMap._(
      b.monday,
      [for (final row in tiles) row.sublist(mapCols).join()],
      b.route,
      Set.unmodifiable({
        for (final p in road)
          if (p.x >= mapCols) Point(p.x - mapCols, p.y),
      }),
      b.theme,
    );
  }
  return joined;
}

/// Stable value 0..1 for a point of the endless lattice.
double _lattice(int i, int j, int salt) {
  var h = i * 374761393 + j * 668265263 + salt * 2147483647;
  h = (h ^ (h >> 13)) * 1274126177;
  h = h ^ (h >> 16);
  return (h & 0xFFFFFF) / 0x1000000;
}

/// Smooth noise at world column [x] and row [y]: lattice values blended,
/// [cellX] tiles apart across and [cellsY] cells over the map's height.
double _noise(int x, int y, double cellX, int cellsY, int salt) {
  double smooth(double t) => t * t * (3 - 2 * t);
  final gx = x / cellX, gy = y / (mapRows - 1) * cellsY;
  final i = gx.floor(), j = min(gy.floor(), cellsY - 1);
  final tx = smooth(gx - i), ty = smooth(gy - j);
  final top = _lattice(i, j, salt) * (1 - tx) + _lattice(i + 1, j, salt) * tx;
  final bottom =
      _lattice(i, j + 1, salt) * (1 - tx) + _lattice(i + 1, j + 1, salt) * tx;
  return top * (1 - ty) + bottom * ty;
}

WeekMap _generate(DateTime monday, Random random, MapTheme theme) {
  // This week's columns of the endless world.
  final offset = daysBetween(_epoch, monday) ~/ 7 * mapCols;
  final tiles = [
    for (var y = 0; y < mapRows; y++)
      [
        for (var x = 0; x < mapCols; x++)
          switch ((
            _noise(offset + x, y, 4, 3, 1),
            _noise(offset + x, y, 5.3, 2, 2),
          )) {
            (< 0.27, _) => 'W',
            (> 0.8, _) => 'M',
            (> 0.7, _) => 'H',
            (_, > 0.6) => 'F',
            (_, < 0.3) => 'S',
            _ => 'G',
          },
      ],
  ];

  // Camp in the lower left, castle in the upper right, the lairs spread out
  // between them from left to right.
  final camp = Point(random.nextInt(2), 6 + random.nextInt(4));
  final castle = Point(14 + random.nextInt(2), random.nextInt(3));
  final route = [camp];
  final taken = [camp, castle];
  for (var i = 0; i < overlordWinsNeeded; i++) {
    final x = 2 + (i * 11 / (overlordWinsNeeded - 1)).round();
    // Any tile in this lair's columns, as far as possible from the other
    // stops so lairs and portraits never crowd; the spacing relaxes only
    // if nothing fits, and stops never share a tile.
    final columns = [
      for (var cx = max(1, x - 1); cx <= min(mapCols - 2, x + 1); cx++)
        for (var cy = 1; cy < mapRows - 1; cy++) Point(cx, cy),
    ];
    for (var spacing = 3; spacing >= 1; spacing--) {
      final free = [
        for (final p in columns)
          if (taken.every(
            (t) => (t.x - p.x).abs() + (t.y - p.y).abs() >= spacing,
          ))
            p,
      ];
      if (free.isNotEmpty) {
        final stop = free[random.nextInt(free.length)];
        route.add(stop);
        taken.add(stop);
        break;
      }
    }
  }
  route.add(castle);
  for (final p in route) {
    if ('WMH'.contains(tiles[p.y][p.x])) tiles[p.y][p.x] = 'G';
  }
  final road = <Point<int>>{};
  for (var i = 0; i < route.length - 1; i++) {
    _connect(tiles, road, route[i], route[i + 1]);
  }
  return WeekMap._(
    monday,
    [for (final row in tiles) row.join()],
    List.unmodifiable(route),
    Set.unmodifiable(road),
    theme,
  );
}

/// Adds the cheapest walk from [from] to [to] to [road], around water and
/// mountains; tiles already on the road cost less, so legs share it instead
/// of running side by side. Where no walk exists, a road is cut straight
/// through (bridges over water).
void _connect(
  List<List<String>> tiles,
  Set<Point<int>> road,
  Point<int> from,
  Point<int> to,
) {
  final width = tiles.first.length;
  bool walkable(Point<int> p) =>
      p.x >= 0 &&
      p.y >= 0 &&
      p.x < width &&
      p.y < mapRows &&
      !'WMH'.contains(tiles[p.y][p.x]);
  final previous = <Point<int>, Point<int>>{};
  final cost = {from: 0};
  final open = [from];
  final seen = <Point<int>>{};
  while (open.isNotEmpty) {
    open.sort((a, b) => cost[a]!.compareTo(cost[b]!));
    final p = open.removeAt(0);
    if (!seen.add(p)) continue;
    if (p == to) break;
    for (final d in const [
      Point(1, 0),
      Point(-1, 0),
      Point(0, 1),
      Point(0, -1),
    ]) {
      final n = p + d;
      if (!walkable(n) || seen.contains(n)) continue;
      final c = cost[p]! + _stepCost(road, n);
      if (c < (cost[n] ?? 1 << 30)) {
        cost[n] = c;
        previous[n] = p;
        open.add(n);
      }
    }
  }
  if (seen.contains(to)) {
    for (Point<int>? p = to; p != null; p = previous[p]) {
      road.add(p);
    }
    return;
  }
  var p = from;
  road.add(p);
  while (p != to) {
    p = p.x != to.x
        ? Point(p.x + (to.x - p.x).sign, p.y)
        : Point(p.x, p.y + (to.y - p.y).sign);
    final tile = tiles[p.y][p.x];
    if (tile == 'W') tiles[p.y][p.x] = 'B';
    if (tile == 'M' || tile == 'H') tiles[p.y][p.x] = 'G';
    road.add(p);
  }
}

/// Walking cost of a tile: the road is cheapest, a new tile right beside the
/// road dearest (it would draw two roads side by side).
int _stepCost(Set<Point<int>> road, Point<int> tile) {
  if (road.contains(tile)) return 1;
  const sides = [Point(1, 0), Point(-1, 0), Point(0, 1), Point(0, -1)];
  return sides.any((d) => road.contains(tile + d)) ? 8 : 3;
}
