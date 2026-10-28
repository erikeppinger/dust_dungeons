// On-device smoke test. Run on an emulator before every commit:
//   flutter test integration_test -d emulator-5554
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homework_and_chores/app/theme/chore_palette.dart';
import 'package:homework_and_chores/data/db/app_database.dart';
import 'package:homework_and_chores/main.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'chores, schedules, plan, stats, undo, editing and settings work on device',
    (tester) async {
      WidgetController.hitTestWarningShouldBeFatal = true;
      tester.platformDispatcher.localesTestValue = [const Locale('en')];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      // Real SQLite on the device, but in memory so the run starts clean.
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      await tester.pumpWidget(await bootstrap(db));
      await tester.pumpAndSettle();

      // First start: the introduction, keeping every chore.
      // Each page change is awaited on screen: on a device the next tap can
      // otherwise land before the page has moved.
      Future<void> waitFor(Finder finder) async {
        for (var i = 0; i < 50 && finder.evaluate().isEmpty; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        await tester.pumpAndSettle();
        expect(finder, findsOneWidget);
      }

      await waitFor(find.text('Welcome!'));
      await tester.tap(find.text('Next'));
      await waitFor(find.text('Which quests apply to you?'));
      await tester.tap(find.text('Next'));
      await waitFor(find.text("Let's go"));
      await tester.tap(find.text("Let's go"));
      await waitFor(find.text('Dusting'));

      // Complete a chore, then undo it.
      expect(find.text('0 points'), findsOneWidget);
      await tester.tap(find.text('Dusting'));
      await tester.pumpAndSettle();
      // Due today: 15 base + 2 on-time bonus.
      expect(find.text('17 points'), findsWidgets);
      expect(find.byTooltip('1× today'), findsOneWidget);
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(find.text('0 points'), findsOneWidget);
      // Let the snackbar leave so it cannot cover the next taps.
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Edit a built-in chore's points via long-press.
      await tester.longPress(find.text('Dusting'));
      await tester.pumpAndSettle();
      expect(find.text('Edit chore'), findsOneWidget);
      await tester.drag(find.byType(Slider), const Offset(400, 0));
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      // 100 base + 10 on-time bonus, shown on the tile.
      expect(find.text('110 points · +10 bonus'), findsOneWidget);

      // Add a custom chore.
      await tester.tap(find.text('Add chore'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField),
        'Wäsche größer ß é Ж 日本 🧺',
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Wäsche größer ß é Ж 日本 🧺'),
        300,
        scrollable: find.byType(Scrollable).first,
      );

      // Plan: week list and month calendar.
      await tester.tap(find.widgetWithText(NavigationDestination, 'Quest Log'));
      await tester.pumpAndSettle();
      expect(find.text('Tomorrow'), findsOneWidget);
      await tester.tap(find.text('Month'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Next month'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Previous month'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Week'));
      await tester.pumpAndSettle();

      // World: the bosses and the hero.
      await tester.tap(find.widgetWithText(NavigationDestination, 'Arena'));
      await tester.pumpAndSettle();
      expect(find.text('Dust Bunny King'), findsOneWidget);
      expect(find.text('Wardrobe'), findsOneWidget);

      // Stats: level card and points explanation.
      await tester.tap(
        find.widgetWithText(NavigationDestination, 'Hall of Fame'),
      );
      await tester.pumpAndSettle();
      expect(find.text('Level 1'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('How points work'), 300);

      // Every tab opens.
      for (final tab in ['Quest Log', 'Arena', 'Hall of Fame', 'Settings']) {
        await tester.tap(find.widgetWithText(NavigationDestination, tab));
        await tester.pumpAndSettle();
        expect(find.widgetWithText(AppBar, tab), findsOneWidget);
      }

      // Archive via Manage chores.
      await tester.tap(find.text('Manage chores'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.widgetWithText(ListTile, 'Dusting'),
          matching: find.byTooltip('Archive'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();

      // Theme modes.
      await tester.tap(find.text('Appearance'));
      await tester.pumpAndSettle();
      for (final (label, mode) in [
        ('Dark', ThemeMode.dark),
        ('Light', ThemeMode.light),
        ('System', ThemeMode.system),
      ]) {
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
        expect(
          tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
          mode,
        );
      }

      // Colorblind palette.
      await tester.tap(find.text('Colorblind-friendly colors'));
      await tester.pumpAndSettle();
      final context = tester.element(find.text('Colorblind-friendly colors'));
      expect(
        Theme.of(context).extension<ChorePalette>()!.isColorblindSafe,
        isTrue,
      );

      await tester.pageBack();
      await tester.pumpAndSettle();

      // Language override to German and back.
      await tester.tap(find.text('Language'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Deutsch'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppBar, 'Sprache'), findsOneWidget);
      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();

      // Archived chore is gone from Today.
      await tester.tap(find.widgetWithText(NavigationDestination, 'Quests'));
      await tester.pumpAndSettle();
      expect(find.text('Dusting'), findsNothing);
    },
  );
}
