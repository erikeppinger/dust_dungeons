import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:homework_and_chores/data/db/app_database.dart';
import 'package:homework_and_chores/data/models/scheduled_chore.dart';
import 'package:homework_and_chores/domain/recurrence.dart';

final today = DateTime(2026, 10, 28);

Chore chore(int id, RepeatType type, {int interval = 1, int order = 0}) =>
    Chore(
      id: id,
      iconKey: 'star',
      colorKey: 0,
      basePoints: 10,
      isArchived: false,
      assignment: Assignment.anyone,
      windowDays: 1,
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

  group('windows and times (docs/design/scheduling.md)', () {
    // Weekly on Wednesdays (today), open 3 days, optionally 18:00-20:00.
    ScheduledChore weekly({
      int windowDays = 3,
      TimeWindow? times,
      DateTime? now,
      DateTime? day,
      DateTime? lastDone,
    }) => ScheduledChore(
      chore: chore(1, RepeatType.weekly).copyWith(
        repeatWeekdays: weekdaysToMask({DateTime.wednesday}),
        windowDays: windowDays,
        windowFrom: Value(times?.from),
        windowTo: Value(times?.to),
      ),
      // Done last Wednesday, so this week's window starts today.
      lastDone: lastDone ?? DateTime(2026, 10, 21, 9),
      doneToday: 0,
      today: day ?? today,
      now: now,
    );
    const evening = TimeWindow(18 * 60, 20 * 60);
    DateTime at(int day, int hour, [int minute = 0]) =>
        DateTime(2026, 10, day, hour, minute);

    test('open, and on time, on every day of its window', () {
      for (final day in [28, 29, 30]) {
        final s = weekly(day: DateTime(2026, 10, day), lastDone: at(21, 9));
        expect(s.isDueToday, isTrue, reason: 'Oct $day');
        expect(s.isOnTimeNow, isTrue);
        expect(s.isOverdue, isFalse);
      }
      final after = weekly(day: DateTime(2026, 10, 31), lastDone: at(21, 9));
      expect(after.isOverdue, isTrue);
      expect(after.isOnTimeNow, isFalse);
    });

    test('done inside the window: next time is next week', () {
      final s = weekly(day: DateTime(2026, 10, 30), lastDone: at(29, 9));
      expect(s.due, DateTime(2026, 11, 4));
      expect(s.isDueToday, isFalse);
    });

    test('times: later today, during, again tomorrow, time is up', () {
      final before = weekly(times: evening, now: at(28, 17, 59));
      expect(before.isLaterToday, isTrue);
      expect(before.isOnTimeNow, isFalse);
      final during = weekly(times: evening, now: at(28, 18));
      expect(during.isLaterToday, isFalse);
      expect(during.isOnTimeNow, isTrue);
      final end = weekly(times: evening, now: at(28, 20));
      expect(end.isOnTimeNow, isTrue);
      // Past the times on the first day of three: again tomorrow.
      final after = weekly(times: evening, now: at(28, 20, 1));
      expect(after.isAgainTomorrow, isTrue);
      expect(after.isTimesUp, isFalse);
      expect(after.isOnTimeNow, isFalse);
      // On the window's last day, it's up.
      final lastDay = weekly(
        times: evening,
        day: DateTime(2026, 10, 30),
        now: at(30, 21),
      );
      expect(lastDay.isTimesUp, isTrue);
    });

    test('sections: later today, due, time is up as overdue', () {
      final later = weekly(windowDays: 1, times: evening, now: at(28, 9));
      final up = ScheduledChore(
        chore: chore(2, RepeatType.daily).copyWith(
          windowFrom: const Value(7 * 60),
          windowTo: const Value(8 * 60),
        ),
        lastDone: DateTime(2026, 10, 27),
        doneToday: 0,
        today: today,
        now: at(28, 9),
      );
      final sections = TodaySections([later, up]);
      expect(sections.laterToday, [later]);
      expect(sections.overdue, [up]);
      expect(sections.dueToday, isEmpty);
    });
  });
}
