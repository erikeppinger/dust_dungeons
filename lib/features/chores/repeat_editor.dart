import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/dates.dart';
import '../../domain/recurrence.dart';
import '../../l10n/app_localizations.dart';
import 'schedule_text.dart';

/// Form section for a chore's schedule.
class RepeatEditor extends StatelessWidget {
  const RepeatEditor({
    super.key,
    required this.value,
    required this.today,
    required this.onChanged,
    this.showErrors = false,
  });

  final Recurrence value;
  final DateTime today;
  final ValueChanged<Recurrence> onChanged;

  /// Show validation errors (set after the first save attempt).
  final bool showErrors;

  static const maxInterval = 99;

  /// Whether [r] can be saved.
  static bool isValid(Recurrence r) =>
      (r.type != RepeatType.weekly || r.weekdays.isNotEmpty) &&
      (r.monthWeek == null || r.weekdays.length == 1);

  void _setType(RepeatType type) {
    if (type == value.type) return;
    // Sensible defaults for the new type, starting today.
    onChanged(
      Recurrence(
        type: type,
        interval: type == RepeatType.afterDone ? 7 : 1,
        weekdays: type == RepeatType.weekly ? {today.weekday} : const {},
        dayOfMonth: type == RepeatType.monthly ? today.day : null,
        start: today,
      ),
    );
  }

  Future<void> _pickStart(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: value.start,
      // The range must contain the stored start, which can be years old.
      firstDate: _earlier(value.start, DateTime(today.year - 1)),
      lastDate: _later(value.start, DateTime(today.year + 5)),
    );
    if (picked != null) onChanged(value.copyWith(start: dayOf(picked)));
  }

  static DateTime _earlier(DateTime a, DateTime b) => a.isBefore(b) ? a : b;
  static DateTime _later(DateTime a, DateTime b) => a.isAfter(b) ? a : b;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final labels = {
      RepeatType.anytime: l10n.repeatAnytime,
      RepeatType.once: l10n.repeatOnce,
      RepeatType.daily: l10n.repeatDaily,
      RepeatType.weekly: l10n.repeatWeekly,
      RepeatType.monthly: l10n.repeatMonthly,
      RepeatType.afterDone: l10n.repeatAfterDone,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.choreRepeat, style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        DropdownButtonFormField<RepeatType>(
          key: const ValueKey('repeat-type'),
          initialValue: value.type,
          isExpanded: true,
          decoration: const InputDecoration(border: OutlineInputBorder()),
          items: [
            for (final type in RepeatType.values)
              DropdownMenuItem(
                value: type,
                child: Text(labels[type]!, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: (type) {
            if (type != null) _setType(type);
          },
        ),
        if (value.type
            case RepeatType.daily ||
                RepeatType.weekly ||
                RepeatType.monthly ||
                RepeatType.afterDone)
          _IntervalRow(
            value: value.interval,
            label: switch (value.type) {
              RepeatType.weekly => l10n.unitWeeks(value.interval),
              RepeatType.monthly => l10n.unitMonths(value.interval),
              _ => l10n.unitDays(value.interval),
            },
            onChanged: (n) => onChanged(value.copyWith(interval: n)),
          ),
        if (value.type == RepeatType.weekly) ...[
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final day in localeWeekdays(context))
                FilterChip(
                  key: ValueKey('weekday-$day'),
                  label: Text(weekdayShort(context, day)),
                  selected: value.weekdays.contains(day),
                  onSelected: (on) => onChanged(
                    value.copyWith(
                      weekdays: on
                          ? {...value.weekdays, day}
                          : ({...value.weekdays}..remove(day)),
                    ),
                  ),
                ),
            ],
          ),
          if (showErrors && value.weekdays.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                l10n.weekdaysRequired,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
        ],
        if (value.type == RepeatType.monthly)
          _MonthlyMode(value: value, today: today, onChanged: onChanged),
        if (value.type == RepeatType.monthly && value.monthWeek == null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: DropdownButtonFormField<int>(
              initialValue: value.dayOfMonth ?? value.start.day,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: l10n.dayOfMonth,
                border: const OutlineInputBorder(),
              ),
              items: [
                for (var d = 1; d <= 31; d++)
                  DropdownMenuItem(value: d, child: Text('$d')),
              ],
              onChanged: (d) => onChanged(value.copyWith(dayOfMonth: () => d)),
            ),
          ),
        if (value.type != RepeatType.anytime)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event),
            title: Text(
              value.type == RepeatType.once
                  ? l10n.repeatDate
                  : value.type == RepeatType.afterDone
                  ? l10n.repeatFirstDue
                  : l10n.repeatStarts,
            ),
            subtitle: Text(formatDay(context, value.start)),
            onTap: () => _pickStart(context),
          ),
        if (value.type
            case RepeatType.daily ||
                RepeatType.weekly ||
                RepeatType.monthly ||
                RepeatType.afterDone)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: DropdownButtonFormField<int>(
              key: const ValueKey('window-days'),
              initialValue: value.windowDays,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: l10n.windowLabel,
                helperText: l10n.windowHelp,
                helperMaxLines: 3,
                border: const OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(value: 1, child: Text(l10n.windowOneDay)),
                for (var n = 2; n <= 7; n++)
                  DropdownMenuItem(value: n, child: Text(l10n.windowDays(n))),
                DropdownMenuItem(value: 0, child: Text(l10n.windowUntilNext)),
              ],
              onChanged: (n) {
                if (n != null) onChanged(value.copyWith(windowDays: n));
              },
            ),
          ),
        Text(
          recurrenceSummary(context, value),
          key: const ValueKey('repeat-summary'),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
        if (_example(context) case final example?)
          Text(
            example,
            key: const ValueKey('repeat-example'),
            style: theme.textTheme.bodySmall,
          ),
      ],
    );
  }

  /// The next dates, so the difference between the repeat types is visible:
  /// "Next: Thu 5 Nov, Sun 8 Nov, Wed 11 Nov".
  String? _example(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final format = DateFormat.MMMEd(Localizations.localeOf(context).toString());
    switch (value.type) {
      case RepeatType.anytime || RepeatType.once:
        return null;
      case RepeatType.afterDone:
        return l10n.repeatNextIfDone(
          format.format(addDays(today, value.interval)),
        );
      case RepeatType.daily || RepeatType.weekly || RepeatType.monthly:
        if (!isValid(value)) return null;
        final dates = <DateTime>[];
        var d = value.firstOnOrAfter(today);
        while (d != null && dates.length < 3) {
          dates.add(d);
          d = value.firstOnOrAfter(addDays(d, 1));
        }
        if (dates.isEmpty) return null;
        return l10n.repeatNextDates(dates.map(format.format).join(', '));
    }
  }
}

/// Monthly on a date ("on the 15th") or on a weekday ("on the 1st Monday").
class _MonthlyMode extends StatelessWidget {
  const _MonthlyMode({
    required this.value,
    required this.today,
    required this.onChanged,
  });

  final Recurrence value;
  final DateTime today;
  final ValueChanged<Recurrence> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final week = value.monthWeek;
    final weekday = value.weekdays.isEmpty
        ? today.weekday
        : value.weekdays.first;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SegmentedButton<bool>(
            key: const ValueKey('monthly-mode'),
            segments: [
              ButtonSegment(value: false, label: Text(l10n.monthlyOnDate)),
              ButtonSegment(value: true, label: Text(l10n.monthlyOnWeekday)),
            ],
            selected: {week != null},
            showSelectedIcon: false,
            onSelectionChanged: (s) {
              if (s.first) {
                // Today's place in the month (2nd Tuesday); a 5th becomes
                // the last.
                final nth = (today.day - 1) ~/ 7 + 1;
                onChanged(
                  value.copyWith(
                    monthWeek: () => nth > 4 ? -1 : nth,
                    weekdays: {today.weekday},
                  ),
                );
              } else {
                onChanged(
                  value.copyWith(monthWeek: () => null, weekdays: const {}),
                );
              }
            },
          ),
          if (week != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    key: const ValueKey('month-week'),
                    initialValue: week,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      for (final n in [1, 2, 3, 4, -1])
                        DropdownMenuItem(
                          value: n,
                          child: Text(
                            l10n.monthWeekName(n == -1 ? 'last' : '$n'),
                          ),
                        ),
                    ],
                    onChanged: (n) =>
                        onChanged(value.copyWith(monthWeek: () => n)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    key: const ValueKey('month-weekday'),
                    initialValue: weekday,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      for (final d in localeWeekdays(context))
                        DropdownMenuItem(
                          value: d,
                          child: Text(weekdayLong(context, d)),
                        ),
                    ],
                    onChanged: (d) {
                      if (d != null) onChanged(value.copyWith(weekdays: {d}));
                    },
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _IntervalRow extends StatelessWidget {
  const _IntervalRow({
    required this.value,
    required this.label,
    required this.onChanged,
  });

  final int value;
  final String label;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Text(l10n.repeatEvery),
        IconButton(
          tooltip: l10n.decrease,
          onPressed: value > 1 ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove_circle_outline),
        ),
        Text('$value', style: Theme.of(context).textTheme.titleMedium),
        IconButton(
          tooltip: l10n.increase,
          onPressed: value < RepeatEditor.maxInterval
              ? () => onChanged(value + 1)
              : null,
          icon: const Icon(Icons.add_circle_outline),
        ),
        Expanded(child: Text(label)),
      ],
    );
  }
}
