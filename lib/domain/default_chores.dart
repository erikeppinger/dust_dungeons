import '../game/game_data.dart' show defaultChores;

export '../game/game_data.dart' show defaultChores;

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
  ]) : suggested = false;

  /// A suggestion: added archived, to be brought in by onboarding or a
  /// sleeping boss (docs/design/more-bosses.md).
  const SeedChore.suggestion(
    this.key,
    this.iconKey,
    this.colorKey,
    this.basePoints,
    this.repeat, [
    this.interval = 1,
  ]) : suggested = true;

  final String key;
  final String iconKey;
  final int colorKey;
  final int basePoints;

  /// Default rhythm: [RepeatType.daily], [RepeatType.afterDone] or
  /// [RepeatType.anytime] (no weekdays/day-of-month needed).
  final RepeatType repeat;
  final int interval;
  final bool suggested;

  /// Default schedule starting around [today]. Start days are staggered by
  /// [index] so a new install does not make every chore due on day one.
  Recurrence defaultRecurrence(DateTime today, int index) => Recurrence(
    type: repeat,
    interval: interval,
    start: addDays(dayOf(today), interval > 1 ? index % interval : 0),
  );
}

/// Keys of the built-in quests that start as suggestions.
final suggestedSeeds = {
  for (final seed in defaultChores)
    if (seed.suggested) seed.key,
};
