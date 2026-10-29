import 'package:flutter_test/flutter_test.dart';
import 'package:homework_and_chores/data/db/app_database.dart';
import 'package:homework_and_chores/data/models/scheduled_chore.dart';

final today = DateTime(2026, 10, 28);

Chore chore(int id, RepeatType type, {int interval = 1, int order = 0}) =>
    Chore(
      id: id,
      iconKey: 'star',
      colorKey: 0,
      basePoints: 10,
      isArchived: false,
      assignment: Assignment.anyone,
      sortOrder: order,
      createdAt: DateTime(2026, 10, 1),
      repeatType: type,
      repeatInterval: interval,
      repeatWeekdays: 0,
      repeatStart: DateTime(2026, 10, 1),
    );

ScheduledChore scheduled(Chore c, {DateTime? lastDone, int doneToday = 0}) =>
    ScheduledChore(
      chore: c,
      lastDone: lastDone,
      doneToday: doneToday,
      today: today,
    );

void main() {
  test('chores land in the right Today section', () {
    final overdue = scheduled(
      chore(1, RepeatType.afterDone, interval: 7),
      lastDone: DateTime(2026, 10, 18),
    );
    final dueToday = scheduled(
      chore(2, RepeatType.daily),
      lastDone: DateTime(2026, 10, 27),
    );
    final doneToday = scheduled(
      chore(3, RepeatType.daily),
      lastDone: DateTime(2026, 10, 28, 7),
      doneToday: 1,
    );
    final soon = scheduled(
      chore(4, RepeatType.afterDone, interval: 3),
      lastDone: DateTime(2026, 10, 27),
    );
    final anytime = scheduled(chore(5, RepeatType.anytime));

    final sections = TodaySections([
      anytime,
      soon,
      doneToday,
      dueToday,
      overdue,
    ]);
    expect(sections.overdue, [overdue]);
    expect(overdue.due, DateTime(2026, 10, 25));
    expect(sections.dueToday, [dueToday]);
    expect(sections.doneToday, [doneToday]);
    expect(sections.later, [soon, anytime], reason: 'soonest first');
  });
}
