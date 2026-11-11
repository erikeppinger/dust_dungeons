import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/widgets/section_header.dart';
import '../../data/backup/backup_file.dart';
import '../../data/backup/merge.dart';
import '../../data/db/app_database.dart' show Profile;
import '../../l10n/app_localizations.dart';
import 'backups.dart';
import '../../app/art/art.dart';
import '../../app/theme/pixel.dart';

void _sayIn(BuildContext context, String text) => ScaffoldMessenger.of(context)
  ..hideCurrentSnackBar()
  ..showSnackBar(SnackBar(content: Text(text)));

/// Runs a backup action; failures become a message.
Future<void> runBackupAction(
  BuildContext context,
  Future<void> Function() work,
) async {
  final l10n = AppLocalizations.of(context);
  try {
    await work();
  } on BackupException catch (e) {
    if (!context.mounted) return;
    _sayIn(context, switch (e.problem) {
      BackupProblem.notABackup => l10n.backupNotABackup,
      BackupProblem.tooNew => l10n.backupTooNew,
    });
  } catch (error, stack) {
    FlutterError.reportError(
      FlutterErrorDetails(exception: error, stack: stack),
    );
    if (context.mounted) _sayIn(context, l10n.backupFailed);
  }
}

/// Lets the user pick a backup, shows what importing it would change and
/// imports it; `true` if it was imported. [run] wraps the two steps that
/// take time (it may disable buttons meanwhile) and must report failures,
/// like [runBackupAction].
Future<bool> importBackup(
  BuildContext context,
  WidgetRef ref, {
  Future<void> Function(Future<void> Function() work)? run,
}) async {
  final backups = ref.read(backupsProvider);
  final l10n = AppLocalizations.of(context);
  run ??= (work) => runBackupAction(context, work);
  PendingImport? pending;
  await run(() async => pending = await backups.open());
  final opened = pending;
  if (opened == null) return false;
  if (!context.mounted) {
    await opened.cancel();
    return false;
  }
  final choice = await showDialog<_ImportChoice>(
    context: context,
    builder: (_) => _ImportDialog(pending: opened),
  );
  if (choice == null || !context.mounted) {
    await opened.cancel();
    return false;
  }
  var imported = false;
  await run(() async {
    await opened.confirm(useSettings: choice.useSettings, isMe: choice.isMe);
    imported = true;
    if (context.mounted) _sayIn(context, l10n.backupImported);
  });
  return imported;
}

/// Settings → Backup: save and import backup files, undo an import, and the
/// folder for daily automatic backups. See docs/design/data-safety.md.
class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  static Future<void> open(BuildContext context) =>
      Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (_) => const BackupScreen()));

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  /// A backup action is running: buttons wait for it.
  var _busy = false;

  Backups get _backups => ref.read(backupsProvider);

  void _say(String text) => _sayIn(context, text);

  /// Runs [work] with the buttons disabled; failures become a message.
  Future<void> _run(Future<void> Function() work) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await runBackupAction(context, work);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _export() => _run(() async {
    final l10n = AppLocalizations.of(context);
    if (await _backups.export()) _say(l10n.backupExported);
  });

  // Not busy while the user reads the preview.
  Future<void> _import() => importBackup(context, ref, run: _run);

  Future<void> _undo() => _run(() async {
    final l10n = AppLocalizations.of(context);
    await _backups.undoImport();
    _say(l10n.backupUndone);
  });

  Future<void> _chooseFolder() => _run(() async {
    try {
      if (!await _backups.chooseFolder()) return;
    } catch (_) {
      // The folder is kept; its first backup failed.
      ref.read(autoBackupErrorProvider.notifier).set(true);
      rethrow;
    }
    ref.read(autoBackupErrorProvider.notifier).set(false);
  });

  Future<void> _backUpNow() => _run(() async {
    final l10n = AppLocalizations.of(context);
    try {
      await _backups.autoBackup(force: true);
    } catch (_) {
      ref.read(autoBackupErrorProvider.notifier).set(true);
      rethrow;
    }
    ref.read(autoBackupErrorProvider.notifier).set(false);
    _say(l10n.backupExported);
  });

  Future<void> _stop() => _run(_backups.stopAutoBackups);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final canUndo = ref.watch(undoImportAvailableProvider).value ?? false;
    final enabled = !_busy;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsBackup)),
      body: ListView(
        padding: EdgeInsets.only(
          bottom: 16 + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          if (_busy) const LinearProgressIndicator(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(l10n.backupIntro, style: theme.textTheme.bodyMedium),
          ),
          ListTile(
            key: const ValueKey('backup-export'),
            leading: const PixelIcon(Sprites.uiDownload),
            title: Text(l10n.backupExport),
            subtitle: Text(l10n.backupExportSubtitle),
            enabled: enabled,
            onTap: _export,
          ),
          ListTile(
            key: const ValueKey('backup-import'),
            leading: const PixelIcon(Sprites.uiFileOpen),
            title: Text(l10n.backupImport),
            subtitle: Text(l10n.backupImportSubtitle),
            enabled: enabled,
            onTap: _import,
          ),
          if (canUndo)
            ListTile(
              key: const ValueKey('backup-undo'),
              leading: const PixelIcon(Sprites.uiUndo),
              title: Text(l10n.backupUndo),
              subtitle: Text(l10n.backupUndoSubtitle),
              enabled: enabled,
              onTap: _undo,
            ),
          SectionHeader(l10n.backupAuto),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              l10n.backupAutoIntro,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          _AutoBackup(
            enabled: enabled,
            onChoose: _chooseFolder,
            onNow: _backUpNow,
            onStop: _stop,
          ),
        ],
      ),
    );
  }
}

class _AutoBackup extends ConsumerWidget {
  const _AutoBackup({
    required this.enabled,
    required this.onChoose,
    required this.onNow,
    required this.onStop,
  });

  final bool enabled;
  final VoidCallback onChoose, onNow, onStop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final state = ref.watch(backupStateProvider).value;
    final folder = state?.folder;
    if (folder == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: FilledButton.icon(
            key: const ValueKey('backup-choose-folder'),
            onPressed: enabled ? onChoose : null,
            icon: const PixelIcon(Sprites.uiFolderOpen),
            label: Text(l10n.backupChooseFolder),
          ),
        ),
      );
    }
    final name = ref.watch(backupFolderNameProvider);
    final lost = name.hasValue && name.value == null;
    final failed = ref.watch(autoBackupErrorProvider);
    final last = state?.lastAuto;
    final locale = Localizations.localeOf(context).toString();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          leading: PixelIcon(
            lost || failed ? Sprites.uiWarning : Sprites.uiFolder,
            color: lost || failed ? scheme.error : null,
          ),
          title: Text(
            lost ? l10n.backupFolderLost : l10n.backupFolder(name.value ?? '…'),
          ),
          subtitle: Text(
            [
              last == null
                  ? l10n.backupNever
                  : l10n.backupLast(
                      DateFormat.yMMMd(locale).add_Hm().format(last),
                    ),
              if (failed && !lost) l10n.backupAutoFailed,
            ].join('\n'),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (!lost)
                FilledButton(
                  key: const ValueKey('backup-now'),
                  onPressed: enabled ? onNow : null,
                  child: Text(l10n.backupNow),
                ),
              OutlinedButton(
                key: const ValueKey('backup-change-folder'),
                onPressed: enabled ? onChoose : null,
                child: Text(
                  lost ? l10n.backupChooseFolder : l10n.backupChangeFolder,
                ),
              ),
              TextButton(
                key: const ValueKey('backup-stop'),
                onPressed: enabled ? onStop : null,
                child: Text(l10n.backupStop),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// What the user chose in the import preview.
typedef _ImportChoice = ({bool useSettings, Profile? isMe});

/// Shows what an import would add and asks how; pops the choices, or `null`
/// for cancel.
class _ImportDialog extends StatefulWidget {
  const _ImportDialog({required this.pending});

  final PendingImport pending;

  @override
  State<_ImportDialog> createState() => _ImportDialogState();
}

class _ImportDialogState extends State<_ImportDialog> {
  // On a new phone the backup's settings are what the user expects back.
  late var _useSettings = !widget.pending.hasHistory;

  /// The person in the backup who is the one using the app here.
  late Profile? _isMe = widget.pending.suggestedMe;
  late MergeReport _report = widget.pending.report;

  /// Counts the preview again for the current choices.
  Future<void> _refresh() async {
    final useSettings = _useSettings;
    final isMe = _isMe;
    final report = await widget.pending.preview(
      useSettings: useSettings,
      isMe: isMe,
    );
    // A later choice has its own count on the way.
    if (!mounted || useSettings != _useSettings || isMe != _isMe) return;
    setState(() => _report = report);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final material = MaterialLocalizations.of(context);
    final MergeReport r = _report;
    final me = widget.pending.me;
    final lines = [
      if (r.chores > 0) l10n.backupCountChores(r.chores),
      if (r.completions > 0) l10n.backupCountCompletions(r.completions),
      if (r.fights > 0) l10n.backupCountFights(r.fights),
      if (r.profiles > 0) l10n.backupCountPeople(r.profiles),
      if (r.ledger +
              r.inventory +
              r.equipped +
              r.screenDays +
              r.undone +
              r.assignees >
          0)
        l10n.backupPreviewMore,
    ];
    return AlertDialog(
      title: Text(l10n.backupPreviewTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (lines.isEmpty)
              Text(l10n.backupPreviewNothing)
            else ...[
              Text(l10n.backupPreviewAdds),
              const SizedBox(height: 4),
              for (final line in lines) Text('• $line'),
              const SizedBox(height: 12),
              Text(l10n.backupPreviewKeeps),
            ],
            if (me != null) ...[
              const SizedBox(height: 12),
              Text(l10n.backupMeQuestion(me.name)),
              RadioGroup<int>(
                groupValue: _isMe?.id ?? 0,
                onChanged: (id) {
                  setState(
                    () => _isMe = widget.pending.newPeople
                        .where((p) => p.id == id)
                        .firstOrNull,
                  );
                  unawaited(_refresh());
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final p in widget.pending.newPeople)
                      RadioListTile<int>(
                        key: ValueKey('backup-me-${p.name}'),
                        contentPadding: EdgeInsets.zero,
                        value: p.id,
                        title: Text(l10n.backupMeYes(p.name)),
                      ),
                    RadioListTile<int>(
                      key: const ValueKey('backup-me-none'),
                      contentPadding: EdgeInsets.zero,
                      value: 0,
                      title: Text(l10n.backupMeNo),
                    ),
                  ],
                ),
              ),
              if (_isMe != null)
                Text(
                  l10n.backupMeHint,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
            CheckboxListTile(
              key: const ValueKey('backup-use-settings'),
              contentPadding: EdgeInsets.zero,
              value: _useSettings,
              onChanged: (v) {
                setState(() => _useSettings = v ?? false);
                unawaited(_refresh());
              },
              title: Text(l10n.backupUseSettings),
              subtitle: Text(l10n.backupUseSettingsHint),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(material.cancelButtonLabel),
        ),
        FilledButton(
          key: const ValueKey('backup-import-confirm'),
          onPressed: () =>
              Navigator.of(context)
                  .pop<_ImportChoice>((useSettings: _useSettings, isMe: _isMe)),
          child: Text(l10n.backupImportConfirm),
        ),
      ],
    );
  }
}
