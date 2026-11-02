import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/models/scheduled_chore.dart';
import '../../domain/dates.dart';
import '../../domain/recurrence.dart';
import '../../l10n/app_localizations.dart';

/// ISO weekdays in the order the user's locale starts the week.
List<int> localeWeekdays(BuildContext context) {
  // MaterialLocalizations: 0 = Sunday; ISO: 7 = Sunday.
  final first = MaterialLocalizations.of(context).firstDayOfWeekIndex;
  final firstIso = first == 0 ? DateTime.sunday : first;
  return [for (var i = 0; i < 7; i++) (firstIso - 1 + i) % 7 + 1];
}

/// Short localized weekday name ("Mon", "Mo.").
String weekdayShort(BuildContext context, int isoWeekday) {
  final locale = Localizations.localeOf(context).toString();
  // 2026-10-26 is a Monday.
  return DateFormat.E(locale).format(DateTime(2026, 10, 25 + isoWeekday));
}

/// Full localized weekday name ("Monday", "Montag").
String weekdayLong(BuildContext context, int isoWeekday) {
  final locale = Localizations.localeOf(context).toString();
  return DateFormat.EEEE(locale).format(DateTime(2026, 10, 25 + isoWeekday));
}

String formatDay(BuildContext context, DateTime day) =>
    DateFormat.yMMMd(Localizations.localeOf(context).toString()).format(day);

/// One-line description of a schedule, e.g. "Every 2 weeks on Mon, Thu".
String recurrenceSummary(BuildContext context, Recurrence r) {
  final l10n = AppLocalizations.of(context);
  switch (r.type) {
    case RepeatType.anytime:
      return l10n.summaryAnytime;
    case RepeatType.once:
      return l10n.summaryOnce(formatDay(context, r.start));
    case RepeatType.daily:
      return l10n.summaryDays(r.interval);
    case RepeatType.weekly:
      final days = [
        for (final d in localeWeekdays(context))
          if (r.weekdays.contains(d)) weekdayShort(context, d),
      ].join(', ');
      return l10n.summaryWeeks(r.interval, days);
    case RepeatType.monthly:
      final week = r.monthWeek;
      if (week != null && r.weekdays.length == 1) {
        return l10n.summaryMonthsWeekday(
          r.interval,
          l10n.monthWeekName(week == -1 ? 'last' : '$week'),
          weekdayLong(context, r.weekdays.first),
        );
      }
      return l10n.summaryMonths(r.interval, r.dayOfMonth ?? r.start.day);
    case RepeatType.afterDone:
      return l10n.summaryAfterDone(r.interval);
  }
}

/// Short due status for a tile: "2 days overdue", "Due today", "In 3 days".
String dueLabel(AppLocalizations l10n, DateTime? due, DateTime today) {
  if (due == null) return l10n.statusAnytime;
  final days = daysBetween(today, due);
  if (days < 0) return l10n.statusOverdue(-days);
  if (days == 0) return l10n.statusDueToday;
  if (days == 1) return l10n.statusTomorrow;
  return l10n.statusInDays(days);
}

/// A time of day ("18:00", "6:00 PM") in the device's format.
String formatMinutes(BuildContext context, int minutes) =>
    MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );

/// "18:00–20:00".
String formatTimes(BuildContext context, TimeWindow times) =>
    '${formatMinutes(context, times.from)}–${formatMinutes(context, times.to)}';

/// The status line for a quest tile, with its day window and times: "Due
/// until Tue, 10 Nov", "Today from 18:00", "Time's up (18:00–20:00)".
String questStatus(BuildContext context, ScheduledChore s) {
  final l10n = AppLocalizations.of(context);
  final locale = Localizations.localeOf(context).toString();
  final times = s.times;
  final due = s.due, end = s.windowEnd;
  if (due == null || end == null) return l10n.statusAnytime;
  if (s.isTimesUp) return l10n.statusTimesUp(formatTimes(context, times!));
  if (s.isOverdue) return l10n.statusOverdue(daysBetween(end, s.today));
  if (s.isLaterToday) {
    return l10n.statusTodayFrom(formatMinutes(context, times!.from));
  }
  if (s.isAgainTomorrow) {
    return l10n.statusAgainTomorrow(formatTimes(context, times!));
  }
  final String label;
  if (s.isDueToday) {
    label = end == s.today
        ? l10n.statusDueToday
        : l10n.statusDueUntil(DateFormat.MMMEd(locale).format(end));
  } else {
    label = dueLabel(l10n, due, s.today);
  }
  return times == null ? label : '$label · ${formatTimes(context, times)}';
}
