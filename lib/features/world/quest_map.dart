import 'dart:math';

import '../../app/theme/pixel.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/fight/boss.dart';
import '../../domain/fight/overworld.dart';
import '../fight/boss_art.dart';
import '../fight/hero_art.dart';
import '../settings/settings_controller.dart';

/// The week's road to the Overlord as a 16-bit style overworld: tiles drawn
/// pixel by pixel in code (no image assets), on a map generated for the week
/// ([WeekMap]). Fog hides what lies ahead; each win clears the way to the
/// next lair and shows the boss beaten there. The Overlord's castle comes
/// into view with the last win before it.
class QuestMap extends ConsumerWidget {
  const QuestMap({
    super.key,
    required this.map,
    required this.wins,
    required this.beaten,
    required this.semanticLabel,
  });

  final WeekMap map;

  /// This week's wins against chore bosses, in order (may exceed the lairs).
  final List<BossFamily> wins;

  /// Whether the Overlord was beaten this week.
  final bool beaten;
  final String semanticLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final reached = wins.length.clamp(0, overlordWinsNeeded);
    final hero = HeroLook.of(settings);
    // Its own TalkBack node, so the progress is read on its own.
    return Semantics(
      container: true,
      label: semanticLabel,
      image: true,
      child: ExcludeSemantics(
        child: PixelFrame(
          child: AspectRatio(
            aspectRatio: mapCols / mapRows,
            child: LayoutBuilder(
              builder: (context, box) {
                final tile = box.maxWidth / mapCols;
                return Stack(
                  children: [
                    Positioned.fill(
                      child: RepaintBoundary(
                        child: CustomPaint(
                          painter: WeekPainter(
                            map: map,
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
                        left: (map.route[i].x + 0.35) * tile,
                        top: (map.route[i].y - 0.55) * tile,
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

/// The hero's colors and hat on the map.
class HeroLook {
  const HeroLook({
    required this.skin,
    required this.hair,
    required this.cape,
    required this.hat,
  });

  /// The look chosen in the Wardrobe.
  factory HeroLook.of(AppSettings settings) => HeroLook(
    skin: avatarSkins[settings.avatarSkin.clamp(0, avatarSkins.length - 1)],
    hair: avatarHair[settings.avatarHair.clamp(0, avatarHair.length - 1)],
    cape: avatarCapes[settings.avatarCape.clamp(0, avatarCapes.length - 1)],
    hat: settings.avatarHat,
  );

  final Color skin, hair, cape;
  final int hat;

  @override
  bool operator ==(Object other) =>
      other is HeroLook &&
      other.skin == skin &&
      other.hair == hair &&
      other.cape == cape &&
      other.hat == hat;

  @override
  int get hashCode => Object.hash(skin, hair, cape, hat);
}

/// Colors of one map theme.
class _Palette {
  const _Palette({
    required this.grass,
    required this.grassDark,
    required this.grassLight,
    required this.leaf,
    required this.leafShade,
    required this.leafLight,
    required this.treeOutline,
    required this.sand,
    required this.sandDark,
    required this.sandLight,
    required this.water,
    required this.waterDeep,
    required this.flower,
  });

  final Color grass, grassDark, grassLight;
  final Color leaf, leafShade, leafLight, treeOutline;
  final Color sand, sandDark, sandLight;
  final Color water, waterDeep, flower;

  static _Palette of(MapTheme theme) => switch (theme) {
    MapTheme.meadow => const _Palette(
      grass: Color(0xFF5AA43C),
      grassDark: Color(0xFF3F822B),
      grassLight: Color(0xFF86C95A),
      leaf: Color(0xFF3E8E35),
      leafShade: Color(0xFF2C6B27),
      leafLight: Color(0xFF6CB84E),
      treeOutline: Color(0xFF1E4A1C),
      sand: Color(0xFFE6C77E),
      sandDark: Color(0xFFC9A45A),
      sandLight: Color(0xFFF4DFA4),
      water: Color(0xFF2C68A8),
      waterDeep: Color(0xFF255A93),
      flower: Color(0xFFF7E26B),
    ),
    MapTheme.autumn => const _Palette(
      grass: Color(0xFF8E9A3E),
      grassDark: Color(0xFF6E7A2C),
      grassLight: Color(0xFFB4B85A),
      leaf: Color(0xFFD9772B),
      leafShade: Color(0xFFA9441F),
      leafLight: Color(0xFFF2B33D),
      treeOutline: Color(0xFF4A2412),
      sand: Color(0xFFD9B271),
      sandDark: Color(0xFFB88E4E),
      sandLight: Color(0xFFEACB92),
      water: Color(0xFF2F5F8F),
      waterDeep: Color(0xFF27507A),
      flower: Color(0xFFC0392B),
    ),
    MapTheme.snow => const _Palette(
      grass: Color(0xFFE6EDF5),
      grassDark: Color(0xFFBFCCDD),
      grassLight: Color(0xFFFFFFFF),
      leaf: Color(0xFF2E6B4A),
      leafShade: Color(0xFF1F4D36),
      leafLight: Color(0xFFF2F6FA),
      treeOutline: Color(0xFF15332A),
      sand: Color(0xFFD4DEEA),
      sandDark: Color(0xFFAFBED2),
      sandLight: Color(0xFFF5F8FC),
      water: Color(0xFF3F7DB4),
      waterDeep: Color(0xFF346A9C),
      flower: Color(0xFFD9E7F7),
    ),
    MapTheme.desert => const _Palette(
      grass: Color(0xFFD8B46A),
      grassDark: Color(0xFFB8924C),
      grassLight: Color(0xFFEBCE8E),
      leaf: Color(0xFF5E8C3A),
      leafShade: Color(0xFF3F6A26),
      leafLight: Color(0xFF8CB85A),
      treeOutline: Color(0xFF2A3A16),
      sand: Color(0xFFEBD08F),
      sandDark: Color(0xFFCCA862),
      sandLight: Color(0xFFF7E4B4),
      water: Color(0xFF2A8CA0),
      waterDeep: Color(0xFF237588),
      flower: Color(0xFFE85D75),
    ),
  };
}

/// Tiles 0 = hidden, 1 = fog edge (dithered), 2 = visible.
int _visibility(
  List<Point<int>> route,
  int x,
  int y,
  int reached,
  bool beaten,
) {
  if (beaten) return 2;
  var best = 0;
  for (var i = 0; i <= min(reached + 1, route.length - 1); i++) {
    // Reached stops light up their surroundings; the next one only peeks.
    final radius = i <= reached ? 2.6 : 1.1;
    final d = sqrt(pow(x - route[i].x, 2) + pow(y - route[i].y, 2));
    if (d <= radius) return 2;
    if (d <= radius + 1) best = 1;
  }
  return best;
}

/// Paints one week of the overworld, scaled to the size it is given. The
/// weeks before and after ([previous], [next]) let roads, shores and the
/// change of season run on across the seams when weeks sit side by side.
class WeekPainter extends CustomPainter {
  WeekPainter({
    required this.map,
    required this.reached,
    required this.beaten,
    this.hero,
    this.previous,
    this.next,
    this.detailed = true,
  });

  final WeekMap map;
  final int reached;
  final bool beaten;

  /// Where the hero stands; `null` paints no hero (past weeks).
  final HeroLook? hero;
  final WeekMap? previous, next;

  /// Full 16-bit detail; plain tiles when the map is drawn small.
  final bool detailed;
  late final _Palette _colors = _Palette.of(map.theme);

  /// The terrain, looking into the neighbouring weeks across the seams
  /// (outside the realm counts as grass).
  String _terrain(int x, int y) {
    if (y < 0 || y >= mapRows) return 'G';
    if (x < 0) return previous?.at(mapCols + x, y) ?? 'G';
    if (x >= mapCols) return next?.at(x - mapCols, y) ?? 'G';
    return map.at(x, y);
  }

  bool _isRoad(int x, int y) {
    if (x < 0) return previous?.road.contains(Point(mapCols + x, y)) ?? false;
    if (x >= mapCols) {
      return next?.road.contains(Point(x - mapCols, y)) ?? false;
    }
    return map.road.contains(Point(x, y));
  }

  bool _isLand(int x, int y) => !'WB'.contains(_terrain(x, y));

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
    canvas.scale(size.width / (mapCols * _px), size.height / (mapRows * _px));
    final route = map.route;
    if (!detailed) {
      _plain();
      return;
    }
    for (var y = 0; y < mapRows; y++) {
      for (var x = 0; x < mapCols; x++) {
        switch (map.at(x, y)) {
          case 'W':
            _water(x, y);
          case 'B':
            _water(x, y);
            _bridge(x, y);
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
            if (!map.road.contains(Point(x, y))) _forest(x, y);
          default:
            _grass(x, y);
        }
        if (x == 0) _seam(y);
        if (map.road.contains(Point(x, y)) && map.at(x, y) != 'B') {
          _path(x, y);
        }
      }
    }
    _camp(route.first.x, route.first.y);
    for (var i = 1; i < route.length - 1; i++) {
      _lair(route[i].x, route[i].y, reached: i <= reached);
    }
    _castle(route.last.x, route.last.y);
    for (var y = 0; y < mapRows; y++) {
      for (var x = 0; x < mapCols; x++) {
        _fog(x, y, _visibility(route, x, y, reached, beaten));
      }
    }
    final look = hero;
    if (look != null) {
      final at = beaten ? route.last : route[reached];
      _hero(at.x, at.y, look);
    }
  }

  // Where the season changes from the week before, its ground frays into
  // this week's over the first tile column.
  void _seam(int y) {
    final before = previous;
    if (before == null || before.theme == map.theme) return;
    if ('WBM'.contains(map.at(0, y))) return;
    final ground = _Palette.of(before.theme).grass;
    for (var j = 0; j < 16; j++) {
      for (var i = j % 2; i < 8 - (j % 4); i += 2) {
        _dot(0, y, i, j, ground);
      }
    }
  }

  // Small maps: one color per tile, the landmarks, and the fog.
  void _plain() {
    for (var y = 0; y < mapRows; y++) {
      for (var x = 0; x < mapCols; x++) {
        final color = switch (map.at(x, y)) {
          'W' => _colors.water,
          'B' => const Color(0xFFA9773F),
          'S' => _colors.sand,
          'F' => _colors.leafShade,
          'M' => const Color(0xFF8C6A44),
          'H' => _colors.grassDark,
          _ => _colors.grass,
        };
        _dot(x, y, 0, 0, color, 16, 16);
        if (map.at(x, y) == 'M') {
          // Small maps: a snow cap only in winter, else it reads as dots.
          _dot(
            x,
            y,
            5,
            2,
            map.theme == MapTheme.snow
                ? const Color(0xFFF4F4EE)
                : const Color(0xFFB8925E),
            6,
            5,
          );
        }
        if (map.road.contains(Point(x, y))) {
          _dot(x, y, 5, 5, const Color(0xFFD7B57C), 6, 6);
          for (final (dx, dy) in const [(1, 0), (-1, 0), (0, 1), (0, -1)]) {
            if (_isRoad(x + dx, y + dy)) {
              _dot(
                x,
                y,
                dx > 0 ? 11 : (dx < 0 ? 0 : 5),
                dy > 0 ? 11 : (dy < 0 ? 0 : 5),
                const Color(0xFFD7B57C),
                dx == 0 ? 6 : 5,
                dy == 0 ? 6 : 5,
              );
            }
          }
        }
      }
    }
    final route = map.route;
    _dot(route.first.x, route.first.y, 3, 3, const Color(0xFFD2553C), 10, 10);
    for (var i = 1; i < route.length - 1; i++) {
      _dot(route[i].x, route[i].y, 2, 4, const Color(0xFF8C8794), 12, 12);
    }
    final castle = route.last;
    _dot(castle.x, castle.y, 1, 3, const Color(0xFFCACAD6), 14, 13);
    _dot(
      castle.x,
      castle.y,
      9,
      0,
      beaten ? const Color(0xFF4CAF50) : const Color(0xFF7E3FC8),
      6,
      5,
    );
    for (var y = 0; y < mapRows; y++) {
      for (var x = 0; x < mapCols; x++) {
        final visibility = _visibility(route, x, y, reached, beaten);
        if (visibility == 0) {
          _dot(x, y, 0, 0, const Color(0xFF1C1A30), 16, 16);
        } else if (visibility == 1) {
          for (var j = 0; j < 16; j += 8) {
            for (var i = (j ~/ 8) * 8 % 16; i < 16; i += 16) {
              _dot(x, y, i, j, const Color(0xFF1C1A30), 8, 8);
            }
          }
        }
      }
    }
  }

  // Grass: three greens, tufts and a few flowers.
  void _grass(int x, int y) {
    _dot(x, y, 0, 0, _colors.grass, 16, 16);
    for (var k = 0; k < 4; k++) {
      final a = (_hash(x, y, k) * 13).floor() + 1;
      final b = (_hash(y, x, k + 7) * 12).floor() + 2;
      _dot(x, y, a, b, _colors.grassDark);
      _dot(x, y, a + 2, b, _colors.grassDark);
      _dot(x, y, a + 1, b + 1, _colors.grassDark);
      _dot(x, y, a + 1, b - 1, _colors.grassLight);
    }
    if (_hash(x, y, 31) > 0.82) {
      final a = (_hash(x, y, 32) * 10).floor() + 2;
      final b = (_hash(x, y, 33) * 10).floor() + 2;
      _dot(x, y, a, b, _colors.flower);
      _dot(x, y, a + 4, b + 2, const Color(0xFFF2F2F2));
    }
  }

  // Forest: round trees with outline, shade and highlight.
  void _forest(int x, int y) {
    final outline = _colors.treeOutline;
    final shade = _colors.leafShade;
    final leaf = _colors.leaf;
    final light = _colors.leafLight;
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
    // Shades of the theme's ground, so hills fit snow and sand too.
    final dark = Color.lerp(_colors.grassDark, const Color(0xFF000000), 0.15)!;
    final mid = Color.lerp(_colors.grass, _colors.grassDark, 0.5)!;
    final light = _colors.grassLight;
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
    _dot(x, y, 0, 0, _colors.water, 16, 16);
    _dot(x, y, 0, 10, _colors.waterDeep, 16, 6);
    for (var k = 0; k < 3; k++) {
      final a = (_hash(x, y, k) * 11).floor() + 1;
      final b = (_hash(y, x, k + 3) * 13).floor() + 1;
      _dot(x, y, a, b, const Color(0xFF7FC4EE), 3, 1);
      _dot(x, y, a + 1, b + 1, const Color(0xFF4F93CF), 2, 1);
    }
    const foam = Color(0xFFD6F0FB);
    if (_isLand(x, y - 1)) _dot(x, y, 0, 0, foam, 16, 1);
    if (_isLand(x, y + 1)) _dot(x, y, 0, 15, foam, 16, 1);
    if (_isLand(x - 1, y)) _dot(x, y, 0, 0, foam, 1, 16);
    if (_isLand(x + 1, y)) _dot(x, y, 15, 0, foam, 1, 16);
  }

  // Sand: warm dunes with ripples and specks.
  void _sand(int x, int y) {
    _dot(x, y, 0, 0, _colors.sand, 16, 16);
    for (var k = 0; k < 3; k++) {
      final a = (_hash(x, y, k) * 10).floor() + 1;
      final b = (_hash(y, x, k + 5) * 13).floor() + 2;
      _dot(x, y, a, b, _colors.sandDark, 4, 1);
      _dot(x, y, a + 1, b - 1, _colors.sandLight, 2, 1);
    }
  }

  // Path: packed earth with darker edges and a pebble.
  void _path(int x, int y) {
    const earth = Color(0xFFD7B57C);
    const edge = Color(0xFFAA8550);
    bool road(int dx, int dy) => _isRoad(x + dx, y + dy);
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
    // Where four road tiles meet in a square, fill the gaps between them so
    // it reads as a small plaza instead of a ladder.
    for (final (dx, dy) in const [(1, 1), (-1, 1), (1, -1), (-1, -1)]) {
      if (road(dx, 0) && road(0, dy) && road(dx, dy)) {
        _dot(x, y, dx > 0 ? 12 : 0, dy > 0 ? 12 : 0, earth, 4, 4);
      }
    }
  }

  // Bridge: planks across the water, with rails, running along the road.
  void _bridge(int x, int y) {
    const plank = Color(0xFFA9773F);
    const dark = Color(0xFF6B4423);
    final across = _isRoad(x - 1, y) || _isRoad(x + 1, y);
    if (across) {
      _dot(x, y, 0, 4, plank, 16, 8);
      for (var i = 1; i < 16; i += 3) {
        _dot(x, y, i, 4, dark, 1, 8);
      }
      _dot(x, y, 0, 3, dark, 16, 1);
      _dot(x, y, 0, 12, dark, 16, 1);
    } else {
      _dot(x, y, 4, 0, plank, 8, 16);
      for (var j = 1; j < 16; j += 3) {
        _dot(x, y, 4, j, dark, 8, 1);
      }
      _dot(x, y, 3, 0, dark, 1, 16);
      _dot(x, y, 12, 0, dark, 1, 16);
    }
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
  void _hero(int x, int y, HeroLook hero) {
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
  bool shouldRepaint(WeekPainter old) =>
      old.map != map ||
      old.previous != previous ||
      old.next != next ||
      old.detailed != detailed ||
      old.reached != reached ||
      old.beaten != beaten ||
      old.hero != hero;
}
