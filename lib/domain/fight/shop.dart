import 'boss.dart';

/// What a shop item is for.
enum ItemKind {
  /// Owned once, worn in its [GearSlot] (see docs/design/items.md).
  gear,

  /// Bought in any number, used up one at a time.
  consumable,

  /// Cosmetic, chosen in the hero editor.
  hat,
}

/// Where a piece of gear is worn: one item per slot. Stored by name: never
/// rename values.
enum GearSlot { head, body, weapon, shield, feet, charm }

/// Something you can own. [key] is stored: never rename.
class ShopItem {
  const ShopItem(
    this.key,
    this.kind,
    this.price, {
    this.slot,
    this.twoHanded = false,
    this.dropsFrom,
  });

  /// Gear that bosses drop and the Armory doesn't sell.
  const ShopItem.loot(
    this.key,
    this.slot,
    this.dropsFrom, {
    this.twoHanded = false,
  }) : kind = ItemKind.gear,
       price = 0;

  final String key;
  final ItemKind kind;

  /// In points; 0 for loot.
  final int price;

  /// For gear: where it's worn.
  final GearSlot? slot;

  /// A two-handed weapon also fills the shield slot.
  final bool twoHanded;

  /// For loot: the boss that drops it.
  final BossFamily? dropsFrom;

  bool get isLoot => dropsFrom != null;

  /// Whether [other] can't be worn together with this (same slot, or a
  /// two-handed weapon and a shield).
  bool clashesWith(ShopItem other) =>
      slot == other.slot ||
      (twoHanded && other.slot == GearSlot.shield) ||
      (other.twoHanded && slot == GearSlot.shield);

  @override
  String toString() => key;
}

// Armory gear.
const shieldItem = ShopItem(
  'sponge_shield',
  ItemKind.gear,
  150,
  slot: GearSlot.shield,
);
const mopItem = ShopItem(
  'turbo_mop',
  ItemKind.gear,
  300,
  slot: GearSlot.weapon,
);
const charmItem = ShopItem(
  'metronome_charm',
  ItemKind.gear,
  100,
  slot: GearSlot.charm,
);
const glovesItem = ShopItem(
  'rubber_gloves',
  ItemKind.gear,
  200,
  slot: GearSlot.body,
);
const colanderItem = ShopItem(
  'colander_of_clarity',
  ItemKind.gear,
  150,
  slot: GearSlot.head,
);
const spatulaItem = ShopItem(
  'spatula_of_flipping',
  ItemKind.gear,
  200,
  slot: GearSlot.weapon,
);
const vestItem = ShopItem(
  'hi_vis_vest',
  ItemKind.gear,
  350,
  slot: GearSlot.body,
);
const bootsItem = ShopItem(
  'rubber_boots',
  ItemKind.gear,
  120,
  slot: GearSlot.feet,
);
const sockItem = ShopItem(
  'lucky_odd_sock',
  ItemKind.gear,
  150,
  slot: GearSlot.charm,
);

const armoryGear = [
  colanderItem,
  glovesItem,
  vestItem,
  mopItem,
  spatulaItem,
  shieldItem,
  bootsItem,
  charmItem,
  sockItem,
];

// Loot.
const dusterItem = ShopItem.loot(
  'feather_duster',
  GearSlot.weapon,
  BossFamily.dust,
);
const helmItem = ShopItem.loot(
  'laundry_basket_helm',
  GearSlot.head,
  BossFamily.laundry,
);
const apronItem = ShopItem.loot(
  'apron_of_holding',
  GearSlot.body,
  BossFamily.kitchen,
);
const plungerItem = ShopItem.loot(
  'plunger_of_smiting',
  GearSlot.weapon,
  BossFamily.bath,
);
const lidItem = ShopItem.loot(
  'trash_can_lid',
  GearSlot.shield,
  BossFamily.trash,
);
const slippersItem = ShopItem.loot(
  'fuzzy_slippers',
  GearSlot.feet,
  BossFamily.bedroom,
);
const gnomeItem = ShopItem.loot(
  'garden_gnome',
  GearSlot.charm,
  BossFamily.outside,
);
const remoteItem = ShopItem.loot(
  'lost_remote',
  GearSlot.charm,
  BossFamily.clutter,
);
const mopOfDoomItem = ShopItem.loot(
  'mop_of_doom',
  GearSlot.weapon,
  BossFamily.overlord,
  twoHanded: true,
);
const capeItem = ShopItem.loot(
  'cape_of_clean_sweep',
  GearSlot.body,
  BossFamily.overlord,
);

/// Every boss's loot, in boss order.
const lootItems = [
  dusterItem,
  helmItem,
  apronItem,
  plungerItem,
  lidItem,
  slippersItem,
  gnomeItem,
  remoteItem,
  mopOfDoomItem,
  capeItem,
];

/// All gear: the Armory's, then the loot.
const allGear = [...armoryGear, ...lootItems];

// Consumables.
const secondWindItem = ShopItem('second_wind', ItemKind.consumable, 60);
const coffeeItem = ShopItem('coffee_of_haste', ItemKind.consumable, 50);
const snackItem = ShopItem('snack_break', ItemKind.consumable, 40);
const soapItem = ShopItem('soap_of_uncursing', ItemKind.consumable, 30);

const fightConsumables = [secondWindItem, coffeeItem, snackItem, soapItem];

/// Consumables picked before a fight, at most one of each.
const preFightConsumables = [coffeeItem, snackItem];

/// Hats in the order of the hero editor (index 1.. in `avatarHat`; 0 = none).
const hats = [
  ShopItem('hat_cap', ItemKind.hat, 80),
  ShopItem('hat_bandana', ItemKind.hat, 80),
  ShopItem('hat_wizard', ItemKind.hat, 200),
  ShopItem('hat_crown', ItemKind.hat, 250),
];

/// Screen-time vouchers: extra minutes for one day (soft budget).
const screenVouchers = [
  ShopItem('screen_15', ItemKind.consumable, 40),
  ShopItem('screen_30', ItemKind.consumable, 75),
];

/// Minutes a screen-time voucher adds.
int voucherMinutes(ShopItem item) => switch (item.key) {
  'screen_15' => 15,
  'screen_30' => 30,
  _ => 0,
};

/// Everything that can be owned.
const shopItems = [...allGear, ...fightConsumables, ...screenVouchers, ...hats];

ShopItem? shopItem(String key) {
  for (final item in shopItems) {
    if (item.key == key) return item;
  }
  return null;
}
