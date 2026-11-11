import 'dart:async';
import 'dart:convert';
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
    required this.allDays,
    required this.profileId,
    required this.person,
    required this.points,
    required this.l10n,
    required this.colorblindSafe,
  });

  final DateTime today;

  /// The quests for today and each following day.
  final List<List<WidgetQuest>> days;

  /// Every active quest, for today and each following day (the list).
  final List<List<WidgetQuest>> allDays;

  /// Whose quests these are: ticks in the list widget are booked for them.
  final int profileId;
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
      other.profileId == profileId &&
      other.person == person &&
      other.points == points &&
      other.l10n.localeName == l10n.localeName &&
      other.colorblindSafe == colorblindSafe &&
      _same(other.days, days) &&
      _same(other.allDays, allDays);

  static bool _same(List<List<WidgetQuest>> a, List<List<WidgetQuest>> b) =>
      a.length == b.length &&
      [for (var i = 0; i < a.length; i++) listEquals(a[i], b[i])]
          .every((same) => same);

  @override
  int get hashCode => Object.hash(
    today,
    profileId,
    person,
    points,
    l10n.localeName,
    colorblindSafe,
    _daysHash(days),
    _daysHash(allDays),
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
    allDays: [
      for (var i = 0; i < homeWidgetDays; i++)
        widgetQuests(
          chores: chores,
          today: today,
          l10n: l10n,
          offset: i,
          all: true,
        ),
    ],
    profileId: ref.watch(currentProfileIdProvider),
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

  /// Quests ticked off in the list widget that the app hasn't booked yet.
  Future<List<WidgetTick>> ticks();

  /// Forgets the ticks made at these moments ([WidgetTick.at]): booked.
  Future<void> dropTicks(List<DateTime> at);
}

/// A quest ticked off in the list widget, waiting to be booked.
@immutable
class WidgetTick {
  const WidgetTick({
    required this.choreId,
    required this.profileId,
    required this.at,
    required this.onTime,
  });

  final int choreId;
  final int profileId;

  /// When it was ticked; also what tells ticks apart.
  final DateTime at;
  final bool onTime;
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

  @override
  Future<List<WidgetTick>> ticks() async => [
    for (final t
        in await _channel.invokeListMethod<Map<Object?, Object?>>('ticks') ??
            const <Map<Object?, Object?>>[])
      WidgetTick(
        choreId: t['chore']! as int,
        profileId: t['profile']! as int,
        at: DateTime.fromMillisecondsSinceEpoch(t['at']! as int),
        onTime: t['onTime'] as bool? ?? false,
      ),
  ];

  @override
  Future<void> dropTicks(List<DateTime> at) =>
      _channel.invokeMethod<void>('dropTicks', {
        'at': [for (final t in at) t.millisecondsSinceEpoch],
      });
}

/// Books the quests ticked off in the list widget: each becomes a normal
/// completion at the moment it was ticked, so points, streak and fight
/// tokens are as if it had been done in the app. Ticks for quests or people
/// that are gone by now are dropped. Returns how many were booked.
Future<int> bookWidgetTicks(ProviderContainer container) async {
  final host = container.read(homeWidgetHostProvider);
  final ticks = await host.ticks();
  if (ticks.isEmpty) return 0;
  final db = container.read(databaseProvider);
  final progress = container.read(progressRepositoryProvider);
  final chores = {
    for (final c in await db.select(db.chores).get())
      if (!c.isArchived) c.id,
  };
  final people = {
    for (final p in await db.select(db.profiles).get())
      if (p.archivedAt == null) p.id,
  };
  var booked = 0;
  // Oldest first, so streaks build up in order. Each is forgotten right
  // after it's booked: stopping halfway never books one twice.
  for (final t in [...ticks]..sort((a, b) => a.at.compareTo(b.at))) {
    if (chores.contains(t.choreId) && people.contains(t.profileId)) {
      await progress.complete(
        choreId: t.choreId,
        profileId: t.profileId,
        onTime: t.onTime,
        at: t.at,
      );
      booked++;
    }
    await host.dropTicks([t.at]);
  }
  return booked;
}

final homeWidgetHostProvider = Provider<HomeWidgetHost>(
  (ref) => PlatformHomeWidgetHost(),
);

/// The name of the list of all quests among the placed widgets. It isn't a
/// [WidgetStyle]: it's a scrolling list of row pictures, not one picture.
const listWidget = 'list';

/// Draws the pictures for [styles]: day and night, for each of the next
/// [homeWidgetDays] days. Files are named `<style>-<day|night>-<date>.png`;
/// any others in [folder] are removed.
///
/// With [list], also the list of all quests:
/// - `list-<day|night>-head.png`, its heading;
/// - `list-<day|night>-row-<n>.png`, each different row once, and
///   `…-row-<n>-done.png` as it looks ticked off (rows that can be);
/// - `list-<date>.json`, the day's rows and whose they are:
///   `{"profile": id, "rows": [{"row": n, "label": "…", "chore": id,
///   "tick": true, "doneLabel": "…", "due": true, "from": 480, "to": 600}],
///   "empty": "…"}`. `label` and `doneLabel` are for screen readers; `tick`
///   says the row can be ticked off; `due` with the time of day (`from`,
///   `to`, if any) tells Android whether a tick is on time; `empty` is the
///   text for a day without quests.
Future<void> drawHomeWidgets(
  WidgetInputs inputs,
  Set<WidgetStyle> styles,
  Directory folder, {
  bool list = false,
}) async {
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
      today: inputs.today,
    );
    // Written whole, then renamed: a widget never reads half a file.
    Future<void> write(String name, List<int> bytes) async {
      keep.add(name);
      final tmp = File('${folder.path}/$name.tmp');
      await tmp.writeAsBytes(bytes, flush: true);
      await tmp.rename('${folder.path}/$name');
    }

    if (list) {
      await write('list-$mode-head.png', await art.renderListHeader());
      // Most rows are the same on every day: each is drawn once.
      final rows = <WidgetQuest, int>{};
      for (final (i, quests) in inputs.allDays.indexed) {
        final day = <Map<String, Object>>[];
        for (final q in quests) {
          var n = rows[q];
          if (n == null) {
            n = rows[q] = rows.length;
            await write('list-$mode-row-$n.png', await art.renderListRow(q));
            if (q.canTick) {
              await write(
                'list-$mode-row-$n-done.png',
                await art.renderListRow(q, done: true),
              );
            }
          }
          day.add({
            'row': n,
            'label': art.listRowLabel(q),
            'chore': q.choreId,
            'tick': q.canTick,
            if (q.canTick) 'doneLabel': art.listRowDoneLabel(q),
            'due': q.dueToday,
            'from': ?q.atMinutes,
            'to': ?q.untilMinutes,
          });
        }
        // The same for day and night; written with the first.
        if (brightness == Brightness.light) {
          await write(
            'list-${_dayKey(addDays(inputs.today, i))}.json',
            utf8.encode(
              jsonEncode({
                'profile': inputs.profileId,
                'rows': day,
                'empty': inputs.l10n.widgetNothingOpen,
              }),
            ),
          );
        }
      }
    }
    for (final style in styles) {
      for (final (i, quests) in inputs.days.indexed) {
        await write(
          '${style.name}-$mode-${_dayKey(addDays(inputs.today, i))}.png',
          await art.render(style, quests),
        );
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
        // First what was ticked off in the widget: booking it changes
        // what there is to draw, which runs this again.
        await bookWidgetTicks(container);
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
        await drawHomeWidgets(
          inputs,
          styles,
          await host.folder(),
          list: placed.contains(listWidget),
        );
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
