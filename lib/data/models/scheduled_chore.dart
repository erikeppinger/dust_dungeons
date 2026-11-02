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
    DateTime? now,
    this.person,
    this.doneBy = const {},
  }) : today = dayOf(today),
       now = now ?? dayOf(today),
       recurrence = chore.recurrence,
       times = chore.timeWindow,
       lastDone = chore.countedLastDone(lastDone) {
    due = recurrence.nextDue(lastDone: this.lastDone);
    final d = due;
    windowEnd = d == null ? null : recurrence.windowEnd(d);
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

  /// The current time, for [times] (start of [today] when not given).
  final DateTime now;

  /// Times of day it's meant to be done; `null` = any time.
  final TimeWindow? times;

  /// Next due day, where its window opens; `null` when never due.
  late final DateTime? due;

  /// The last day of that window (see `Recurrence.windowEnd`).
  late final DateTime? windowEnd;

  /// Its window ended before today.
  bool get isOverdue => windowEnd != null && windowEnd!.isBefore(today);

  /// Its window is open today (the due day itself for a 1-day window).
  bool get isDueToday =>
      due != null && !due!.isAfter(today) && !windowEnd!.isBefore(today);
  bool get isDoneToday => doneToday > 0;

  int get _minutes => TimeWindow.minutesOf(now);

  /// Open today, but its times haven't started yet.
  bool get isLaterToday =>
      isDueToday && times != null && _minutes < times!.from;

  /// Open today and past its times, and today is the window's last day.
  bool get isTimesUp =>
      isDueToday && times != null && _minutes > times!.to && windowEnd == today;

  /// Past today's times, but the window goes on: next chance tomorrow.
  bool get isAgainTomorrow =>
      isDueToday && times != null && _minutes > times!.to && windowEnd != today;

  /// Doing it now earns the on-time bonus: inside the open window and, if it
  /// has times, inside them (docs/design/scheduling.md).
  bool get isOnTimeNow => isDueToday && (times == null || times!.contains(now));

  /// Due days after today up to [to] (for the plan views).
  List<DateTime> upcomingDueDays(DateTime to) =>
      recurrence.upcomingDueDays(today: today, to: to, lastDone: lastDone);
}

/// Today's chores split into the sections of the Today screen.
class TodaySections {
  TodaySections(List<ScheduledChore> all)
    : overdue = all.where((c) => c.isOverdue || c.isTimesUp).toList()
        ..sort((a, b) => a.due!.compareTo(b.due!)),
      dueToday = all
          .where(
            (c) =>
                c.isDueToday &&
                !c.isLaterToday &&
                !c.isTimesUp &&
                !c.isAgainTomorrow,
          )
          .toList(),
      laterToday = all.where((c) => c.isLaterToday).toList()
        ..sort((a, b) => a.times!.from.compareTo(b.times!.from)),
      doneToday = all
          .where((c) => c.isDoneToday && !c.isOverdue && !c.isDueToday)
          .toList(),
      later =
          all
              .where(
                (c) =>
                    !c.isOverdue &&
                    !c.isDoneToday &&
                    (!c.isDueToday || c.isAgainTomorrow),
              )
              .toList()
            ..sort(_byDueThenOrder);

  final List<ScheduledChore> overdue;
  final List<ScheduledChore> dueToday;

  /// Open today, with times that haven't started yet.
  final List<ScheduledChore> laterToday;
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
  DateTime? now,
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
          now: now,
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
          now: now,
          person: p,
          doneBy: count > 0 ? {p} : const {},
        ),
      );
    }
  }
  return result;
}
