import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../app/art/art.dart';

import '../../domain/fight/boss.dart';
import '../../domain/fight/overlord.dart';
import '../../game/game_texts.dart';
import '../../l10n/app_localizations.dart';
import 'overlord_art.dart';

/// How a boss looks right now: the frames of its strip in
/// `assets/art/bosses/<family>.png` are idle, bob, hit and defeated.
enum BossMood { idle, hit, defeated }

/// A boss's name: in its form at [tier], or with [look] the Overlord's name
/// that week.
String bossName(
  AppLocalizations l10n,
  BossFamily family, [
  OverlordLook? look,
  int tier = 1,
]) => family == BossFamily.overlord
    ? (look == null ? gameBossName(l10n, family) : overlordName(l10n, look))
    : (tier >= 2 ? gameBossFormName(l10n, family, min(tier, 3)) : null) ??
          gameBossName(l10n, family);

/// Main and light color of [family] in its form at [tier] (its own colors at
/// tier 1), for cards and backgrounds.
(Color, Color) bossFormColorPair(BossFamily family, int tier) {
  final form = bossForm(family, tier);
  return form == null
      ? bossColors(family)
      : (Color(form.main), Color(form.light));
}

/// The bosses palette with [family]'s four colors (main, its shade, light,
/// its shade) swapped for its form at [tier].
List<Color> bossFormColors(BossFamily family, int tier) {
  final form = bossForm(family, tier);
  if (form == null) return bosses.colors;
  final (main, _) = bossColors(family);
  final at = bosses.colors.indexOf(main);
  if (at < 0) return bosses.colors;
  final m = Color(form.main), l = Color(form.light);
  Color shade(Color c, double t) => Color.lerp(c, const Color(0xFF000000), t)!;
  return [
    for (final (i, c) in bosses.colors.indexed)
      switch (i - at) {
        0 => m,
        1 => shade(m, 0.28),
        2 => l,
        3 => shade(l, 0.18),
        _ => c,
      },
  ];
}

/// Which chores feed a family's tokens, in a few words.
String bossSource(AppLocalizations l10n, BossFamily family) =>
    family == BossFamily.overlord
    ? l10n.bossSourceOverlord(overlordWinsNeeded)
    : gameBossFedBy(l10n, family) ?? '';

String trophyName(AppLocalizations l10n, BossFamily family) =>
    gameBossTrophy(l10n, family) ?? l10n.trophyGeneric(bossName(l10n, family));

/// Main and light color of each boss. Families also differ in silhouette,
/// so color is never the only way to tell them apart.
(Color, Color) bossColors(BossFamily family) => switch (family) {
  BossFamily.dust => (const Color(0xFFB9A3C4), const Color(0xFFD7C4DE)),
  BossFamily.laundry => (const Color(0xFF00838F), const Color(0xFF4DB6C3)),
  BossFamily.kitchen => (const Color(0xFFF4A259), const Color(0xFFE08A3C)),
  BossFamily.bath => (const Color(0xFF90A4AE), const Color(0xFFCFD8DC)),
  BossFamily.trash => (const Color(0xFF6D7F3F), const Color(0xFF9CAF6A)),
  BossFamily.bedroom => (const Color(0xFF9FA8DA), const Color(0xFFC5CAE9)),
  BossFamily.outside => (const Color(0xFF81D4FA), const Color(0xFFB3E5FC)),
  BossFamily.clutter => (const Color(0xFF78909C), const Color(0xFFB0BEC5)),
  BossFamily.overlord => (const Color(0xFF5E35B1), const Color(0xFFB39DDB)),
  BossFamily.homework => (const Color(0xFFF2EBD3), const Color(0xFF3F4E8C)),
  BossFamily.pets => (const Color(0xFFA0704A), const Color(0xFFE2C29A)),
  BossFamily.garden => (const Color(0xFF4E9A3A), const Color(0xFFA8D878)),
  BossFamily.cooking => (const Color(0xFFC0392B), const Color(0xFFF5B7A0)),
};

/// A boss: its pixel sprite, scaled by whole pixels from 48 up (smaller
/// sizes scale down evenly). [bob] shows the idle pose one pixel lower, so
/// the boss can bounce to its beats. From [tier] 2 a chore boss wears its
/// form: other colors and the overlay in `assets/art/bosses/forms`. The
/// Overlord is drawn as [look] (see [OverlordArt]), the classic one without
/// it.
class BossArt extends StatelessWidget {
  const BossArt({
    super.key,
    required this.family,
    this.look,
    this.tier = 1,
    this.size = 64,
    this.mood = BossMood.idle,
    this.bob = false,
    this.semanticLabel,
  });

  final BossFamily family;
  final OverlordLook? look;
  final int tier;
  final double size;
  final BossMood mood;
  final bool bob;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    if (family == BossFamily.overlord) {
      return OverlordArt(
        look: look ?? OverlordLook.classic,
        size: size,
        mood: mood,
        bob: bob,
        semanticLabel: semanticLabel,
      );
    }
    final frames = Sprites.all['bosses/${family.name}']!.$1;
    final frame = switch (mood) {
      BossMood.idle => bob ? 1 : 0,
      BossMood.hit => 2,
      BossMood.defeated => 3,
    };
    final form = tier >= 2
        ? Sprites.all['bosses/forms/${family.name}_${min(tier, 3)}']?.$1[frame]
        : null;
    final picture = CustomPaint(
      size: Size.square(size),
      painter: _BossPainter(frames[frame], form, bossFormColors(family, tier)),
    );
    // An empty label: decoration next to text that already names the boss.
    if (semanticLabel == '') return ExcludeSemantics(child: picture);
    return Semantics(
      label:
          semanticLabel ??
          bossName(AppLocalizations.of(context), family, null, tier),
      image: true,
      child: picture,
    );
  }
}

class _BossPainter extends CustomPainter {
  _BossPainter(this.sprite, this.form, this.colors);

  final Sprite sprite;

  /// The form's overlay, if any.
  final Sprite? form;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width >= sprite.width
        ? (size.width / sprite.width).floorToDouble()
        : size.width / sprite.width;
    final offset = ((size.width - cell * sprite.width) / 2).roundToDouble();
    canvas
      ..translate(offset, offset)
      ..scale(cell);
    sprite.paint(canvas, colors);
    form?.paint(canvas, colors);
  }

  @override
  bool shouldRepaint(_BossPainter old) =>
      !identical(old.sprite, sprite) ||
      !identical(old.form, form) ||
      !listEquals(old.colors, colors);
}
