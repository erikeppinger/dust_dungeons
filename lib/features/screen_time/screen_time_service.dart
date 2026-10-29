import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// An app with a launcher icon, for the picker.
class LauncherApp {
  const LauncherApp(this.package, this.label, this.icon);

  final String package;
  final String label;

  /// PNG bytes.
  final Uint8List icon;
}

/// The Android side of the soft screen-time budget: usage access, the app
/// list, usage totals and the snapshot for the background check. Behind an
/// interface so tests use a fake.
abstract class ScreenTimeService {
  Future<bool> hasAccess();
  Future<void> openAccessSettings();
  Future<List<LauncherApp>> launcherApps();

  /// Foreground minutes per package between [from] and [to].
  Future<Map<String, int>> usageMinutes(
    Set<String> packages,
    DateTime from,
    DateTime to,
  );

  /// Hands the background check its data; it runs only while enabled.
  Future<void> writeSnapshot(Map<String, Object?> snapshot);
}

class PlatformScreenTimeService implements ScreenTimeService {
  static const _channel = MethodChannel('screen_time');

  @override
  Future<bool> hasAccess() async =>
      await _channel.invokeMethod<bool>('hasAccess') ?? false;

  @override
  Future<void> openAccessSettings() =>
      _channel.invokeMethod<void>('openAccessSettings');

  @override
  Future<List<LauncherApp>> launcherApps() async {
    final list = await _channel.invokeListMethod<Map<Object?, Object?>>(
      'launcherApps',
    );
    return [
      for (final app in list ?? const <Map<Object?, Object?>>[])
        LauncherApp(
          app['package']! as String,
          app['label']! as String,
          app['icon']! as Uint8List,
        ),
    ];
  }

  @override
  Future<Map<String, int>> usageMinutes(
    Set<String> packages,
    DateTime from,
    DateTime to,
  ) async {
    final ms = await _channel.invokeMapMethod<String, int>('usage', {
      'packages': packages.toList(),
      'from': from.millisecondsSinceEpoch,
      'to': to.millisecondsSinceEpoch,
    });
    return {
      for (final entry in (ms ?? const <String, int>{}).entries)
        entry.key: entry.value ~/ 60000,
    };
  }

  @override
  Future<void> writeSnapshot(Map<String, Object?> snapshot) => _channel
      .invokeMethod<void>('writeSnapshot', {'json': jsonEncode(snapshot)});
}

final screenTimeServiceProvider = Provider<ScreenTimeService>(
  (ref) => PlatformScreenTimeService(),
);
