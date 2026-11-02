import 'package:flutter_test/flutter_test.dart';
import 'package:homework_and_chores/domain/dates.dart';
import 'package:homework_and_chores/domain/recurrence.dart';

DateTime d(int y, int m, int day) => DateTime(y, m, day);

void main() {
  // 2026-10-26 is a Monday.
  final monday = d(2026, 10, 26);

  group('dates', () {
    test('daysBetween ignores DST (Europe changes on 2026-10-25)', () {
      expect(daysBetween(d(2026, 10, 24), d(2026, 10, 26)), 2);
      expect(daysBetween(d(2026, 3, 28), d(2026, 3, 30)), 2);
      expect(addDays(d(2026, 10, 24), 1), d(2026, 10, 25));
    });

    test('weekStartOf returns Monday', () {
      expect(weekStartOf(d(2026, 11, 1)), monday); // Sunday
      expect(weekStartOf(monday), monday);
    });

    test('weekday mask round-trip', () {
      const days = {DateTime.monday, DateTime.thursday, DateTime.sunday};
      expect(weekdaysFromMask(weekdaysToMask(days)), days);
    });
  });

  group('anytime', () {
    test('is never due', () {
      final r = Recurrence.anytime(monday);
      expect(r.nextDue(), isNull);
      expect(r.nextDue(lastDone: monday), isNull);
      expect(r.upcomingDueDays(today: monday, to: d(2026, 12, 31)), isEmpty);
    });
  });

  group('once', () {
    final r = Recurrence(type: RepeatType.once, start: d(2026, 10, 30));
    test('due on its date until done', () {
      expect(r.nextDue(), d(2026, 10, 30));
      expect(r.nextDue(lastDone: d(2026, 10, 28)), isNull);
    });
    test('upcoming only when in the future', () {
      expect(r.upcomingDueDays(today: monday, to: d(2026, 11, 30)), [
        d(2026, 10, 30),
      ]);
      expect(
        r.upcomingDueDays(today: d(2026, 10, 30), to: d(2026, 11, 30)),
        isEmpty,
      );
    });
  });

  group('daily', () {
    final every3 = Recurrence(
      type: RepeatType.daily,
      interval: 3,
      start: monday,
    );
    test('first due is the start', () {
      expect(every3.nextDue(), monday);
    });
    test('done on time -> next occurrence', () {
      expect(every3.nextDue(lastDone: monday), d(2026, 10, 29));
    });
    test('done late in the same cycle still covers it', () {
      expect(every3.nextDue(lastDone: d(2026, 10, 28)), d(2026, 10, 29));
    });
    test('done before the start does not count', () {
      expect(every3.nextDue(lastDone: d(2026, 10, 20)), monday);
    });
    test('works across DST and month ends', () {
      final r = Recurrence(type: RepeatType.daily, start: d(2026, 10, 24));
      expect(r.nextDue(lastDone: d(2026, 10, 24)), d(2026, 10, 25));
      expect(r.nextDue(lastDone: d(2026, 10, 31)), d(2026, 11, 1));
    });
    test('upcoming days after an overdue chore start tomorrow', () {
      expect(
        every3.upcomingDueDays(
          today: d(2026, 11, 2),
          to: d(2026, 11, 9),
          lastDone: monday,
        ),
        [d(2026, 11, 4), d(2026, 11, 7)],
      );
    });
  });

  group('weekly', () {
    final monThu = Recurrence(
      type: RepeatType.weekly,
      weekdays: {DateTime.monday, DateTime.thursday},
      start: monday,
    );
    test('due on chosen weekdays', () {
      expect(monThu.nextDue(), monday);
      expect(monThu.nextDue(lastDone: monday), d(2026, 10, 29));
      expect(monThu.nextDue(lastDone: d(2026, 10, 30)), d(2026, 11, 2));
    });
    test('start mid-week begins at the next chosen weekday', () {
      final r = monThu.copyWith(start: d(2026, 10, 27)); // Tuesday
      expect(r.nextDue(), d(2026, 10, 29));
    });
    test('every 2 weeks skips the odd weeks', () {
      final r = Recurrence(
        type: RepeatType.weekly,
        interval: 2,
        weekdays: {DateTime.saturday},
        start: monday,
      );
      expect(r.nextDue(), d(2026, 10, 31));
      expect(r.nextDue(lastDone: d(2026, 10, 31)), d(2026, 11, 14));
      expect(r.occursOn(d(2026, 11, 7)), isFalse);
    });
    test('without weekdays it never occurs', () {
      final r = Recurrence(type: RepeatType.weekly, start: monday);
      expect(r.nextDue(), isNull);
    });
  });

  group('monthly', () {
    test('day 31 is clamped to short months', () {
      final r = Recurrence(
        type: RepeatType.monthly,
        dayOfMonth: 31,
        start: d(2027, 1, 31),
      );
      expect(r.nextDue(lastDone: d(2027, 1, 31)), d(2027, 2, 28));
      expect(r.nextDue(lastDone: d(2027, 2, 28)), d(2027, 3, 31));
      expect(r.nextDue(lastDone: d(2027, 3, 31)), d(2027, 4, 30));
    });
    test('leap year February', () {
      final r = Recurrence(
        type: RepeatType.monthly,
        dayOfMonth: 30,
        start: d(2028, 1, 30),
      );
      expect(r.nextDue(lastDone: d(2028, 1, 30)), d(2028, 2, 29));
    });
    test('every 3 months, default day from start', () {
      final r = Recurrence(
        type: RepeatType.monthly,
        interval: 3,
        start: d(2026, 11, 15),
      );
      expect(r.nextDue(), d(2026, 11, 15));
      expect(r.nextDue(lastDone: d(2026, 11, 20)), d(2027, 2, 15));
    });
    test('across the year boundary', () {
      final r = Recurrence(type: RepeatType.monthly, start: d(2026, 12, 5));
      expect(r.nextDue(lastDone: d(2026, 12, 5)), d(2027, 1, 5));
    });
  });

  group('afterDone', () {
    final r = Recurrence(
      type: RepeatType.afterDone,
      interval: 14,
      start: monday,
    );
    test('due at start until first done, then N days after each time', () {
      expect(r.nextDue(), monday);
      expect(r.nextDue(lastDone: d(2026, 11, 3)), d(2026, 11, 17));
    });
    test('upcoming days project from today when overdue', () {
      expect(
        r.upcomingDueDays(
          today: d(2026, 11, 20),
          to: d(2026, 12, 31),
          lastDone: d(2026, 11, 3),
        ),
        [d(2026, 12, 4), d(2026, 12, 18)],
      );
    });
  });

  test('equality ignores time of day and weekday order', () {
    final a = Recurrence(
      type: RepeatType.weekly,
      weekdays: {1, 4},
      start: DateTime(2026, 10, 26, 9),
    );
    final b = Recurrence(
      type: RepeatType.weekly,
      weekdays: {4, 1},
      start: DateTime(2026, 10, 26, 18),
    );
    expect(a, b);
    expect(a.hashCode, b.hashCode);
  });

  group('monthly on a weekday', () {
    Recurrence nth(int week, int weekday, {int interval = 1}) => Recurrence(
      type: RepeatType.monthly,
      monthWeek: week,
      weekdays: {weekday},
      interval: interval,
      start: d(2026, 1, 1),
    );

    test('1st Monday of each month', () {
      final r = nth(1, DateTime.monday);
      expect(r.firstOnOrAfter(d(2026, 11, 1)), d(2026, 11, 2));
      expect(r.firstOnOrAfter(d(2026, 11, 3)), d(2026, 12, 7));
    });

    test('2nd, 3rd and 4th weekdays', () {
      expect(
        nth(2, DateTime.friday).firstOnOrAfter(d(2026, 11, 1)),
        d(2026, 11, 13),
      );
      expect(
        nth(3, DateTime.sunday).firstOnOrAfter(d(2026, 11, 1)),
        d(2026, 11, 15),
      );
      expect(
        nth(4, DateTime.thursday).firstOnOrAfter(d(2026, 11, 1)),
        d(2026, 11, 26),
      );
    });

    test('the last weekday, in months of every length', () {
      final r = nth(-1, DateTime.friday);
      expect(r.firstOnOrAfter(d(2026, 2, 1)), d(2026, 2, 27)); // 28 days
      expect(r.firstOnOrAfter(d(2028, 2, 1)), d(2028, 2, 25)); // leap year
      expect(r.firstOnOrAfter(d(2026, 4, 1)), d(2026, 4, 24)); // 30 days
      expect(r.firstOnOrAfter(d(2026, 7, 1)), d(2026, 7, 31)); // 31 days
    });

    test('every 2 months, counted from the start month', () {
      final r = nth(1, DateTime.monday, interval: 2);
      expect(r.firstOnOrAfter(d(2026, 2, 1)), d(2026, 3, 2));
      expect(r.firstOnOrAfter(d(2026, 3, 3)), d(2026, 5, 4));
    });

    test('done late counts for its cycle', () {
      final r = nth(1, DateTime.monday);
      expect(r.nextDue(lastDone: d(2026, 11, 10)), d(2026, 12, 7));
    });
  });

  group('day windows', () {
    test('a monthly quest open from the 1st to the 10th', () {
      final r = Recurrence(
        type: RepeatType.monthly,
        dayOfMonth: 1,
        windowDays: 10,
        start: d(2026, 1, 1),
      );
      expect(r.windowEnd(d(2026, 11, 1)), d(2026, 11, 10));
    });

    test('never reaches the next occurrence', () {
      final r = Recurrence(
        type: RepeatType.daily,
        interval: 3,
        windowDays: 7,
        start: monday,
      );
      expect(r.windowEnd(monday), d(2026, 10, 28));
    });

    test('"until the next time" ends the day before it', () {
      final weekly = Recurrence(
        type: RepeatType.weekly,
        weekdays: {DateTime.monday, DateTime.thursday},
        windowDays: 0,
        start: monday,
      );
      expect(weekly.windowEnd(monday), d(2026, 10, 28)); // before Thursday
      expect(weekly.windowEnd(d(2026, 10, 29)), d(2026, 11, 1)); // before Mon
      final floating = Recurrence(
        type: RepeatType.afterDone,
        interval: 5,
        windowDays: 0,
        start: monday,
      );
      expect(floating.windowEnd(monday), d(2026, 10, 30));
    });

    test('one day is the due day only; once has no next time', () {
      final daily = Recurrence(type: RepeatType.daily, start: monday);
      expect(daily.windowEnd(monday), monday);
      final once = Recurrence(
        type: RepeatType.once,
        windowDays: 0,
        start: monday,
      );
      expect(once.windowEnd(monday), monday);
      final onceThree = Recurrence(
        type: RepeatType.once,
        windowDays: 3,
        start: monday,
      );
      expect(onceThree.windowEnd(monday), d(2026, 10, 28));
    });

    test('across the DST change', () {
      final r = Recurrence(
        type: RepeatType.weekly,
        weekdays: {DateTime.saturday},
        windowDays: 3,
        start: d(2026, 10, 24),
      );
      expect(r.windowEnd(d(2026, 10, 24)), d(2026, 10, 26));
    });
  });

  test('time windows include both ends', () {
    const w = TimeWindow(18 * 60, 20 * 60);
    expect(w.contains(DateTime(2026, 11, 2, 17, 59)), isFalse);
    expect(w.contains(DateTime(2026, 11, 2, 18)), isTrue);
    expect(w.contains(DateTime(2026, 11, 2, 20)), isTrue);
    expect(w.contains(DateTime(2026, 11, 2, 20, 1)), isFalse);
  });
}
