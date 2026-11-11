import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/drift.dart' show Value;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homework_and_chores/data/db/app_database.dart';
import 'package:homework_and_chores/data/models/scheduled_chore.dart';
import 'package:homework_and_chores/domain/recurrence.dart';
import 'package:homework_and_chores/features/home_widget/home_widget_sync.dart';
import 'package:homework_and_chores/features/home_widget/widget_art.dart';
import 'package:homework_and_chores/features/home_widget/widget_quests.dart';
import 'package:homework_and_chores/l10n/app_localizations.dart';

/// The home screen widgets (docs/design/scheduling.md).
void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));
  final today = DateTime(2026, 10, 28); // Wednesday

  Chore chore(int id, String title, RepeatType type) => Chore(
    id: id,
    customTitle: title,
    iconKey: 'star',
    colorKey: id,
    basePoints: 10,
    isArchived: false,
    assignment: Assignment.anyone,
    windowDays: 1,
    sortOrder: id,
    createdAt: DateTime(2026, 10, 1),
    repeatType: type,
    repeatInterval: 1,
    repeatWeekdays: 0,
    repeatStart: DateTime(2026, 10, 1),
  );

  ScheduledChore scheduled(Chore c, {DateTime? lastDone}) => ScheduledChore(
    chore: c,
    lastDone: lastDone,
    doneToday: 0,
    today: today,
    now: DateTime(2026, 10, 28, 9),
  );

  final chores = [
    scheduled(
      chore(1, 'Dishes', RepeatType.daily),
      lastDone: DateTime(2026, 10, 27),
    ),
    scheduled(
      chore(2, 'Plants', RepeatType.afterDone).copyWith(repeatInterval: 3),
      lastDone: DateTime(2026, 10, 23),
    ),
    scheduled(
      chore(3, 'Walk', RepeatType.daily).copyWith(
        windowFrom: const Value(18 * 60),
        windowTo: const Value(19 * 60),
      ),
      lastDone: DateTime(2026, 10, 27),
    ),
    scheduled(
      chore(
        4,
        'Bathroom',
        RepeatType.weekly,
      ).copyWith(repeatWeekdays: weekdaysToMask({DateTime.friday})),
      lastDone: DateTime(2026, 10, 23),
    ),
  ];

  test('today: late first, then open, later today, then coming up', () {
    final quests = widgetQuests(chores: chores, today: today, l10n: l10n);
    expect(
      [for (final q in quests) (q.title, q.status)],
      [
        ('Plants', WidgetStatus.late),
        ('Dishes', WidgetStatus.now),
        ('Walk', WidgetStatus.at),
        ('Bathroom', WidgetStatus.upcoming),
      ],
    );
    expect(quests.first.lateDays, 2);
    expect(quests[2].atMinutes, 18 * 60);
    expect(quests.last.day, DateTime(2026, 10, 30));
  });

  test('later days: still late, and what is due that day', () {
    final friday = widgetQuests(
      chores: chores,
      today: today,
      l10n: l10n,
      offset: 2,
    );
    expect(friday.first.title, 'Plants');
    expect(friday.first.lateDays, 4);
    expect([
      for (final q in friday) (q.title, q.status),
    ], contains(('Bathroom', WidgetStatus.now)));
  });

  /// The four above, one due in three weeks and two without a schedule.
  final everything = [
    ...chores,
    scheduled(
      chore(
        5,
        'Windows',
        RepeatType.monthly,
      ).copyWith(repeatDayOfMonth: const Value(18)),
      lastDone: DateTime(2026, 10, 18),
    ),
    scheduled(chore(6, 'Declutter', RepeatType.anytime)),
    scheduled(chore(7, 'Wash the car', RepeatType.anytime)),
  ];

  test('all quests: the week first, then later ones, then anytime', () {
    final quests = widgetQuests(
      chores: everything,
      today: today,
      l10n: l10n,
      all: true,
    );
    expect(
      [for (final q in quests) (q.title, q.status)],
      [
        ('Plants', WidgetStatus.late),
        ('Dishes', WidgetStatus.now),
        ('Walk', WidgetStatus.at),
        ('Bathroom', WidgetStatus.upcoming),
        ('Windows', WidgetStatus.upcoming),
        ('Declutter', WidgetStatus.anytime),
        ('Wash the car', WidgetStatus.anytime),
      ],
    );
    expect(quests[4].day, DateTime(2026, 11, 18));
    // The other widgets keep to what is due.
    expect(
      widgetQuests(chores: everything, today: today, l10n: l10n),
      hasLength(4),
    );
  });

  test('all quests has no limit', () {
    final many = [
      for (var i = 1; i <= 30; i++)
        scheduled(chore(i, 'Quest $i', RepeatType.anytime)),
    ];
    expect(
      widgetQuests(chores: many, today: today, l10n: l10n, all: true),
      hasLength(30),
    );
  });

  testWidgets('the list: a heading, each row once, and the rows per day', (
    tester,
  ) async {
    final folder = Directory.systemTemp.createTempSync('widgets');
    addTearDown(() => folder.deleteSync(recursive: true));
    List<List<WidgetQuest>> days({bool all = false}) => [
      for (var i = 0; i < homeWidgetDays; i++)
        widgetQuests(
          chores: everything,
          today: today,
          l10n: l10n,
          offset: i,
          all: all,
        ),
    ];
    final inputs = WidgetInputs(
      today: today,
      days: days(),
      allDays: days(all: true),
      profileId: 1,
      person: 'Sam',
      points: 42,
      l10n: l10n,
      colorblindSafe: false,
    );
    await tester.runAsync(
      () => drawHomeWidgets(inputs, const {}, folder, list: true),
    );
    final names = {for (final f in folder.listSync()) f.uri.pathSegments.last};
    expect(names, contains('list-day-head.png'));
    expect(names, contains('list-night-head.png'));
    for (var i = 0; i < homeWidgetDays; i++) {
      expect(
        names,
        contains('list-2026-${i < 4 ? '10-${28 + i}' : '11-0${i - 3}'}.json'),
      );
    }
    final Map<String, dynamic> day = jsonDecode(
      File('${folder.path}/list-2026-10-28.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final rows = (day['rows'] as List).cast<Map<String, dynamic>>();
    expect(rows, hasLength(7));
    expect(rows.first['label'], 'Plants, 2 days overdue, 10 points');
    expect(rows.last['label'], 'Wash the car, Anytime, 10 points');
    expect(day['empty'], 'No open quests. Well done!');
    // For ticking off: whose rows, which quest, and whether a tick is on
    // time (due today, within its time of day).
    expect(day['profile'], 1);
    final walk = rows.singleWhere((r) => r['chore'] == 3);
    expect(
      (walk['tick'], walk['due'], walk['from'], walk['to']),
      (true, true, 18 * 60, 19 * 60),
    );
    expect(walk['doneLabel'], 'Walk, done. Tap to Undo');
    expect(rows.first['due'], isFalse, reason: 'late');
    expect(rows.last['tick'], isTrue, reason: 'anytime');
    // Quests due on a later day can't be ticked, and have no done picture.
    final bathroom = rows.singleWhere((r) => r['chore'] == 4);
    expect(bathroom['tick'], isFalse);
    expect(names, contains('list-day-row-${walk['row']}-done.png'));
    expect(names, contains('list-night-row-${walk['row']}-done.png'));
    expect(names, isNot(contains('list-day-row-${bathroom['row']}-done.png')));
    // Every row a day names has its picture, day and night.
    final used = <int>{};
    for (final name in names.where((n) => n.endsWith('.json'))) {
      final json = jsonDecode(
        File('${folder.path}/$name').readAsStringSync(),
      ) as Map<String, dynamic>;
      used.addAll([
        for (final r in json['rows'] as List) (r as Map)['row'] as int,
      ]);
    }
    for (final n in used) {
      expect(names, contains('list-day-row-$n.png'));
      expect(names, contains('list-night-row-$n.png'));
    }
    // Rows that don't change over the week are drawn once, not per day.
    final pictures = names
        .where((n) => n.startsWith('list-day-row-') && !n.contains('done'))
        .length;
    expect(pictures, used.length);
    expect(pictures, lessThan(7 * homeWidgetDays));
    // A row picture, at three times its size.
    final frame = await tester.runAsync(() async {
      final codec = await ui.instantiateImageCodec(
        File('${folder.path}/list-day-row-0.png').readAsBytesSync(),
      );
      return codec.getNextFrame();
    });
    expect(
      (frame!.image.width, frame.image.height),
      (
        (WidgetArt.listWidth * 3).round(),
        (WidgetArt.listRowHeight * 3).round(),
      ),
    );
    // Without the list placed, its files go away again.
    await tester.runAsync(() => drawHomeWidgets(inputs, const {}, folder));
    expect(folder.listSync(), isEmpty);
  });

  testWidgets('each style is drawn day and night for the next days', (
    tester,
  ) async {
    final folder = Directory.systemTemp.createTempSync('widgets');
    addTearDown(() => folder.deleteSync(recursive: true));
    final inputs = WidgetInputs(
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
      profileId: 1,
      person: 'Sam',
      points: 42,
      l10n: l10n,
      colorblindSafe: false,
    );
    File('${folder.path}/old-day-2026-01-01.png').writeAsStringSync('x');
    await tester.runAsync(
      () => drawHomeWidgets(inputs, WidgetStyle.values.toSet(), folder),
    );
    final names = {for (final f in folder.listSync()) f.uri.pathSegments.last};
    expect(names, hasLength(3 * 2 * homeWidgetDays));
    expect(names, contains('board-day-2026-10-28.png'));
    expect(names, contains('path-night-2026-11-03.png'));
    expect(names, isNot(contains('old-day-2026-01-01.png')));
    // A real picture, at three times the widget's size.
    final frame = await tester.runAsync(() async {
      final codec = await ui.instantiateImageCodec(
        File('${folder.path}/next-day-2026-10-28.png').readAsBytesSync(),
      );
      return codec.getNextFrame();
    });
    expect(
      (frame!.image.width, frame.image.height),
      (
        (WidgetStyle.next.width * 3).round(),
        (WidgetStyle.next.height * 3).round(),
      ),
    );
  });
}
