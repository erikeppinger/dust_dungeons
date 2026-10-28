import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homework_and_chores/app/theme/chore_palette.dart';
import 'package:homework_and_chores/data/repositories/settings_repository.dart';
import 'package:homework_and_chores/features/chores/chore_edit_screen.dart';
import 'package:homework_and_chores/features/chores/today_screen.dart';
import 'package:homework_and_chores/data/db/app_database.dart';
import 'package:homework_and_chores/features/notifications/notification_planner.dart';
import 'package:homework_and_chores/main.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'helpers.dart';

/// Umlauts, ß, accents, Cyrillic, CJK and emoji in one chore name.
const _unicodeName = 'Wäsche größer ß é Ж 日本 🧺';

Finder get _todayScrollable => find.descendant(
  of: find.byType(TodayScreen),
  matching: find.byType(Scrollable),
);

/// The edit form's list (text fields have their own inner Scrollables).
Finder get _editScrollable => find
    .descendant(
      of: find.byType(ChoreEditScreen),
      matching: find.byType(Scrollable),
    )
    .first;

/// Opens Settings, then the category [entry] (e.g. 'Appearance').
Future<void> _openSettingsPage(WidgetTester tester, String entry) async {
  await _openSettings(tester);
  await tester.tap(find.text(entry));
  await tester.pumpAndSettle();
}

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

    // Dusting is due today: 15 base + 10 % on-time bonus, shown on the tile.
    expect(find.text('17 points · +2 bonus'), findsWidgets);
    await tester.tap(find.text('Dusting'));
    await tester.pumpAndSettle();
    expect(find.text('Dusting done · +17 (incl. 2 bonus)'), findsOneWidget);
    expect(find.text('17 points'), findsWidgets);
    expect(find.byTooltip('1× today'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(find.text('0 points'), findsOneWidget);
    expect(find.byTooltip('1× today'), findsNothing);
  });

  testWidgets('the undo snackbar disappears by itself', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Dusting'));
    await tester.pumpAndSettle();
    expect(find.text('Undo'), findsOneWidget);

    await tester.pumpAndSettle(const Duration(seconds: 6));
    expect(find.text('Undo'), findsNothing);
  });

  testWidgets('a quick double tap completes only one chore', (tester) async {
    await pumpApp(tester);

    // Both taps hit the same spot; after the first, another tile moves there.
    final spot = tester.getCenter(find.text('Dusting'));
    await tester.tapAt(spot);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tapAt(spot);
    await tester.pumpAndSettle();

    expect(find.text('17 points'), findsWidgets);
    expect(find.byTooltip('1× today'), findsOneWidget);
  });

  testWidgets('Stats shows level, streak and points', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Dusting'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(NavigationDestination, 'Stats'));
    await tester.pumpAndSettle();
    expect(find.text('Level 1'), findsOneWidget);
    expect(find.text('83 XP to level 2'), findsOneWidget);
    expect(find.text('1-day streak'), findsOneWidget);
    expect(find.text('17 points'), findsWidgets);

    await tester.scrollUntilVisible(find.text('Most done (30 days)'), 200);
    await tester.scrollUntilVisible(find.text('1×'), 200);
    expect(find.text('1×'), findsOneWidget);
  });

  testWidgets('reaching a new level is celebrated', (tester) async {
    final db = memoryDb();
    await db.defaultProfileId(); // seed
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    await db
        .into(db.completions)
        .insert(
          CompletionsCompanion.insert(
            choreId: 8, // "Hang up laundry" (anytime), so Dusting stays due
            profileId: 1,
            completedAt: yesterday,
            pointsAwarded: 95,
          ),
        );
    await pumpApp(tester, db: db);
    expect(find.text('Level 1'), findsOneWidget);
    expect(find.text('1-day streak'), findsOneWidget);

    // 15 base + 2 on time + 1 streak = 18 -> 113 XP.
    await tester.tap(find.text('Dusting'));
    await tester.pumpAndSettle();
    expect(
      find.text('Level 2 reached! 🎉\nDusting done · +18 (incl. 3 bonus)'),
      findsOneWidget,
    );
    expect(find.text('Level 2'), findsOneWidget);
    expect(find.text('2-day streak'), findsOneWidget);
  });

  testWidgets('turning on notifications asks for permission and plans', (
    tester,
  ) async {
    final notifications = FakeNotificationService();
    await pumpApp(tester, notifications: notifications);
    expect(notifications.scheduled, isEmpty);

    await _openSettingsPage(tester, 'Notifications');
    await tester.tap(find.text('Reminders & summaries'));
    await tester.pumpAndSettle();

    expect(notifications.permissionRequests, 1);
    expect(find.text('Daily summary'), findsOneWidget);
    // Daily built-ins are due every day -> a summary is planned.
    expect(
      notifications.scheduled.where(
        (n) => n.channel == NotificationChannel.summary,
      ),
      isNotEmpty,
    );

    await tester.scrollUntilVisible(find.text('Send a test notification'), 200);
    await tester.ensureVisible(find.text('Send a test notification'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send a test notification'));
    await tester.pump();
    expect(notifications.shown.single.title, startsWith('Notifications work'));

    // Turning it off clears the plan.
    await tester.ensureVisible(find.text('Reminders & summaries'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reminders & summaries'));
    await tester.pumpAndSettle();
    expect(notifications.scheduled, isEmpty);
  });

  testWidgets('denied permission keeps notifications off', (tester) async {
    final notifications = FakeNotificationService(grantPermission: false);
    await pumpApp(tester, notifications: notifications);
    await _openSettingsPage(tester, 'Notifications');
    await tester.tap(find.text('Reminders & summaries'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Notifications are blocked'), findsOneWidget);
    expect(find.text('Daily summary'), findsNothing);
    expect(notifications.scheduled, isEmpty);
  });

  testWidgets('a chore reminder can be switched on in the editor', (
    tester,
  ) async {
    final db = await pumpApp(tester);
    await tester.longPress(find.text('Wash the dishes'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('reminder-switch')),
      200,
      scrollable: _editScrollable,
    );
    await tester.ensureVisible(find.byKey(const ValueKey('reminder-switch')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Notifications are off'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('reminder-switch')));
    await tester.pumpAndSettle();
    expect(find.text('At 9:00 AM'), findsOneWidget);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final dishes = await tester.runAsync(
      () => (db.select(
        db.chores,
      )..where((c) => c.seedKey.equals('dishes'))).getSingle(),
    );
    expect(dishes!.reminderMinutes, 9 * 60);
  });

  testWidgets('tapping a recap notification opens Stats', (tester) async {
    final notifications = FakeNotificationService();
    await pumpApp(tester, notifications: notifications);
    notifications.onTap!(NotificationTarget.stats);
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Stats'), findsOneWidget);
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
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('icon-pets')),
      200,
      scrollable: _editScrollable,
    );
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

  testWidgets('Today groups chores; completing moves one to "done today"', (
    tester,
  ) async {
    await pumpApp(tester);

    // Daily built-ins are due on the first day.
    expect(find.textContaining('Due today ('), findsOneWidget);
    expect(find.text('Wash the dishes'), findsOneWidget);
    expect(find.textContaining('Done today ('), findsNothing);

    await tester.tap(find.text('Wash the dishes'));
    await tester.pumpAndSettle();
    expect(find.text('Done today (1)'), findsOneWidget);
    expect(find.text('Due tomorrow'), findsWidgets);
  });

  testWidgets('a weekly schedule can be set in the editor', (tester) async {
    final db = await pumpApp(tester);

    await tester.longPress(find.text('Dusting'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('repeat-type')),
      200,
      scrollable: _editScrollable,
    );
    await tester.ensureVisible(find.byKey(const ValueKey('repeat-type')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('repeat-type')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Weekly on set days').last);
    await tester.pumpAndSettle();

    // Deselect today's preselected weekday -> validation error on save.
    final today = DateTime.now().weekday;
    await tester.scrollUntilVisible(
      find.byKey(ValueKey('weekday-$today')),
      100,
      scrollable: _editScrollable,
    );
    await tester.ensureVisible(find.byKey(ValueKey('weekday-$today')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ValueKey('weekday-$today')));
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Pick at least one day'), findsOneWidget);

    final other = today == DateTime.monday ? DateTime.tuesday : DateTime.monday;
    await tester.tap(find.byKey(ValueKey('weekday-$other')));
    await tester.pump();
    expect(find.byKey(const ValueKey('repeat-summary')), findsOneWidget);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final dusting = await tester.runAsync(
      () => (db.select(
        db.chores,
      )..where((c) => c.seedKey.equals('dusting'))).getSingle(),
    );
    expect(dusting!.recurrence.type, RepeatType.weekly);
    expect(dusting.recurrence.weekdays, {other});
  });

  testWidgets('date picker opens for a start date years in the past', (
    tester,
  ) async {
    final db = await pumpApp(tester);
    await tester.runAsync(
      () => (db.update(db.chores)..where((c) => c.seedKey.equals('dusting')))
          .write(ChoresCompanion(repeatStart: Value(DateTime(2020, 1, 15)))),
    );
    await tester.pumpAndSettle();

    await tester.longPress(find.text('Dusting'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('First due'),
      200,
      scrollable: _editScrollable,
    );
    await tester.ensureVisible(find.text('First due'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('First due'));
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsOneWidget);
  });

  testWidgets('Plan shows the week and the month calendar', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.widgetWithText(NavigationDestination, 'Plan'));
    await tester.pumpAndSettle();

    expect(find.text('Today'), findsWidgets);
    expect(find.text('Tomorrow'), findsOneWidget);
    expect(find.text('Wash the dishes'), findsWidgets);

    await tester.tap(find.text('Month'));
    await tester.pumpAndSettle();
    final now = DateTime.now();
    expect(
      find.byKey(ValueKey('day-${now.year}-${now.month}-${now.day}')),
      findsOneWidget,
    );
    await tester.tap(find.byTooltip('Next month'));
    await tester.pumpAndSettle();
    final next = DateTime(now.year, now.month + 1, 1);
    expect(
      find.byKey(ValueKey('day-${next.year}-${next.month}-1')),
      findsOneWidget,
    );
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
    await _openSettingsPage(tester, 'Appearance');

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

    // The overview summarizes the current state.
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Dark · colorblind-friendly colors'), findsOneWidget);
  });

  testWidgets('language override switches UI to German', (tester) async {
    await pumpApp(tester);
    await _openSettingsPage(tester, 'Language');

    await tester.tap(find.text('Deutsch'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Sprache'), findsOneWidget);

    // pageBack() looks for the English "Back" tooltip; the UI is German now.
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Einstellungen'), findsOneWidget);
    expect(find.text('Deutsch'), findsOneWidget); // overview subtitle
  });

  testWidgets('settings overview shows each category with its state', (
    tester,
  ) async {
    await pumpApp(tester);
    await _openSettings(tester);
    for (final entry in [
      'Manage chores',
      'Appearance',
      'Notifications',
      'Language',
      'About',
    ]) {
      expect(find.text(entry), findsOneWidget);
    }
    expect(find.text('System'), findsOneWidget); // theme
    expect(find.text('Off'), findsOneWidget); // notifications
    expect(find.text('System default'), findsOneWidget); // language
  });

  testWidgets('About shows privacy, license and the version', (tester) async {
    PackageInfo.setMockInitialValues(
      appName: 'Homework & Chores',
      packageName: 'io.github.changeme.homework_and_chores',
      version: '0.4.1',
      buildNumber: '6',
      buildSignature: '',
    );
    await pumpApp(tester);
    await _openSettingsPage(tester, 'About');
    expect(
      find.textContaining('All data stays on this device'),
      findsOneWidget,
    );
    expect(find.text('Version 0.4.1 (6)'), findsOneWidget);
  });
}
