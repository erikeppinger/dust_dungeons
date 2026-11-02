import 'package:flutter/material.dart';

import '../../app/art/art.dart';
import '../../app/theme/pixel.dart';
import '../../domain/fight/boss.dart';
import '../../domain/fight/items.dart';
import '../../domain/fight/shop.dart';
import '../../l10n/app_localizations.dart';
import '../fight/boss_art.dart';

String itemName(AppLocalizations l10n, ShopItem item) => switch (item.key) {
  'sponge_shield' => l10n.itemShield,
  'turbo_mop' => l10n.itemMop,
  'metronome_charm' => l10n.itemCharm,
  'rubber_gloves' => l10n.itemGloves,
  'colander_of_clarity' => l10n.itemColander,
  'spatula_of_flipping' => l10n.itemSpatula,
  'hi_vis_vest' => l10n.itemVest,
  'rubber_boots' => l10n.itemBoots,
  'lucky_odd_sock' => l10n.itemSock,
  'feather_duster' => l10n.itemDuster,
  'laundry_basket_helm' => l10n.itemHelm,
  'apron_of_holding' => l10n.itemApron,
  'plunger_of_smiting' => l10n.itemPlunger,
  'trash_can_lid' => l10n.itemLid,
  'fuzzy_slippers' => l10n.itemSlippers,
  'garden_gnome' => l10n.itemGnome,
  'lost_remote' => l10n.itemRemote,
  'mop_of_doom' => l10n.itemMopOfDoom,
  'cape_of_clean_sweep' => l10n.itemCape,
  'second_wind' => l10n.itemSecondWind,
  'coffee_of_haste' => l10n.itemCoffee,
  'snack_break' => l10n.itemSnack,
  'soap_of_uncursing' => l10n.itemSoap,
  'screen_15' || 'screen_30' => l10n.itemScreenTime(voucherMinutes(item)),
  'hat_cap' => l10n.hatCap,
  'hat_bandana' => l10n.hatBandana,
  'hat_wizard' => l10n.hatWizard,
  'hat_crown' => l10n.hatCrown,
  _ => item.key,
};

/// What [item] does, in words.
String itemDescription(AppLocalizations l10n, ShopItem item) {
  String boss(BossFamily f) => bossName(l10n, f);
  return switch (item.key) {
    'sponge_shield' => l10n.itemShieldDesc,
    'turbo_mop' => l10n.itemMopDesc,
    'metronome_charm' => l10n.itemCharmDesc,
    'rubber_gloves' => l10n.itemGlovesDesc,
    'colander_of_clarity' => l10n.itemColanderDesc,
    'spatula_of_flipping' => l10n.itemSpatulaDesc,
    'hi_vis_vest' => l10n.itemVestDesc,
    'rubber_boots' => l10n.itemBootsDesc(
      boss(BossFamily.bath),
      boss(BossFamily.outside),
    ),
    'lucky_odd_sock' => l10n.itemSockDesc,
    'feather_duster' => l10n.itemDusterDesc(boss(BossFamily.dust)),
    'laundry_basket_helm' => l10n.itemHelmDesc(boss(BossFamily.laundry)),
    'apron_of_holding' => l10n.itemApronDesc,
    'plunger_of_smiting' => l10n.itemPlungerDesc(boss(BossFamily.bath)),
    'trash_can_lid' => l10n.itemLidDesc,
    'fuzzy_slippers' => l10n.itemSlippersDesc,
    'garden_gnome' => l10n.itemGnomeDesc,
    'lost_remote' => l10n.itemRemoteDesc,
    'mop_of_doom' => l10n.itemMopOfDoomDesc,
    'cape_of_clean_sweep' => l10n.itemCapeDesc,
    'second_wind' => l10n.itemSecondWindDesc,
    'coffee_of_haste' => l10n.itemCoffeeDesc,
    'snack_break' => l10n.itemSnackDesc,
    'soap_of_uncursing' => l10n.itemSoapDesc,
    'screen_15' || 'screen_30' => l10n.itemScreenTimeDesc,
    _ => l10n.hatDesc,
  };
}

String slotName(AppLocalizations l10n, GearSlot slot) => switch (slot) {
  GearSlot.head => l10n.slotHead,
  GearSlot.body => l10n.slotBody,
  GearSlot.weapon => l10n.slotWeapon,
  GearSlot.shield => l10n.slotShield,
  GearSlot.feet => l10n.slotFeet,
  GearSlot.charm => l10n.slotCharm,
};

String curseName(AppLocalizations l10n, BossFamily family) => switch (family) {
  BossFamily.dust => l10n.curseDust,
  BossFamily.laundry => l10n.curseLaundry,
  BossFamily.kitchen => l10n.curseKitchen,
  BossFamily.bath => l10n.curseBath,
  BossFamily.trash => l10n.curseTrash,
  BossFamily.bedroom => l10n.curseBedroom,
  BossFamily.outside => l10n.curseOutside,
  BossFamily.clutter => l10n.curseClutter,
  BossFamily.overlord => l10n.curseOverlord,
};

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

Sprite? _sprite(String key) => switch (key) {
  'sponge_shield' => Sprites.spongeShield,
  'turbo_mop' => Sprites.turboMop,
  'metronome_charm' => Sprites.metronomeCharm,
  'rubber_gloves' => Sprites.rubberGloves,
  'colander_of_clarity' => Sprites.colanderOfClarity,
  'spatula_of_flipping' => Sprites.spatulaOfFlipping,
  'hi_vis_vest' => Sprites.hiVisVest,
  'rubber_boots' => Sprites.rubberBoots,
  'lucky_odd_sock' => Sprites.luckyOddSock,
  'feather_duster' => Sprites.featherDuster,
  'laundry_basket_helm' => Sprites.laundryBasketHelm,
  'apron_of_holding' => Sprites.apronOfHolding,
  'plunger_of_smiting' => Sprites.plungerOfSmiting,
  'trash_can_lid' => Sprites.trashCanLid,
  'fuzzy_slippers' => Sprites.fuzzySlippers,
  'garden_gnome' => Sprites.gardenGnome,
  'lost_remote' => Sprites.lostRemote,
  'mop_of_doom' => Sprites.mopOfDoom,
  'cape_of_clean_sweep' => Sprites.capeOfCleanSweep,
  'second_wind' => Sprites.secondWind,
  'coffee_of_haste' => Sprites.coffeeOfHaste,
  'snack_break' => Sprites.snackBreak,
  'soap_of_uncursing' => Sprites.soapOfUncursing,
  _ => null,
};

/// An item's pixel icon; screen-time vouchers and hats, which have none,
/// get a plain icon. [unknown]: loot not found yet, shown as "?".
class ItemIcon extends StatelessWidget {
  const ItemIcon(this.item, {super.key, this.size = 32, this.unknown = false});

  final ShopItem item;
  final double size;
  final bool unknown;

  @override
  Widget build(BuildContext context) {
    final sprite = _sprite(item.key);
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
      return Icon(
        voucherMinutes(item) > 0 ? Icons.hourglass_bottom : Icons.checkroom,
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
