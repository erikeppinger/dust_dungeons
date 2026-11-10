import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show AppLifecycleListener;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/day_clock.dart';
import '../../core/platform.dart';
import '../../data/db/app_database.dart';
import '../../data/providers.dart';
import '../../data/repositories/screen_time_repository.dart';
import '../../domain/dates.dart';
import '../../domain/screen_time.dart';
import '../notifications/notification_sync.dart';
import '../settings/settings_controller.dart';
import 'screen_time_service.dart';

final screenTimeRepositoryProvider = Provider(
  (ref) => ScreenTimeRepository(ref.watch(databaseProvider)),
);

/// Saved screen-time days, oldest first.
final screenDaysProvider = StreamProvider<List<ScreenDay>>(
  (ref) => ref
      .watch(screenTimeRepositoryProvider)
      .watchDays(ref.watch(currentProfileIdProvider)),
);

/// Whether usage access is granted; re-checked when the app comes back
/// (the user grants it in the system settings).
final screenAccessProvider = FutureProvider<bool>((ref) {
  final listener = AppLifecycleListener(onResume: ref.invalidateSelf);
  ref.onDispose(listener.dispose);
  return ref.watch(screenTimeServiceProvider).hasAccess();
});

/// Chore points earned on [day].
int pointsOn(List<Completion> completions, DateTime day) => completions
    .where((c) => dayOf(c.completedAt) == dayOf(day))
    .fold(0, (sum, c) => sum + c.pointsAwarded);

/// Today's screen time: the budget, use per app and whether access is
/// granted. `null` while screen time is off.
@immutable
class ScreenToday {
  const ScreenToday({
    required this.budget,
    required this.perApp,
    required this.access,
    required this.capReached,
  });

  final ScreenBudget budget;

  /// Minutes per chosen app today, most used first.
  final List<MapEntry<String, int>> perApp;
  final bool access;

  /// Quests can't earn more minutes today.
  final bool capReached;

  // Equal values compare equal, so saving today's totals (which updates the
  // saved days this is built from) does not trigger another save.
  @override
  bool operator ==(Object other) =>
      other is ScreenToday &&
      other.budget == budget &&
      other.access == access &&
      other.capReached == capReached &&
      listEquals(
        [for (final e in other.perApp) (e.key, e.value)],
        [for (final e in perApp) (e.key, e.value)],
      );

  @override
  int get hashCode => Object.hash(
    budget,
    access,
    capReached,
    Object.hashAll([for (final e in perApp) (e.key, e.value)]),
  );
}

/// Screen time is on and works: usage is measured per phone, so it needs a
/// single person (docs/design/profiles.md).
final screenTimeActiveProvider = Provider<bool>(
  (ref) =>
      // Android only; a backup from a phone may carry the setting.
      isAndroidApp &&
      ref.watch(settingsProvider).screenTime &&
      ref.watch(profilesProvider).length == 1,
);

final screenTodayProvider = FutureProvider<ScreenToday?>((ref) async {
  final settings = ref.watch(settingsProvider);
  if (!ref.watch(screenTimeActiveProvider)) return null;
  // Usage moves on while the app is away: fresh numbers on return.
  final listener = AppLifecycleListener(onResume: ref.invalidateSelf);
  ref.onDispose(listener.dispose);
  final today = ref.watch(todayProvider);
  final completions = await ref.watch(allCompletionsProvider.future);
  final days = await ref.watch(screenDaysProvider.future);
  final access = await ref.watch(screenAccessProvider.future);
  final perApp = access && settings.screenApps.isNotEmpty
      ? await ref
            .read(screenTimeServiceProvider)
            .usageMinutes(settings.screenApps.toSet(), today, DateTime.now())
      : const <String, int>{};
  final row = days.where((d) => d.day == today).firstOrNull;
  final earned = earnedScreenMinutes(
    pointsOn(completions, today),
    settings.screenEarnCap,
  );
  return ScreenToday(
    budget: ScreenBudget(
      base: settings.screenBaseMinutes,
      earned: earned,
      vouchers: row?.voucherMinutes ?? 0,
      used: perApp.values.fold(0, (sum, m) => sum + m),
    ),
    perApp: perApp.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value)),
    access: access,
    capReached: earned >= settings.screenEarnCap,
  );
});

/// Yesterday's saved day, if any.
final screenYesterdayProvider = Provider<ScreenDay?>((ref) {
  final yesterday = addDays(ref.watch(todayProvider), -1);
  return ref
      .watch(screenDaysProvider)
      .value
      ?.where((d) => d.day == yesterday)
      .firstOrNull;
});

/// Over the budget yesterday: the hero starts today's fights tired.
final tiredProvider = Provider<bool>((ref) {
  if (!ref.watch(screenTimeActiveProvider)) return false;
  final yesterday = ref.watch(screenYesterdayProvider);
  return yesterday != null &&
      yesterday.budgetMinutes > 0 &&
      yesterday.usedMinutes > yesterday.budgetMinutes;
});

/// Keeps the Android side in line for the app's lifetime: the snapshot the
/// background check reads, today's saved totals, and yesterday's complete
/// day (so history and Tired survive Android dropping old usage).
ProviderSubscription<AsyncValue<ScreenToday?>> syncScreenTime(
  ProviderContainer container,
) {
  var wasEnabled = false;
  DateTime? settledDay;

  Future<void> apply(ScreenToday? today) async {
    final settings = container.read(settingsProvider);
    final service = container.read(screenTimeServiceProvider);
    if (today == null) {
      // Switched off: stop the background check once.
      if (wasEnabled) await service.writeSnapshot({'enabled': false});
      wasEnabled = false;
      return;
    }
    wasEnabled = true;
    final day = container.read(todayProvider);
    final l10n = notificationLocalizations(
      settings.locale,
      container.read(deviceLocaleProvider),
    );
    await service.writeSnapshot({
      'enabled': true,
      'day':
          '${day.year.toString().padLeft(4, '0')}-'
          '${day.month.toString().padLeft(2, '0')}-'
          '${day.day.toString().padLeft(2, '0')}',
      'budgetMinutes': today.budget.total,
      'baseMinutes': settings.screenBaseMinutes,
      'packages': settings.screenApps,
      'warn': settings.screenWarn,
      'over': settings.screenOver,
      'texts': {
        'channel': l10n.channelScreenTime,
        'warnTitle': l10n.screenWarnTitle,
        // The check fills in the minutes left.
        'warnBody': l10n.screenWarnBody(99).replaceAll('99', '{left}'),
        'overTitle': l10n.screenOverTitle,
        'overBody': today.capReached
            ? l10n.screenOverCapped
            : l10n.screenOverEarnMore,
        'overBodyNewDay': l10n.screenOverEarnMore,
      },
    });
    if (!today.access) return;
    final repo = container.read(screenTimeRepositoryProvider);
    final profile = container.read(currentProfileIdProvider);
    await repo.saveDay(
      profile,
      day,
      usedMinutes: today.budget.used,
      budgetMinutes: today.budget.total,
    );
    // Once a day: yesterday's complete use, with its own budget.
    if (settledDay == day) return;
    settledDay = day;
    final yesterday = addDays(day, -1);
    final used = await container
        .read(screenTimeServiceProvider)
        .usageMinutes(settings.screenApps.toSet(), yesterday, day);
    final completions = await container.read(allCompletionsProvider.future);
    final days = await container.read(screenDaysProvider.future);
    final row = days.where((d) => d.day == yesterday).firstOrNull;
    // A whole day is at least what was saved while it ran: if Android has
    // already dropped it (or access was off), keep the saved total.
    final full = used.values.fold(0, (sum, m) => sum + m);
    await repo.saveDay(
      profile,
      yesterday,
      usedMinutes: row == null || full > row.usedMinutes
          ? full
          : row.usedMinutes,
      budgetMinutes:
          settings.screenBaseMinutes +
          earnedScreenMinutes(
            pointsOn(completions, yesterday),
            settings.screenEarnCap,
          ) +
          (row?.voucherMinutes ?? 0),
    );
  }

  var running = false;
  ScreenToday? queued;
  var pending = false;
  // The last value applied, and settings it was applied with: unchanged
  // inputs are not written again.
  Object? applied = const Object();
  Future<void> drain() async {
    running = true;
    while (pending) {
      pending = false;
      try {
        await apply(queued);
      } catch (error, stack) {
        FlutterError.reportError(
          FlutterErrorDetails(exception: error, stack: stack),
        );
      }
    }
    running = false;
  }

  return container.listen<AsyncValue<ScreenToday?>>(screenTodayProvider, (
    previous,
    next,
  ) {
    if (!next.hasValue || next.isLoading) return;
    final key = (next.value, container.read(settingsProvider));
    if (key == applied) return;
    applied = key;
    queued = next.value;
    pending = true;
    if (!running) unawaited(drain());
  }, fireImmediately: true);
}
