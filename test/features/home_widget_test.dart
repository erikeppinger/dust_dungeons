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
