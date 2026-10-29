import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homework_and_chores/data/db/app_database.dart';
import 'package:homework_and_chores/data/models/app_settings.dart';
import 'package:homework_and_chores/data/repositories/settings_repository.dart';

import 'helpers.dart';

/// Several people sharing the phone (docs/design/profiles.md).
void main() {
  Future<void> openSwitcher(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('person-button')));
    await tester.pumpAndSettle();
  }

  Future<void> addPerson(WidgetTester tester, String name) async {
    await openSwitcher(tester);
    await tester.tap(find.byKey(const ValueKey('manage-people')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add a person'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('person-name')), name);
    await tester.tap(find.byKey(const ValueKey('person-save')));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
  }

  Future<void> switchTo(WidgetTester tester, String name) async {
    await openSwitcher(tester);
    await tester.tap(find.widgetWithText(ListTile, name).last);
    await tester.pumpAndSettle();
  }

  Future<void> completeDusting(WidgetTester tester) async {
    await tester.tap(find.text('Dusting'));
    await tester.pumpAndSettle();
    // Let the undo snackbar go.
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
  }

  testWidgets('each person has their own points; switching is remembered', (
    tester,
  ) async {
    final db = await pumpApp(tester);
    await completeDusting(tester);
    expect(find.text('17 points'), findsOneWidget);

    await addPerson(tester, 'Sam');
    await switchTo(tester, 'Sam');
    expect(find.text('0 points'), findsOneWidget);
    expect(find.byTooltip('Switch person, now: Sam'), findsOneWidget);

    // A restart keeps Sam.
    await tester.pumpWidget(const SizedBox());
    await pumpApp(tester, db: db);
    expect(find.byTooltip('Switch person, now: Sam'), findsOneWidget);
    await switchTo(tester, 'Me');
    expect(find.text('17 points'), findsOneWidget);
  });

  testWidgets("anyone's quest done by Sam shows who did it", (tester) async {
    await pumpApp(tester);
    await addPerson(tester, 'Sam');
    await switchTo(tester, 'Sam');
    await completeDusting(tester);
    await switchTo(tester, 'Me');
    await tester.scrollUntilVisible(
      find.text('Dusting'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Sam'), findsOneWidget); // the done badge
    expect(find.text('0 points'), findsOneWidget);
  });

  testWidgets("a quest for one person isn't shown to others", (tester) async {
    await pumpApp(tester);
    await addPerson(tester, 'Sam');
    await tester.longPress(find.text('Dusting'));
    await tester.pumpAndSettle();
    final assignment = find.byKey(const ValueKey('assignment'));
    await tester.scrollUntilVisible(
      assignment,
      200,
      scrollable: find
          .descendant(of: find.byType(Form), matching: find.byType(Scrollable))
          .first,
    );
    await tester.tap(find.text('One person'));
    await tester.pumpAndSettle();
    final samChip = find.byKey(const ValueKey('assignee-2'));
    await tester.ensureVisible(samChip);
    await tester.tap(samChip);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Dusting'), findsNothing);
    await switchTo(tester, 'Sam');
    expect(find.text('Dusting'), findsOneWidget);
  });

  testWidgets('a second person turns screen time off', (tester) async {
    final db = memoryDb();
    await tester.runAsync(
      () =>
          SettingsRepository(db)
              .save(const AppSettings(screenTime: true, onboardingDone: true)),
    );
    await pumpApp(tester, db: db);
    await openSwitcher(tester);
    await tester.tap(find.byKey(const ValueKey('manage-people')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add a person'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Screen time works with one person on this phone, '
        'so it will turn off.',
      ),
      findsOneWidget,
    );
    await tester.enterText(find.byKey(const ValueKey('person-name')), 'Sam');
    await tester.tap(find.byKey(const ValueKey('person-save')));
    await tester.pumpAndSettle();
    final saved = await tester.runAsync(() => SettingsRepository(db).load());
    expect(saved!.screenTime, isFalse);

    // And it can't be turned back on while two people share the phone.
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(NavigationDestination, 'Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Screen time'));
    await tester.pumpAndSettle();
    expect(
      find.text('Screen time works with one person on this phone.'),
      findsOneWidget,
    );
    final enable = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Use a screen-time budget'),
    );
    expect(enable.onPressed, isNull);
  });

  testWidgets('names must be new; the last person stays', (tester) async {
    await pumpApp(tester);
    await openSwitcher(tester);
    await tester.tap(find.byKey(const ValueKey('manage-people')));
    await tester.pumpAndSettle();
    // Alone: nobody can be removed.
    expect(find.byIcon(Icons.person_remove_outlined), findsNothing);
    await tester.tap(find.text('Add a person'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('person-name')), ' me ');
    await tester.tap(find.byKey(const ValueKey('person-save')));
    await tester.pumpAndSettle();
    expect(find.text('Someone here already has that name.'), findsOneWidget);
  });

  testWidgets('removing a person after confirming', (tester) async {
    await pumpApp(tester);
    await addPerson(tester, 'Sam');
    await openSwitcher(tester);
    await tester.tap(find.byKey(const ValueKey('manage-people')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Remove Sam?'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('remove-confirm')));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(ListTile, 'Sam'), findsNothing);
  });

  testWidgets('the Hall of Fame ranks the week with several people', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(
      find.widgetWithText(NavigationDestination, 'Hall of Fame'),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('leaderboard')), findsNothing);

    await tester.tap(find.widgetWithText(NavigationDestination, 'Quests'));
    await tester.pumpAndSettle();
    await completeDusting(tester);
    await addPerson(tester, 'Sam');
    await tester.tap(
      find.widgetWithText(NavigationDestination, 'Hall of Fame'),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('leaderboard')), findsOneWidget);
    expect(
      find.bySemanticsLabel('Rank 1: Me, 17 points, 1 quest'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('Rank 2: Sam, 0 points, 0 quests'),
      findsOneWidget,
    );
  });

  testWidgets('story mode belongs to the person', (tester) async {
    final db = await pumpApp(tester);
    await addPerson(tester, 'Sam');
    await tester.tap(find.widgetWithText(NavigationDestination, 'Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Boss fights'));
    await tester.pumpAndSettle();
    expect(find.text('For Me:'), findsOneWidget);
    await tester.tap(find.text('Story mode'));
    await tester.pumpAndSettle();
    final people = await tester.runAsync(() => db.select(db.profiles).get());
    expect(
      {for (final Profile p in people!) p.name: p.storyMode},
      {'Me': true, 'Sam': false},
    );
  });
}
