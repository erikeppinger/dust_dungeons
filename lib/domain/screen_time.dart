import 'dart:math';

/// Chore points per minute of screen time earned.
const pointsPerScreenMinute = 5;

/// Minutes left at which the warning comes.
const screenWarnMinutes = 10;

/// Minutes quests earned today: one per [pointsPerScreenMinute] points,
/// up to [cap]. Derived from the day's completions, so an undo takes its
/// minutes back.
int earnedScreenMinutes(int pointsToday, int cap) =>
    min(max(cap, 0), max(pointsToday, 0) ~/ pointsPerScreenMinute);

/// One day's screen-time budget and use.
class ScreenBudget {
  const ScreenBudget({
    required this.base,
    required this.earned,
    required this.vouchers,
    required this.used,
  });

  final int base, earned, vouchers, used;

  int get total => base + earned + vouchers;

  /// Minutes left (negative when over).
  int get left => total - used;

  bool get over => used > total;
  bool get low => !over && left <= screenWarnMinutes;

  @override
  bool operator ==(Object other) =>
      other is ScreenBudget &&
      other.base == base &&
      other.earned == earned &&
      other.vouchers == vouchers &&
      other.used == used;

  @override
  int get hashCode => Object.hash(base, earned, vouchers, used);
}

/// The hero is tired after a day over budget: one heart less, never below 1.
int tiredMaxHp(int maxHp, {required bool tired}) =>
    tired ? max(1, maxHp - 1) : maxHp;
