import 'package:flutter/widgets.dart';

import '../../app/art/art.dart';

import '../../data/models/scheduled_chore.dart';
import '../../domain/dates.dart';
import '../../domain/points.dart';
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
}

/// One quest as the home screen widgets show it.
@immutable
class WidgetQuest {
  const WidgetQuest({
    required this.title,
    required this.icon,
    required this.colorKey,
    required this.status,
    required this.points,
    this.lateDays = 0,
    this.atMinutes,
    this.day,
  });

  final String title;
  final Sprite icon;
  final int colorKey;
  final WidgetStatus status;
  final int points;

  /// Days overdue, for [WidgetStatus.late] (0 = time's up today).
  final int lateDays;

  /// Start time for [WidgetStatus.at].
  final int? atMinutes;

  /// The due day for [WidgetStatus.upcoming].
  final DateTime? day;

  @override
  bool operator ==(Object other) =>
      other is WidgetQuest &&
      other.title == title &&
      other.icon == icon &&
      other.colorKey == colorKey &&
      other.status == status &&
      other.points == points &&
      other.lateDays == lateDays &&
      other.atMinutes == atMinutes &&
      other.day == day;

  @override
  int get hashCode => Object.hash(
    title,
    icon,
    colorKey,
    status,
    points,
    lateDays,
    atMinutes,
    day,
  );
}

/// The quests a widget shows on the day [offset] days after [today]: late
/// ones first, then open, then later today, then the next due ones, at
/// most [max]. Days after today are a projection, for when the app isn't
/// opened (assuming nothing gets done meanwhile).
List<WidgetQuest> widgetQuests({
  required List<ScheduledChore> chores,
  required DateTime today,
  required AppLocalizations l10n,
  int offset = 0,
  int max = 8,
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
    title: choreTitle(s.chore, l10n),
    icon: choreIcon(s.chore.iconKey),
    colorKey: s.chore.colorKey,
    status: status,
    points: basePointsOf(s.chore.basePoints),
    lateDays: lateDays,
    atMinutes: s.times?.from,
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
  return result.take(max).toList();
}
