/// A built-in chore that is seeded into the database.
///
/// [key] is stable forever: it links the database row to its localized title.
/// Never rename or reuse a key; add new ones instead.
class SeedChore {
  const SeedChore(this.key, this.iconKey, this.colorKey, this.basePoints);

  final String key;
  final String iconKey;
  final int colorKey;
  final int basePoints;
}

const defaultChores = <SeedChore>[
  SeedChore('dusting', 'auto_awesome', 6, 15),
  SeedChore('sweeping', 'cleaning_services', 5, 15),
  SeedChore('vacuuming', 'air', 5, 20),
  SeedChore('mopping', 'water_drop', 5, 25),
  SeedChore('dishes', 'soap', 1, 10),
  SeedChore('dishwasher', 'flatware', 1, 5),
  SeedChore('laundry', 'local_laundry_service', 4, 10),
  SeedChore('hang_laundry', 'checkroom', 4, 10),
  SeedChore('fold_laundry', 'layers', 4, 10),
  SeedChore('ironing', 'iron', 4, 20),
  SeedChore('clean_bathroom', 'bathtub', 7, 30),
  SeedChore('clean_toilet', 'wc', 7, 20),
  SeedChore('clean_kitchen', 'countertops', 1, 25),
  SeedChore('take_out_trash', 'delete', 3, 5),
  SeedChore('recycling', 'recycling', 3, 5),
  SeedChore('change_bed_sheets', 'bed', 7, 20),
  SeedChore('clean_windows', 'window', 6, 40),
  SeedChore('clean_fridge', 'kitchen', 1, 30),
  SeedChore('groceries', 'shopping_cart', 2, 15),
  SeedChore('water_plants', 'local_florist', 3, 5),
  SeedChore('tidy_up', 'inventory_2', 0, 10),
];
