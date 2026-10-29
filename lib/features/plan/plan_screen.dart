import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/theme/chore_palette.dart';
import '../../core/day_clock.dart';
import '../../core/widgets/section_header.dart';
import '../../data/db/app_database.dart';
import '../../data/models/scheduled_chore.dart';
import '../../data/providers.dart';
import '../../domain/dates.dart';
import '../../domain/points.dart';
import '../../l10n/app_localizations.dart';
import '../chores/chore_edit_screen.dart';
import '../chores/chore_icons.dart';
import '../chores/chore_titles.dart';
import '../chores/schedule_text.dart';
import 'plan_data.dart';

enum _PlanView { week, month }

/// Week list and month calendar of due and completed chores.
class PlanScreen extends ConsumerStatefulWidget {
  const PlanScreen({super.key});

  @override
  ConsumerState<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends ConsumerState<PlanScreen> {
  var _view = _PlanView.week;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheduled = ref.watch(scheduledChoresProvider);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: SegmentedButton<_PlanView>(
            segments: [
              ButtonSegment(
                value: _PlanView.week,
                icon: const Icon(Icons.view_week),
                label: Text(l10n.planWeek),
              ),
              ButtonSegment(
                value: _PlanView.month,
                icon: const Icon(Icons.calendar_month),
                label: Text(l10n.planMonth),
              ),
            ],
            selected: {_view},
            onSelectionChanged: (s) => setState(() => _view = s.first),
          ),
        ),
        Expanded(
          child: scheduled.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => Center(child: Text(l10n.errorGeneric)),
            data: (list) => switch (_view) {
              _PlanView.week => _WeekView(list),
              _PlanView.month => _MonthView(list),
            },
          ),
        ),
      ],
    );
  }
}

/// Today (overdue + due + done) and the next six days.
class _WeekView extends ConsumerWidget {
  const _WeekView(this.chores);

  final List<ScheduledChore> chores;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayProvider);
    final plan = PlanData(chores, today: today, to: addDays(today, 6));
    return ListView(
      padding: EdgeInsets.only(
        bottom: 16 + MediaQuery.paddingOf(context).bottom,
      ),
      children: [
        for (var i = 0; i < 7; i++) ...[
          SectionHeader(dayTitle(context, addDays(today, i), today)),
          ..._dayEntries(context, plan, addDays(today, i), today, const []),
        ],
      ],
    );
  }
}

/// Calendar grid for one month with done/due counts; tap a day for details.
class _MonthView extends ConsumerStatefulWidget {
  const _MonthView(this.chores);

  final List<ScheduledChore> chores;

  @override
  ConsumerState<_MonthView> createState() => _MonthViewState();
}

class _MonthViewState extends ConsumerState<_MonthView> {
  late DateTime _month = DateTime(
    ref.read(todayProvider).year,
    ref.read(todayProvider).month,
  );
  late DateTime _selected = ref.read(todayProvider);

  void _shiftMonth(int delta) => setState(() {
    _month = DateTime(_month.year, _month.month + delta);
    final today = ref.read(todayProvider);
    _selected = _month.year == today.year && _month.month == today.month
        ? today
        : _month;
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final today = ref.watch(todayProvider);
    // At midnight, move a selection that was on "today" along with it.
    ref.listen(todayProvider, (previous, next) {
      if (previous != null && _selected == previous) {
        setState(() {
          _selected = next;
          _month = DateTime(next.year, next.month);
        });
      }
    });
    final monthEnd = DateTime(_month.year, _month.month + 1);
    final completions =
        ref.watch(completionsBetweenProvider((_month, monthEnd))).value ??
        const <Completion>[];
    final plan = PlanData(
      widget.chores,
      today: today,
      to: addDays(monthEnd, -1),
      allChores: ref.watch(allChoresProvider).value ?? const [],
    );
    final doneByDay = <DateTime, List<Completion>>{};
    for (final c in completions) {
      (doneByDay[dayOf(c.completedAt)] ??= []).add(c);
    }

    // Grid starts on the locale's first weekday.
    final weekdays = localeWeekdays(context);
    final leading = (_month.weekday - weekdays.first + 7) % 7;
    final gridStart = addDays(_month, -leading);
    final cellCount =
        ((leading + daysInMonth(_month.year, _month.month) + 6) ~/ 7) * 7;

    return ListView(
      padding: EdgeInsets.only(
        bottom: 16 + MediaQuery.paddingOf(context).bottom,
      ),
      children: [
        Row(
          children: [
            IconButton(
              tooltip: l10n.previousMonth,
              onPressed: () => _shiftMonth(-1),
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Text(
                DateFormat.yMMMM(locale).format(_month),
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
            ),
            IconButton(
              tooltip: l10n.nextMonth,
              onPressed: () => _shiftMonth(1),
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            children: [
              Row(
                children: [
                  for (final d in weekdays)
                    Expanded(
                      child: Center(
                        child: Text(
                          weekdayShort(context, d),
                          style: theme.textTheme.labelSmall,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              for (var row = 0; row < cellCount ~/ 7; row++)
                Row(
                  children: [
                    for (final day in [
                      for (var col = 0; col < 7; col++)
                        addDays(gridStart, row * 7 + col),
                    ])
                      Expanded(
                        child: _DayCell(
                          day: day,
                          inMonth: day.month == _month.month,
                          today: today,
                          selected: day == _selected,
                          done: doneByDay[day]?.length ?? 0,
                          due: plan.openCountOn(day),
                          onTap: () => setState(() => _selected = day),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
        SectionHeader(dayTitle(context, _selected, today)),
        ..._dayEntries(
          context,
          plan,
          _selected,
          today,
          doneByDay[_selected] ?? const [],
        ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.inMonth,
    required this.today,
    required this.selected,
    required this.done,
    required this.due,
    required this.onTap,
  });

  final DateTime day;
  final bool inMonth;
  final DateTime today;
  final bool selected;
  final int done;
  final int due;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final isToday = day == today;
    final locale = Localizations.localeOf(context).toString();
    return Semantics(
      button: true,
      selected: selected,
      label:
          '${DateFormat.MMMMd(locale).format(day)}: '
          '${l10n.planDueCount(due)}, ${l10n.planDoneCount(done)}',
      excludeSemantics: true,
      child: InkWell(
        key: ValueKey('day-${day.year}-${day.month}-${day.day}'),
        borderRadius: BorderRadius.zero,
        onTap: onTap,
        child: Container(
          height: 56,
          margin: const EdgeInsets.all(1),
          decoration: BoxDecoration(
            color: selected ? scheme.primaryContainer : null,
            border: isToday
                ? Border.all(color: scheme.primary, width: 2)
                : null,
            borderRadius: BorderRadius.zero,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${day.day}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: inMonth ? null : theme.disabledColor,
                  fontWeight: isToday ? FontWeight.bold : null,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (done > 0) ...[
                    Icon(Icons.check, size: 12, color: scheme.tertiary),
                    Text('$done', style: theme.textTheme.labelSmall),
                  ],
                  if (done > 0 && due > 0) const SizedBox(width: 3),
                  if (due > 0) ...[
                    Icon(Icons.circle, size: 7, color: scheme.secondary),
                    const SizedBox(width: 1),
                    Text('$due', style: theme.textTheme.labelSmall),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Today", "Tomorrow" or a formatted weekday + date.
String dayTitle(BuildContext context, DateTime day, DateTime today) {
  final l10n = AppLocalizations.of(context);
  final diff = daysBetween(today, day);
  if (diff == 0) return l10n.planToday;
  if (diff == 1) return l10n.planTomorrow;
  return DateFormat.MMMEd(Localizations.localeOf(context).toString())
      .format(day);
}

/// List rows for one day: done (past/today), overdue + due (today) or
/// planned (future).
List<Widget> _dayEntries(
  BuildContext context,
  PlanData plan,
  DateTime day,
  DateTime today,
  List<Completion> doneThatDay,
) {
  final l10n = AppLocalizations.of(context);
  final rows = <Widget>[];
  if (day == today) {
    for (final s in [...plan.overdue, ...plan.dueToday]) {
      rows.add(
        _ChoreRow(
          chore: s.chore,
          trailing: dueLabel(l10n, s.due, today),
          overdue: s.isOverdue,
        ),
      );
    }
    for (final s in plan.doneToday) {
      rows.add(_ChoreRow(chore: s.chore, done: true));
    }
  } else if (day.isAfter(today)) {
    for (final s in plan.dueOn(day)) {
      rows.add(_ChoreRow(chore: s.chore));
    }
  } else {
    for (final c in doneThatDay) {
      final chore = plan.choreById(c.choreId);
      if (chore != null) {
        rows.add(_ChoreRow(chore: chore, done: true));
      }
    }
  }
  if (rows.isEmpty) {
    rows.add(
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Text(
          l10n.planNothing,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );
  }
  return rows;
}

class _ChoreRow extends StatelessWidget {
  const _ChoreRow({
    required this.chore,
    this.trailing,
    this.overdue = false,
    this.done = false,
  });

  final Chore chore;
  final String? trailing;
  final bool overdue;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final palette = theme.extension<ChorePalette>()!;
    return ListTile(
      dense: true,
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: palette.colorFor(chore.colorKey),
        child: Icon(
          choreIcon(chore.iconKey),
          size: 20,
          color: palette.onColorFor(chore.colorKey),
        ),
      ),
      title: Text(
        choreTitle(chore, l10n),
        style: done
            ? const TextStyle(decoration: TextDecoration.lineThrough)
            : null,
      ),
      subtitle: Text(l10n.pointsValue(basePointsOf(chore.basePoints))),
      trailing: done
          ? Tooltip(
              message: l10n.planDone,
              child: Icon(
                Icons.check_circle,
                color: theme.colorScheme.tertiary,
              ),
            )
          : trailing == null
          ? null
          : Text(
              trailing!,
              style: TextStyle(
                color: overdue ? theme.colorScheme.error : null,
                fontWeight: overdue ? FontWeight.bold : null,
              ),
            ),
      onTap: () => ChoreEditScreen.open(context, chore),
    );
  }
}
