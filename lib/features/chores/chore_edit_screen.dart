import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/chore_palette.dart';
import '../../data/db/app_database.dart';
import '../../core/day_clock.dart';
import '../../data/providers.dart';
import '../../domain/recurrence.dart';
import '../../domain/points.dart';
import '../../l10n/app_localizations.dart';
import 'chore_icons.dart';
import 'chore_tile.dart';
import 'chore_titles.dart';
import '../notifications/notification_settings.dart';
import '../settings/settings_controller.dart';
import '../../domain/fight/boss.dart';
import '../fight/boss_art.dart';
import 'repeat_editor.dart';

/// Add a new chore (`chore == null`) or edit/archive an existing one.
class ChoreEditScreen extends ConsumerStatefulWidget {
  const ChoreEditScreen({super.key, this.chore});

  final Chore? chore;

  static Future<void> open(BuildContext context, Chore? chore) =>
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => ChoreEditScreen(chore: chore)),
      );

  @override
  ConsumerState<ChoreEditScreen> createState() => _ChoreEditScreenState();
}

class _ChoreEditScreenState extends ConsumerState<ChoreEditScreen> {
  static const _pointsStep = 5;

  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  late String _iconKey;
  late int _colorKey;
  late int _points;
  late Recurrence _recurrence;

  /// Reminder time in minutes after midnight; `null` = no reminder.
  int? _reminderMinutes;
  late BossFamily _family;
  bool _showErrors = false;
  bool _initialized = false;
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Needs localizations for the built-in title, so not in initState.
    if (_initialized) return;
    _initialized = true;
    final chore = widget.chore;
    _title.text = chore == null
        ? ''
        : choreTitle(chore, AppLocalizations.of(context));
    _iconKey = chore?.iconKey ?? defaultIconKey;
    _colorKey = chore?.colorKey ?? 0;
    _points = (chore?.basePoints ?? 10).clamp(minBasePoints, maxBasePoints);
    _recurrence =
        chore?.recurrence ?? Recurrence.anytime(ref.read(todayProvider));
    _reminderMinutes = chore?.reminderMinutes;
    _family = chore?.family ?? BossFamily.clutter;
    _title.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final formValid = _formKey.currentState!.validate();
    if (!formValid || !RepeatEditor.isValid(_recurrence)) {
      setState(() => _showErrors = true);
      return;
    }
    final repo = ref.read(choreRepositoryProvider);
    final title = _title.text.trim();
    final chore = widget.chore;
    // Keep following the built-in (translated) title unless it was changed.
    final builtIn = chore == null
        ? null
        : builtInTitle(chore, AppLocalizations.of(context));
    // Reminders need due days; an unscheduled chore never has one.
    final reminder = _recurrence.type == RepeatType.anytime
        ? null
        : _reminderMinutes;
    // Store only a deviation from the default, so built-ins keep following
    // their default family.
    final family = _family == familyOfSeed(chore?.seedKey) ? null : _family;
    await _run(
      () => chore == null
          ? repo.add(
              title: title,
              iconKey: _iconKey,
              colorKey: _colorKey,
              basePoints: _points,
              recurrence: _recurrence,
              reminderMinutes: reminder,
              bossFamily: family,
            )
          : repo.update(
              chore.id,
              customTitle: title == builtIn ? null : title,
              iconKey: _iconKey,
              colorKey: _colorKey,
              basePoints: _points,
              recurrence: _recurrence,
              reminderMinutes: reminder,
              bossFamily: family,
            ),
    );
  }

  Future<void> _toggleArchived() {
    final chore = widget.chore!;
    return _run(
      () => ref
          .read(choreRepositoryProvider)
          .setArchived(chore.id, archived: !chore.isArchived),
    );
  }

  /// Runs a database write, closes the screen on success and shows an error
  /// (keeping the screen usable) on failure.
  Future<void> _run(Future<Object?> Function() write) async {
    setState(() => _saving = true);
    try {
      await write();
      if (mounted) Navigator.of(context).pop();
    } catch (error, stack) {
      FlutterError.reportError(
        FlutterErrorDetails(exception: error, stack: stack),
      );
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).errorGeneric)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final palette = theme.extension<ChorePalette>()!;
    final chore = widget.chore;

    return Scaffold(
      appBar: AppBar(
        title: Text(chore == null ? l10n.addChore : l10n.editChore),
        actions: [
          TextButton(onPressed: _saving ? null : _save, child: Text(l10n.save)),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          // Custom padding replaces the automatic system-bar inset; add it back
          // so the last row stays clear of the (edge-to-edge) navigation bar.
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            16 + MediaQuery.paddingOf(context).bottom,
          ),
          children: [
            Center(
              child: SizedBox(
                width: 180,
                height: 150,
                child: ChoreTile(
                  title: _title.text.trim().isEmpty ? '…' : _title.text.trim(),
                  iconKey: _iconKey,
                  colorKey: _colorKey,
                  points: basePointsOf(_points),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _title,
              decoration: InputDecoration(
                labelText: l10n.choreName,
                border: const OutlineInputBorder(),
              ),
              maxLength: 40,
              textCapitalization: TextCapitalization.sentences,
              autofocus: chore == null,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? l10n.choreNameRequired
                  : null,
            ),
            const SizedBox(height: 8),
            Text(l10n.chorePoints, style: theme.textTheme.titleSmall),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _points.toDouble(),
                    min: minBasePoints.toDouble(),
                    max: maxBasePoints.toDouble(),
                    divisions: (maxBasePoints - minBasePoints) ~/ _pointsStep,
                    label: '$_points',
                    onChanged: (v) => setState(() => _points = v.round()),
                  ),
                ),
                SizedBox(
                  width: 88,
                  child: Text(
                    l10n.pointsValue(_points),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            RepeatEditor(
              value: _recurrence,
              today: ref.watch(todayProvider),
              showErrors: _showErrors,
              onChanged: (r) => setState(() => _recurrence = r),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<BossFamily>(
              key: const ValueKey('boss-family'),
              initialValue: _family,
              decoration: InputDecoration(
                labelText: l10n.choreBoss,
                helperText: l10n.choreBossHelp,
                border: const OutlineInputBorder(),
              ),
              items: [
                for (final f in BossFamily.values)
                  DropdownMenuItem(
                    value: f,
                    child: Row(
                      children: [
                        BossArt(family: f, size: 28),
                        const SizedBox(width: 10),
                        Text(bossName(l10n, f)),
                      ],
                    ),
                  ),
              ],
              onChanged: (f) {
                if (f != null) setState(() => _family = f);
              },
            ),
            const SizedBox(height: 16),
            _ReminderEditor(
              minutes: _reminderMinutes,
              hasSchedule: _recurrence.type != RepeatType.anytime,
              onChanged: (m) => setState(() => _reminderMinutes = m),
            ),
            const SizedBox(height: 24),
            Text(l10n.choreColor, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < palette.colors.length; i++)
                  Semantics(
                    label: l10n.colorOption(i + 1),
                    selected: i == _colorKey,
                    button: true,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => setState(() => _colorKey = i),
                      child: CircleAvatar(
                        radius: 22,
                        backgroundColor: i == _colorKey
                            ? theme.colorScheme.onSurface
                            : Colors.transparent,
                        child: CircleAvatar(
                          radius: 19,
                          backgroundColor: palette.colorFor(i),
                          child: i == _colorKey
                              ? Icon(Icons.check, color: palette.onColorFor(i))
                              : null,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(l10n.choreIcon, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                for (final entry in choreIcons.entries)
                  IconButton(
                    key: ValueKey('icon-${entry.key}'),
                    isSelected: entry.key == _iconKey,
                    style: entry.key == _iconKey
                        ? IconButton.styleFrom(
                            backgroundColor: palette.colorFor(_colorKey),
                            foregroundColor: palette.onColorFor(_colorKey),
                          )
                        : null,
                    onPressed: () => setState(() => _iconKey = entry.key),
                    icon: Icon(entry.value),
                  ),
              ],
            ),
            if (chore != null) ...[
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: _saving ? null : _toggleArchived,
                icon: Icon(
                  chore.isArchived ? Icons.unarchive : Icons.archive_outlined,
                ),
                label: Text(chore.isArchived ? l10n.restore : l10n.archive),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Optional reminder time on the chore's due days.
class _ReminderEditor extends ConsumerWidget {
  const _ReminderEditor({
    required this.minutes,
    required this.hasSchedule,
    required this.onChanged,
  });

  static const _defaultMinutes = 9 * 60;

  final int? minutes;
  final bool hasSchedule;
  final ValueChanged<int?> onChanged;

  Future<void> _pick(BuildContext context) async {
    final m = minutes ?? _defaultMinutes;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: m ~/ 60, minute: m % 60),
    );
    if (picked != null) onChanged(picked.hour * 60 + picked.minute);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final notificationsOn = ref.watch(settingsProvider).notificationsEnabled;
    final m = minutes;
    String? hint;
    if (!hasSchedule) {
      hint = l10n.choreReminderNeedsSchedule;
    } else if (!notificationsOn) {
      hint = l10n.choreReminderNotificationsOff;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.choreReminder, style: theme.textTheme.titleSmall),
        SwitchListTile(
          key: const ValueKey('reminder-switch'),
          contentPadding: EdgeInsets.zero,
          secondary: const Icon(Icons.alarm),
          title: Text(l10n.choreReminderOn),
          value: hasSchedule && m != null,
          onChanged: hasSchedule
              ? (on) => onChanged(on ? _defaultMinutes : null)
              : null,
        ),
        if (hasSchedule && m != null)
          ListTile(
            key: const ValueKey('reminder-time'),
            contentPadding: EdgeInsets.zero,
            leading: const SizedBox(width: 24),
            title: Text(l10n.choreReminderAt(formatMinutes(context, m))),
            trailing: const Icon(Icons.schedule),
            onTap: () => _pick(context),
          ),
        if (hint != null) Text(hint, style: theme.textTheme.bodySmall),
      ],
    );
  }
}
