import 'dart:math';

import '../../app/theme/pixel.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/fight/boss.dart';
import '../../app/art/art.dart';
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

/// The colors of one map theme, from `assets/art/palettes/map_*.gpl`. Tiles
/// are drawn in meadow colors and painted in the theme's palette.
MapPalette _paletteOf(MapTheme theme) => switch (theme) {
  MapTheme.meadow => mapMeadow,
  MapTheme.autumn => mapAutumn,
  MapTheme.snow => mapSnow,
  MapTheme.desert => mapDesert,
};

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
  late final MapPalette _colors = _paletteOf(map.theme);

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

  /// Paints [sprite] over tile ([x], [y]) in this week's palette.
  void _sprite(int x, int y, Sprite sprite) =>
      sprite.paint(_c, _colors.colors, Offset(x * _px * 1.0, y * _px * 1.0));

  /// One of [variants], picked per tile so the map never flickers.
  Sprite _pick(int x, int y, List<Sprite> variants) =>
      variants[(_hash(x, y, 1) * variants.length).floor()];

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
    final ground = _paletteOf(before.theme).grass;
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
          'B' => _colors.plank,
          'S' => _colors.sand,
          'F' => _colors.leafShade,
          'M' => _colors.mountainPlain,
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
            map.theme == MapTheme.snow ? _colors.snow : _colors.mountainLit,
            6,
            5,
          );
        }
        if (map.road.contains(Point(x, y))) {
          _dot(x, y, 5, 5, _colors.pathEarth, 6, 6);
          for (final (dx, dy) in const [(1, 0), (-1, 0), (0, 1), (0, -1)]) {
            if (_isRoad(x + dx, y + dy)) {
              _dot(
                x,
                y,
                dx > 0 ? 11 : (dx < 0 ? 0 : 5),
                dy > 0 ? 11 : (dy < 0 ? 0 : 5),
                _colors.pathEarth,
                dx == 0 ? 6 : 5,
                dy == 0 ? 6 : 5,
              );
            }
          }
        }
      }
    }
    final route = map.route;
    _dot(route.first.x, route.first.y, 3, 3, _colors.tent, 10, 10);
    for (var i = 1; i < route.length - 1; i++) {
      _dot(route[i].x, route[i].y, 2, 4, _colors.rock, 12, 12);
    }
    final castle = route.last;
    _dot(castle.x, castle.y, 1, 3, _colors.wall, 14, 13);
    _dot(
      castle.x,
      castle.y,
      9,
      0,
      beaten ? _colors.bannerWon : _colors.banner,
      6,
      5,
    );
    for (var y = 0; y < mapRows; y++) {
      for (var x = 0; x < mapCols; x++) {
        final visibility = _visibility(route, x, y, reached, beaten);
        if (visibility == 0) {
          _dot(x, y, 0, 0, _colors.fog, 16, 16);
        } else if (visibility == 1) {
          for (var j = 0; j < 16; j += 8) {
            for (var i = (j ~/ 8) * 8 % 16; i < 16; i += 16) {
              _dot(x, y, i, j, _colors.fog, 8, 8);
            }
          }
        }
      }
    }
  }

  // Terrain tiles are sprites from assets/art/map; shores and roads are
  // joined here, since they depend on the neighbouring tiles.
  void _grass(int x, int y) => _sprite(x, y, _pick(x, y, Sprites.grass));

  void _forest(int x, int y) =>
      _sprite(x, y, Sprites.forest[_hash(x, y, 5) > 0.5 ? 0 : 1]);

  void _hill(int x, int y) => _sprite(x, y, Sprites.hill);

  void _mountain(int x, int y) => _sprite(x, y, Sprites.mountain);

  // Water, with foam where it meets land.
  void _water(int x, int y) {
    _sprite(x, y, _pick(x, y, Sprites.water));
    final foam = _colors.foam;
    if (_isLand(x, y - 1)) _dot(x, y, 0, 0, foam, 16, 1);
    if (_isLand(x, y + 1)) _dot(x, y, 0, 15, foam, 16, 1);
    if (_isLand(x - 1, y)) _dot(x, y, 0, 0, foam, 1, 16);
    if (_isLand(x + 1, y)) _dot(x, y, 15, 0, foam, 1, 16);
  }

  void _sand(int x, int y) => _sprite(x, y, _pick(x, y, Sprites.sand));

  // Path: packed earth with darker edges and a pebble.
  void _path(int x, int y) {
    final earth = _colors.pathEarth;
    final edge = _colors.pathEdge;
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

  // Bridge: planks running along the road.
  void _bridge(int x, int y) => _sprite(
    x,
    y,
    _isRoad(x - 1, y) || _isRoad(x + 1, y)
        ? Sprites.bridgeAcross
        : Sprites.bridgeAlong,
  );

  void _camp(int x, int y) => _sprite(x, y, Sprites.camp);

  // A lair; unexplored ones carry a "?" sign.
  void _lair(int x, int y, {required bool reached}) {
    _sprite(x, y, Sprites.lair);
    if (!reached) _sprite(x, y, Sprites.lairSign);
  }

  // The Overlord's castle; its banner turns green once he's beaten.
  void _castle(int x, int y) =>
      _sprite(x, y, beaten ? Sprites.castleWon : Sprites.castle);

  // Fog: deep night blue, dithered at its edge.
  void _fog(int x, int y, int visibility) {
    if (visibility == 2) return;
    final fog = _colors.fog;
    if (visibility == 0) {
      _dot(x, y, 0, 0, fog, 16, 16);
      if (_hash(x, y, 77) > 0.85) {
        final i = (_hash(x, y, 78) * 14).floor() + 1;
        _dot(x, y, i, 4, _colors.star);
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
