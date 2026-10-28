import 'package:flutter/material.dart';

/// Icons a chore can use, by stable key (stored in the database).
/// Keys must never change; new icons may be appended.
const choreIcons = <String, IconData>{
  // Built-in chores
  'auto_awesome': Icons.auto_awesome,
  'cleaning_services': Icons.cleaning_services,
  'air': Icons.air,
  'water_drop': Icons.water_drop,
  'soap': Icons.soap,
  'flatware': Icons.flatware,
  'local_laundry_service': Icons.local_laundry_service,
  'checkroom': Icons.checkroom,
  'layers': Icons.layers,
  'iron': Icons.iron,
  'bathtub': Icons.bathtub,
  'wc': Icons.wc,
  'countertops': Icons.countertops,
  'delete': Icons.delete,
  'recycling': Icons.recycling,
  'bed': Icons.bed,
  'window': Icons.window,
  'kitchen': Icons.kitchen,
  'shopping_cart': Icons.shopping_cart,
  'local_florist': Icons.local_florist,
  'inventory_2': Icons.inventory_2,
  // Extra choices for user chores
  'restaurant': Icons.restaurant,
  'dinner_dining': Icons.dinner_dining,
  'microwave': Icons.microwave,
  'coffee_maker': Icons.coffee_maker,
  'shower': Icons.shower,
  'sanitizer': Icons.sanitizer,
  'dry_cleaning': Icons.dry_cleaning,
  'pets': Icons.pets,
  'child_care': Icons.child_care,
  'yard': Icons.yard,
  'grass': Icons.grass,
  'compost': Icons.compost,
  'directions_car': Icons.directions_car,
  'local_car_wash': Icons.local_car_wash,
  'handyman': Icons.handyman,
  'lightbulb': Icons.lightbulb,
  'mail': Icons.mail,
  'menu_book': Icons.menu_book,
  'toys': Icons.toys,
  'chair': Icons.chair,
  'pest_control': Icons.pest_control,
  'ac_unit': Icons.ac_unit,
  'home': Icons.home,
  'star': Icons.star,
};

/// Preselected icon for a new chore.
const defaultIconKey = 'star';

/// Icon for [key]; unknown keys (e.g. from a newer app version) get a fallback.
IconData choreIcon(String key) => choreIcons[key] ?? Icons.task_alt;
