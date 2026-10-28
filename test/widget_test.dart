import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homework_and_chores/app/theme/chore_palette.dart';
import 'package:homework_and_chores/data/repositories/settings_repository.dart';
import 'package:homework_and_chores/features/chores/today_screen.dart';
import 'package:homework_and_chores/main.dart';

import 'helpers.dart';

/// Umlauts, ß, accents, Cyrillic, CJK and emoji in one chore name.
const _unicodeName = 'Wäsche größer ß é Ж 日本 🧺';

Finder get _todayScrollable => find.descendant(
  of: find.byType(TodayScreen),
  matching: find.byType(Scrollable),
);

Future<void> _openSettings(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(NavigationDestination, 'Settings'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('starts on Today with built-in chores and 0 points', (
    tester,
  ) async {
    await pumpApp(tester);

    for (final label in ['Today', 'Plan', 'World', 'Stats', 'Settings']) {
      expect(find.widgetWithText(NavigationDestination, label), findsOneWidget);
    }
    expect(find.text('0 points'), findsOneWidget);
    expect(find.text('Dusting'), findsOneWidget);
  });

  testWidgets('uses German on a German device', (tester) async {
    await pumpApp(tester, locale: const Locale('de'));

    expect(find.text('Heute'), findsWidgets);
    expect(find.text('Staub wischen'), findsOneWidget);
    expect(find.text('0 Punkte'), findsOneWidget);
  });

  testWidgets('completing a chore awards points and undo reverts them', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.text('Dusting'));
    await tester.pumpAndSettle();
    expect(find.text('Dusting done · +15'), findsOneWidget);
    expect(find.text('15 points'), findsWidgets);
    expect(find.byTooltip('1× today'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(find.text('0 points'), findsOneWidget);
    expect(find.byTooltip('1× today'), findsNothing);
  });

  testWidgets('a quick double tap counts as one completion', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('Dusting'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('Dusting'));
    await tester.pumpAndSettle();

    expect(find.text('15 points'), findsWidgets);
    expect(find.byTooltip('1× today'), findsOneWidget);
  });

  testWidgets('startup error screen explains the problem', (tester) async {
    tester.platformDispatcher.localesTestValue = [const Locale('en')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(const StartupErrorApp(error: 'disk full'));
    await tester.pumpAndSettle();

    expect(find.textContaining('could not open its data'), findsOneWidget);
    expect(find.text('disk full'), findsOneWidget);
  });

  testWidgets('adds a new chore with special characters, validating the name', (
    tester,
  ) async {
    final db = await pumpApp(tester);

    await tester.tap(find.text('Add chore'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Please enter a name'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), _unicodeName);
    await tester.ensureVisible(find.byKey(const ValueKey('icon-pets')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('icon-pets')));
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.byType(TodayScreen), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text(_unicodeName),
      300,
      scrollable: _todayScrollable,
    );
    expect(find.text(_unicodeName), findsOneWidget);
    final saved = await tester.runAsync(
      () => (db.select(
        db.chores,
      )..where((c) => c.customTitle.equals(_unicodeName))).getSingle(),
    );
    expect(saved!.iconKey, 'pets');
  });

  testWidgets('archiving in Manage chores hides a chore from Today', (
    tester,
  ) async {
    await pumpApp(tester);
    await _openSettings(tester);

    await tester.tap(find.text('Manage chores'));
    await tester.pumpAndSettle();
    final dustingRow = find.widgetWithText(ListTile, 'Dusting');
    await tester.tap(
      find.descendant(of: dustingRow, matching: find.byTooltip('Archive')),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Archived (1)'), 300);
    expect(
      find.descendant(
        of: find.widgetWithText(ListTile, 'Dusting'),
        matching: find.byTooltip('Restore'),
      ),
      findsOneWidget,
    );

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(NavigationDestination, 'Today'));
    await tester.pumpAndSettle();
    expect(find.text('Dusting'), findsNothing);
  });

  testWidgets('settings change theme and palette and are saved', (
    tester,
  ) async {
    final db = await pumpApp(tester);
    await _openSettings(tester);

    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.dark,
    );

    await tester.tap(find.text('Colorblind-friendly colors'));
    await tester.pumpAndSettle();
    final context = tester.element(find.text('Colorblind-friendly colors'));
    expect(
      Theme.of(context).extension<ChorePalette>()!.isColorblindSafe,
      isTrue,
    );

    final saved = await tester.runAsync(() => SettingsRepository(db).load());
    expect(saved!.themeMode, ThemeMode.dark);
    expect(saved.colorblindSafe, isTrue);
  });

  testWidgets('language override switches UI to German', (tester) async {
    await pumpApp(tester);
    await _openSettings(tester);

    await tester.scrollUntilVisible(find.text('Deutsch'), 200);
    await tester.tap(find.text('Deutsch'));
    await tester.pumpAndSettle();

    expect(find.text('Einstellungen'), findsWidgets);
  });
}
