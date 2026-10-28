/// What a shop item is for.
enum ItemKind {
  /// Owned once, always active in fights.
  gear,

  /// Bought in any number, used up one at a time.
  consumable,

  /// Cosmetic, chosen in the hero editor.
  hat,
}

/// Something you can buy with points. [key] is stored: never rename.
class ShopItem {
  const ShopItem(this.key, this.kind, this.price);

  final String key;
  final ItemKind kind;
  final int price;
}

const shieldItem = ShopItem('sponge_shield', ItemKind.gear, 150);
const mopItem = ShopItem('turbo_mop', ItemKind.gear, 300);
const charmItem = ShopItem('metronome_charm', ItemKind.gear, 100);
const glovesItem = ShopItem('rubber_gloves', ItemKind.gear, 200);
const secondWindItem = ShopItem('second_wind', ItemKind.consumable, 60);

/// Hats in the order of the hero editor (index 1.. in `avatarHat`; 0 = none).
const hats = [
  ShopItem('hat_cap', ItemKind.hat, 80),
  ShopItem('hat_bandana', ItemKind.hat, 80),
  ShopItem('hat_wizard', ItemKind.hat, 200),
  ShopItem('hat_crown', ItemKind.hat, 250),
];

const shopItems = [
  shieldItem,
  mopItem,
  charmItem,
  glovesItem,
  secondWindItem,
  ...hats,
];

ShopItem? shopItem(String key) {
  for (final item in shopItems) {
    if (item.key == key) return item;
  }
  return null;
}

/// The gear a hero brings to a fight.
class Loadout {
  const Loadout({
    this.shield = false,
    this.turboMop = false,
    this.metronome = false,
    this.gloves = false,
  });

  /// From the owned item counts (item key → count).
  factory Loadout.fromInventory(Map<String, int> owned) {
    bool has(ShopItem item) => (owned[item.key] ?? 0) > 0;
    return Loadout(
      shield: has(shieldItem),
      turboMop: has(mopItem),
      metronome: has(charmItem),
      gloves: has(glovesItem),
    );
  }

  /// The first miss of each fight costs no heart.
  final bool shield;

  /// Perfect hits deal 3× instead of 2× damage.
  final bool turboMop;

  /// Wider timing windows.
  final bool metronome;

  /// One extra heart.
  final bool gloves;

  static const none = Loadout();
}
