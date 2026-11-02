import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homework_and_chores/data/db/app_database.dart';

import 'helpers.dart';

/// The quest editor's schedule options (docs/design/scheduling.md).
void main() {
  final editScrollable = find
      .descendant(of: find.byType(Form), matching: find.byType(Scrollable))
      .first;

  Future<void> show(WidgetTester tester, Finder target) async {
    await tester.scrollUntilVisible(target, 200, scrollable: editScrollable);
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
  }

  Future<void> pick(WidgetTester tester, String dropdown, String item) async {
    await show(tester, find.byKey(ValueKey(dropdown)));
    await tester.tap(find.byKey(ValueKey(dropdown)));
    await tester.pumpAndSettle();
    await tester.tap(find.text(item).last);
    await tester.pumpAndSettle();
  }

  testWidgets('monthly on a weekday, open 3 days, at certain times', (
    tester,
  ) async {
    final db = await pumpApp(tester);
    await tester.tap(find.text('Add quest'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Water filter');

    await pick(tester, 'repeat-type', 'Monthly');
    await show(tester, find.text('On a weekday'));
    await tester.tap(find.text('On a weekday'));
    await tester.pumpAndSettle();
    await pick(tester, 'month-week', '1st');
    await pick(tester, 'month-weekday', 'Monday');
    expect(find.text('Monthly on the 1st Monday'), findsOneWidget);
    expect(find.textContaining('Next: '), findsOneWidget);

    await pick(tester, 'window-days', '3 days');
    await show(tester, find.byKey(const ValueKey('times-switch')));
    await tester.tap(find.byKey(const ValueKey('times-switch')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    final saved = await tester.runAsync(
      () => (db.select(
        db.chores,
      )..where((c) => c.customTitle.equals('Water filter'))).getSingle(),
    );
    final r = saved!.recurrence;
    expect(r.type, RepeatType.monthly);
    expect(r.monthWeek, 1);
    expect(r.weekdays, {DateTime.monday});
    expect(r.windowDays, 3);
    expect((saved.windowFrom, saved.windowTo), (18 * 60, 20 * 60));
  });

  testWidgets('the two "every few days" options show how they differ', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.text('Add quest'));
    await tester.pumpAndSettle();
    await pick(tester, 'repeat-type', 'Every … days, fixed rhythm');
    expect(find.textContaining('Next: '), findsOneWidget);
    await pick(tester, 'repeat-type', "… days after it's done");
    expect(find.textContaining('If done today, next on'), findsOneWidget);
  });
}
