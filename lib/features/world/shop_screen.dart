import 'package:flutter/material.dart';

import '../../app/theme/pixel.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/section_header.dart';
import '../../data/providers.dart';
import '../../data/repositories/shop_repository.dart';
import '../../domain/fight/shop.dart';
import '../../l10n/app_localizations.dart';
import '../fight/hero_art.dart';
import '../screen_time/screen_time_providers.dart';

String itemName(AppLocalizations l10n, ShopItem item) => switch (item.key) {
  'sponge_shield' => l10n.itemShield,
  'turbo_mop' => l10n.itemMop,
  'metronome_charm' => l10n.itemCharm,
  'rubber_gloves' => l10n.itemGloves,
  'second_wind' => l10n.itemSecondWind,
  'screen_15' || 'screen_30' => l10n.itemScreenTime(voucherMinutes(item)),
  'hat_cap' => l10n.hatCap,
  'hat_bandana' => l10n.hatBandana,
  'hat_wizard' => l10n.hatWizard,
  'hat_crown' => l10n.hatCrown,
  _ => item.key,
};

String itemDescription(AppLocalizations l10n, ShopItem item) =>
    switch (item.key) {
      'sponge_shield' => l10n.itemShieldDesc,
      'turbo_mop' => l10n.itemMopDesc,
      'metronome_charm' => l10n.itemCharmDesc,
      'rubber_gloves' => l10n.itemGlovesDesc,
      'second_wind' => l10n.itemSecondWindDesc,
      'screen_15' || 'screen_30' => l10n.itemScreenTimeDesc,
      _ => l10n.hatDesc,
    };

IconData _icon(ShopItem item) => switch (item.key) {
  'sponge_shield' => Icons.shield_outlined,
  'turbo_mop' => Icons.cleaning_services,
  'metronome_charm' => Icons.av_timer,
  'rubber_gloves' => Icons.back_hand_outlined,
  'second_wind' => Icons.air,
  'screen_15' || 'screen_30' => Icons.hourglass_bottom,
  _ => Icons.checkroom,
};

/// Spend points on gear, consumables and hats. Spending never lowers XP.
class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key});

  static Future<void> open(BuildContext context) =>
      Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (_) => const ShopScreen()));

  Future<void> _buy(BuildContext context, WidgetRef ref, ShopItem item) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.shopConfirmTitle(itemName(l10n, item))),
        content: Text(l10n.shopConfirmBody(item.price)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.shopCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.shopBuyAction),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final result = await ref
        .read(shopRepositoryProvider)
        .buy(ref.read(currentProfileIdProvider), item);
    messenger.showSnackBar(
      SnackBar(
        content: Text(switch (result) {
          PurchaseResult.bought => l10n.shopBought(itemName(l10n, item)),
          PurchaseResult.notEnoughPoints => l10n.shopNotEnough,
          PurchaseResult.alreadyOwned => l10n.shopOwned,
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final balance = ref.watch(balanceProvider).value ?? 0;
    final owned = ref.watch(inventoryProvider).value ?? const {};
    final person = ref.watch(currentProfileProvider);

    Widget tile(ShopItem item, {Widget? leading}) {
      final count = owned[item.key] ?? 0;
      final ownedOnce = item.kind != ItemKind.consumable && count > 0;
      return ListTile(
        key: ValueKey('shop-${item.key}'),
        leading: leading ?? Icon(_icon(item)),
        title: Text(itemName(l10n, item)),
        subtitle: Text(
          item.kind == ItemKind.consumable && count > 0
              ? '${itemDescription(l10n, item)} · ${l10n.shopInStock(count)}'
              : itemDescription(l10n, item),
        ),
        trailing: ownedOnce
            ? Chip(
                avatar: const Icon(Icons.check, size: 16),
                label: Text(l10n.shopOwned),
              )
            : FilledButton.tonal(
                onPressed: balance >= item.price
                    ? () => _buy(context, ref, item)
                    : null,
                child: Text(l10n.shopPrice(item.price)),
              ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.shopTitle)),
      body: ListView(
        padding: EdgeInsets.only(
          bottom: 16 + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                const PixelCoin(),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.shopBalance(balance),
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Text(l10n.shopXpNote, style: theme.textTheme.bodySmall),
          ),
          SectionHeader(l10n.shopGear),
          for (final item in shopItems.where((i) => i.kind == ItemKind.gear))
            tile(item),
          SectionHeader(l10n.shopConsumables),
          for (final item in shopItems.where(
            (i) => i.kind == ItemKind.consumable && !screenVouchers.contains(i),
          ))
            tile(item),
          if (ref.watch(screenTimeActiveProvider)) ...[
            SectionHeader(l10n.settingsScreenTime),
            for (final item in screenVouchers) tile(item),
          ],
          SectionHeader(l10n.shopHats),
          for (final (i, item) in hats.indexed)
            tile(
              item,
              leading: HeroArt(
                skin: person.avatarSkin,
                hair: person.avatarHair,
                cape: person.avatarCape,
                hat: i + 1,
                size: 36,
              ),
            ),
        ],
      ),
    );
  }
}
