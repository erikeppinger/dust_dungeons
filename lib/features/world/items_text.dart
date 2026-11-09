import 'package:flutter/material.dart';

import '../../app/art/art.dart';
import '../../app/theme/pixel.dart';
import '../../domain/fight/boss.dart';
import '../../domain/fight/items.dart';
import '../../domain/fight/shop.dart';
import '../../game/game_texts.dart';
import '../../l10n/app_localizations.dart';
import '../fight/boss_art.dart';

/// An item's name (game/items.toml; vouchers say their minutes).
String itemName(AppLocalizations l10n, ShopItem item) =>
    item.use == ItemUse.screenMinutes
    ? l10n.itemScreenTime(item.minutes)
    : gameItemName(l10n, item.key) ?? item.key;

/// What [item] does, in words: written from its effects, so it always says
/// what the item really does. Items without effects have a written line.
String itemDescription(AppLocalizations l10n, ShopItem item) {
  final written = switch (item) {
    ShopItem(use: ItemUse.screenMinutes) => l10n.itemScreenTimeDesc,
    ShopItem(kind: ItemKind.hat) => l10n.hatDesc,
    _ => gameItemDescription(l10n, item.key),
  };
  final lines = [
    if (written != null) written else ..._effectLines(l10n, item),
    ?gameItemFlavor(l10n, item.key),
  ];
  final text = lines.join(' · ');
  return text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);
}

List<String> _effectLines(AppLocalizations l10n, ShopItem item) {
  final general = effectPhrases(l10n, item.effects);
  // Bosses where the item does something else, grouped when it's the same.
  final against = <String, List<String>>{};
  for (final MapEntry(key: boss, value: effects) in item.against.entries) {
    final changed = effectPhrases(
      l10n,
      effects,
    ).where((p) => !general.contains(p)).join(', ');
    if (changed.isNotEmpty) {
      (against[changed] ??= []).add(bossName(l10n, boss));
    }
  }
  final all = [
    ...general,
    for (final MapEntry(key: effects, value: bosses) in against.entries)
      l10n.effectAgainst(bosses.join(', '), effects),
    if (item.twoHanded) l10n.effectTwoHanded,
  ];
  return item.beforeFight && all.isNotEmpty
      ? [l10n.effectForOneFight(all.join(', '))]
      : all;
}

/// [e] in short phrases ("+1 heart", …).
List<String> effectPhrases(AppLocalizations l10n, Effects e) => [
  if (e.hearts > 0) l10n.effectHearts(e.hearts),
  if (e.perfectTimes > Effects.none.perfectTimes)
    l10n.effectPerfectTimes(e.perfectTimes),
  if (e.damage > 0) l10n.effectDamage(e.damage),
  if (e.goodDamage > 0) l10n.effectGoodDamage(e.goodDamage),
  if (e.freeMisses > 0) l10n.effectFreeMisses(e.freeMisses),
  if (e.wideTiming) l10n.effectWideTiming,
  if (e.comboHeal > 0) l10n.effectComboHeal(e.comboHeal),
  if (e.sneakAttack) l10n.effectSneakAttack,
  if (e.slowerBoss) l10n.effectSlowerBoss,
  if (e.thirdMissFree) l10n.effectThirdMissFree,
  if (e.fullRevive) l10n.effectFullRevive,
  if (e.lootBonus > 0) l10n.effectLootBonus(e.lootBonus),
];

String slotName(AppLocalizations l10n, GearSlot slot) => switch (slot) {
  GearSlot.head => l10n.slotHead,
  GearSlot.body => l10n.slotBody,
  GearSlot.weapon => l10n.slotWeapon,
  GearSlot.shield => l10n.slotShield,
  GearSlot.feet => l10n.slotFeet,
  GearSlot.charm => l10n.slotCharm,
};

String curseName(AppLocalizations l10n, BossFamily family) =>
    gameCurseName(l10n, family);

/// What [curse] does in the next fight.
String curseEffect(AppLocalizations l10n, Curse curse) => switch (curse.kind) {
  CurseKind.heart => l10n.curseEffectHeart,
  CurseKind.tightTiming => l10n.curseEffectTight,
  CurseKind.slotOff => l10n.curseEffectSlot(slotName(l10n, curse.slot!)),
};

/// How to get rid of [curse] before the fight.
String curseLift(AppLocalizations l10n, Curse curse) =>
    curse.family == BossFamily.overlord
    ? l10n.curseLiftAny
    : l10n.curseLift(bossSource(l10n, curse.family));

/// An item's pixel icon; screen-time vouchers and hats, which have none,
/// get a plain icon. [unknown]: loot not found yet, shown as "?".
class ItemIcon extends StatelessWidget {
  const ItemIcon(this.item, {super.key, this.size = 32, this.unknown = false});

  final ShopItem item;
  final double size;
  final bool unknown;

  @override
  Widget build(BuildContext context) {
    final sprite = gameItemSprite(item.key);
    if (unknown) {
      return SizedBox.square(
        dimension: size,
        child: Center(
          child: Text(
            '?',
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontSize: size * 0.7),
          ),
        ),
      );
    }
    if (sprite == null) {
      return PixelIcon(
        item.use == ItemUse.screenMinutes
            ? Sprites.uiHourglass
            : Sprites.questCheckroom,
        size: size,
      );
    }
    final night = Theme.of(context).brightness == Brightness.dark;
    return PixelIcon(
      sprite,
      size: size,
      palette: (night ? itemsNight : itemsDay).colors,
    );
  }
}
