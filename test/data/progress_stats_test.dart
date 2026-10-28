import 'package:flutter_test/flutter_test.dart';
import 'package:homework_and_chores/data/db/app_database.dart';
import 'package:homework_and_chores/data/models/progress_stats.dart';

var _id = 0;
Completion done(int choreId, DateTime at, int points) => Completion(
  id: ++_id,
  choreId: choreId,
  profileId: 1,
  completedAt: at,
  pointsAwarded: points,
);

void main() {
  final today = DateTime(2026, 10, 28, 15);

  test('empty history', () {
    final s = ProgressStats(const [], today: today);
    expect(s.xp, 0);
    expect(s.level, 1);
    expect(s.currentStreak, 0);
    expect(s.last7Days, hasLength(7));
    expect(s.last7Days.every((d) => d.$2 == 0), isTrue);
    expect(s.top30Days, isEmpty);
  });

  test('totals, streaks, per-day points and top chores', () {
    final s = ProgressStats([
      done(1, DateTime(2026, 9, 1), 50), // > 30 days ago
      done(1, DateTime(2026, 10, 20), 10),
      done(2, DateTime(2026, 10, 26, 8), 20),
      done(2, DateTime(2026, 10, 27, 9), 20),
      done(2, DateTime(2026, 10, 28, 7), 25),
      done(3, DateTime(2026, 10, 28, 9), 5),
    ], today: today);

    expect(s.xp, 130);
    expect(s.level, 2); // 100..299
    expect(s.levelProgress, closeTo(0.15, 0.001));
    expect(s.completions, 6);
    expect(s.currentStreak, 3);
    expect(s.streakBefore, 2);
    expect(s.bestStreak, 3);
    expect(s.pointsToday, 30);
    expect(s.points7Days, 70);
    expect(s.points30Days, 80);
    expect(s.last7Days.first, (DateTime(2026, 10, 22), 0));
    expect(s.last7Days.last, (DateTime(2026, 10, 28), 30));
    expect(s.top30Days.first, (2, 3));
  });
}
