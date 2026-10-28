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
