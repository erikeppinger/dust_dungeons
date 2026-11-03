import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/section_header.dart';
import '../../data/providers.dart';
import '../../domain/fight/boss.dart';
import '../../domain/fight/items.dart';
import '../../domain/fight/shop.dart';
import '../../domain/screen_time.dart';
import '../../l10n/app_localizations.dart';
import '../screen_time/screen_time_providers.dart';
import '../world/gear_screen.dart';
import '../world/items_text.dart';
import 'boss_art.dart';
import 'fight_screen.dart';
import 'fight_settings.dart';
import '../../app/art/art.dart';
import '../../app/theme/pixel.dart';

/// Before a fight: the gear worn, a waiting curse, consumables to pick and
/// which owned items are good against this boss.
class FightPrepScreen extends ConsumerStatefulWidget {
  const FightPrepScreen({
    super.key,
    required this.family,
    required this.tier,
    this.motifs = const [],
  });

  final BossFamily family;
  final int tier;

  /// For the Overlord: the bosses beaten this week.
  final List<BossFamily> motifs;

  static bool _opening = false;

  /// Opens the screen. A second call while one is opening or open is
  /// ignored, so a double tap opens one.
  static Future<void> open(
    BuildContext context,
    BossFamily family,
    int tier, {
    List<BossFamily> motifs = const [],
  }) async {
    if (_opening) return;
    _opening = true;
    try {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              FightPrepScreen(family: family, tier: tier, motifs: motifs),
        ),
      );
    } finally {
      _opening = false;
    }
  }

  @override
  ConsumerState<FightPrepScreen> createState() => _FightPrepScreenState();
}

class _FightPrepScreenState extends ConsumerState<FightPrepScreen> {
  final _picked = <ShopItem>{};
  bool _starting = false;

  /// Spends the picked consumables and starts the fight. Guarded so a double
  /// tap can't start (and pay for) two.
  Future<void> _start(Loadout gear) async {
    if (_starting) return;
    _starting = true;
    final shop = ref.read(shopRepositoryProvider);
    final profile = ref.read(currentProfileIdProvider);
    final used = [
      for (final item in preFightConsumables)
        if (_picked.contains(item) && await shop.use(profile, item)) item,
    ];
    if (!mounted) return;
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => FightScreen(
          family: widget.family,
          tier: widget.tier,
          loadout: Loadout(
            gear: gear.gear,
            consumables: used,
            curse: gear.curse,
          ),
          motifs: widget.motifs,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final family = widget.family;
    final gear = ref.watch(gearLoadoutProvider);
    final owned = ref.watch(inventoryProvider).value ?? const {};
    final level = ref.watch(progressStatsProvider).value?.level ?? 1;
    final base = HeroStats.forLevel(level);
    final effects = Loadout(
      gear: gear.gear,
      consumables: [..._picked],
      curse: gear.curse,
    ).against(family);
    final hearts = heartsWith(
      tiredMaxHp(base.maxHp, tired: ref.watch(tiredProvider)),
      effects,
    );
    final strong = [
      for (final item in allGear)
        if ((owned[item.key] ?? 0) > 0 && strongAgainst(item, family)) item,
    ];
    final worn = gear.gear.values.toSet();

    return Scaffold(
      appBar: AppBar(title: Text(bossName(l10n, family))),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          12,
          8,
          12,
          16 + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          Row(
            children: [
              BossArt(family: family, size: 96),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${l10n.worldTier(widget.tier)} · '
                      '${difficultyName(l10n, ref.watch(currentProfileProvider).difficulty)}',
                      key: const ValueKey('prep-tier'),
                      style: theme.textTheme.titleMedium,
                    ),
                    Text(
                      l10n.worldHeroStats(hearts, base.damage),
                      key: const ValueKey('prep-stats'),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (gear.curse case final curse?) ...[
            const SizedBox(height: 8),
            CurseCard(curse: curse),
          ],
          SectionHeader(l10n.prepGear),
          if (gear.gear.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(l10n.prepNoGear),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final MapEntry(key: slot, value: item)
                    in gear.gear.entries)
                  Tooltip(
                    message: slotName(l10n, slot),
                    child: Chip(
                      avatar: ItemIcon(item, size: 20),
                      label: Text(
                        gear.working.contains(item)
                            ? itemName(l10n, item)
                            : '${itemName(l10n, item)} · '
                                  '${curseEffect(l10n, gear.curse!)}',
                      ),
                    ),
                  ),
              ],
            ),
          for (final item in strong)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  const PixelIcon(Sprites.uiStar, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      worn.contains(item)
                          ? l10n.prepStrong(itemName(l10n, item))
                          : l10n.prepStrongInBag(itemName(l10n, item)),
                    ),
                  ),
                ],
              ),
            ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: () => GearScreen.open(context),
              icon: const PixelIcon(Sprites.uiBackpack),
              label: Text(l10n.prepChangeGear),
            ),
          ),
          if (preFightConsumables.any((i) => (owned[i.key] ?? 0) > 0)) ...[
            SectionHeader(l10n.prepExtras),
            for (final item in preFightConsumables)
              if ((owned[item.key] ?? 0) > 0)
                CheckboxListTile(
                  key: ValueKey('prep-${item.key}'),
                  value: _picked.contains(item),
                  onChanged: (on) => setState(
                    () => on == true ? _picked.add(item) : _picked.remove(item),
                  ),
                  secondary: ItemIcon(item),
                  title: Text(
                    l10n.prepInStock(itemName(l10n, item), owned[item.key]!),
                  ),
                  subtitle: Text(itemDescription(l10n, item)),
                ),
          ],
          const SizedBox(height: 16),
          FilledButton(
            key: const ValueKey('prep-fight'),
            onPressed: () => _start(gear),
            child: Text(l10n.prepFight),
          ),
        ],
      ),
    );
  }
}
