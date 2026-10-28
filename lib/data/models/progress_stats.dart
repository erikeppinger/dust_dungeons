import '../../domain/dates.dart';
import '../../domain/progress.dart' as progress;
import '../db/app_database.dart';

/// Everything the Stats screen and the Today header show, derived from the
/// completion history (undone completions excluded).
class ProgressStats {
  factory ProgressStats(
    List<Completion> completions, {
    required DateTime today,
  }) {
    final t = dayOf(today);
    final days = {for (final c in completions) dayOf(c.completedAt)};
    var xp = 0, todayPts = 0, weekPts = 0, monthPts = 0;
    final perDay = {for (var i = 6; i >= 0; i--) addDays(t, -i): 0};
    final counts30 = <int, int>{};
    for (final c in completions) {
      final day = dayOf(c.completedAt);
      final age = daysBetween(day, t);
      xp += c.pointsAwarded;
      if (age == 0) todayPts += c.pointsAwarded;
      if (age >= 0 && age < 7) {
        weekPts += c.pointsAwarded;
        perDay[day] = perDay[day]! + c.pointsAwarded;
      }
      if (age >= 0 && age < 30) {
        monthPts += c.pointsAwarded;
        counts30[c.choreId] = (counts30[c.choreId] ?? 0) + 1;
      }
    }
    final top = counts30.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return ProgressStats._(
      xp: xp,
      completions: completions.length,
      currentStreak: progress.currentStreak(days, t),
      streakBefore: progress.streakBefore(days, t),
      bestStreak: progress.bestStreak(days),
      pointsToday: todayPts,
      points7Days: weekPts,
      points30Days: monthPts,
      last7Days: [for (final e in perDay.entries) (e.key, e.value)],
      top30Days: [for (final e in top.take(5)) (e.key, e.value)],
    );
  }

  const ProgressStats._({
    required this.xp,
    required this.completions,
    required this.currentStreak,
    required this.streakBefore,
    required this.bestStreak,
    required this.pointsToday,
    required this.points7Days,
    required this.points30Days,
    required this.last7Days,
    required this.top30Days,
  });

  /// Experience: all points ever earned (spending in 0.5 will not lower it).
  final int xp;
  final int completions;
  final int currentStreak;

  /// Streak ending yesterday: the one that earns today's bonus.
  final int streakBefore;
  final int bestStreak;
  final int pointsToday;
  final int points7Days;
  final int points30Days;

  /// Points per day, oldest first, ending today.
  final List<(DateTime day, int points)> last7Days;

  /// Most completed chores in the last 30 days (chore id, count).
  final List<(int choreId, int count)> top30Days;

  int get level => progress.levelForXp(xp);
  int get levelStartXp => progress.xpForLevel(level);
  int get nextLevelXp => progress.xpForLevel(level + 1);

  /// Progress within the current level, 0..1.
  double get levelProgress =>
      (xp - levelStartXp) / (nextLevelXp - levelStartXp);
}
