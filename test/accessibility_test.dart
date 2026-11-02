import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homework_and_chores/data/models/app_settings.dart';
import 'package:homework_and_chores/data/repositories/settings_repository.dart';

import 'helpers.dart';

/// Accessibility audit: every main screen meets Flutter's guidelines for
/// tap target size, labeled tap targets and text contrast, in light and dark
/// mode with both palettes, and still lays out at 200 % font size.
void main() {
  const tabs = ['Quests', 'Quest Log', 'Arena', 'Hall of Fame', 'Settings'];

  Future<void> pumpWith(WidgetTester tester, AppSettings settings) async {
    final db = memoryDb();
    await tester.runAsync(() => SettingsRepository(db).save(settings));
    await pumpApp(tester, db: db);
  }

  Future<void> openTab(WidgetTester tester, String tab) async {
    await tester.tap(find.widgetWithText(NavigationDestination, tab));
    await tester.pumpAndSettle();
  }

  for (final (name, settings) in [
    ('light', const AppSettings(themeMode: ThemeMode.light)),
    ('dark', const AppSettings(themeMode: ThemeMode.dark)),
    (
      'dark colorblind',
      const AppSettings(themeMode: ThemeMode.dark, colorblindSafe: true),
    ),
    (
      'light colorblind',
      const AppSettings(themeMode: ThemeMode.light, colorblindSafe: true),
    ),
  ]) {
    for (final tab in tabs) {
      testWidgets('$tab meets the guidelines ($name)', (tester) async {
        // A typical phone screen.
        tester.view.physicalSize = const Size(1080, 2340);
        tester.view.devicePixelRatio = 2.75;
        addTearDown(tester.view.reset);
        final handle = tester.ensureSemantics();
        await pumpWith(tester, settings);
        await openTab(tester, tab);
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      });
    }
  }

  /// Opens a screen below the tabs by tapping through [steps] (texts).
  Future<void> openScreen(
    WidgetTester tester,
    String tab,
    List<String> steps,
  ) async {
    await openTab(tester, tab);
    for (final step in steps) {
      final target = find.text(step);
      await tester.scrollUntilVisible(
        target,
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.ensureVisible(target.first);
      await tester.pumpAndSettle();
      await tester.tap(target.first);
      await tester.pumpAndSettle();
    }
  }

  /// Secondary screens: (name, tab, taps in English, taps in German).
  const screens = [
    ('shop', 'Arena', ['Armory'], ['Rüstkammer']),
    ('avatar', 'Arena', ['Wardrobe'], ['Garderobe']),
    ('gear', 'Arena', ['Gear'], ['Ausrüstung']),
    ('fight settings', 'Settings', ['Boss fights'], ['Bosskämpfe']),
    (
      'calibration',
      'Settings',
      ['Boss fights', 'Timing calibration'],
      ['Bosskämpfe', 'Timing kalibrieren'],
    ),
    ('appearance', 'Settings', ['Appearance'], ['Darstellung']),
    ('notifications', 'Settings', ['Notifications'], ['Benachrichtigungen']),
    ('about', 'Settings', ['About'], ['Über']),
    ('manage chores', 'Settings', ['Manage quests'], ['Quests verwalten']),
    ('add chore', 'Quests', ['Add quest'], ['Quest hinzufügen']),
    ('screen time', 'Settings', ['Screen time'], ['Bildschirmzeit']),
    ('backup', 'Settings', ['Backup'], ['Datensicherung']),
    ('people', 'Settings', ['People'], ['Personen']),
  ];

  for (final (name, tab, steps, _) in screens) {
    for (final dark in [false, true]) {
      testWidgets('$name meets the guidelines (${dark ? 'dark' : 'light'})', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(1080, 2340);
        tester.view.devicePixelRatio = 2.75;
        addTearDown(tester.view.reset);
        final handle = tester.ensureSemantics();
        await pumpWith(
          tester,
          AppSettings(themeMode: dark ? ThemeMode.dark : ThemeMode.light),
        );
        await openScreen(tester, tab, steps);
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      });
    }
  }

  for (final (name, _, _, stepsDe) in screens) {
    testWidgets('$name lays out at 200 % font size in German', (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 2.75;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpWith(tester, const AppSettings(locale: Locale('de')));
      final tab = switch (name) {
        'shop' || 'avatar' || 'gear' => 'Arena',
        'add chore' => 'Quests',
        _ => 'Einstellungen',
      };
      await openScreen(tester, tab, stepsDe);
      expect(tester.takeException(), isNull);
    });
  }

  for (final dark in [false, true]) {
    testWidgets(
      'onboarding meets the guidelines (${dark ? 'dark' : 'light'})',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2340);
        tester.view.devicePixelRatio = 2.75;
        addTearDown(tester.view.reset);
        final handle = tester.ensureSemantics();
        final db = memoryDb();
        await tester.runAsync(
          () => SettingsRepository(db).save(
            AppSettings(themeMode: dark ? ThemeMode.dark : ThemeMode.light),
          ),
        );
        await pumpApp(tester, db: db, onboarding: true);
        for (var page = 0; page < 3; page++) {
          await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
          await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
          await expectLater(tester, meetsGuideline(textContrastGuideline));
          if (page < 2) {
            await tester.tap(find.text('Next'));
            await tester.pumpAndSettle();
          }
        }
        handle.dispose();
      },
    );
  }

  testWidgets('onboarding lays out at 200 % font size in German', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.75;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final db = memoryDb();
    await tester.runAsync(
      () =>
          SettingsRepository(db).save(const AppSettings(locale: Locale('de'))),
    );
    await pumpApp(tester, db: db, onboarding: true);
    for (var page = 0; page < 2; page++) {
      await tester.tap(find.text('Weiter'));
      await tester.pumpAndSettle();
    }
    expect(tester.takeException(), isNull);
  });

  for (final tab in tabs) {
    testWidgets('$tab lays out at 200 % font size', (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 2.75;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpWith(tester, const AppSettings());
      await openTab(tester, tab);
      // Overflows are reported as errors and fail the test.
      expect(tester.takeException(), isNull);
    });

    testWidgets('$tab lays out at 200 % font size in German', (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 2.75;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpWith(tester, const AppSettings(locale: Locale('de')));
      const german = {
        'Quests': 'Quests',
        'Quest Log': 'Questbuch',
        'Arena': 'Arena',
        'Hall of Fame': 'Ruhmeshalle',
        'Settings': 'Einstellungen',
      };
      await openTab(tester, german[tab]!);
      expect(tester.takeException(), isNull);
    });
  }
}
