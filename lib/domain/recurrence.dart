import 'dart:math';

import 'dates.dart';

/// How a chore repeats. Stored by name in the database: never rename values.
enum RepeatType {
  /// No schedule: never due, can be done any time.
  anytime,

  /// Due once on [Recurrence.start].
  once,

  /// Every [Recurrence.interval] days from [Recurrence.start].
  daily,

  /// Every [Recurrence.interval] weeks on [Recurrence.weekdays].
  weekly,

  /// Every [Recurrence.interval] months on [Recurrence.dayOfMonth]
  /// (clamped to the month's last day), or with [Recurrence.monthWeek] on
  /// the nth weekday ("1st Monday").
  monthly,

  /// [Recurrence.interval] days after the last completion ("floating").
  afterDone,
}

/// A chore's schedule.
///
/// Fixed schedules (once/daily/weekly/monthly) split time into cycles that
/// start at each occurrence; every cycle needs one completion. A completion
/// counts for the cycle it falls in, so after doing an overdue chore the next
/// due date is the next occurrence after that cycle.
class Recurrence {
  const Recurrence({
    required this.type,
    this.interval = 1,
    this.weekdays = const {},
    this.dayOfMonth,
    this.monthWeek,
    this.windowDays = 1,
    required this.start,
  }) : assert(interval >= 1),
       assert(windowDays >= 0);

  const Recurrence.anytime(this.start)
    : type = RepeatType.anytime,
      interval = 1,
      weekdays = const {},
      dayOfMonth = null,
      monthWeek = null,
      windowDays = 1;

  final RepeatType type;
  final int interval;

  /// ISO weekdays (`DateTime.monday` … `DateTime.sunday`) for [RepeatType.weekly].
  final Set<int> weekdays;

  /// Day of month for [RepeatType.monthly]; defaults to [start]'s day.
  final int? dayOfMonth;

  /// Monthly on a weekday: 1–4 for the 1st–4th, -1 for the last; the
  /// weekday is the single one in [weekdays]. `null`: on [dayOfMonth].
  final int? monthWeek;

  /// Days each occurrence stays open, from its due day: 1 = that day only.
  /// 0 = until the day before the next occurrence. Never past that day, so
  /// windows of one chore don't overlap (see docs/design/scheduling.md).
  final int windowDays;

  /// First possible occurrence (the date for [RepeatType.once]).
  final DateTime start;

  bool get isFixed => switch (type) {
    RepeatType.once ||
    RepeatType.daily ||
    RepeatType.weekly ||
    RepeatType.monthly => true,
    RepeatType.anytime || RepeatType.afterDone => false,
  };

  /// Whether a fixed schedule has an occurrence on [day].
  bool occursOn(DateTime day) {
    final d = dayOf(day);
    final s = dayOf(start);
    if (d.isBefore(s)) return false;
    switch (type) {
      case RepeatType.anytime:
      case RepeatType.afterDone:
        return false;
      case RepeatType.once:
        return d == s;
      case RepeatType.daily:
        return daysBetween(s, d) % interval == 0;
      case RepeatType.weekly:
        return weekdays.contains(d.weekday) &&
            (daysBetween(weekStartOf(s), weekStartOf(d)) ~/ 7) % interval == 0;
      case RepeatType.monthly:
        if (monthsBetween(s, d) % interval != 0) return false;
        final week = monthWeek;
        if (week != null) {
          if (weekdays.length != 1 || d.weekday != weekdays.first) {
            return false;
          }
          return week == -1
              ? d.day + 7 > daysInMonth(d.year, d.month)
              : (d.day - 1) ~/ 7 + 1 == week;
        }
        final dom = min(dayOfMonth ?? s.day, daysInMonth(d.year, d.month));
        return d.day == dom;
    }
  }

  /// Longest possible gap between two occurrences, bounding the searches.
  int get _searchSpan => switch (type) {
    RepeatType.daily => interval,
    RepeatType.weekly => 7 * interval + 7,
    RepeatType.monthly => 31 * interval + 31,
    _ => 0,
  };

  /// First occurrence on or after [day], or `null` if there is none.
  DateTime? firstOnOrAfter(DateTime day) {
    if (!isFixed) return null;
    final s = dayOf(start);
    var d = dayOf(day);
    if (d.isBefore(s)) d = s;
    if (type == RepeatType.once) return d == s ? s : null;
    for (var i = 0; i <= _searchSpan; i++) {
      final candidate = addDays(d, i);
      if (occursOn(candidate)) return candidate;
    }
    return null; // e.g. weekly without weekdays
  }

  /// Last occurrence on or before [day], or `null` if there is none.
  DateTime? lastOnOrBefore(DateTime day) {
    if (!isFixed) return null;
    final s = dayOf(start);
    final d = dayOf(day);
    if (d.isBefore(s)) return null;
    if (type == RepeatType.once) return s;
    for (var i = 0; i <= _searchSpan; i++) {
      final candidate = addDays(d, -i);
      if (candidate.isBefore(s)) return null;
      if (occursOn(candidate)) return candidate;
    }
    return null;
  }

  /// The day the chore is next due, given its last completion.
  /// `null` means it is never due (anytime, or a one-off that is done).
  ///
  /// For [RepeatType.once], pass only completions made after the schedule
  /// was set, so older history does not count as done.
  DateTime? nextDue({DateTime? lastDone}) {
    final last = lastDone == null ? null : dayOf(lastDone);
    switch (type) {
      case RepeatType.anytime:
        return null;
      case RepeatType.afterDone:
        return last == null ? dayOf(start) : addDays(last, interval);
      case RepeatType.once:
        return last == null ? dayOf(start) : null;
      case RepeatType.daily:
      case RepeatType.weekly:
      case RepeatType.monthly:
        final first = firstOnOrAfter(start);
        if (last == null) return first;
        final cycle = lastOnOrBefore(last);
        // Done before the schedule started: does not cover any cycle.
        if (cycle == null) return first;
        return firstOnOrAfter(addDays(cycle, 1));
    }
  }

  /// The last day the occurrence due on [due] is open (see [windowDays]):
  /// never on or after the next occurrence.
  DateTime windowEnd(DateTime due) {
    final d = dayOf(due);
    final DateTime? next = switch (type) {
      RepeatType.anytime || RepeatType.once => null,
      RepeatType.afterDone => addDays(d, interval),
      _ => firstOnOrAfter(addDays(d, 1)),
    };
    final cap = next == null ? null : addDays(next, -1);
    if (windowDays == 0) return cap ?? d;
    final wanted = addDays(d, windowDays - 1);
    return cap != null && cap.isBefore(wanted) ? cap : wanted;
  }

  /// Future due days strictly after [today] up to [to], assuming the chore is
  /// done when due (an overdue chore is assumed done today).
  List<DateTime> upcomingDueDays({
    required DateTime today,
    required DateTime to,
    DateTime? lastDone,
  }) {
    final t = dayOf(today);
    final end = dayOf(to);
    final due = nextDue(lastDone: lastDone);
    if (due == null) return const [];
    final result = <DateTime>[];
    switch (type) {
      case RepeatType.anytime:
        break;
      case RepeatType.once:
        if (due.isAfter(t) && !due.isAfter(end)) result.add(due);
      case RepeatType.afterDone:
        var d = due.isAfter(t) ? due : addDays(t, interval);
        while (!d.isAfter(end)) {
          result.add(d);
          d = addDays(d, interval);
        }
      case RepeatType.daily:
      case RepeatType.weekly:
      case RepeatType.monthly:
        var d = firstOnOrAfter(due.isAfter(t) ? due : addDays(t, 1));
        while (d != null && !d.isAfter(end)) {
          result.add(d);
          d = firstOnOrAfter(addDays(d, 1));
        }
    }
    return result;
  }

  Recurrence copyWith({
    RepeatType? type,
    int? interval,
    Set<int>? weekdays,
    int? Function()? dayOfMonth,
    int? Function()? monthWeek,
    int? windowDays,
    DateTime? start,
  }) => Recurrence(
    type: type ?? this.type,
    interval: interval ?? this.interval,
    weekdays: weekdays ?? this.weekdays,
    dayOfMonth: dayOfMonth != null ? dayOfMonth() : this.dayOfMonth,
    monthWeek: monthWeek != null ? monthWeek() : this.monthWeek,
    windowDays: windowDays ?? this.windowDays,
    start: start ?? this.start,
  );

  @override
  bool operator ==(Object other) =>
      other is Recurrence &&
      other.type == type &&
      other.interval == interval &&
      other.weekdays.length == weekdays.length &&
      other.weekdays.containsAll(weekdays) &&
      other.dayOfMonth == dayOfMonth &&
      other.monthWeek == monthWeek &&
      other.windowDays == windowDays &&
      dayOf(other.start) == dayOf(start);

  @override
  int get hashCode => Object.hash(
    type,
    interval,
    Object.hashAllUnordered(weekdays),
    dayOfMonth,
    monthWeek,
    windowDays,
    dayOf(start),
  );

  @override
  String toString() =>
      'Recurrence($type, every $interval, $weekdays, dom $dayOfMonth, '
      'week $monthWeek, window $windowDays, from $start)';
}

/// Weekday set <-> bitmask (bit 0 = Monday) for storage.
int weekdaysToMask(Set<int> weekdays) =>
    weekdays.fold(0, (mask, d) => mask | (1 << (d - 1)));

Set<int> weekdaysFromMask(int mask) => {
  for (var d = DateTime.monday; d <= DateTime.sunday; d++)
    if (mask & (1 << (d - 1)) != 0) d,
};

/// Times of day a chore is meant to be done, as minutes after midnight
/// ([from] < [to], within one day).
class TimeWindow {
  const TimeWindow(this.from, this.to);

  final int from, to;

  /// Minutes after midnight of [time].
  static int minutesOf(DateTime time) => time.hour * 60 + time.minute;

  bool contains(DateTime time) {
    final m = minutesOf(time);
    return m >= from && m <= to;
  }

  @override
  bool operator ==(Object other) =>
      other is TimeWindow && other.from == from && other.to == to;

  @override
  int get hashCode => Object.hash(from, to);
}
