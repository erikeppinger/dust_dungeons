import 'dates.dart';

/// Consecutive days with at least one completion, ending the day before
/// [today]. This is the streak that earns a bonus today.
int streakBefore(Set<DateTime> completionDays, DateTime today) {
  var streak = 0;
  var day = addDays(dayOf(today), -1);
  while (completionDays.contains(day)) {
    streak++;
    day = addDays(day, -1);
  }
  return streak;
}

/// The streak shown to the user: still alive today even before today's
/// first completion, so it only breaks after a whole day without chores.
int currentStreak(Set<DateTime> completionDays, DateTime today) =>
    streakBefore(completionDays, today) +
    (completionDays.contains(dayOf(today)) ? 1 : 0);

/// Longest run of consecutive completion days ever.
int bestStreak(Set<DateTime> completionDays) {
  final days = completionDays.toList()..sort();
  var best = 0, run = 0;
  DateTime? previous;
  for (final day in days) {
    run = previous != null && daysBetween(previous, day) == 1 ? run + 1 : 1;
    if (run > best) best = run;
    previous = day;
  }
  return best;
}

/// Total XP needed to reach [level] (level 1 starts at 0 XP).
/// Each level needs 100 XP more than the previous one: 0, 100, 300, 600 …
int xpForLevel(int level) => 50 * level * (level - 1);

/// Level for a total of [xp] (at least 1).
int levelForXp(int xp) {
  var level = 1;
  while (xpForLevel(level + 1) <= xp) {
    level++;
  }
  return level;
}
