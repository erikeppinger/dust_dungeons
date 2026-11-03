import 'package:flutter/material.dart';

import '../../app/art/art.dart';

import '../../domain/fight/boss.dart';
import '../../game/game_texts.dart';
import '../../l10n/app_localizations.dart';

/// How a boss looks right now: the frames of its strip in
/// `assets/art/bosses/<family>.png` are idle, bob, hit and defeated.
enum BossMood { idle, hit, defeated }

String bossName(AppLocalizations l10n, BossFamily family) =>
    gameBossName(l10n, family);

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
};

/// A boss: its pixel sprite, scaled by whole pixels from 48 up (smaller
/// sizes scale down evenly). [bob] shows the idle pose one pixel lower, so
/// the boss can bounce to its beats.
class BossArt extends StatelessWidget {
  const BossArt({
    super.key,
    required this.family,
    this.size = 64,
    this.mood = BossMood.idle,
    this.bob = false,
    this.semanticLabel,
  });

  final BossFamily family;
  final double size;
  final BossMood mood;
  final bool bob;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final frames = Sprites.all['bosses/${family.name}']!.$1;
    final frame = switch (mood) {
      BossMood.idle => bob ? 1 : 0,
      BossMood.hit => 2,
      BossMood.defeated => 3,
    };
    return Semantics(
      label: semanticLabel ?? bossName(AppLocalizations.of(context), family),
      image: true,
      child: CustomPaint(
        size: Size.square(size),
        painter: _BossPainter(frames[frame]),
      ),
    );
  }
}

class _BossPainter extends CustomPainter {
  _BossPainter(this.sprite);

  final Sprite sprite;

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width >= sprite.width
        ? (size.width / sprite.width).floorToDouble()
        : size.width / sprite.width;
    final offset = ((size.width - cell * sprite.width) / 2).roundToDouble();
    canvas
      ..translate(offset, offset)
      ..scale(cell);
    sprite.paint(canvas, bosses.colors);
  }

  @override
  bool shouldRepaint(_BossPainter old) => !identical(old.sprite, sprite);
}
