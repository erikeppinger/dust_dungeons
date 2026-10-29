import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/chore_palette.dart';
import '../../core/widgets/section_header.dart';
import '../../data/db/app_database.dart';
import '../../data/providers.dart';
import '../../domain/points.dart';
import '../../l10n/app_localizations.dart';
import 'chore_edit_screen.dart';
import 'chore_icons.dart';
import 'chore_titles.dart';
import 'schedule_text.dart';

/// All chores, active and archived, for editing and archiving.
class ManageChoresScreen extends ConsumerWidget {
  const ManageChoresScreen({super.key});

  static Future<void> open(BuildContext context) => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => const ManageChoresScreen()));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final chores = ref.watch(allChoresProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.manageChores)),
      body: chores.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(child: Text(l10n.errorGeneric)),
        data: (list) {
          final active = list.where((c) => !c.isArchived).toList();
          final archived = list.where((c) => c.isArchived).toList();
          return ListView(
            // Room for the FAB plus the edge-to-edge navigation bar.
            padding: EdgeInsets.only(
              bottom: 88 + MediaQuery.paddingOf(context).bottom,
            ),
            children: [
              SectionHeader('${l10n.activeChores} (${active.length})'),
              for (final c in active) _ChoreRow(c),
              if (archived.isNotEmpty) ...[
                SectionHeader('${l10n.archivedChores} (${archived.length})'),
                for (final c in archived) _ChoreRow(c),
              ],
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'addChoreManage',
        onPressed: () => ChoreEditScreen.open(context, null),
        icon: const Icon(Icons.add),
        label: Text(l10n.addChore),
      ),
    );
  }
}

class _ChoreRow extends ConsumerWidget {
  const _ChoreRow(this.chore);

  final Chore chore;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final palette = Theme.of(context).extension<ChorePalette>()!;
    final title = choreTitle(chore, l10n);
    // Who it's for, with several people sharing the phone.
    final people = ref.watch(profilesProvider);
    final assigned = ref.watch(choreAssigneesProvider).value?[chore.id] ?? {};
    final names = [
      for (final p in people)
        if (assigned.contains(p.id)) p.name,
    ];
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: palette.colorFor(chore.colorKey),
        child: Icon(
          choreIcon(chore.iconKey),
          color: palette.onColorFor(chore.colorKey),
        ),
      ),
      title: Text(title),
      subtitle: Text(
        [
          l10n.pointsValue(basePointsOf(chore.basePoints)),
          recurrenceSummary(context, chore.recurrence),
          if (people.length > 1)
            chore.assignment == Assignment.anyone || names.isEmpty
                ? l10n.assignAnyone
                : names.join(', '),
        ].join(' · '),
      ),
      onTap: () => ChoreEditScreen.open(context, chore),
      trailing: IconButton(
        tooltip: chore.isArchived ? l10n.restore : l10n.archive,
        icon: Icon(chore.isArchived ? Icons.unarchive : Icons.archive_outlined),
        onPressed: () => unawaited(
          ref
              .read(choreRepositoryProvider)
              .setArchived(chore.id, archived: !chore.isArchived),
        ),
      ),
    );
  }
}
