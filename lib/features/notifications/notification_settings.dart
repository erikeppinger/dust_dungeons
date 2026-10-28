import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../settings/settings_controller.dart';
import 'notification_planner.dart';
import 'notification_sync.dart';

/// Whether Android currently allows notifications; re-checked when the app
/// resumes (the user may have changed it in the system settings).
final notificationPermissionProvider = FutureProvider<bool>((ref) {
  final listener = AppLifecycleListener(onResume: ref.invalidateSelf);
  ref.onDispose(listener.dispose);
  return ref.watch(notificationServiceProvider).permissionGranted();
});

String formatMinutes(BuildContext context, int minutes) =>
    MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );

/// Notification settings page content.
class NotificationSettings extends ConsumerWidget {
  const NotificationSettings({super.key});

  Future<void> _setEnabled(
    BuildContext context,
    WidgetRef ref,
    bool enabled,
  ) async {
    final controller = ref.read(settingsProvider.notifier);
    if (!enabled) {
      controller.update((s) => s.copyWith(notificationsEnabled: false));
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    final blocked = AppLocalizations.of(context).notifBlocked;
    final granted = await ref
        .read(notificationServiceProvider)
        .requestPermission();
    ref.invalidate(notificationPermissionProvider);
    if (granted) {
      controller.update((s) => s.copyWith(notificationsEnabled: true));
    } else {
      messenger.showSnackBar(SnackBar(content: Text(blocked)));
    }
  }

  Future<void> _pickSummaryTime(BuildContext context, WidgetRef ref) async {
    final minutes = ref.read(settingsProvider).dailySummaryMinutes;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
    );
    if (picked != null) {
      ref
          .read(settingsProvider.notifier)
          .update(
            (s) => s.copyWith(
              dailySummaryMinutes: picked.hour * 60 + picked.minute,
            ),
          );
    }
  }

  Future<void> _sendTest(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(notificationServiceProvider)
          .showNow(
            PlannedNotification(
              id: 0,
              when: DateTime.now(),
              channel: NotificationChannel.reminder,
              title: l10n.notifTestTitle,
              body: l10n.notifTestBody,
              target: NotificationTarget.today,
            ),
            channelNames(l10n),
          );
    } catch (error, stack) {
      FlutterError.reportError(
        FlutterErrorDetails(exception: error, stack: stack),
      );
      messenger.showSnackBar(SnackBar(content: Text(l10n.errorGeneric)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);
    final permitted = ref.watch(notificationPermissionProvider).value ?? true;
    final on = settings.notificationsEnabled;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          secondary: const Icon(Icons.notifications_outlined),
          title: Text(l10n.notifEnable),
          subtitle: Text(l10n.notifEnableSubtitle),
          value: on,
          onChanged: (v) => unawaited(_setEnabled(context, ref, v)),
        ),
        if (on && !permitted)
          ListTile(
            leading: Icon(Icons.block, color: theme.colorScheme.error),
            title: Text(
              l10n.notifBlocked,
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        if (on) ...[
          SwitchListTile(
            secondary: const Icon(Icons.wb_sunny_outlined),
            title: Text(l10n.notifDailySummary),
            subtitle: Text(l10n.notifDailySummarySubtitle),
            value: settings.dailySummary,
            onChanged: (v) =>
                controller.update((s) => s.copyWith(dailySummary: v)),
          ),
          if (settings.dailySummary)
            ListTile(
              key: const ValueKey('summary-time'),
              leading: const SizedBox(width: 24),
              title: Text(formatMinutes(context, settings.dailySummaryMinutes)),
              trailing: const Icon(Icons.schedule),
              onTap: () => unawaited(_pickSummaryTime(context, ref)),
            ),
          SwitchListTile(
            secondary: const Icon(Icons.alarm),
            title: Text(l10n.notifChoreReminders),
            subtitle: Text(l10n.notifChoreRemindersSubtitle),
            value: settings.choreReminders,
            onChanged: (v) =>
                controller.update((s) => s.copyWith(choreReminders: v)),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.date_range),
            title: Text(l10n.notifWeeklyRecap),
            subtitle: Text(
              l10n.notifWeeklyRecapSubtitle(
                formatMinutes(context, weeklyRecapMinutes),
              ),
            ),
            value: settings.weeklyRecap,
            onChanged: (v) =>
                controller.update((s) => s.copyWith(weeklyRecap: v)),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.calendar_month),
            title: Text(l10n.notifMonthlyRecap),
            subtitle: Text(
              l10n.notifMonthlyRecapSubtitle(
                formatMinutes(context, monthlyRecapMinutes),
              ),
            ),
            value: settings.monthlyRecap,
            onChanged: (v) =>
                controller.update((s) => s.copyWith(monthlyRecap: v)),
          ),
          ListTile(
            leading: const Icon(Icons.send_outlined),
            title: Text(l10n.notifSendTest),
            onTap: () => unawaited(_sendTest(context, ref)),
          ),
        ],
      ],
    );
  }
}
