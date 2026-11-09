import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../app/art/art.dart';
import '../../data/models/fight_progress.dart';
import '../../domain/fight/overlord.dart';
import '../../game/game_data.dart';
import '../../game/game_texts.dart';
import '../../l10n/app_localizations.dart';
import 'boss_art.dart';

/// This week's Overlord: the one beaten this week as it looked then,
/// otherwise the week's own look on this phone ([seed]) with the
/// [holidays] turned on.
OverlordLook weekOverlord(
  FightProgress? progress,
  DateTime today,
  Set<String> holidays, {
  int seed = 0,
}) =>
    progress?.beatenOverlord(today) ??
    OverlordLook.forWeek(today, holidays: holidays, seed: seed);

/// The classic Overlord in [holiday]'s parts, for its trophy.
OverlordLook holidayLook(String holiday) {
  final h = overlordHolidays[holiday]!;
  return OverlordLook(
    body: OverlordLook.classic.body,
    face: OverlordLook.classic.face,
    hat: h.hat,
    item: h.item,
    extra: h.extra,
    scheme: h.scheme,
    holiday: holiday,
  );
}

/// The Overlord's name: "Grimeclaw of the Sticky Floor", or a holiday
/// Overlord's own name.
String overlordName(AppLocalizations l10n, OverlordLook look) {
  final holiday = look.holiday;
  if (holiday != null) {
    return gameHolidayName(l10n, holiday) ?? l10n.gameBossOverlord;
  }
  final name = gameOverlordName(l10n, look.name);
  final title = gameOverlordTitle(l10n, look.title);
  return name == null || title == null ? l10n.gameBossOverlord : '$name $title';
}

/// "Heavy: slower, but longer rhythms."
String overlordTraitLine(AppLocalizations l10n, OverlordLook look) =>
    '${gameOverlordTrait(l10n, look.body) ?? ''}: '
    '${gameOverlordTraitDescription(l10n, look.body) ?? ''}';

/// The bosses palette with the Overlord's four key colors swapped for
/// [scheme]'s: main, light (the skin) and a darker shade of each.
List<Color> overlordColors(String scheme) {
  final (main, light) = overlordSchemes[scheme] ?? overlordSchemes['violet']!;
  final m = Color(main), l = Color(light);
  Color shade(Color c, double t) => Color.lerp(c, const Color(0xFF000000), t)!;
  final keys = {
    bosses.overlord: m,
    bosses.overlordShade: shade(m, 0.28),
    bosses.overlordLight: l,
    bosses.overlordLightShade: shade(l, 0.18),
  };
  return [for (final c in bosses.colors) keys[c] ?? c];
}

/// A weekly Overlord, stacked from its parts (assets/art/bosses/overlord)
/// and painted in its scheme. Like [BossArt]: scaled by whole pixels from
/// 48 up, [bob] shows it one pixel lower, and [mood] picks the face; when
/// defeated, the headgear slips.
class OverlordArt extends StatelessWidget {
  const OverlordArt({
    super.key,
    required this.look,
    this.size = 64,
    this.mood = BossMood.idle,
    this.bob = false,
    this.semanticLabel,
  });

  final OverlordLook look;
  final double size;
  final BossMood mood;
  final bool bob;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    Sprite part(String kind, String key, [int frame = 0]) =>
        Sprites.all['bosses/overlord/$kind/$key']!.$1[frame];
    final face = switch (mood) {
      BossMood.idle => 0,
      BossMood.hit => 1,
      BossMood.defeated => 2,
    };
    final label =
        semanticLabel ?? overlordName(AppLocalizations.of(context), look);
    return Semantics(
      label: label.isEmpty ? null : label,
      image: label.isNotEmpty,
      excludeSemantics: label.isEmpty,
      child: CustomPaint(
        size: Size.square(size),
        painter: _OverlordPainter(
          [
            (part('extra', look.extra), Offset.zero),
            (part('body', look.body), Offset.zero),
            (part('item', look.item), Offset.zero),
            (part('face', look.face, face), Offset.zero),
            (
              part('hat', look.hat),
              mood == BossMood.defeated ? const Offset(2, 2) : Offset.zero,
            ),
            (part('extra', look.extra, 1), Offset.zero),
          ],
          overlordColors(look.scheme),
          bob: bob,
        ),
      ),
    );
  }
}

class _OverlordPainter extends CustomPainter {
  _OverlordPainter(this.layers, this.colors, {required this.bob});

  final List<(Sprite, Offset)> layers;
  final List<Color> colors;
  final bool bob;

  @override
  void paint(Canvas canvas, Size size) {
    const width = 48;
    final cell = size.width >= width
        ? (size.width / width).floorToDouble()
        : size.width / width;
    final offset = ((size.width - cell * width) / 2).roundToDouble();
    canvas
      ..translate(offset, offset)
      ..scale(cell);
    if (bob) canvas.translate(0, 1);
    for (final (sprite, at) in layers) {
      sprite.paint(canvas, colors, at);
    }
  }

  @override
  bool shouldRepaint(_OverlordPainter old) =>
      old.bob != bob ||
      !listEquals(old.colors, colors) ||
      !listEquals(
        [for (final l in old.layers) l.$1],
        [for (final l in layers) l.$1],
      ) ||
      !listEquals(
        [for (final l in old.layers) l.$2],
        [for (final l in layers) l.$2],
      );
}
