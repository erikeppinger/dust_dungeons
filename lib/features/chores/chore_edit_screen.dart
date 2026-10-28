import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/chore_palette.dart';
import '../../data/db/app_database.dart';
import '../../data/providers.dart';
import '../../domain/points.dart';
import '../../l10n/app_localizations.dart';
import 'chore_icons.dart';
import 'chore_tile.dart';
import 'chore_titles.dart';

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
    _title.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    final repo = ref.read(choreRepositoryProvider);
    final title = _title.text.trim();
    final chore = widget.chore;
    // Keep following the built-in (translated) title unless it was changed.
    final builtIn = chore == null
        ? null
        : builtInTitle(chore, AppLocalizations.of(context));
    await _run(
      () => chore == null
          ? repo.add(
              title: title,
              iconKey: _iconKey,
              colorKey: _colorKey,
              basePoints: _points,
            )
          : repo.update(
              chore.id,
              customTitle: title == builtIn ? null : title,
              iconKey: _iconKey,
              colorKey: _colorKey,
              basePoints: _points,
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
                  points: pointsForCompletion(basePoints: _points),
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
