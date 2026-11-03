import 'package:flutter/material.dart';

import '../../app/art/art.dart';
import '../../app/theme/pixel.dart';

/// Icons a chore can use, by stable key (stored in the database): 12×12
/// pixel icons in `assets/art/quests/`, tinted like the tab icons.
/// Keys must never change; new icons may be appended.
const choreIcons = <String, Sprite>{
  // Built-in chores
  'auto_awesome': Sprites.questAutoAwesome,
  'cleaning_services': Sprites.questCleaningServices,
  'air': Sprites.questAir,
  'water_drop': Sprites.questWaterDrop,
  'soap': Sprites.questSoap,
  'flatware': Sprites.questFlatware,
  'local_laundry_service': Sprites.questLocalLaundryService,
  'checkroom': Sprites.questCheckroom,
  'layers': Sprites.questLayers,
  'iron': Sprites.questIron,
  'bathtub': Sprites.questBathtub,
  'wc': Sprites.questWc,
  'countertops': Sprites.questCountertops,
  'delete': Sprites.questDelete,
  'recycling': Sprites.questRecycling,
  'bed': Sprites.questBed,
  'window': Sprites.questWindow,
  'kitchen': Sprites.questKitchen,
  'shopping_cart': Sprites.questShoppingCart,
  'local_florist': Sprites.questLocalFlorist,
  'inventory_2': Sprites.questInventory2,
  // Extra choices for user chores
  'restaurant': Sprites.questRestaurant,
  'dinner_dining': Sprites.questDinnerDining,
  'microwave': Sprites.questMicrowave,
  'coffee_maker': Sprites.questCoffeeMaker,
  'shower': Sprites.questShower,
  'sanitizer': Sprites.questSanitizer,
  'dry_cleaning': Sprites.questDryCleaning,
  'pets': Sprites.questPets,
  'child_care': Sprites.questChildCare,
  'yard': Sprites.questYard,
  'grass': Sprites.questGrass,
  'compost': Sprites.questCompost,
  'directions_car': Sprites.questDirectionsCar,
  'local_car_wash': Sprites.questLocalCarWash,
  'handyman': Sprites.questHandyman,
  'lightbulb': Sprites.questLightbulb,
  'mail': Sprites.questMail,
  'menu_book': Sprites.questMenuBook,
  'toys': Sprites.questToys,
  'chair': Sprites.questChair,
  'pest_control': Sprites.questPestControl,
  'ac_unit': Sprites.questAcUnit,
  'home': Sprites.questHome,
  'star': Sprites.questStar,
};

/// Preselected icon for a new chore.
const defaultIconKey = 'star';

/// Icon for [key]; unknown keys (e.g. from a newer app version) get a fallback.
Sprite choreIcon(String key) => choreIcons[key] ?? Sprites.questTaskAlt;

/// A quest's icon in one [color], by whole pixels.
class ChoreIcon extends StatelessWidget {
  const ChoreIcon(this.iconKey, {super.key, this.size = 24, this.color});

  final String iconKey;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) =>
      PixelIcon(choreIcon(iconKey), size: size, color: color);
}
