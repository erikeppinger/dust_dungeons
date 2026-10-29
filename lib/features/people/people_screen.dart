import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/app_database.dart';
import '../../data/providers.dart';
import '../../domain/progress.dart';
import '../../l10n/app_localizations.dart';
import '../fight/hero_art.dart';
import '../settings/settings_controller.dart';

/// Everyone's level, by profile id (XP is the sum of their completions).
final peopleLevelsProvider = Provider<Map<int, int>>((ref) {
  final xp = <int, int>{};
  for (final c
      in ref.watch(householdCompletionsProvider).value ??
          const <Completion>[]) {
    xp[c.profileId] = (xp[c.profileId] ?? 0) + c.pointsAwarded;
  }
  return {
    for (final p in ref.watch(profilesProvider))
      p.id: levelForXp(xp[p.id] ?? 0),
  };
});

/// A person's hero, small.
class PersonAvatar extends StatelessWidget {
  const PersonAvatar(this.person, {super.key, this.size = 36});

  final Profile person;
  final double size;

  @override
  Widget build(BuildContext context) => HeroArt(
    skin: person.avatarSkin,
    hair: person.avatarHair,
    cape: person.avatarCape,
    hat: person.avatarHat,
    size: size,
  );
}

/// The current person's hero in the top bar: tap to switch person.
class PersonButton extends ConsumerWidget {
  const PersonButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final person = ref.watch(currentProfileProvider);
    return IconButton(
      key: const ValueKey('person-button'),
      tooltip: AppLocalizations.of(context).switchPerson(person.name),
      icon: PersonAvatar(person, size: 32),
      onPressed: () => showPersonSwitcher(context),
    );
  }
}

/// Everyone sharing the phone; picking one switches to them.
Future<void> showPersonSwitcher(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => const _Switcher(),
    );

class _Switcher extends ConsumerWidget {
  const _Switcher();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final people = ref.watch(profilesProvider);
    final current = ref.watch(currentProfileIdProvider);
    final levels = ref.watch(peopleLevelsProvider);
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final p in people)
              ListTile(
                key: ValueKey('switch-${p.id}'),
                leading: PersonAvatar(p),
                title: Text(p.name),
                subtitle: Text(l10n.levelValue(levels[p.id] ?? 1)),
                selected: p.id == current,
                trailing: p.id == current ? const Icon(Icons.check) : null,
                onTap: () {
                  unawaited(
                    ref.read(currentProfileIdProvider.notifier).select(p.id),
                  );
                  Navigator.of(context).pop();
                },
              ),
            const Divider(),
            ListTile(
              key: const ValueKey('manage-people'),
              leading: const Icon(Icons.group_outlined),
              title: Text(l10n.peopleManage),
              onTap: () {
                Navigator.of(context).pop();
                unawaited(PeopleScreen.open(context));
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Settings → People: add, rename and remove the people sharing the phone.
class PeopleScreen extends ConsumerWidget {
  const PeopleScreen({super.key});

  static Future<void> open(BuildContext context) =>
      Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (_) => const PeopleScreen()));

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final settings = ref.read(settingsProvider);
    final people = ref.read(profilesProvider);
    // Screen time is per phone: a second person turns it off.
    final turnsOffScreenTime = settings.screenTime && people.length == 1;
    final name = await _askName(
      context,
      ref,
      title: l10n.peopleAdd,
      note: turnsOffScreenTime ? l10n.peopleScreenTimeOff : null,
    );
    if (name == null) return;
    if (turnsOffScreenTime) {
      ref
          .read(settingsProvider.notifier)
          .update((s) => s.copyWith(screenTime: false));
    }
    await ref.read(profileRepositoryProvider).add(name: name);
  }

  Future<void> _rename(
    BuildContext context,
    WidgetRef ref,
    Profile person,
  ) async {
    final name = await _askName(
      context,
      ref,
      title: AppLocalizations.of(context).peopleRename,
      initial: person.name,
      exceptId: person.id,
    );
    if (name == null) return;
    await ref
        .read(profileRepositoryProvider)
        .update(person.id, ProfilesCompanion(name: Value(name)));
  }

  Future<void> _remove(
    BuildContext context,
    WidgetRef ref,
    Profile person,
  ) async {
    final l10n = AppLocalizations.of(context);
    final material = MaterialLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.peopleRemoveTitle(person.name)),
        content: Text(l10n.peopleRemoveBody(person.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(material.cancelButtonLabel),
          ),
          FilledButton(
            key: const ValueKey('remove-confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.peopleRemove),
          ),
        ],
      ),
    );
    if (ok ?? false) {
      await ref.read(profileRepositoryProvider).remove(person.id);
    }
  }

  /// A name that's not empty and not someone else's; `null` if cancelled.
  Future<String?> _askName(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    String initial = '',
    int? exceptId,
    String? note,
  }) => showDialog<String>(
    context: context,
    builder: (_) => _NameDialog(
      title: title,
      initial: initial,
      note: note,
      taken: (name) => ref
          .read(profileRepositoryProvider)
          .nameTaken(name, exceptId: exceptId),
    ),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final people = ref.watch(profilesProvider);
    final current = ref.watch(currentProfileIdProvider);
    final levels = ref.watch(peopleLevelsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.peopleTitle)),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'addPerson',
        onPressed: () => _add(context, ref),
        icon: const Icon(Icons.person_add_alt),
        label: Text(l10n.peopleAdd),
      ),
      body: ListView(
        padding: EdgeInsets.only(
          top: 8,
          bottom: 88 + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(l10n.peopleIntro),
          ),
          for (final p in people)
            ListTile(
              key: ValueKey('person-${p.id}'),
              leading: PersonAvatar(p),
              title: Text(p.name),
              subtitle: Text(l10n.levelValue(levels[p.id] ?? 1)),
              selected: p.id == current,
              onTap: () => _rename(context, ref, p),
              trailing: people.length > 1
                  ? IconButton(
                      key: ValueKey('remove-${p.id}'),
                      tooltip: l10n.peopleRemoveTitle(p.name),
                      icon: const Icon(Icons.person_remove_outlined),
                      onPressed: () => _remove(context, ref, p),
                    )
                  : null,
            ),
        ],
      ),
    );
  }
}

class _NameDialog extends StatefulWidget {
  const _NameDialog({
    required this.title,
    required this.initial,
    required this.taken,
    this.note,
  });

  final String title;
  final String initial;
  final String? note;
  final Future<bool> Function(String) taken;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final _controller = TextEditingController(text: widget.initial);
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final name = _controller.text.trim();
    if (name.isEmpty) {
      setState(() => _error = l10n.peopleNameEmpty);
      return;
    }
    if (await widget.taken(name)) {
      setState(() => _error = l10n.peopleNameTaken);
      return;
    }
    if (mounted) Navigator.of(context).pop(name);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final material = MaterialLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            key: const ValueKey('person-name'),
            controller: _controller,
            autofocus: true,
            maxLength: 24,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: l10n.peopleName,
              errorText: _error,
            ),
            onSubmitted: (_) => _save(),
          ),
          if (widget.note case final note?) ...[
            const SizedBox(height: 8),
            Text(note),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(material.cancelButtonLabel),
        ),
        FilledButton(
          key: const ValueKey('person-save'),
          onPressed: _save,
          child: Text(material.saveButtonLabel),
        ),
      ],
    );
  }
}
