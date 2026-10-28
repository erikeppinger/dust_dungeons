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

int daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;

/// Calendar months from [from]'s month to [to]'s month.
int monthsBetween(DateTime from, DateTime to) =>
    (to.year - from.year) * 12 + (to.month - from.month);
