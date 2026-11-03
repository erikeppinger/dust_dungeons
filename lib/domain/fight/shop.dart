import '../../game/game_data.dart';
import 'boss.dart';
import 'effects.dart';

export '../../game/game_data.dart'
    show
        armoryGear,
        lootItems,
        allGear,
        fightConsumables,
        preFightConsumables,
        screenVouchers,
        hats,
        shopItems,
        reviveItem,
        curseLiftItem;

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

/// What a consumable does besides fight effects; handled in code.
enum ItemUse {
  none,

  /// Continue a lost fight (Second Wind).
  revive,

  /// Lift the waiting curse.
  liftCurse,

  /// Extra screen minutes for one day.
  screenMinutes,
}

/// Something you can own, from game/items.toml. [key] is stored: never
/// rename.
class ShopItem {
  const ShopItem(
    this.key,
    this.kind,
    this.price, {
    this.slot,
    this.twoHanded = false,
    this.dropsFrom,
    this.effects = Effects.none,
    this.against = const {},
    this.use = ItemUse.none,
    this.minutes = 0,
    this.beforeFight = false,
    this.look = 0,
    this.retired = false,
  });

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

  /// What it does in fights.
  final Effects effects;

  /// What it does instead in fights against these bosses.
  final Map<BossFamily, Effects> against;
  final ItemUse use;

  /// For screen-time vouchers.
  final int minutes;

  /// A consumable picked on a fight's start screen.
  final bool beforeFight;

  /// For hats: the number stored for the hero (1, 2, …).
  final int look;

  /// No longer sold or dropped; owners keep it.
  final bool retired;

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

ShopItem? shopItem(String key) {
  for (final item in shopItems) {
    if (item.key == key) return item;
  }
  return null;
}
