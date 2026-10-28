import 'package:flutter/material.dart';

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
      r.type != RepeatType.weekly || r.weekdays.isNotEmpty;

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
        Text(
          recurrenceSummary(context, value),
          key: const ValueKey('repeat-summary'),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
      ],
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
