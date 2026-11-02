import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show AppLifecycleListener;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/day_clock.dart';
import '../../data/providers.dart';
import '../../domain/dates.dart';
import '../../l10n/app_localizations.dart';
import '../notifications/notification_sync.dart';
import '../settings/settings_controller.dart';
import 'widget_art.dart';
import 'widget_quests.dart';

/// Days the home screen widgets can show without the app: each picks the
/// picture for the current day, so they stay right after midnight.
const homeWidgetDays = 7;

String _dayKey(DateTime day) =>
    '${day.year.toString().padLeft(4, '0')}-'
    '${day.month.toString().padLeft(2, '0')}-'
    '${day.day.toString().padLeft(2, '0')}';

/// Everything a set of widget pictures depends on; equal inputs draw equal
/// pictures, so they aren't drawn again.
@immutable
class WidgetInputs {
  const WidgetInputs({
    required this.today,
    required this.days,
    required this.person,
    required this.points,
    required this.l10n,
    required this.colorblindSafe,
  });

  final DateTime today;

  /// The quests for today and each following day.
  final List<List<WidgetQuest>> days;
  final String person;
  final int points;
  final AppLocalizations l10n;
  final bool colorblindSafe;

  static int _daysHash(List<List<WidgetQuest>> days) =>
      Object.hashAll([for (final d in days) Object.hashAll(d)]);

  @override
  bool operator ==(Object other) =>
      other is WidgetInputs &&
      other.today == today &&
      other.person == person &&
      other.points == points &&
      other.l10n.localeName == l10n.localeName &&
      other.colorblindSafe == colorblindSafe &&
      other.days.length == days.length &&
      [for (var i = 0; i < days.length; i++) listEquals(other.days[i], days[i])]
          .every((same) => same);

  @override
  int get hashCode => Object.hash(
    today,
    person,
    points,
    l10n.localeName,
    colorblindSafe,
    _daysHash(days),
  );
}

final _widgetInputsProvider = Provider<WidgetInputs?>((ref) {
  final chores = ref.watch(scheduledChoresProvider).value;
  final points = ref.watch(balanceProvider).value;
  if (chores == null || points == null) return null;
  final settings = ref.watch(settingsProvider);
  final l10n = notificationLocalizations(
    settings.locale,
    ref.watch(deviceLocaleProvider),
  );
  final today = ref.watch(todayProvider);
  return WidgetInputs(
    today: today,
    days: [
      for (var i = 0; i < homeWidgetDays; i++)
        widgetQuests(chores: chores, today: today, l10n: l10n, offset: i),
    ],
    person: ref.watch(currentProfileProvider).name,
    points: points,
    l10n: l10n,
    colorblindSafe: settings.colorblindSafe,
  );
});

/// The Android side: which widgets are placed, and redrawing them. Behind
/// an interface so tests can stand in for it.
abstract class HomeWidgetHost {
  /// Names of the [WidgetStyle]s placed on the home screen.
  Future<Set<String>> placed();

  /// Where the pictures go (the app's private files).
  Future<Directory> folder();

  /// Redraws every placed widget from the pictures.
  Future<void> refresh();
}

class PlatformHomeWidgetHost implements HomeWidgetHost {
  static const _channel = MethodChannel('home_widget');

  @override
  Future<Set<String>> placed() async => {
    ...?await _channel.invokeListMethod<String>('placed'),
  };

  @override
  Future<Directory> folder() async =>
      Directory('${(await getApplicationSupportDirectory()).path}/widget');

  @override
  Future<void> refresh() => _channel.invokeMethod<void>('refresh');
}

final homeWidgetHostProvider = Provider<HomeWidgetHost>(
  (ref) => PlatformHomeWidgetHost(),
);

/// Draws the pictures for [styles]: day and night, for each of the next
/// [homeWidgetDays] days. Files are named `<style>-<day|night>-<date>.png`;
/// any others in [folder] are removed.
Future<void> drawHomeWidgets(
  WidgetInputs inputs,
  Set<WidgetStyle> styles,
  Directory folder,
) async {
  await folder.create(recursive: true);
  // The pictures name weekdays; Flutter may not have loaded them yet.
  await initializeDateFormatting(inputs.l10n.localeName);
  final keep = <String>{};
  for (final (mode, brightness) in [
    ('day', Brightness.light),
    ('night', Brightness.dark),
  ]) {
    final art = WidgetArt(
      l10n: inputs.l10n,
      look: WidgetLook(brightness, colorblindSafe: inputs.colorblindSafe),
      person: inputs.person,
      points: inputs.points,
    );
    for (final style in styles) {
      for (final (i, quests) in inputs.days.indexed) {
        final name =
            '${style.name}-$mode-${_dayKey(addDays(inputs.today, i))}.png';
        keep.add(name);
        final png = await art.render(style, quests);
        // Written whole, then renamed: a widget never reads half a file.
        final tmp = File('${folder.path}/$name.tmp');
        await tmp.writeAsBytes(png, flush: true);
        await tmp.rename('${folder.path}/$name');
      }
    }
  }
  await for (final file in folder.list()) {
    final name = file.uri.pathSegments.last;
    if (!keep.contains(name)) await file.delete();
  }
}

/// Keeps the home screen widgets up to date for the app's lifetime: draws
/// when what they show changes, and when the app comes back (a widget may
/// have been placed meanwhile). Only placed styles are drawn. Returns a
/// function that stops it.
void Function() syncHomeWidget(ProviderContainer container) {
  WidgetInputs? drawn;
  Set<String>? drawnStyles;
  var running = false;
  var again = false;

  Future<void> run() async {
    if (running) {
      again = true;
      return;
    }
    running = true;
    try {
      do {
        again = false;
        final inputs = container.read(_widgetInputsProvider);
        if (inputs == null) return;
        final host = container.read(homeWidgetHostProvider);
        final placed = await host.placed();
        if (placed.isEmpty) continue;
        if (inputs == drawn && setEquals(placed, drawnStyles)) {
          // Nothing new to draw, but the phone may have switched between
          // day and night: show the matching pictures.
          await host.refresh();
          continue;
        }
        final styles = {
          for (final s in WidgetStyle.values)
            if (placed.contains(s.name)) s,
        };
        await drawHomeWidgets(inputs, styles, await host.folder());
        await host.refresh();
        drawn = inputs;
        drawnStyles = placed;
      } while (again);
    } on MissingPluginException {
      // Not on Android (tests, desktop): no home screen widgets.
    } catch (error, stack) {
      FlutterError.reportError(
        FlutterErrorDetails(exception: error, stack: stack),
      );
    } finally {
      running = false;
    }
  }

  final sub = container.listen<WidgetInputs?>(
    _widgetInputsProvider,
    (_, _) => unawaited(run()),
    fireImmediately: true,
  );
  final listener = AppLifecycleListener(onResume: () => unawaited(run()));
  return () {
    sub.close();
    listener.dispose();
  };
}
