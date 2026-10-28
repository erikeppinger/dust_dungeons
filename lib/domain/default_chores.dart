import 'dates.dart';
import 'recurrence.dart';

/// A built-in chore that is seeded into the database.
///
/// [key] is stable forever: it links the database row to its localized title.
/// Never rename or reuse a key; add new ones instead.
class SeedChore {
  const SeedChore(
    this.key,
    this.iconKey,
    this.colorKey,
    this.basePoints,
    this.repeat, [
    this.interval = 1,
  ]);

  final String key;
  final String iconKey;
  final int colorKey;
  final int basePoints;

  /// Default rhythm: [RepeatType.daily], [RepeatType.afterDone] or
  /// [RepeatType.anytime] (no weekdays/day-of-month needed).
  final RepeatType repeat;
  final int interval;

  /// Default schedule starting around [today]. Start days are staggered by
  /// [index] so a new install does not make every chore due on day one.
  Recurrence defaultRecurrence(DateTime today, int index) => Recurrence(
    type: repeat,
    interval: interval,
    start: addDays(dayOf(today), interval > 1 ? index % interval : 0),
  );
}

const defaultChores = <SeedChore>[
  SeedChore('dusting', 'auto_awesome', 6, 15, RepeatType.afterDone, 7),
  SeedChore('sweeping', 'cleaning_services', 5, 15, RepeatType.afterDone, 3),
  SeedChore('vacuuming', 'air', 5, 20, RepeatType.afterDone, 7),
  SeedChore('mopping', 'water_drop', 5, 25, RepeatType.afterDone, 7),
  SeedChore('dishes', 'soap', 1, 10, RepeatType.daily),
  SeedChore('dishwasher', 'flatware', 1, 5, RepeatType.daily),
  SeedChore('laundry', 'local_laundry_service', 4, 10, RepeatType.afterDone, 4),
  SeedChore('hang_laundry', 'checkroom', 4, 10, RepeatType.anytime),
  SeedChore('fold_laundry', 'layers', 4, 10, RepeatType.anytime),
  SeedChore('ironing', 'iron', 4, 20, RepeatType.afterDone, 7),
  SeedChore('clean_bathroom', 'bathtub', 7, 30, RepeatType.afterDone, 7),
  SeedChore('clean_toilet', 'wc', 7, 20, RepeatType.afterDone, 7),
  SeedChore('clean_kitchen', 'countertops', 1, 25, RepeatType.afterDone, 7),
  SeedChore('take_out_trash', 'delete', 3, 5, RepeatType.afterDone, 3),
  SeedChore('recycling', 'recycling', 3, 5, RepeatType.afterDone, 7),
  SeedChore('change_bed_sheets', 'bed', 7, 20, RepeatType.afterDone, 14),
  SeedChore('clean_windows', 'window', 6, 40, RepeatType.afterDone, 30),
  SeedChore('clean_fridge', 'kitchen', 1, 30, RepeatType.afterDone, 30),
  SeedChore('groceries', 'shopping_cart', 2, 15, RepeatType.afterDone, 7),
  SeedChore('water_plants', 'local_florist', 3, 5, RepeatType.afterDone, 3),
  SeedChore('tidy_up', 'inventory_2', 0, 10, RepeatType.daily),
];
