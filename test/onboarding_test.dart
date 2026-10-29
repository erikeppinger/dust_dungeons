import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homework_and_chores/data/db/app_database.dart';
import 'package:homework_and_chores/data/repositories/settings_repository.dart';

import 'helpers.dart';

void main() {
  testWidgets('first start: language, chores and setup, then Today', (
    tester,
  ) async {
    final db = await pumpApp(tester, onboarding: true);
    expect(find.text('Welcome!'), findsOneWidget);
    expect(find.bySemanticsLabel('Step 1 of 3'), findsOneWidget);

    // Switching the language applies at once.
    await tester.tap(find.text('Deutsch'));
    await tester.pumpAndSettle();
    expect(find.text('Willkommen!'), findsOneWidget);
    await tester.tap(find.text('Weiter'));
    await tester.pumpAndSettle();

    // Untick "Bügeln" (ironing): it gets archived.
    expect(find.text('Welche Quests passen zu dir?'), findsOneWidget);
    final ironing = find.widgetWithText(CheckboxListTile, 'Bügeln');
    await tester.scrollUntilVisible(
      ironing,
      200,
      scrollable: find.byType(Scrollable).at(1),
    );
    await tester.tap(ironing);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Weiter'));
    await tester.pumpAndSettle();

    expect(find.text('Letzter Schliff'), findsOneWidget);
    expect(find.text('Überspringen'), findsNothing, reason: 'last page');
    await tester.tap(find.text("Los geht's"));
    await tester.pumpAndSettle();

    expect(find.text('Quests'), findsWidgets);
    final saved = await tester.runAsync(() => SettingsRepository(db).load());
    expect(saved!.onboardingDone, isTrue);
    expect(saved.locale, const Locale('de'));
    final chores = await tester.runAsync(() => db.select(db.chores).get());
    expect(
      chores!.singleWhere((c) => c.seedKey == 'ironing').isArchived,
      isTrue,
    );
    expect(
      chores.where((c) => c.isArchived).length,
      1,
      reason: 'only the unticked chore',
    );
  });

  testWidgets('skipping keeps every chore', (tester) async {
    final db = await pumpApp(tester, onboarding: true);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(CheckboxListTile).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(find.text('Quests'), findsWidgets);
    final chores = await tester.runAsync(() => db.select(db.chores).get());
    expect(chores!.where((c) => c.isArchived), isEmpty);
  });

  testWidgets('the introduction can be shown again from About', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.widgetWithText(NavigationDestination, 'Settings'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('About'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.ensureVisible(find.text('About'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('About'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Show the introduction again'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome!'), findsOneWidget);
  });

  test('installs from before 0.6 with history skip the introduction', () async {
    final db = memoryDb();
    addTearDown(db.close);
    expect((await SettingsRepository(db).load()).onboardingDone, isFalse);

    final chore = (await db.select(db.chores).get()).first;
    await db
        .into(db.completions)
        .insert(
          CompletionsCompanion.insert(
            choreId: chore.id,
            profileId: await db.defaultProfileId(),
            completedAt: DateTime(2026, 10, 1),
            pointsAwarded: 10,
          ),
        );
    expect((await SettingsRepository(db).load()).onboardingDone, isTrue);
  });

  testWidgets('TalkBack reads a chore tile as one node', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpApp(tester);
    final node = tester.getSemantics(
      find.ancestor(of: find.text('Dusting'), matching: find.byType(InkWell)),
    );
    expect(node.label, contains('Dusting'));
    expect(node.label, contains('points'));
    expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    expect(
      node.getSemanticsData().hasAction(SemanticsAction.longPress),
      isTrue,
    );
    handle.dispose();
  });
}
