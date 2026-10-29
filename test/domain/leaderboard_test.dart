import 'package:flutter_test/flutter_test.dart';
import 'package:homework_and_chores/domain/leaderboard.dart';

void main() {
  final monday = DateTime(2026, 10, 26);
  const sam = 1, alex = 2, kim = 3;

  test('ranks by points this week; ties share a rank', () {
    final rows = leaderboard(
      completions: [
        (sam, DateTime(2026, 10, 26, 9), 15),
        (alex, DateTime(2026, 10, 27, 9), 10),
        (alex, DateTime(2026, 10, 28, 9), 5),
        (kim, DateTime(2026, 10, 29, 9), 7),
      ],
      people: [sam, alex, kim],
      weekStart: monday,
    );
    expect(
      [for (final r in rows) (r.person, r.rank, r.points, r.quests)],
      [
        (alex, 1, 15, 2), // more quests first among equal points
        (sam, 1, 15, 1),
        (kim, 3, 7, 1),
      ],
    );
  });

  test('only this week counts (Monday to Sunday)', () {
    final rows = leaderboard(
      completions: [
        (sam, DateTime(2026, 10, 25, 23, 59), 50), // last Sunday
        (sam, DateTime(2026, 11, 2), 50), // next Monday
        (sam, DateTime(2026, 11, 1, 23), 3), // this Sunday
      ],
      people: [sam],
      weekStart: monday,
    );
    expect((rows.single.points, rows.single.quests), (3, 1));
  });

  test('people without quests are listed with zero', () {
    final rows = leaderboard(
      completions: [(sam, DateTime(2026, 10, 27), 5)],
      people: [sam, alex],
      weekStart: monday,
    );
    expect(
      [for (final r in rows) (r.person, r.rank, r.points)],
      [(sam, 1, 5), (alex, 2, 0)],
    );
  });

  test('removed people are left out', () {
    final rows = leaderboard(
      completions: [(kim, DateTime(2026, 10, 27), 99)],
      people: [sam],
      weekStart: monday,
    );
    expect(rows.single.person, sam);
  });

  test('last week: the winner, everyone tied, or nobody', () {
    List<int> winners(List<(int, DateTime, int)> done) =>
        weekWinners(completions: done, people: [sam, alex], weekStart: monday);
    expect(winners([(alex, DateTime(2026, 10, 27), 9)]), [alex]);
    expect(
      winners([
        (sam, DateTime(2026, 10, 27), 9),
        (alex, DateTime(2026, 10, 28), 9),
      ]),
      [sam, alex],
    );
    expect(winners(const []), isEmpty);
  });
}
