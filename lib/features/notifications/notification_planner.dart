import 'package:flutter/foundation.dart';

import '../../data/db/app_database.dart';
import '../../data/models/app_settings.dart';
import '../../data/models/scheduled_chore.dart';
import '../../domain/dates.dart';
import '../../domain/points.dart';
import '../../l10n/app_localizations.dart';
import '../chores/chore_titles.dart';

/// Which screen a notification opens when tapped.
enum NotificationTarget { today, stats }

/// Android notification channel (users can mute each one separately).
enum NotificationChannel { summary, reminder, recap }

/// One notification to schedule. Everything is decided up front because the
/// app is not running when it fires; the plan is rebuilt on every change
/// (completion, edit, settings, new day), so the content stays current.
@immutable
class PlannedNotification {
  const PlannedNotification({
    required this.id,
    required this.when,
    required this.channel,
    required this.title,
    required this.body,
    required this.target,
  });

  final int id;
  final DateTime when;
  final NotificationChannel channel;
  final String title;
  final String body;
  final NotificationTarget target;

  @override
  bool operator ==(Object other) =>
      other is PlannedNotification &&
      other.id == id &&
      other.when == when &&
      other.channel == channel &&
      other.title == title &&
      other.body == body &&
      other.target == target;

  @override
  int get hashCode => Object.hash(id, when, channel, title, body, target);

  @override
  String toString() => 'PlannedNotification($id, $when, $title: $body)';
}

/// How far ahead notifications are scheduled. The plan is refreshed whenever
/// the app is used, so a week is plenty and keeps well below Android's limit
/// of 500 alarms per app.
const planDays = 7;

/// Upper bound for per-chore reminders in one plan.
const maxChoreReminders = 60;

const weeklyRecapWeekday = DateTime.sunday;
const weeklyRecapMinutes = 18 * 60;
const monthlyRecapMinutes = 10 * 60;

/// Builds all notifications from [now] on for the next [planDays] days.
List<PlannedNotification> planNotifications({
  required DateTime now,
  required AppSettings settings,
  required List<ScheduledChore> chores,
  required List<Completion> completions,
  required AppLocalizations l10n,

  /// Yesterday's screen time (used, budget) for today's summary.
  (int, int)? screenYesterday,

  /// Names by profile id when several people share the phone: their own
  /// chores are named, as in "Trash (Sam)".
  Map<int, String> people = const {},
}) {
  String titleOf(ScheduledChore c) {
    final title = choreTitle(c.chore, l10n);
    final who = c.person == null ? null : people[c.person];
    return who == null ? title : l10n.notifChoreOf(title, who);
  }

  if (!settings.notificationsEnabled) return const [];
  final today = dayOf(now);
  final lastDay = addDays(today, planDays - 1);
  final result = <PlannedNotification>[];
  var nextId = 1;
  void add(
    DateTime when,
    NotificationChannel channel,
    String title,
    String body,
    NotificationTarget target,
  ) {
    if (!when.isAfter(now)) return;
    result.add(
      PlannedNotification(
        id: nextId++,
        when: when,
        channel: channel,
        title: title,
        body: body,
        target: target,
      ),
    );
  }

  // Which chores are open on each day: currently overdue ones stay open until
  // done; the rest are open on their (projected) due days.
  // A window counts as open on each of its days (assuming it isn't done).
  final overdue = chores.where((c) => c.isOverdue).toList();
  final dueByDay = <DateTime, List<ScheduledChore>>{};
  void open(ScheduledChore c, DateTime from) {
    final end = c.recurrence.windowEnd(from);
    for (var day = from; !day.isAfter(end); day = addDays(day, 1)) {
      if (day.isBefore(today) || day.isAfter(lastDay)) continue;
      final list = dueByDay[day] ??= [];
      if (!list.contains(c)) list.add(c);
    }
  }

  for (final c in chores) {
    if (c.isOverdue) continue;
    if (c.isDueToday) open(c, c.due!);
    for (final day in c.upcomingDueDays(lastDay)) {
      open(c, day);
    }
  }

  for (var d = 0; d < planDays; d++) {
    final day = addDays(today, d);
    final due = dueByDay[day] ?? const [];

    if (settings.dailySummary) {
      final open = [...overdue, ...due];
      if (open.isNotEmpty) {
        final names = open.take(3).map(titleOf);
        final list = open.length > 3
            ? '${names.join(', ')}, …'
            : names.join(', ');
        final screen = d == 0 && settings.screenTime && settings.screenSummary
            ? screenYesterday
            : null;
        final body = overdue.isEmpty
            ? list
            : '${l10n.notifOverdueCount(overdue.length)} · $list';
        add(
          _at(day, settings.dailySummaryMinutes),
          NotificationChannel.summary,
          l10n.notifSummaryTitle(open.length),
          screen == null
              ? body
              : '$body\n${l10n.notifScreenYesterday(screen.$1, screen.$2)}',
          NotificationTarget.today,
        );
      }
    }
  }

  if (settings.choreReminders) {
    var reminders = 0;
    for (var d = 0; d < planDays && reminders < maxChoreReminders; d++) {
      final day = addDays(today, d);
      for (final c in [...overdue, ...?dueByDay[day]]) {
        final minutes = c.chore.reminderMinutes;
        if (minutes == null || reminders >= maxChoreReminders) continue;
        final before = result.length;
        add(
          _at(day, minutes),
          NotificationChannel.reminder,
          titleOf(c),
          c.isOverdue
              ? l10n.notifReminderOverdue(basePointsOf(c.chore.basePoints))
              : l10n.notifReminderDue(basePointsOf(c.chore.basePoints)),
          NotificationTarget.today,
        );
        if (result.length > before) reminders++;
      }
    }
  }

  if (settings.weeklyRecap) {
    // The coming recap day (today if it is still ahead), covering Mon–Sun.
    var day = today;
    while (day.weekday != weeklyRecapWeekday) {
      day = addDays(day, 1);
    }
    if (!_at(day, weeklyRecapMinutes).isAfter(now)) day = addDays(day, 7);
    final weekStart = weekStartOf(day);
    final week = completions.where(
      (c) => !dayOf(c.completedAt).isBefore(weekStart),
    );
    // No streak here: it would be computed now but shown days later, when
    // it may already be broken. Counts stay correct if nothing else is done.
    add(
      _at(day, weeklyRecapMinutes),
      NotificationChannel.recap,
      l10n.notifWeeklyTitle,
      l10n.notifWeeklyBody(
        week.length,
        week.fold(0, (sum, c) => sum + c.pointsAwarded),
      ),
      NotificationTarget.stats,
    );
  }

  if (settings.monthlyRecap) {
    // On the 1st, about the month before. Normally that is next month's 1st;
    // on the 1st itself before the recap time it is still today's recap.
    final todaysRecap = _at(
      DateTime(today.year, today.month),
      monthlyRecapMinutes,
    );
    final recapDay = todaysRecap.isAfter(now)
        ? DateTime(today.year, today.month)
        : DateTime(today.year, today.month + 1);
    final monthStart = DateTime(recapDay.year, recapDay.month - 1);
    final month = completions.where((c) {
      final day = dayOf(c.completedAt);
      return !day.isBefore(monthStart) && day.isBefore(recapDay);
    });
    add(
      _at(recapDay, monthlyRecapMinutes),
      NotificationChannel.recap,
      l10n.notifMonthlyTitle,
      l10n.notifMonthlyBody(
        month.length,
        month.fold(0, (sum, c) => sum + c.pointsAwarded),
      ),
      NotificationTarget.stats,
    );
  }

  return result;
}

DateTime _at(DateTime day, int minutes) =>
    DateTime(day.year, day.month, day.day, minutes ~/ 60, minutes % 60);
