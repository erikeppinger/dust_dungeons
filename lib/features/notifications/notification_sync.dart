import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show AppLifecycleListener;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/day_clock.dart';
import '../../data/providers.dart';
import '../../l10n/app_localizations.dart';
import '../settings/settings_controller.dart';
import 'notification_planner.dart';
import 'notification_service.dart';

/// The platform notification service. Overridden in `bootstrap()`.
final notificationServiceProvider = Provider<NotificationService>(
  (ref) => throw UnimplementedError('notificationServiceProvider'),
);

/// What should currently be scheduled, plus localized channel names.
@immutable
class NotificationPlan {
  const NotificationPlan(this.notifications, this.channelNames);

  final List<PlannedNotification> notifications;
  final ChannelNames channelNames;

  @override
  bool operator ==(Object other) =>
      other is NotificationPlan &&
      listEquals(other.notifications, notifications) &&
      mapEquals(other.channelNames, channelNames);

  @override
  int get hashCode => Object.hash(
    Object.hashAll(notifications),
    Object.hashAll(channelNames.values),
  );
}

/// The device language. Re-read when the app resumes, since it can only
/// change in the system settings while the app is in the background.
class DeviceLocale extends Notifier<Locale> {
  @override
  Locale build() {
    final listener = AppLifecycleListener(
      onResume: () => state = PlatformDispatcher.instance.locale,
    );
    ref.onDispose(listener.dispose);
    return PlatformDispatcher.instance.locale;
  }
}

final deviceLocaleProvider = NotifierProvider<DeviceLocale, Locale>(
  DeviceLocale.new,
);

/// Notification texts follow the app language (setting, else device).
AppLocalizations notificationLocalizations(Locale? setting, Locale device) {
  final wanted = setting ?? device;
  final supported = AppLocalizations.supportedLocales.firstWhere(
    (l) => l.languageCode == wanted.languageCode,
    orElse: () => const Locale('en'),
  );
  return lookupAppLocalizations(supported);
}

ChannelNames channelNames(AppLocalizations l10n) => {
  NotificationChannel.summary: l10n.channelSummary,
  NotificationChannel.reminder: l10n.channelReminder,
  NotificationChannel.recap: l10n.channelRecap,
};

/// Rebuilt whenever chores, completions, settings or the day change;
/// `null` while data is still loading.
final notificationPlanProvider = Provider<NotificationPlan?>((ref) {
  final settings = ref.watch(settingsProvider);
  final l10n = notificationLocalizations(
    settings.locale,
    ref.watch(deviceLocaleProvider),
  );
  if (!settings.notificationsEnabled) {
    return NotificationPlan(const [], channelNames(l10n));
  }
  ref.watch(todayProvider);
  final chores = ref.watch(scheduledChoresProvider).value;
  final completions = ref.watch(allCompletionsProvider).value;
  if (chores == null || completions == null) return null;
  return NotificationPlan(
    planNotifications(
      now: DateTime.now(),
      settings: settings,
      chores: chores,
      completions: completions,
      l10n: l10n,
    ),
    channelNames(l10n),
  );
});

/// Applies every plan change to the platform for the app's lifetime.
///
/// Updates run one at a time: a cancel-and-reschedule must not interleave
/// with the previous one. Plans arriving meanwhile are coalesced, so only
/// the newest is applied next.
ProviderSubscription<NotificationPlan?> syncNotifications(
  ProviderContainer container,
) {
  var running = false;
  NotificationPlan? queued;

  Future<void> drain() async {
    running = true;
    while (queued != null) {
      final plan = queued!;
      queued = null;
      try {
        await container
            .read(notificationServiceProvider)
            .replaceAll(plan.notifications, plan.channelNames);
      } catch (error, stack) {
        FlutterError.reportError(
          FlutterErrorDetails(exception: error, stack: stack),
        );
      }
    }
    running = false;
  }

  return container.listen<NotificationPlan?>(notificationPlanProvider, (
    previous,
    next,
  ) {
    if (next == null || next == previous) return;
    queued = next;
    if (!running) unawaited(drain());
  }, fireImmediately: true);
}
