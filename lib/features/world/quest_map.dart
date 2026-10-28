import 'dart:collection';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/fight/boss.dart';
import '../fight/boss_art.dart';
import '../fight/hero_art.dart';
import '../settings/settings_controller.dart';

/// The week's road to the Overlord as a 16-bit style overworld: tiles drawn
/// pixel by pixel in code (no image assets). Fog hides what lies ahead; each
/// win clears the way to the next lair and shows the boss beaten there. The
/// Overlord's castle comes into view with the last win before it.
class QuestMap extends ConsumerWidget {
  const QuestMap({
    super.key,
    required this.wins,
    required this.beaten,
    required this.semanticLabel,
  });

  /// This week's wins against chore bosses, in order (may exceed the lairs).
  final List<BossFamily> wins;

  /// Whether the Overlord was beaten this week.
  final bool beaten;
  final String semanticLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final reached = wins.length.clamp(0, overlordWinsNeeded);
    final hero = _HeroLook(
      skin: avatarSkins[settings.avatarSkin.clamp(0, avatarSkins.length - 1)],
      hair: avatarHair[settings.avatarHair.clamp(0, avatarHair.length - 1)],
      cape: avatarCapes[settings.avatarCape.clamp(0, avatarCapes.length - 1)],
      hat: settings.avatarHat,
    );
    // Its own TalkBack node, so the progress is read on its own.
    return Semantics(
      container: true,
      label: semanticLabel,
      image: true,
      child: ExcludeSemantics(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: AspectRatio(
            aspectRatio: _cols / _rows,
            child: LayoutBuilder(
              builder: (context, box) {
                final tile = box.maxWidth / _cols;
                return Stack(
                  children: [
                    Positioned.fill(
                      child: RepaintBoundary(
                        child: CustomPaint(
                          painter: _OverworldPainter(
                            reached: reached,
                            beaten: beaten,
                            hero: hero,
                          ),
                        ),
                      ),
                    ),
                    // Portraits of the bosses beaten at the reached lairs.
                    for (var i = 1; i <= reached; i++)
                      Positioned(
                        // Above-right of the lair, clear of the hero.
                        left: (_route[i].x + 0.35) * tile,
                        top: (_route[i].y - 0.55) * tile,
                        width: tile * 1.1,
                        height: tile * 1.1,
                        child: BossArt(family: wins[i - 1], size: tile * 1.1),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroLook {
  const _HeroLook({
    required this.skin,
    required this.hair,
    required this.cape,
    required this.hat,
  });

  final Color skin, hair, cape;
  final int hat;

  @override
  bool operator ==(Object other) =>
      other is _HeroLook &&
      other.skin == skin &&
      other.hair == hair &&
      other.cape == cape &&
      other.hat == hat;

  @override
  int get hashCode => Object.hash(skin, hair, cape, hat);
}

const _cols = 16, _rows = 10;

/// G grass, F forest, H hills, M mountains, W water, S sand.
const _terrain = [
  'WWWWWMMMMHSSSSSS',
  'WWWGGFMMHHSSSSSS',
  'WWGGFFFGGHSSSSSS',
  'WGGFFFGGGGHMSSSS',
  'GGFFGGGGGGFFHMSS',
  'GGFGGWWWGGGFFHMM',
  'GFGGWWWWWGGGFFHM',
  'GGGGGWWWGGGGGFFH',
  'GGGGGGGGGGGFFGGG',
  'MHGGFFGGGGGGFFMH',
];

/// Camp, the five lairs, then the Overlord's castle.
const _route = [
  Point(1, 8),
  Point(3, 5),
  Point(6, 2),
  Point(9, 4),
  Point(11, 7),
  Point(12, 3),
  Point(14, 1),
];

String _at(int x, int y) => _terrain[y][x];

bool _land(int x, int y) =>
    x < 0 || y < 0 || x >= _cols || y >= _rows || _at(x, y) != 'W';

/// The road: shortest walks between the stops around water and mountains.
final Set<Point<int>> _road = () {
  final road = <Point<int>>{};
  bool walkable(Point<int> p) =>
      p.x >= 0 &&
      p.y >= 0 &&
      p.x < _cols &&
      p.y < _rows &&
      !'WMH'.contains(_at(p.x, p.y));
  for (var i = 0; i < _route.length - 1; i++) {
    final from = _route[i], to = _route[i + 1];
    final previous = <Point<int>, Point<int>>{};
    final queue = Queue.of([from]);
    final seen = {from};
    while (queue.isNotEmpty) {
      final p = queue.removeFirst();
      if (p == to) break;
      for (final d in const [
        Point(1, 0),
        Point(-1, 0),
        Point(0, 1),
        Point(0, -1),
      ]) {
        final n = p + d;
        if ((walkable(n) || n == to) && seen.add(n)) {
          previous[n] = p;
          queue.add(n);
        }
      }
    }
    for (Point<int>? p = to; p != null; p = previous[p]) {
      road.add(p);
    }
  }
  return road;
}();

/// Tiles 0 = hidden, 1 = fog edge (dithered), 2 = visible.
int _visibility(int x, int y, int reached, bool beaten) {
  if (beaten) return 2;
  var best = 0;
  for (var i = 0; i <= min(reached + 1, _route.length - 1); i++) {
    // Reached stops light up their surroundings; the next one only peeks.
    final radius = i <= reached ? 2.6 : 1.1;
    final d = sqrt(pow(x - _route[i].x, 2) + pow(y - _route[i].y, 2));
    if (d <= radius) return 2;
    if (d <= radius + 1) best = 1;
  }
  return best;
}

class _OverworldPainter extends CustomPainter {
  _OverworldPainter({
    required this.reached,
    required this.beaten,
    required this.hero,
  });

  final int reached;
  final bool beaten;
  final _HeroLook hero;

  static const _px = 16; // pixels per tile side
  late Canvas _c;
  final _paints = <int, Paint>{};

  void _dot(int tx, int ty, int x, int y, Color color, [int w = 1, int h = 1]) {
    final paint = _paints.putIfAbsent(
      color.toARGB32(),
      () => Paint()
        ..color = color
        ..isAntiAlias = false,
    );
    _c.drawRect(
      Rect.fromLTWH(
        tx * _px + x.toDouble(),
        ty * _px + y.toDouble(),
        w.toDouble(),
        h.toDouble(),
      ),
      paint,
    );
  }

  /// Stable pseudo-random 0..1 per tile and salt, so the map never flickers.
  double _hash(int x, int y, int salt) {
    final n = sin(x * 12.9898 + y * 78.233 + salt * 37.719) * 43758.5453;
    return n - n.floorToDouble();
  }

  @override
  void paint(Canvas canvas, Size size) {
    _c = canvas;
    canvas.scale(size.width / (_cols * _px), size.height / (_rows * _px));
    for (var y = 0; y < _rows; y++) {
      for (var x = 0; x < _cols; x++) {
        switch (_at(x, y)) {
          case 'W':
            _water(x, y);
          case 'S':
            _sand(x, y);
          case 'M':
            _grass(x, y);
            _mountain(x, y);
          case 'H':
            _grass(x, y);
            _hill(x, y);
          case 'F':
            _grass(x, y);
            if (!_road.contains(Point(x, y))) _forest(x, y);
          default:
            _grass(x, y);
        }
        if (_road.contains(Point(x, y))) _path(x, y);
      }
    }
    _camp(_route.first.x, _route.first.y);
    for (var i = 1; i < _route.length - 1; i++) {
      _lair(_route[i].x, _route[i].y, reached: i <= reached);
    }
    _castle(_route.last.x, _route.last.y);
    for (var y = 0; y < _rows; y++) {
      for (var x = 0; x < _cols; x++) {
        _fog(x, y, _visibility(x, y, reached, beaten));
      }
    }
    final at = beaten ? _route.last : _route[reached];
    _hero(at.x, at.y);
  }

  // Grass: three greens, tufts and a few flowers.
  void _grass(int x, int y) {
    _dot(x, y, 0, 0, const Color(0xFF5AA43C), 16, 16);
    for (var k = 0; k < 4; k++) {
      final a = (_hash(x, y, k) * 13).floor() + 1;
      final b = (_hash(y, x, k + 7) * 12).floor() + 2;
      _dot(x, y, a, b, const Color(0xFF3F822B));
      _dot(x, y, a + 2, b, const Color(0xFF3F822B));
      _dot(x, y, a + 1, b + 1, const Color(0xFF3F822B));
      _dot(x, y, a + 1, b - 1, const Color(0xFF86C95A));
    }
    if (_hash(x, y, 31) > 0.82) {
      final a = (_hash(x, y, 32) * 10).floor() + 2;
      final b = (_hash(x, y, 33) * 10).floor() + 2;
      _dot(x, y, a, b, const Color(0xFFF7E26B));
      _dot(x, y, a + 4, b + 2, const Color(0xFFF2F2F2));
    }
  }

  // Forest: round trees with outline, shade and highlight.
  void _forest(int x, int y) {
    const outline = Color(0xFF1E4A1C);
    const shade = Color(0xFF2C6B27);
    const leaf = Color(0xFF3E8E35);
    const light = Color(0xFF6CB84E);
    const trunk = Color(0xFF5B3A1F);
    final trees = _hash(x, y, 5) > 0.5
        ? const [Point(1, 1), Point(9, 3), Point(4, 8)]
        : const [Point(5, 0), Point(1, 7), Point(9, 8)];
    for (final t in trees) {
      _dot(x, y, t.x + 2, t.y + 6, trunk, 2, 2);
      _dot(x, y, t.x + 1, t.y, outline, 4, 1);
      _dot(x, y, t.x, t.y + 1, outline, 6, 4);
      _dot(x, y, t.x + 1, t.y + 5, outline, 4, 1);
      _dot(x, y, t.x + 1, t.y + 1, leaf, 4, 4);
      _dot(x, y, t.x + 3, t.y + 3, shade, 2, 2);
      _dot(x, y, t.x + 1, t.y + 1, light, 2, 1);
      _dot(x, y, t.x + 1, t.y + 2, light);
    }
  }

  // Hills: a rounded mound with a lit side.
  void _hill(int x, int y) {
    const dark = Color(0xFF4C7A2A);
    const mid = Color(0xFF6E9E3A);
    const light = Color(0xFF98C25A);
    const widths = [3, 5, 6, 7, 7, 8, 8];
    for (var j = 0; j < widths.length; j++) {
      final half = widths[j];
      _dot(x, y, 8 - half, 8 + j, mid, half * 2, 1);
      _dot(x, y, 8, 8 + j, dark, half, 1);
      if (j > 0) _dot(x, y, 9 - half, 8 + j, light, max(1, half ~/ 2), 1);
    }
  }

  // Mountains: two-faced rock with outline and a snow cap.
  void _mountain(int x, int y) {
    const outline = Color(0xFF3E2A1A);
    const lit = Color(0xFFB8925E);
    const dark = Color(0xFF7C5A36);
    const snow = Color(0xFFF4F4EE);
    const snowShade = Color(0xFFBFD0E0);
    for (var j = 0; j < 14; j++) {
      final half = j ~/ 2 + 1;
      _dot(x, y, 8 - half - 1, 2 + j, outline);
      _dot(x, y, 8 + half, 2 + j, outline);
      _dot(x, y, 8 - half, 2 + j, j < 4 ? snow : lit, half, 1);
      _dot(x, y, 8, 2 + j, j < 4 ? snowShade : dark, half, 1);
    }
    _dot(x, y, 7, 1, outline, 2, 1);
  }

  // Water: deep bands, glints and foam where it meets land.
  void _water(int x, int y) {
    _dot(x, y, 0, 0, const Color(0xFF2C68A8), 16, 16);
    _dot(x, y, 0, 10, const Color(0xFF255A93), 16, 6);
    for (var k = 0; k < 3; k++) {
      final a = (_hash(x, y, k) * 11).floor() + 1;
      final b = (_hash(y, x, k + 3) * 13).floor() + 1;
      _dot(x, y, a, b, const Color(0xFF7FC4EE), 3, 1);
      _dot(x, y, a + 1, b + 1, const Color(0xFF4F93CF), 2, 1);
    }
    const foam = Color(0xFFD6F0FB);
    if (_land(x, y - 1)) _dot(x, y, 0, 0, foam, 16, 1);
    if (_land(x, y + 1)) _dot(x, y, 0, 15, foam, 16, 1);
    if (_land(x - 1, y)) _dot(x, y, 0, 0, foam, 1, 16);
    if (_land(x + 1, y)) _dot(x, y, 15, 0, foam, 1, 16);
  }

  // Sand: warm dunes with ripples and specks.
  void _sand(int x, int y) {
    _dot(x, y, 0, 0, const Color(0xFFE6C77E), 16, 16);
    for (var k = 0; k < 3; k++) {
      final a = (_hash(x, y, k) * 10).floor() + 1;
      final b = (_hash(y, x, k + 5) * 13).floor() + 2;
      _dot(x, y, a, b, const Color(0xFFC9A45A), 4, 1);
      _dot(x, y, a + 1, b - 1, const Color(0xFFF4DFA4), 2, 1);
    }
  }

  // Path: packed earth with darker edges and a pebble.
  void _path(int x, int y) {
    const earth = Color(0xFFD7B57C);
    const edge = Color(0xFFAA8550);
    bool road(int dx, int dy) => _road.contains(Point(x + dx, y + dy));
    _dot(x, y, 4, 4, earth, 8, 8);
    if (road(0, -1)) _dot(x, y, 4, 0, earth, 8, 4);
    if (road(0, 1)) _dot(x, y, 4, 12, earth, 8, 4);
    if (road(-1, 0)) _dot(x, y, 0, 4, earth, 4, 8);
    if (road(1, 0)) _dot(x, y, 12, 4, earth, 4, 8);
    if (!road(0, -1)) _dot(x, y, 4, 3, edge, 8, 1);
    if (!road(0, 1)) _dot(x, y, 4, 12, edge, 8, 1);
    if (!road(-1, 0)) _dot(x, y, 3, 4, edge, 1, 8);
    if (!road(1, 0)) _dot(x, y, 12, 4, edge, 1, 8);
    _dot(x, y, 6 + (_hash(x, y, 9) * 4).floor(), 7, edge);
  }

  // The camp: a tent with a lit and a shaded side, and a small fire.
  void _camp(int x, int y) {
    const outline = Color(0xFF4A1E14);
    for (var j = 0; j < 9; j++) {
      final w = j * 2 ~/ 3;
      _dot(x, y, 7 - w, 4 + j, outline);
      _dot(x, y, 8 + w, 4 + j, outline);
      if (w > 0) {
        _dot(x, y, 8 - w, 4 + j, const Color(0xFFD2553C), w, 1);
        _dot(x, y, 8, 4 + j, const Color(0xFF9C3524), w, 1);
      }
    }
    _dot(x, y, 7, 10, const Color(0xFF2A1408), 2, 3);
    _dot(x, y, 13, 11, const Color(0xFFF7A93B), 2, 2);
    _dot(x, y, 13, 10, const Color(0xFFFFE07A));
    _dot(x, y, 12, 13, const Color(0xFF6B4423), 4, 1);
  }

  // A lair: a rocky cave mouth; unexplored ones carry a "?" sign.
  void _lair(int x, int y, {required bool reached}) {
    const outline = Color(0xFF2E2A2E);
    const rock = Color(0xFF8C8794);
    const rockLight = Color(0xFFB6B1BC);
    const cave = Color(0xFF141018);
    _dot(x, y, 2, 6, outline, 12, 10);
    _dot(x, y, 3, 5, outline, 10, 1);
    _dot(x, y, 3, 6, rock, 10, 9);
    _dot(x, y, 3, 6, rockLight, 4, 2);
    _dot(x, y, 6, 9, cave, 4, 6);
    _dot(x, y, 7, 8, cave, 2, 1);
    if (!reached) {
      const wood = Color(0xFF6B4423);
      const ink = Color(0xFF3A2414);
      _dot(x, y, 11, 0, wood, 1, 8);
      _dot(x, y, 8, 0, ink, 7, 5);
      _dot(x, y, 9, 1, const Color(0xFFC8945A), 5, 3);
      _dot(x, y, 10, 1, ink, 2, 1);
      _dot(x, y, 12, 1, ink);
      _dot(x, y, 11, 2, ink);
      _dot(x, y, 11, 4, const Color(0xFFC8945A));
    }
  }

  // The Overlord's castle: towers, battlements, gate and banner.
  void _castle(int x, int y) {
    const outline = Color(0xFF3A3A4A);
    const wall = Color(0xFFCACAD6);
    const shade = Color(0xFF9A9AAE);
    const gate = Color(0xFF241A2C);
    _dot(x, y, 1, 4, outline, 14, 12);
    _dot(x, y, 2, 5, wall, 12, 10);
    _dot(x, y, 9, 5, shade, 5, 10);
    for (final tx in const [1, 11]) {
      _dot(x, y, tx, 1, outline, 4, 5);
      _dot(x, y, tx + 1, 2, wall, 2, 4);
    }
    for (var i = 5; i < 11; i += 2) {
      _dot(x, y, i, 3, outline);
    }
    _dot(x, y, 6, 9, gate, 4, 6);
    _dot(x, y, 7, 8, gate, 2, 1);
    final banner = beaten ? const Color(0xFF4CAF50) : const Color(0xFF7E3FC8);
    _dot(x, y, 8, 0, outline, 1, 5);
    _dot(x, y, 9, 0, banner, 4, 2);
    _dot(x, y, 9, 2, banner, 2, 1);
  }

  // Fog: deep night blue, dithered at its edge.
  void _fog(int x, int y, int visibility) {
    if (visibility == 2) return;
    const fog = Color(0xFF1C1A30);
    if (visibility == 0) {
      _dot(x, y, 0, 0, fog, 16, 16);
      if (_hash(x, y, 77) > 0.85) {
        final i = (_hash(x, y, 78) * 14).floor() + 1;
        _dot(x, y, i, 4, const Color(0xFF8E8AB8));
      }
      return;
    }
    for (var j = 0; j < 16; j++) {
      for (var i = j % 2; i < 16; i += 2) {
        _dot(x, y, i, j, fog);
      }
    }
  }

  // The hero: a small sprite in the player's colors, standing on the stop.
  void _hero(int x, int y) {
    const outline = Color(0xFF1A1418);
    const legs = Color(0xFF3A2A4A);
    // Half a tile left of the stop, so a boss portrait can sit beside it.
    void p(int i, int j, Color c, [int w = 1, int h = 1]) =>
        _dot(x, y, i - 8, j - 4, c, w, h);
    // Mop in the right hand.
    p(13, 4, const Color(0xFF8D6E63), 1, 10);
    p(12, 14, const Color(0xFFB0BEC5), 3, 2);
    // Body and cape.
    p(4, 8, outline, 8, 7);
    p(5, 9, hero.cape, 6, 5);
    p(5, 12, const Color(0xFFFFB13B), 6, 1);
    p(5, 15, legs, 2, 2);
    p(9, 15, legs, 2, 2);
    // Head.
    p(5, 2, outline, 6, 7);
    p(6, 3, hero.skin, 4, 5);
    p(6, 5, outline);
    p(9, 5, outline);
    p(6, 2, hero.hair, 4, 2);
    switch (hero.hat) {
      case 1: // cap
        p(5, 1, const Color(0xFFD32F2F), 6, 2);
        p(10, 2, const Color(0xFFD32F2F), 2, 1);
      case 2: // bandana
        p(5, 2, const Color(0xFF1E88E5), 6, 1);
        p(4, 3, const Color(0xFF1E88E5));
      case 3: // wizard hat
        p(4, 2, const Color(0xFF5E35B1), 8, 1);
        p(6, 0, const Color(0xFF5E35B1), 4, 2);
        p(7, -2, const Color(0xFF5E35B1), 2, 2);
        p(8, -3, const Color(0xFFFFD54F));
      case 4: // crown
        p(5, 0, const Color(0xFFFFC107), 6, 2);
        p(5, -1, const Color(0xFFFFC107));
        p(7, -1, const Color(0xFFFFC107), 2, 1);
        p(10, -1, const Color(0xFFFFC107));
    }
  }

  @override
  bool shouldRepaint(_OverworldPainter old) =>
      old.reached != reached || old.beaten != beaten || old.hero != hero;
}
