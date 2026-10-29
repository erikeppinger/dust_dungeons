import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homework_and_chores/core/day_clock.dart';
import 'package:homework_and_chores/data/db/app_database.dart';
import 'package:homework_and_chores/data/models/app_settings.dart';
import 'package:homework_and_chores/data/repositories/settings_repository.dart';
import 'package:homework_and_chores/domain/dates.dart';

import 'helpers.dart';

const video = 'com.example.video';

void main() {
  final today = startOfDay(DateTime.now());

  /// A database with screen time on, counting the video app.
  Future<AppDatabase> screenDb(
    WidgetTester tester, {
    int pointsYesterday = 0,
    ({int used, int budget})? yesterday,
  }) async => (await tester.runAsync(() async {
    final db = memoryDb();
    final profile = await db.defaultProfileId();
    await SettingsRepository(db).save(
      const AppSettings(
        onboardingDone: true,
        screenTime: true,
        screenApps: [video],
      ),
    );
    if (pointsYesterday > 0) {
      final chore = (await db.select(db.chores).get()).first;
      final id = await db
          .into(db.completions)
          .insert(
            CompletionsCompanion.insert(
              choreId: chore.id,
              profileId: profile,
              completedAt: addDays(today, -1),
              pointsAwarded: pointsYesterday,
            ),
          );
      await db
          .into(db.pointLedger)
          .insert(
            PointLedgerCompanion.insert(
              profileId: profile,
              delta: pointsYesterday,
              reason: LedgerReason.completion,
              completionId: Value(id),
              createdAt: addDays(today, -1),
            ),
          );
    }
    if (yesterday != null) {
      await db
          .into(db.screenDays)
          .insert(
            ScreenDaysCompanion.insert(
              profileId: profile,
              day: addDays(today, -1),
              usedMinutes: Value(yesterday.used),
              budgetMinutes: Value(yesterday.budget),
            ),
          );
    }
    return db;
  }))!;

  Future<void> openScreenTime(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(NavigationDestination, 'Settings'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Screen time'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Screen time'));
    await tester.pumpAndSettle();
  }

  testWidgets('switching it on asks for usage access', (tester) async {
    final screen = FakeScreenTimeService()..access = false;
    final db = await pumpApp(tester, screenTime: screen);
    await openScreenTime(tester);
    expect(find.text('Use a screen-time budget'), findsOneWidget);
    await tester.tap(find.text('Use a screen-time budget'));
    await tester.pumpAndSettle();
    expect(screen.settingsOpened, 1);
    expect(
      find.text("Usage access is off, so screen time can't be measured."),
      findsOneWidget,
    );
    final saved = await tester.runAsync(() => SettingsRepository(db).load());
    expect(saved!.screenTime, isTrue);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(NavigationDestination, 'Quests'));
    await tester.pumpAndSettle();
    expect(find.text('Usage access is off'), findsOneWidget);
  });

  testWidgets('the Quests bar counts down, and quests earn minutes', (
    tester,
  ) async {
    final screen = FakeScreenTimeService()
      ..usage[today] = {video: 50, 'com.example.chat': 99};
    final db = await screenDb(tester);
    await pumpApp(tester, db: db, screenTime: screen);
    // 60 base − 50 used; the chat app does not count.
    expect(find.text('10 min left'), findsOneWidget);

    await tester.tap(find.text('Dusting'));
    await tester.pumpAndSettle();
    // 17 points earn 3 minutes.
    expect(find.text('13 min left'), findsOneWidget);
    final snapshot = screen.snapshots.last;
    expect(snapshot['enabled'], isTrue);
    expect(snapshot['budgetMinutes'], 63);
    expect(snapshot['packages'], [video]);
    expect(
      (snapshot['texts']! as Map)['warnBody'],
      'Screen time left today: {left} min',
    );
    final days = await tester.runAsync(() => db.select(db.screenDays).get());
    final saved = days!.singleWhere((d) => d.day == today);
    expect((saved.usedMinutes, saved.budgetMinutes), (50, 63));

    screen.usage[today] = {video: 70};
    await tester.tap(find.byKey(const ValueKey('screen-time-bar')));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
  });

  testWidgets('vouchers are sold in the Armory and add minutes', (
    tester,
  ) async {
    final db = await screenDb(tester, pointsYesterday: 100);
    await pumpApp(tester, db: db);
    await tester.tap(find.widgetWithText(NavigationDestination, 'Arena'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Armory'));
    await tester.pumpAndSettle();
    final voucher = find.byKey(const ValueKey('shop-screen_15'));
    await tester.scrollUntilVisible(voucher, 200);
    await tester.tap(
      find.descendant(of: voucher, matching: find.text('40 pts')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Buy'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    await openScreenTime(tester);
    expect(find.text('0 of 60 min used'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('use-screen_15')));
    await tester.pumpAndSettle();
    expect(find.text('0 of 75 min used'), findsOneWidget);
    expect(find.byKey(const ValueKey('use-screen_15')), findsNothing);
  });

  testWidgets('a day over budget makes the hero tired', (tester) async {
    final db = await screenDb(tester, yesterday: (used: 90, budget: 60));
    await pumpApp(tester, db: db);
    await tester.tap(find.widgetWithText(NavigationDestination, 'Arena'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('tired')), findsOneWidget);
    expect(find.text('HP 4 · damage 1'), findsOneWidget);
  });

  testWidgets('a day within budget leaves the hero rested', (tester) async {
    final db = await screenDb(tester, yesterday: (used: 40, budget: 60));
    await pumpApp(tester, db: db);
    await tester.tap(find.widgetWithText(NavigationDestination, 'Arena'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('tired')), findsNothing);
    expect(find.text('HP 5 · damage 1'), findsOneWidget);
  });

  testWidgets('the app picker chooses which apps count', (tester) async {
    final db = await screenDb(tester);
    await pumpApp(tester, db: db);
    await openScreenTime(tester);
    await tester.scrollUntilVisible(
      find.text('Apps that count'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.ensureVisible(find.text('Apps that count'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apps that count'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('app-com.example.game')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('app-com.example.game')));
    await tester.pumpAndSettle();
    final saved = await tester.runAsync(() => SettingsRepository(db).load());
    expect(saved!.screenApps, [video, 'com.example.game']);
  });

  testWidgets('the screen-time page meets the accessibility guidelines', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    final handle = tester.ensureSemantics();
    final db = await screenDb(tester, yesterday: (used: 90, budget: 60));
    await pumpApp(
      tester,
      db: db,
      screenTime: FakeScreenTimeService()..usage[today] = {video: 20},
    );
    await openScreenTime(tester);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    handle.dispose();
  });
}
