import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/section_header.dart';
import '../../data/providers.dart';
import '../../domain/fight/items.dart';
import '../../domain/fight/shop.dart';
import '../../l10n/app_localizations.dart';
import '../fight/hero_art.dart';
import 'items_text.dart';
import '../../app/art/art.dart';
import '../../app/theme/pixel.dart';

/// The six gear slots: what's worn, and what else is in the bag for each.
class GearScreen extends ConsumerWidget {
  const GearScreen({super.key});

  static Future<void> open(BuildContext context) =>
      Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (_) => const GearScreen()));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final equipped = ref.watch(equippedProvider).value ?? const {};
    final owned = ref.watch(inventoryProvider).value ?? const {};
    bool has(ShopItem i) => (owned[i.key] ?? 0) > 0;
    final found = allGear.where(has).length;
    // Retired items count only for people who have them.
    final total = allGear.where((i) => !i.retired || has(i)).length;
    final curse = ref.watch(curseProvider);
    final person = ref.watch(currentProfileProvider);
    // The shield slot under a two-handed weapon.
    final twoHanded = shopItem(equipped[GearSlot.weapon] ?? '')?.twoHanded;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.gearTitle)),
      body: ListView(
        padding: EdgeInsets.only(
          bottom: 16 + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Text(l10n.gearIntro, style: theme.textTheme.bodyMedium),
          ),
          // The hero wearing it all: changes as soon as an item does.
          Center(
            child: HeroArt(
              key: const ValueKey('gear-hero'),
              skin: person.avatarSkin,
              hair: person.avatarHair,
              cape: person.avatarCape,
              hat: person.avatarHat,
              gear: equipped,
              size: 128,
            ),
          ),
          if (curse != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: CurseCard(curse: curse),
            ),
          SectionHeader(l10n.prepGear),
          for (final slot in GearSlot.values)
            Builder(
              builder: (context) {
                final item = shopItem(equipped[slot] ?? '');
                final blocked = slot == GearSlot.shield && twoHanded == true;
                final off =
                    curse?.kind == CurseKind.slotOff && curse?.slot == slot;
                return ListTile(
                  key: ValueKey('gear-${slot.name}'),
                  leading: item == null
                      ? const SizedBox.square(dimension: 32)
                      : ItemIcon(item),
                  title: Text(slotName(l10n, slot)),
                  subtitle: Text(
                    [
                      if (blocked)
                        l10n.gearTwoHanded
                      else if (item == null)
                        l10n.gearEmpty
                      else ...[
                        itemName(l10n, item),
                        itemDescription(l10n, item),
                      ],
                      if (off && item != null) curseEffect(l10n, curse!),
                    ].join(' · '),
                  ),
                  trailing: const PixelIcon(Sprites.uiChevronRight),
                  onTap: () => _pick(context, slot),
                );
              },
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Text(
              l10n.gearCollection(found, total),
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pick(BuildContext context, GearSlot slot) =>
      showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (context) => _SlotSheet(slot: slot),
      );
}

class _SlotSheet extends ConsumerWidget {
  const _SlotSheet({required this.slot});

  final GearSlot slot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final owned = ref.watch(inventoryProvider).value ?? const {};
    final worn = ref.watch(equippedProvider).value?[slot];
    final profile = ref.watch(currentProfileIdProvider);
    final shop = ref.watch(shopRepositoryProvider);
    final items = [
      for (final item in allGear)
        if (item.slot == slot && (owned[item.key] ?? 0) > 0) item,
    ];
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                slotName(l10n, slot),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Text(l10n.gearNothingOwned),
              ),
            for (final item in items)
              ListTile(
                key: ValueKey('wear-${item.key}'),
                leading: ItemIcon(item),
                title: Text(itemName(l10n, item)),
                subtitle: Text(itemDescription(l10n, item)),
                selected: worn == item.key,
                trailing: worn == item.key
                    ? Chip(
                        avatar: const PixelIcon(Sprites.uiCheck, size: 16),
                        label: Text(l10n.shopWorn),
                      )
                    : null,
                onTap: () async {
                  await shop.wear(profile, item);
                  if (context.mounted) Navigator.of(context).pop();
                },
              ),
            if (worn != null)
              ListTile(
                key: const ValueKey('gear-take-off'),
                leading: const PixelIcon(Sprites.uiRemoveCircle),
                title: Text(l10n.gearTakeOff),
                onTap: () async {
                  await shop.takeOff(profile, slot);
                  if (context.mounted) Navigator.of(context).pop();
                },
              ),
          ],
        ),
      ),
    );
  }
}

/// A waiting curse: its name, what it does, how to lift it, and soap if
/// there is some. Text and icon, never color alone.
class CurseCard extends ConsumerWidget {
  const CurseCard({super.key, required this.curse});

  final Curse curse;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final soap = ref.watch(inventoryProvider).value?[curseLiftItem.key] ?? 0;
    return Card(
      key: const ValueKey('curse'),
      color: theme.colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                PixelIcon(
                  Sprites.uiSad,
                  color: theme.colorScheme.onErrorContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.curseTitle(curseName(l10n, curse.family)),
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${curseEffect(l10n, curse)}. ${curseLift(l10n, curse)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
            if (soap > 0) ...[
              const SizedBox(height: 8),
              FilledButton.tonalIcon(
                key: const ValueKey('use-soap'),
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final lifted = await ref
                      .read(shopRepositoryProvider)
                      .useSoap(ref.read(currentProfileIdProvider));
                  if (lifted) {
                    messenger.showSnackBar(
                      SnackBar(content: Text(l10n.curseLifted)),
                    );
                  }
                },
                icon: const ItemIcon(curseLiftItem, size: 20),
                label: Text(l10n.curseUseSoap(soap)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
