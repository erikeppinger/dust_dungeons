import 'dart:async';

import '../../app/theme/pixel.dart';

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/day_clock.dart';
import '../../core/widgets/section_header.dart';
import '../../data/db/app_database.dart';
import '../../data/providers.dart';
import '../../domain/dates.dart';
import '../../domain/fight/shop.dart';
import '../../domain/screen_time.dart';
import '../../l10n/app_localizations.dart';
import '../settings/settings_controller.dart';
import 'screen_time_providers.dart';
import 'screen_time_service.dart';

/// Apps with a launcher icon, loaded once for names and icons.
final launcherAppsProvider = FutureProvider<List<LauncherApp>>(
  (ref) => ref.watch(screenTimeServiceProvider).launcherApps(),
);

/// The soft screen-time budget: today's budget and use, vouchers, the last
/// 7 days and the settings. Shows an introduction while it is off.
class ScreenTimeScreen extends ConsumerWidget {
  const ScreenTimeScreen({super.key});

  static Future<void> open(BuildContext context) => Navigator.of(context)
      .push(MaterialPageRoute<void>(builder: (_) => const ScreenTimeScreen()));

  Future<void> _enable(WidgetRef ref) async {
    ref
        .read(settingsProvider.notifier)
        .update((s) => s.copyWith(screenTime: true));
    final service = ref.read(screenTimeServiceProvider);
    if (!await service.hasAccess()) await service.openAccessSettings();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final today = ref.watch(screenTodayProvider).value;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsScreenTime)),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          8,
          16,
          16 + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          if (!ref.watch(screenTimeActiveProvider)) ...[
            Text(l10n.screenIntro, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 12),
            Text(l10n.screenEarnRule(pointsPerScreenMinute)),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lock_outline, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(child: Text(l10n.screenPrivacy)),
              ],
            ),
            const SizedBox(height: 20),
            // Usage is per phone: with several people it stays off.
            if (ref.watch(profilesProvider).length > 1) ...[
              Text(l10n.screenOnePersonOnly),
              const SizedBox(height: 8),
            ],
            FilledButton(
              onPressed: ref.watch(profilesProvider).length > 1
                  ? null
                  : () => _enable(ref),
              child: Text(l10n.screenEnable),
            ),
          ] else ...[
            if (today != null && !today.access) const _AccessCard(),
            if (today != null) _TodayCard(today: today),
            if (today != null && today.access) ...[
              SectionHeader(l10n.screenUsedToday),
              _PerApp(today: today),
              SectionHeader(l10n.statsLast7Days),
              const _History(),
            ],
            SectionHeader(l10n.screenSettings),
            const _Settings(),
          ],
        ],
      ),
    );
  }
}

class _AccessCard extends ConsumerWidget {
  const _AccessCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.screenAccessMissing,
              style: TextStyle(color: scheme.onErrorContainer),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () =>
                  ref.read(screenTimeServiceProvider).openAccessSettings(),
              child: Text(l10n.screenGrantAccess),
            ),
          ],
        ),
      ),
    );
  }
}

class _TodayCard extends ConsumerWidget {
  const _TodayCard({required this.today});

  final ScreenToday today;

  Future<void> _useVoucher(
    BuildContext context,
    WidgetRef ref,
    ShopItem voucher,
  ) async {
    final used = await ref
        .read(screenTimeRepositoryProvider)
        .useVoucher(
          ref.read(currentProfileIdProvider),
          voucher,
          ref.read(todayProvider),
        );
    if (used) ref.invalidate(screenTodayProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    final owned = ref.watch(inventoryProvider).value ?? const {};
    final b = today.budget;
    final scheme = theme.colorScheme;
    Widget part(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: theme.textTheme.titleSmall),
        ],
      ),
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 84,
                  height: 84,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox.expand(
                        child: CircularProgressIndicator(
                          value: b.total == 0
                              ? 1
                              : (b.used / b.total).clamp(0, 1),
                          strokeWidth: 9,
                          color: b.over || b.low ? scheme.error : null,
                          // The track shows the budget even with nothing used.
                          backgroundColor: scheme.surfaceContainerHighest,
                          semanticsLabel: l10n.screenUsedOf(b.used, b.total),
                        ),
                      ),
                      Text(
                        '${b.left.abs()}',
                        style: theme.textTheme.titleLarge,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        b.over
                            ? l10n.screenOverBy(b.left.abs())
                            : l10n.screenLeft(b.left),
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(l10n.screenUsedOf(b.used, b.total)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            part(l10n.screenBase, l10n.screenMinutes(b.base)),
            part(
              l10n.screenQuests(settings.screenEarnCap),
              '+${l10n.screenMinutes(b.earned)}',
            ),
            if (b.vouchers > 0)
              part(l10n.screenVouchers, '+${l10n.screenMinutes(b.vouchers)}'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final voucher in screenVouchers)
                  if ((owned[voucher.key] ?? 0) > 0)
                    OutlinedButton.icon(
                      key: ValueKey('use-${voucher.key}'),
                      onPressed: () => _useVoucher(context, ref, voucher),
                      icon: const Icon(Icons.hourglass_bottom),
                      label: Text(
                        l10n.screenUseVoucher(
                          voucher.minutes,
                          owned[voucher.key]!,
                        ),
                      ),
                    ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PerApp extends ConsumerWidget {
  const _PerApp({required this.today});

  final ScreenToday today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final apps = {
      for (final a
          in ref.watch(launcherAppsProvider).value ?? const <LauncherApp>[])
        a.package: a,
    };
    if (today.perApp.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(l10n.screenNoUse),
      );
    }
    return Card(
      child: Column(
        children: [
          for (final e in today.perApp)
            ListTile(
              leading: apps[e.key] == null
                  ? const Icon(Icons.apps)
                  : Image.memory(apps[e.key]!.icon, width: 32, height: 32),
              title: Text(apps[e.key]?.label ?? e.key),
              trailing: Text(l10n.screenMinutes(e.value)),
            ),
        ],
      ),
    );
  }
}

/// The last 7 days as bars; over-budget days are marked by an icon too.
class _History extends ConsumerWidget {
  const _History();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final today = ref.watch(todayProvider);
    final saved = {
      for (final d
          in ref.watch(screenDaysProvider).value ?? const <ScreenDay>[])
        d.day: d,
    };
    final days = [for (var i = 6; i >= 0; i--) addDays(today, -i)];
    final shown = [for (final d in days) ?saved[d]];
    // Bars scale to the busiest day (use or budget) of the week.
    final top = shown.fold(
      1,
      (m, d) => [m, d.usedMinutes, d.budgetMinutes].reduce(max),
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: shown.isEmpty
            ? Text(l10n.screenNoHistory)
            : SizedBox(
                height: 120,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final d in days)
                      Expanded(
                        child: () {
                          final row = saved[d];
                          final over =
                              row != null &&
                              row.budgetMinutes > 0 &&
                              row.usedMinutes > row.budgetMinutes;
                          return Semantics(
                            label: row == null
                                ? MaterialLocalizations.of(context)
                                      .formatShortMonthDay(d)
                                : l10n.screenDayResult(
                                    MaterialLocalizations.of(context)
                                        .formatShortMonthDay(d),
                                    row.usedMinutes,
                                    row.budgetMinutes,
                                  ),
                            child: ExcludeSemantics(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (over)
                                    Icon(
                                      Icons.warning_amber,
                                      size: 16,
                                      color: scheme.error,
                                    ),
                                  Container(
                                    height:
                                        70 * (row?.usedMinutes ?? 0) / top + 2,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      // A faint dash where nothing was saved.
                                      color: row == null
                                          ? scheme.outlineVariant
                                          : over
                                          ? scheme.error
                                          : scheme.primary,
                                      borderRadius: BorderRadius.zero,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    weekdayShort(context, d.weekday),
                                    style: theme.textTheme.labelSmall,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }(),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}

/// Short weekday name in the app's language.
String weekdayShort(BuildContext context, int weekday) =>
    MaterialLocalizations.of(context).narrowWeekdays[weekday % 7];

class _Settings extends ConsumerWidget {
  const _Settings();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final s = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);
    final single = ref.watch(profilesProvider).length == 1;
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            title: Text(l10n.screenEnable),
            // Usage is per phone, so it needs a single person.
            subtitle: single ? null : Text(l10n.screenOnePersonOnly),
            value: s.screenTime && single,
            onChanged: single
                ? (v) => controller.update((x) => x.copyWith(screenTime: v))
                : null,
          ),
          ListTile(
            title: Text(l10n.screenBaseBudget),
            subtitle: Slider(
              value: s.screenBaseMinutes.toDouble(),
              max: 240,
              divisions: 16,
              label: l10n.screenMinutes(s.screenBaseMinutes),
              onChanged: (v) => controller.update(
                (x) => x.copyWith(screenBaseMinutes: v.round()),
              ),
            ),
            trailing: Text(l10n.screenMinutes(s.screenBaseMinutes)),
          ),
          ListTile(
            title: Text(l10n.screenEarnCapSetting),
            subtitle: Slider(
              value: s.screenEarnCap.toDouble(),
              max: 120,
              divisions: 24,
              label: l10n.screenMinutes(s.screenEarnCap),
              onChanged: (v) => controller.update(
                (x) => x.copyWith(screenEarnCap: v.round()),
              ),
            ),
            trailing: Text(l10n.screenMinutes(s.screenEarnCap)),
          ),
          ListTile(
            leading: const Icon(Icons.apps),
            title: Text(l10n.screenApps),
            subtitle: Text(l10n.screenAppsCount(s.screenApps.length)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => AppPickerScreen.open(context),
          ),
          SwitchListTile(
            title: Text(l10n.screenNotifyWarn(screenWarnMinutes)),
            value: s.screenWarn,
            onChanged: (v) =>
                controller.update((x) => x.copyWith(screenWarn: v)),
          ),
          SwitchListTile(
            title: Text(l10n.screenNotifyOver),
            value: s.screenOver,
            onChanged: (v) =>
                controller.update((x) => x.copyWith(screenOver: v)),
          ),
          SwitchListTile(
            title: Text(l10n.screenNotifySummary),
            value: s.screenSummary,
            onChanged: (v) =>
                controller.update((x) => x.copyWith(screenSummary: v)),
          ),
        ],
      ),
    );
  }
}

/// Picks the apps that count against the budget.
class AppPickerScreen extends ConsumerWidget {
  const AppPickerScreen({super.key});

  static Future<void> open(BuildContext context) => Navigator.of(context)
      .push(MaterialPageRoute<void>(builder: (_) => const AppPickerScreen()));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final chosen = ref.watch(settingsProvider).screenApps.toSet();
    final controller = ref.read(settingsProvider.notifier);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.screenApps)),
      body: ref
          .watch(launcherAppsProvider)
          .when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => Center(child: Text(l10n.errorGeneric)),
            data: (apps) => ListView(
              padding: EdgeInsets.only(
                bottom: 16 + MediaQuery.paddingOf(context).bottom,
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(l10n.screenPickerHint),
                ),
                for (final app in apps)
                  CheckboxListTile(
                    key: ValueKey('app-${app.package}'),
                    secondary: Image.memory(app.icon, width: 36, height: 36),
                    title: Text(app.label),
                    value: chosen.contains(app.package),
                    onChanged: (on) => controller.update(
                      (s) => s.copyWith(
                        screenApps: on == true
                            ? [...s.screenApps, app.package]
                            : [
                                for (final p in s.screenApps)
                                  if (p != app.package) p,
                              ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
    );
  }
}

/// The slim bar on the Quests tab: time left today, a warning style when
/// little or none is left. Hidden while screen time is off.
class ScreenTimeBar extends ConsumerWidget {
  const ScreenTimeBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final today = ref.watch(screenTodayProvider).value;
    if (today == null) return const SizedBox.shrink();
    final b = today.budget;
    final warn = !today.access || b.low || b.over;
    final background = warn ? scheme.errorContainer : scheme.primaryContainer;
    final foreground = warn
        ? scheme.onErrorContainer
        : scheme.onPrimaryContainer;
    final text = !today.access
        ? l10n.screenAccessMissingShort
        : b.over
        ? l10n.screenOverBy(b.left.abs())
        : l10n.screenLeft(b.left);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Material(
        color: background,
        shape: PixelBorder(
          side: BorderSide(color: PixelColors.of(context).frame, width: 2),
        ),
        child: InkWell(
          key: const ValueKey('screen-time-bar'),
          customBorder: const PixelBorder(),
          onTap: () => unawaited(ScreenTimeScreen.open(context)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      warn ? Icons.warning_amber : Icons.phone_android,
                      size: 18,
                      color: foreground,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        l10n.settingsScreenTime,
                        style: TextStyle(color: foreground),
                      ),
                    ),
                    Text(
                      text,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: foreground,
                      ),
                    ),
                  ],
                ),
                if (today.access) ...[
                  const SizedBox(height: 6),
                  PixelBar(
                    value: b.total == 0 ? 1 : (b.used / b.total).clamp(0, 1),
                    height: 12,
                    color: foreground,
                    trackColor: background,
                    semanticsLabel: l10n.screenUsedOf(b.used, b.total),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
