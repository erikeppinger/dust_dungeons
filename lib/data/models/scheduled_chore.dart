import '../../domain/dates.dart';
import '../../domain/recurrence.dart';
import '../db/app_database.dart';

/// A chore together with its schedule state on a given day.
class ScheduledChore {
  ScheduledChore({
    required this.chore,
    required DateTime? lastDone,
    required this.doneToday,
    required DateTime today,
    this.person,
    this.doneBy = const {},
  }) : today = dayOf(today),
       recurrence = chore.recurrence,
       lastDone = chore.countedLastDone(lastDone) {
    due = recurrence.nextDue(lastDone: this.lastDone);
  }

  final Chore chore;
  final Recurrence recurrence;

  /// Last completion that counts for the schedule.
  final DateTime? lastDone;

  /// Completions today (including ones that do not count for the schedule).
  final int doneToday;
  final DateTime today;

  /// Whose chore this is: `null` for anyone's (the household's), otherwise
  /// the person it's scheduled for.
  final int? person;

  /// Who did it today (profile ids).
  final Set<int> doneBy;

  /// Next due day; `null` when the chore is never due.
  late final DateTime? due;

  bool get isOverdue => due != null && due!.isBefore(today);
  bool get isDueToday => due == today;
  bool get isDoneToday => doneToday > 0;

  /// Due days after today up to [to] (for the plan views).
  List<DateTime> upcomingDueDays(DateTime to) =>
      recurrence.upcomingDueDays(today: today, to: to, lastDone: lastDone);
}

/// Today's chores split into the sections of the Today screen.
class TodaySections {
  TodaySections(List<ScheduledChore> all)
    : overdue = all.where((c) => c.isOverdue).toList()
        ..sort((a, b) => a.due!.compareTo(b.due!)),
      dueToday = all.where((c) => c.isDueToday).toList(),
      doneToday = all
          .where((c) => c.isDoneToday && !c.isOverdue && !c.isDueToday)
          .toList(),
      later =
          all
              .where((c) => !c.isOverdue && !c.isDueToday && !c.isDoneToday)
              .toList()
            ..sort(_byDueThenOrder);

  final List<ScheduledChore> overdue;
  final List<ScheduledChore> dueToday;
  final List<ScheduledChore> doneToday;

  /// Due later or never due ("anytime"), soonest first.
  final List<ScheduledChore> later;

  static int _byDueThenOrder(ScheduledChore a, ScheduledChore b) {
    final ad = a.due, bd = b.due;
    if (ad != null && bd != null && ad != bd) return ad.compareTo(bd);
    if (ad == null && bd != null) return 1;
    if (ad != null && bd == null) return -1;
    return a.chore.sortOrder.compareTo(b.chore.sortOrder);
  }
}

/// The chores' schedule state on [today], from the completions of everyone
/// (docs/design/profiles.md):
///
/// * anyone's chores once, due from the household's latest completion;
/// * chores for one or each person, due from that person's completions.
///
/// For a [person], only what they see: anyone's chores and their own. For
/// the household (`person == null`), each personal chore once per assignee.
List<ScheduledChore> schedule({
  required List<Chore> chores,
  required Map<int, Set<int>> assignees,
  required Map<(int, int), DateTime> lastDone,
  required Map<(int, int), int> doneToday,
  required DateTime today,
  int? person,
}) {
  final result = <ScheduledChore>[];
  for (final chore in chores) {
    final people = assignees[chore.id] ?? const <int>{};
    if (chore.assignment == Assignment.anyone || people.isEmpty) {
      DateTime? last;
      var count = 0;
      final by = <int>{};
      for (final MapEntry(key: (c, _), value: t) in lastDone.entries) {
        if (c == chore.id && (last == null || t.isAfter(last))) last = t;
      }
      for (final MapEntry(key: (c, p), value: n) in doneToday.entries) {
        if (c == chore.id && n > 0) {
          count += n;
          by.add(p);
        }
      }
      result.add(
        ScheduledChore(
          chore: chore,
          lastDone: last,
          doneToday: count,
          today: today,
          doneBy: by,
        ),
      );
      continue;
    }
    for (final p in people) {
      if (person != null && p != person) continue;
      final count = doneToday[(chore.id, p)] ?? 0;
      result.add(
        ScheduledChore(
          chore: chore,
          lastDone: lastDone[(chore.id, p)],
          doneToday: count,
          today: today,
          person: p,
          doneBy: count > 0 ? {p} : const {},
        ),
      );
    }
  }
  return result;
}
