/// Calendar-day helpers. All "days" are local midnights; arithmetic goes
/// through calendar fields so DST changes never shift a date.
library;

/// Local midnight at the start of [time]'s day.
DateTime dayOf(DateTime time) => DateTime(time.year, time.month, time.day);

DateTime addDays(DateTime day, int days) =>
    DateTime(day.year, day.month, day.day + days);

/// Whole calendar days from [from] to [to] (negative if [to] is earlier).
int daysBetween(DateTime from, DateTime to) => DateTime.utc(
  to.year,
  to.month,
  to.day,
).difference(DateTime.utc(from.year, from.month, from.day)).inDays;

/// Monday of [day]'s week (ISO weeks).
DateTime weekStartOf(DateTime day) => addDays(dayOf(day), 1 - day.weekday);

/// ISO 8601 week of [day] as (week-based year, week 1..53): weeks start on
/// Monday, and week 1 is the one with the year's first Thursday.
(int, int) isoWeek(DateTime day) {
  final thursday = addDays(dayOf(day), 4 - day.weekday);
  return (
    thursday.year,
    daysBetween(DateTime(thursday.year), thursday) ~/ 7 + 1,
  );
}

int daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;

/// Calendar months from [from]'s month to [to]'s month.
int monthsBetween(DateTime from, DateTime to) =>
    (to.year - from.year) * 12 + (to.month - from.month);
