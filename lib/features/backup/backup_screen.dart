import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/widgets/section_header.dart';
import '../../data/backup/backup_file.dart';
import '../../data/backup/merge.dart';
import '../../l10n/app_localizations.dart';
import 'backups.dart';

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

  void _say(String text) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));

  /// Runs [work] with the buttons disabled; failures become a message.
  Future<void> _run(Future<void> Function() work) async {
    if (_busy) return;
    setState(() => _busy = true);
    final l10n = AppLocalizations.of(context);
    try {
      await work();
    } on BackupException catch (e) {
      _say(switch (e.problem) {
        BackupProblem.notABackup => l10n.backupNotABackup,
        BackupProblem.tooNew => l10n.backupTooNew,
      });
    } catch (error, stack) {
      FlutterError.reportError(
        FlutterErrorDetails(exception: error, stack: stack),
      );
      _say(l10n.backupFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _export() => _run(() async {
    final l10n = AppLocalizations.of(context);
    if (await _backups.export()) _say(l10n.backupExported);
  });

  Future<void> _import() async {
    PendingImport? pending;
    await _run(() async => pending = await _backups.open());
    final opened = pending;
    if (opened == null || !mounted) return;
    // Not busy while the user reads the preview.
    final useSettings = await showDialog<bool>(
      context: context,
      builder: (_) => _ImportDialog(pending: opened),
    );
    if (useSettings == null || !mounted) {
      await opened.cancel();
      return;
    }
    await _run(() async {
      final l10n = AppLocalizations.of(context);
      await opened.confirm(useSettings: useSettings);
      _say(l10n.backupImported);
    });
  }

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
            leading: const Icon(Icons.save_alt),
            title: Text(l10n.backupExport),
            subtitle: Text(l10n.backupExportSubtitle),
            enabled: enabled,
            onTap: _export,
          ),
          ListTile(
            key: const ValueKey('backup-import'),
            leading: const Icon(Icons.file_open_outlined),
            title: Text(l10n.backupImport),
            subtitle: Text(l10n.backupImportSubtitle),
            enabled: enabled,
            onTap: _import,
          ),
          if (canUndo)
            ListTile(
              key: const ValueKey('backup-undo'),
              leading: const Icon(Icons.undo),
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
            icon: const Icon(Icons.folder_open),
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
          leading: Icon(
            lost || failed ? Icons.warning_amber : Icons.folder_outlined,
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

/// Shows what an import would add; pops the "use settings" choice, or
/// `null` for cancel.
class _ImportDialog extends StatefulWidget {
  const _ImportDialog({required this.pending});

  final PendingImport pending;

  @override
  State<_ImportDialog> createState() => _ImportDialogState();
}

class _ImportDialogState extends State<_ImportDialog> {
  // On a new phone the backup's settings are what the user expects back.
  late var _useSettings = !widget.pending.hasHistory;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final material = MaterialLocalizations.of(context);
    final MergeReport r = widget.pending.report;
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
            CheckboxListTile(
              key: const ValueKey('backup-use-settings'),
              contentPadding: EdgeInsets.zero,
              value: _useSettings,
              onChanged: (v) => setState(() => _useSettings = v ?? false),
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
          onPressed: () => Navigator.of(context).pop(_useSettings),
          child: Text(l10n.backupImportConfirm),
        ),
      ],
    );
  }
}
