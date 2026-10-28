import '../../data/db/app_database.dart';
import '../../data/models/scheduled_chore.dart';

/// Scheduled chores indexed for the plan views: today's sections plus the
/// projected due days after today up to [to].
class PlanData {
  PlanData(
    List<ScheduledChore> chores, {
    required this.today,
    required DateTime to,
    List<Chore> allChores = const [],
  }) : _sections = TodaySections(chores),
       _byId = {
         for (final c in allChores) c.id: c,
         for (final s in chores) s.chore.id: s.chore,
       } {
    for (final s in chores) {
      for (final day in s.upcomingDueDays(to)) {
        (_dueByDay[day] ??= []).add(s);
      }
    }
    assert(!_dueByDay.keys.any((d) => !d.isAfter(today)));
  }

  final DateTime today;
  final TodaySections _sections;
  final Map<int, Chore> _byId;
  final _dueByDay = <DateTime, List<ScheduledChore>>{};

  List<ScheduledChore> get overdue => _sections.overdue;
  List<ScheduledChore> get dueToday => _sections.dueToday;
  List<ScheduledChore> get doneToday => _sections.doneToday;

  /// Chores due on a future [day] (empty for the past; use the section
  /// getters for today's details).
  List<ScheduledChore> dueOn(DateTime day) => _dueByDay[day] ?? const [];

  /// Open chores on [day]: overdue + due for today, projected for the future.
  int openCountOn(DateTime day) =>
      day == today ? overdue.length + dueToday.length : dueOn(day).length;

  /// Any chore by id, including archived ones passed as `allChores`, so
  /// past completions of archived chores still show up.
  Chore? choreById(int id) => _byId[id];
}
