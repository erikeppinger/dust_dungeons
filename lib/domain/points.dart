/// Smallest and largest base points a chore can have.
const minBasePoints = 5;
const maxBasePoints = 100;

/// Bonus for doing a scheduled chore on its due day (not when overdue).
const onTimeBonusPercent = 10;

/// Bonus per day of the current streak, capped at [maxStreakBonusDays].
const streakBonusPercentPerDay = 2;
const maxStreakBonusDays = 10;

/// A chore's base points, clamped to the allowed range.
int basePointsOf(int basePoints) =>
    basePoints.clamp(minBasePoints, maxBasePoints);

/// Points for one completion, split into base and bonuses.
class PointsBreakdown {
  const PointsBreakdown({
    required this.base,
    required this.onTimeBonus,
    required this.streakBonus,
  });

  final int base;
  final int onTimeBonus;
  final int streakBonus;

  int get bonus => onTimeBonus + streakBonus;
  int get total => base + bonus;
}

/// Points for completing a chore with [basePoints].
///
/// [onTime]: the chore was due today (not overdue, not unscheduled).
/// [streakDays]: consecutive days with completions before today.
/// Bonuses are percentages of the base, rounded, at least 1 when earned.
PointsBreakdown pointsFor({
  required int basePoints,
  bool onTime = false,
  int streakDays = 0,
}) {
  final base = basePointsOf(basePoints);
  int percent(int p) => p <= 0 ? 0 : ((base * p) / 100).round().clamp(1, base);
  final streak = streakDays.clamp(0, maxStreakBonusDays);
  return PointsBreakdown(
    base: base,
    onTimeBonus: onTime ? percent(onTimeBonusPercent) : 0,
    streakBonus: percent(streak * streakBonusPercentPerDay),
  );
}
