import 'package:flutter_test/flutter_test.dart';
import 'package:homework_and_chores/domain/points.dart';
import 'package:homework_and_chores/domain/progress.dart';

DateTime d(int day) => DateTime(2026, 10, day);

void main() {
  group('points', () {
    test('base only without bonuses', () {
      final p = pointsFor(basePoints: 15);
      expect((p.base, p.bonus, p.total), (15, 0, 15));
    });

    test('on-time and streak bonuses are percentages of the base', () {
      final p = pointsFor(basePoints: 20, onTime: true, streakDays: 5);
      expect(p.onTimeBonus, 2); // 10 %
      expect(p.streakBonus, 2); // 5 days * 2 % = 10 %
      expect(p.total, 24);
    });

    test('small chores still get at least 1 bonus point', () {
      final p = pointsFor(basePoints: 5, onTime: true, streakDays: 1);
      expect(p.onTimeBonus, 1);
      expect(p.streakBonus, 1);
    });

    test('streak bonus is capped', () {
      expect(
        pointsFor(basePoints: 100, streakDays: 50).streakBonus,
        pointsFor(basePoints: 100, streakDays: maxStreakBonusDays).streakBonus,
      );
      expect(pointsFor(basePoints: 100, streakDays: 50).streakBonus, 20);
    });

    test('base is clamped to the allowed range', () {
      expect(pointsFor(basePoints: 0).base, minBasePoints);
      expect(pointsFor(basePoints: 1000).base, maxBasePoints);
    });
  });

  group('streaks', () {
    test('counts consecutive days before today', () {
      expect(streakBefore({d(25), d(26), d(27)}, d(28)), 3);
      expect(streakBefore({d(25), d(27)}, d(28)), 1);
      expect(streakBefore({d(28)}, d(28)), 0);
    });

    test('current streak survives until a whole day is missed', () {
      expect(currentStreak({d(26), d(27)}, d(28)), 2); // not done yet today
      expect(currentStreak({d(26), d(27), d(28)}, d(28)), 3);
      expect(currentStreak({d(25), d(26)}, d(28)), 0); // missed the 27th
    });

    test('streaks cross month ends and DST', () {
      final days = {
        DateTime(2026, 10, 24),
        DateTime(2026, 10, 25), // DST ends in Europe
        DateTime(2026, 10, 31),
        DateTime(2026, 11, 1),
      };
      expect(streakBefore(days, DateTime(2026, 11, 2)), 2);
      expect(bestStreak(days), 2);
    });

    test('best streak', () {
      expect(bestStreak({}), 0);
      expect(bestStreak({d(1), d(2), d(3), d(10), d(11)}), 3);
    });
  });

  group('levels', () {
    test('thresholds grow by 100 XP per level', () {
      expect(
        [for (var l = 1; l <= 5; l++) xpForLevel(l)],
        [0, 100, 300, 600, 1000],
      );
    });

    test('level for XP', () {
      expect(levelForXp(0), 1);
      expect(levelForXp(99), 1);
      expect(levelForXp(100), 2);
      expect(levelForXp(299), 2);
      expect(levelForXp(1000), 5);
    });
  });
}
