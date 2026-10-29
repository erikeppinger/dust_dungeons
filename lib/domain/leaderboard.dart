import 'dates.dart';

/// One person's week on the leaderboard.
class LeaderRow {
  const LeaderRow({
    required this.person,
    required this.rank,
    required this.points,
    required this.quests,
  });

  final int person;

  /// 1 for the leader; people with equal points share a rank (1, 1, 3).
  final int rank;

  /// Points earned by quests this week; spending doesn't lower it.
  final int points;
  final int quests;
}

/// The week starting [weekStart] (Monday) for [people], best first. A
/// completion is (person, when, points awarded); undone ones must be left
/// out by the caller. Equal points rank by quests, then [people] order, but
/// share the rank number.
List<LeaderRow> leaderboard({
  required Iterable<(int, DateTime, int)> completions,
  required List<int> people,
  required DateTime weekStart,
}) {
  final end = addDays(weekStart, 7);
  final points = {for (final p in people) p: 0};
  final quests = {for (final p in people) p: 0};
  for (final (person, at, awarded) in completions) {
    if (!points.containsKey(person)) continue;
    if (at.isBefore(weekStart) || !at.isBefore(end)) continue;
    points[person] = points[person]! + awarded;
    quests[person] = quests[person]! + 1;
  }
  final order = [...people]
    ..sort((a, b) {
      final byPoints = points[b]!.compareTo(points[a]!);
      if (byPoints != 0) return byPoints;
      final byQuests = quests[b]!.compareTo(quests[a]!);
      if (byQuests != 0) return byQuests;
      return people.indexOf(a).compareTo(people.indexOf(b));
    });
  final rows = <LeaderRow>[];
  for (final (i, person) in order.indexed) {
    final shares = i > 0 && points[order[i - 1]] == points[person];
    rows.add(
      LeaderRow(
        person: person,
        rank: shares ? rows.last.rank : i + 1,
        points: points[person]!,
        quests: quests[person]!,
      ),
    );
  }
  return rows;
}

/// Who won the week starting [weekStart]: everyone with the most points,
/// or nobody if no one earned any.
List<int> weekWinners({
  required Iterable<(int, DateTime, int)> completions,
  required List<int> people,
  required DateTime weekStart,
}) {
  final rows = leaderboard(
    completions: completions,
    people: people,
    weekStart: weekStart,
  );
  if (rows.isEmpty || rows.first.points == 0) return const [];
  return [
    for (final r in rows)
      if (r.rank == 1) r.person,
  ];
}
