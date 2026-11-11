import 'package:flutter/widgets.dart';

import '../../app/art/art.dart';

import '../../data/models/scheduled_chore.dart';
import '../../domain/dates.dart';
import '../../domain/points.dart';
import '../../domain/recurrence.dart';
import '../../l10n/app_localizations.dart';
import '../chores/chore_icons.dart';
import '../chores/chore_titles.dart';
import '../plan/plan_data.dart';

/// Where a quest stands, for the widget's badge.
enum WidgetStatus {
  /// Overdue (or its time is up today).
  late,

  /// Open now.
  now,

  /// Open today, at a time of day ([WidgetQuest.atMinutes]).
  at,

  /// Due on a later day ([WidgetQuest.day]).
  upcoming,

  /// No schedule: can be done whenever. Only in the list of all quests.
  anytime,
}

/// One quest as the home screen widgets show it.
@immutable
class WidgetQuest {
  const WidgetQuest({
    required this.choreId,
    required this.title,
    required this.icon,
    required this.colorKey,
    required this.status,
    required this.points,
    this.lateDays = 0,
    this.atMinutes,
    this.untilMinutes,
    this.day,
  });

  final int choreId;
  final String title;
  final Sprite icon;
  final int colorKey;
  final WidgetStatus status;
  final int points;

  /// Days overdue, for [WidgetStatus.late] (0 = time's up today).
  final int lateDays;

  /// Start time for [WidgetStatus.at].
  final int? atMinutes;

  /// End of its time of day, if it has one.
  final int? untilMinutes;

  /// Can be ticked off in the list widget: everything that is open now.
  bool get canTick => status != WidgetStatus.upcoming;

  /// Due today (not late, not just "anytime"): done within its time of
  /// day, if any, it earns the on-time bonus.
  bool get dueToday => status == WidgetStatus.now || status == WidgetStatus.at;

  /// The due day for [WidgetStatus.upcoming].
  final DateTime? day;

  @override
  bool operator ==(Object other) =>
      other is WidgetQuest &&
      other.choreId == choreId &&
      other.title == title &&
      other.icon == icon &&
      other.colorKey == colorKey &&
      other.status == status &&
      other.points == points &&
      other.lateDays == lateDays &&
      other.atMinutes == atMinutes &&
      other.untilMinutes == untilMinutes &&
      other.day == day;

  @override
  int get hashCode => Object.hash(
    choreId,
    title,
    icon,
    colorKey,
    status,
    points,
    lateDays,
    atMinutes,
    untilMinutes,
    day,
  );
}

/// The quests a widget shows on the day [offset] days after [today]: late
/// ones first, then open, then later today, then the next due ones, at
/// most [max]. Days after today are a projection, for when the app isn't
/// opened (assuming nothing gets done meanwhile).
///
/// With [all], every active quest follows, without a limit: those due after
/// this week at their next day (within [allQuestsDays]), then the ones
/// without a schedule.
List<WidgetQuest> widgetQuests({
  required List<ScheduledChore> chores,
  required DateTime today,
  required AppLocalizations l10n,
  int offset = 0,
  int max = 8,
  bool all = false,
}) {
  final day = addDays(today, offset);
  final horizon = addDays(today, 6);
  final plan = PlanData(chores, today: today, to: horizon);
  WidgetQuest quest(
    ScheduledChore s,
    WidgetStatus status, {
    int lateDays = 0,
    DateTime? on,
  }) => WidgetQuest(
    choreId: s.chore.id,
    title: choreTitle(s.chore, l10n),
    icon: choreIcon(s.chore.iconKey),
    colorKey: s.chore.colorKey,
    status: status,
    points: basePointsOf(s.chore.basePoints),
    lateDays: lateDays,
    atMinutes: s.times?.from,
    untilMinutes: s.times?.to,
    day: on,
  );

  final result = <WidgetQuest>[
    for (final s in plan.overdue)
      quest(
        s,
        WidgetStatus.late,
        lateDays: s.isTimesUp && offset == 0
            ? 0
            : daysBetween(s.windowEnd!, today) + offset,
      ),
  ];
  final seen = {for (final s in plan.overdue) s};
  final open = offset == 0
      ? [...plan.dueToday, ...plan.laterToday]
      : [...plan.dueOn(day), ...plan.continuingOn(day)];
  for (final s in open) {
    if (!seen.add(s)) continue;
    final timed = s.times != null && (offset > 0 || s.isLaterToday);
    result.add(quest(s, timed ? WidgetStatus.at : WidgetStatus.now));
  }
  // Coming up: each quest once, at its next due day.
  for (var d = addDays(day, 1); !d.isAfter(horizon); d = addDays(d, 1)) {
    for (final s in plan.dueOn(d)) {
      if (seen.add(s)) result.add(quest(s, WidgetStatus.upcoming, on: d));
    }
  }
  if (!all) return result.take(max).toList();
  final far = addDays(today, allQuestsDays);
  final later = <(DateTime, ScheduledChore)>[];
  final anytime = <ScheduledChore>[];
  for (final s in chores) {
    if (seen.contains(s)) continue;
    final next = s
        .upcomingDueDays(far)
        .where((d) => d.isAfter(horizon))
        .firstOrNull;
    if (next != null) {
      later.add((next, s));
    } else if (s.recurrence.type == RepeatType.anytime) {
      anytime.add(s);
    }
  }
  later.sort((a, b) => a.$1.compareTo(b.$1));
  return [
    ...result,
    for (final (d, s) in later) quest(s, WidgetStatus.upcoming, on: d),
    for (final s in anytime) quest(s, WidgetStatus.anytime),
  ];
}

/// How far ahead the list of all quests looks for a quest's next day.
const allQuestsDays = 366;
