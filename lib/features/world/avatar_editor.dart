import 'package:flutter/material.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../data/db/app_database.dart';
import '../../data/providers.dart';
import '../../domain/fight/shop.dart';
import '../fight/hero_art.dart';
import 'shop_screen.dart';

/// Choose the hero's look. Changes apply (and are saved) immediately.
class AvatarEditor extends ConsumerWidget {
  const AvatarEditor({super.key});

  static Future<void> open(BuildContext context) =>
      Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (_) => const AvatarEditor()));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    // The current person's hero.
    final s = ref.watch(currentProfileProvider);
    final owned = ref.watch(inventoryProvider).value ?? const {};
    void set(ProfilesCompanion look) =>
        ref.read(profileRepositoryProvider).update(s.id, look);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.avatarTitle)),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          16 + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          Center(
            child: HeroArt(
              skin: s.avatarSkin,
              hair: s.avatarHair,
              cape: s.avatarCape,
              hat: s.avatarHat,
              size: 160,
            ),
          ),
          _Swatches(
            title: l10n.avatarSkin,
            keyPrefix: 'skin',
            colors: avatarSkins,
            selected: s.avatarSkin,
            onSelect: (i) => set(ProfilesCompanion(avatarSkin: Value(i))),
          ),
          _Swatches(
            title: l10n.avatarHair,
            keyPrefix: 'hair',
            colors: avatarHair,
            selected: s.avatarHair,
            onSelect: (i) => set(ProfilesCompanion(avatarHair: Value(i))),
          ),
          _Swatches(
            title: l10n.avatarCape,
            keyPrefix: 'cape',
            colors: avatarCapes,
            selected: s.avatarCape,
            onSelect: (i) => set(ProfilesCompanion(avatarCape: Value(i))),
          ),
          const SizedBox(height: 20),
          Text(l10n.avatarHat, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                key: const ValueKey('hat-0'),
                label: Text(l10n.avatarNoHat),
                selected: s.avatarHat == 0,
                onSelected: (_) =>
                    set(const ProfilesCompanion(avatarHat: Value(0))),
              ),
              for (final (i, hat) in hats.indexed)
                if ((owned[hat.key] ?? 0) > 0)
                  ChoiceChip(
                    key: ValueKey('hat-${i + 1}'),
                    avatar: HeroArt(
                      skin: s.avatarSkin,
                      hair: s.avatarHair,
                      cape: s.avatarCape,
                      hat: i + 1,
                      size: 22,
                    ),
                    label: Text(itemName(l10n, hat)),
                    selected: s.avatarHat == i + 1,
                    onSelected: (_) =>
                        set(ProfilesCompanion(avatarHat: Value(i + 1))),
                  )
                else
                  ActionChip(
                    key: ValueKey('hat-${i + 1}'),
                    avatar: const Icon(Icons.lock_outline, size: 18),
                    label: Text(itemName(l10n, hat)),
                    onPressed: () => ShopScreen.open(context),
                  ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            l10n.avatarMoreHats,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _Swatches extends StatelessWidget {
  const _Swatches({
    required this.title,
    required this.keyPrefix,
    required this.colors,
    required this.selected,
    required this.onSelect,
  });

  final String title;
  final String keyPrefix;
  final List<Color> colors;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(title, style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < colors.length; i++)
              Semantics(
                label: '$title: ${l10n.avatarOption(i + 1)}',
                selected: i == selected,
                button: true,
                child: InkWell(
                  key: ValueKey('$keyPrefix-$i'),
                  customBorder: const CircleBorder(),
                  onTap: () => onSelect(i),
                  child: CircleAvatar(
                    radius: 24,
                    backgroundColor: i == selected
                        ? theme.colorScheme.onSurface
                        : Colors.transparent,
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: colors[i],
                      // Selection is marked by a check, not only a ring.
                      child: i == selected
                          ? Icon(
                              Icons.check,
                              color:
                                  ThemeData.estimateBrightnessForColor(
                                        colors[i],
                                      ) ==
                                      Brightness.dark
                                  ? Colors.white
                                  : Colors.black,
                            )
                          : null,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
