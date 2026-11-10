import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
// The full database: the trimmed one lacks aliases such as "GMT" and "UTC",
// which some devices (e.g. emulators) report.
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../core/platform.dart';
import 'notification_planner.dart';

/// Localized Android channel names.
typedef ChannelNames = Map<NotificationChannel, String>;

/// Local notifications. Behind an interface so tests can use a fake.
abstract class NotificationService {
  /// Sets up the plugin; [onTap] receives the tapped notification's target.
  Future<void> init({required void Function(NotificationTarget) onTap});

  /// The target of the notification that launched the app, if any.
  Future<NotificationTarget?> launchTarget();

  /// Asks for permission (Android 13+); `true` if notifications may be shown.
  Future<bool> requestPermission();

  /// Whether notifications may currently be shown.
  Future<bool> permissionGranted();

  /// Cancels everything and schedules [plan] instead.
  Future<void> replaceAll(List<PlannedNotification> plan, ChannelNames names);

  /// Shows [notification] immediately (for "send a test notification").
  Future<void> showNow(PlannedNotification notification, ChannelNames names);
}

class LocalNotificationService implements NotificationService {
  final _plugin = FlutterLocalNotificationsPlugin();

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  @override
  Future<void> init({required void Function(NotificationTarget) onTap}) async {
    tzdata.initializeTimeZones();
    String? deviceZone;
    try {
      deviceZone = (await FlutterTimezone.getLocalTimezone()).identifier;
    } catch (error) {
      debugPrint('Could not read the device time zone: $error');
    }
    tz.setLocalLocation(
      resolveLocation(deviceZone, DateTime.now().timeZoneOffset),
    );
    await _plugin.initialize(
      settings: const InitializationSettings(
        // White silhouette; kept in release builds by res/raw/keep.xml.
        android: AndroidInitializationSettings('ic_notification'),
        // The ID and GUID identify the app to Windows: never change them.
        windows: WindowsInitializationSettings(
          appName: 'Homework & Chores',
          appUserModelId: 'HomeworkAndChores.App',
          guid: '5d706548-c56f-47c7-8cde-616abb18aad4',
        ),
      ),
      onDidReceiveNotificationResponse: (response) {
        final target = _parse(response.payload);
        if (target != null) onTap(target);
      },
    );
  }

  static NotificationTarget? _parse(String? payload) =>
      NotificationTarget.values.where((t) => t.name == payload).firstOrNull;

  @override
  Future<NotificationTarget?> launchTarget() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details == null || !details.didNotificationLaunchApp) return null;
    return _parse(details.notificationResponse?.payload);
  }

  @override
  Future<bool> requestPermission() async =>
      // Windows has no permission to ask for; its own settings can mute us.
      isWindowsApp ||
      (await _android?.requestNotificationsPermission() ?? false);

  @override
  Future<bool> permissionGranted() async =>
      isWindowsApp || (await _android?.areNotificationsEnabled() ?? false);

  NotificationDetails _details(
    NotificationChannel channel,
    ChannelNames names,
  ) => NotificationDetails(
    android: AndroidNotificationDetails(
      'chores_${channel.name}',
      names[channel] ?? channel.name,
      importance: channel == NotificationChannel.recap
          ? Importance.low
          : Importance.defaultImportance,
    ),
  );

  @override
  Future<void> replaceAll(
    List<PlannedNotification> plan,
    ChannelNames names,
  ) async {
    // Only pending ones: notifications already in the tray stay visible.
    // Windows can't tell the two apart, and (without an installer package)
    // leaves shown ones alone anyway.
    await (isWindowsApp
        ? _plugin.cancelAll()
        : _plugin.cancelAllPendingNotifications());
    final now = DateTime.now();
    for (final n in plan) {
      if (!n.when.isAfter(now)) continue;
      await _plugin.zonedSchedule(
        id: n.id,
        scheduledDate: tz.TZDateTime.from(n.when, tz.local),
        notificationDetails: _details(n.channel, names),
        // Inexact on purpose: no exact-alarm permission, battery friendly.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: n.title,
        body: n.body,
        payload: n.target.name,
      );
    }
  }

  @override
  Future<void> showNow(PlannedNotification notification, ChannelNames names) =>
      _plugin.show(
        id: 0,
        title: notification.title,
        body: notification.body,
        notificationDetails: _details(notification.channel, names),
        payload: notification.target.name,
      );
}

/// The time zone for scheduling: the device's [identifier] if the database
/// knows it, else a fixed-offset zone for [offset] (correct until the next DST
/// change, and the plan is rebuilt every time the app is used), else UTC.
/// Requires the time zone database to be initialized.
tz.Location resolveLocation(String? identifier, Duration offset) {
  for (final name in [?identifier, if (identifier != null) 'Etc/$identifier']) {
    try {
      return tz.getLocation(name);
    } on Object {
      // try the next candidate
    }
  }
  if (offset.inMinutes % 60 == 0) {
    final hours = offset.inHours;
    // Etc/GMT zones have inverted signs: Etc/GMT-2 is UTC+2.
    final name = hours == 0
        ? 'Etc/UTC'
        : 'Etc/GMT${hours > 0 ? '-' : '+'}${hours.abs()}';
    try {
      return tz.getLocation(name);
    } on Object {
      // fall through to UTC
    }
  }
  return tz.UTC;
}
