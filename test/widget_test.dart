import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homework_and_chores/app/theme/chore_palette.dart';
import 'package:homework_and_chores/data/repositories/settings_repository.dart';
import 'package:homework_and_chores/features/chores/chore_edit_screen.dart';
import 'package:homework_and_chores/features/chores/today_screen.dart';
import 'package:homework_and_chores/data/db/app_database.dart';
import 'package:homework_and_chores/domain/dates.dart';
import 'package:homework_and_chores/domain/fight/calibration.dart';
import 'package:homework_and_chores/features/notifications/notification_planner.dart';
import 'package:homework_and_chores/features/fight/boss_art.dart';
import 'package:homework_and_chores/features/world/quest_map.dart';
import 'package:homework_and_chores/features/world/world_screen.dart';
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
  await tester.ensureVisible(find.text(entry));
  await tester.pumpAndSettle();
  await tester.tap(find.text(entry));
  await tester.pumpAndSettle();
}

Future<void> _openSettings(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(NavigationDestination, 'Settings'));
  await tester.pumpAndSettle();
}

void main() {
  /// Scrolls the Arena until [finder] is built and on screen: the boss
  /// cards sit below the hero and the quest map.
  Future<void> showInArena(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      200,
      scrollable: find
          .descendant(
            of: find.byType(WorldScreen),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('starts on Today with built-in chores and 0 points', (
    tester,
  ) async {
    await pumpApp(tester);

    for (final label in [
      'Quests',
      'Quest Log',
      'Arena',
      'Hall of Fame',
      'Settings',
    ]) {
      expect(find.widgetWithText(NavigationDestination, label), findsOneWidget);
    }
    expect(find.text('0 points'), findsOneWidget);
    expect(find.text('Dusting'), findsOneWidget);
  });

  testWidgets('uses German on a German device', (tester) async {
    await pumpApp(tester, locale: const Locale('de'));

    expect(find.text('Quests'), findsWidgets);
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

    await tester.tap(
      find.widgetWithText(NavigationDestination, 'Hall of Fame'),
    );
    await tester.pumpAndSettle();
    expect(find.text('Level 1'), findsOneWidget);
    expect(find.text('83 XP to level 2'), findsOneWidget);
    expect(find.text('1-day streak'), findsOneWidget);
    // Below the realm.
    await tester.scrollUntilVisible(
      find.text('Last 30 days'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('17 points'), findsWidgets);

    await tester.scrollUntilVisible(
      find.text('Favorite quests (30 days)'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.scrollUntilVisible(
      find.text('1×'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
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
    expect(find.text('LV 1'), findsOneWidget);
    expect(find.text('1-day streak'), findsOneWidget);

    // 15 base + 2 on time + 1 streak = 18 -> 113 XP.
    await tester.tap(find.text('Dusting'));
    await tester.pumpAndSettle();
    expect(
      find.text('Level 2 reached! 🎉\nDusting done · +18 (incl. 3 bonus)'),
      findsOneWidget,
    );
    expect(find.text('LV 2'), findsOneWidget);
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
    expect(find.widgetWithText(AppBar, 'Hall of Fame'), findsOneWidget);
  });

  testWidgets('a chore earns a token; leaving a fight uses it up', (
    tester,
  ) async {
    final db = await pumpApp(tester);
    Finder dustCard() => find.byKey(const ValueKey('boss-dust'));

    await tester.tap(find.widgetWithText(NavigationDestination, 'Arena'));
    await tester.pumpAndSettle();
    await showInArena(tester, dustCard());
    expect(find.text('Dust Bunny King'), findsOneWidget);
    expect(
      find.descendant(
        of: dustCard(),
        matching: find.text('Finish a quest for a fight token'),
      ),
      findsOneWidget,
    );
    expect(find.text('Laundry Hydra'), findsOneWidget);

    // Dusting belongs to the dust family: one token.
    await tester.tap(find.widgetWithText(NavigationDestination, 'Quests'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dusting'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(NavigationDestination, 'Arena'));
    await tester.pumpAndSettle();
    await showInArena(tester, dustCard());
    expect(
      find.descendant(of: dustCard(), matching: find.text('× 1')),
      findsOneWidget,
    );

    final fight = find.descendant(of: dustCard(), matching: find.text('Fight'));
    await showInArena(tester, fight);
    await tester.pumpAndSettle();
    // A double tap must start only one fight.
    await tester.tap(fight);
    await tester.tap(fight, warnIfMissed: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Get ready…'), findsOneWidget);

    await tester.tap(find.byTooltip('Leave'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Leave the fight?'), findsOneWidget);
    // "Keep fighting" goes back to the fight, which starts a fresh round.
    await tester.tap(find.text('Keep fighting'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Get ready…'), findsOneWidget);
    await tester.tap(find.byTooltip('Leave'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.widgetWithText(TextButton, 'Leave'));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: dustCard(),
        matching: find.text('Finish a quest for a fight token'),
      ),
      findsOneWidget,
    );
    final fights = await tester.runAsync(() => db.select(db.fights).get());
    expect(fights!.single.family, BossFamily.dust);
    expect(fights.single.result, FightResult.abandoned);
  });

  testWidgets('the hero can be customized and the choice is saved', (
    tester,
  ) async {
    final db = await pumpApp(tester);
    await tester.tap(find.widgetWithText(NavigationDestination, 'Arena'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Wardrobe'));
    await tester.pumpAndSettle();
    expect(find.text('Wardrobe'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const ValueKey('cape-2')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('cape-2')));
    await tester.pumpAndSettle();

    final saved = await tester.runAsync(() => SettingsRepository(db).load());
    expect(saved!.avatarCape, 2);
  });

  testWidgets('fight settings are reachable from World and saved', (
    tester,
  ) async {
    final db = await pumpApp(tester);
    await tester.tap(find.widgetWithText(NavigationDestination, 'Arena'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Boss fights'),
      200,
      scrollable: find
          .descendant(
            of: find.byType(WorldScreen),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.ensureVisible(find.text('Boss fights'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Boss fights'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Story mode'));
    await tester.pumpAndSettle();

    final saved = await tester.runAsync(() => SettingsRepository(db).load());
    expect(saved!.fightStoryMode, isTrue);
    expect(saved.fightSound, isTrue, reason: 'sound is on by default');
  });

  /// A database with [points] to spend and one dust token.
  Future<AppDatabase> richDb(int points) async {
    final db = memoryDb();
    final profile = await db.defaultProfileId();
    final dusting = (await db.select(db.chores).get()).singleWhere(
      (c) => c.seedKey == 'dusting',
    );
    final id = await db
        .into(db.completions)
        .insert(
          CompletionsCompanion.insert(
            choreId: dusting.id,
            profileId: profile,
            completedAt: DateTime.now(),
            pointsAwarded: points,
          ),
        );
    await db
        .into(db.pointLedger)
        .insert(
          PointLedgerCompanion.insert(
            profileId: profile,
            delta: points,
            reason: LedgerReason.completion,
            completionId: Value(id),
            createdAt: DateTime.now(),
          ),
        );
    return db;
  }

  /// Adds one more dust token (a second dusting completion).
  Future<void> richDbAddToken(AppDatabase db) async {
    final dusting = (await db.select(db.chores).get()).singleWhere(
      (c) => c.seedKey == 'dusting',
    );
    await db
        .into(db.completions)
        .insert(
          CompletionsCompanion.insert(
            choreId: dusting.id,
            profileId: await db.defaultProfileId(),
            completedAt: DateTime.now(),
            pointsAwarded: 0,
          ),
        );
  }

  testWidgets('the shop sells hats that the hero can wear', (tester) async {
    final db = await tester.runAsync(() => richDb(300));
    await pumpApp(tester, db: db);
    await tester.tap(find.widgetWithText(NavigationDestination, 'Arena'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Armory'));
    await tester.pumpAndSettle();
    expect(find.text('You have 300 points'), findsOneWidget);

    final crown = find.byKey(const ValueKey('shop-hat_crown'));
    await tester.scrollUntilVisible(crown, 200);
    await tester.ensureVisible(crown);
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(of: crown, matching: find.text('250 pts')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Buy Crown?'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Buy'));
    await tester.pumpAndSettle();
    expect(find.text('Crown bought!'), findsOneWidget);
    expect(
      find.descendant(of: crown, matching: find.text('Owned')),
      findsOneWidget,
    );

    // Too expensive now: the button is disabled.
    final mop = find.byKey(const ValueKey('shop-turbo_mop'));
    await tester.scrollUntilVisible(mop, -200);
    await tester.scrollUntilVisible(find.text('You have 50 points'), -200);
    expect(find.text('You have 50 points'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.descendant(of: mop, matching: find.byType(FilledButton)),
          )
          .onPressed,
      isNull,
    );

    // Wear it.
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Wardrobe'));
    await tester.pumpAndSettle();
    final hat = find.byKey(const ValueKey('hat-4'));
    await tester.scrollUntilVisible(hat, 200);
    await tester.ensureVisible(hat);
    await tester.pumpAndSettle();
    await tester.tap(hat);
    await tester.pumpAndSettle();
    final saved = await tester.runAsync(() => SettingsRepository(db!).load());
    expect(saved!.avatarHat, 4);
  });

  testWidgets('owned gear is used in the next fight after a restart', (
    tester,
  ) async {
    final db = await tester.runAsync(() async {
      final db = await richDb(10);
      await db
          .into(db.inventory)
          .insert(
            InventoryCompanion.insert(
              profileId: 1,
              itemKey: 'rubber_gloves',
              count: 1,
            ),
          );
      return db;
    });
    await pumpApp(tester, db: db);
    await tester.tap(find.widgetWithText(NavigationDestination, 'Arena'));
    await tester.pumpAndSettle();
    expect(find.text('HP 6 · damage 1'), findsOneWidget);

    final fight = find.descendant(
      of: find.byKey(const ValueKey('boss-dust')),
      matching: find.text('Fight'),
    );
    await showInArena(tester, fight);
    await tester.pumpAndSettle();
    await tester.tap(fight);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.bySemanticsLabel('Health 6 of 6'), findsOneWidget);

    await tester.tap(find.byTooltip('Leave'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.widgetWithText(TextButton, 'Leave'));
    await tester.pumpAndSettle();
  });

  testWidgets('Second Wind continues a lost fight', (tester) async {
    final db = await tester.runAsync(() => richDb(100));
    await pumpApp(tester, db: db);
    await tester.tap(find.widgetWithText(NavigationDestination, 'Arena'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Armory'));
    await tester.pumpAndSettle();
    final wind = find.byKey(const ValueKey('shop-second_wind'));
    await tester.scrollUntilVisible(wind, 200);
    await tester.ensureVisible(wind);
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: wind, matching: find.text('60 pts')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Buy'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    final fight = find.descendant(
      of: find.byKey(const ValueKey('boss-dust')),
      matching: find.text('Fight'),
    );
    await showInArena(tester, fight);
    await tester.pumpAndSettle();
    await tester.tap(fight);
    // Never tap: the fight is lost after a few rounds.
    for (
      var i = 0;
      i < 400 && find.textContaining('got away').evaluate().isEmpty;
      i++
    ) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Dust Bunny King got away'), findsOneWidget);
    await tester.tap(find.text('Use Second Wind · 1 left'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Get ready…'), findsOneWidget);
    final inventory = await tester.runAsync(
      () => db!.select(db.inventory).get(),
    );
    expect(inventory!.single.count, 0);

    // Leave; the fight is recorded once, as abandoned (it was still running).
    await tester.tap(find.byTooltip('Leave'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.widgetWithText(TextButton, 'Leave'));
    await tester.pumpAndSettle();
    final fights = await tester.runAsync(() => db!.select(db.fights).get());
    expect(fights!.single.result, FightResult.abandoned);
  });

  Future<void> openFightSettings(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(NavigationDestination, 'Arena'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Boss fights'),
      200,
      scrollable: find
          .descendant(
            of: find.byType(WorldScreen),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.ensureVisible(find.text('Boss fights'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Boss fights'));
    await tester.pumpAndSettle();
  }

  testWidgets('the weekly Overlord waits for five wins', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.widgetWithText(NavigationDestination, 'Arena'));
    await tester.pumpAndSettle();
    final card = find.byKey(const ValueKey('boss-overlord'));
    expect(
      find.descendant(of: card, matching: find.text('Chore Overlord')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: card, matching: find.text('0 of 5 wins this week')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: card, matching: find.text('Fight')),
      findsNothing,
    );
  });

  testWidgets('the quest map shows each win on the road to the Overlord', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final db = await tester.runAsync(() async {
      final db = memoryDb();
      final profile = await db.defaultProfileId();
      for (final f in [BossFamily.trash, BossFamily.dust, BossFamily.trash]) {
        await db
            .into(db.fights)
            .insert(
              FightsCompanion.insert(
                profileId: profile,
                family: f,
                tier: 1,
                startedAt: DateTime.now(),
                result: const Value(FightResult.won),
              ),
            );
      }
      return db;
    });
    await pumpApp(tester, db: db);
    await tester.tap(find.widgetWithText(NavigationDestination, 'Arena'));
    await tester.pumpAndSettle();
    final map = find.byType(QuestMap);
    expect(find.bySemanticsLabel('3 of 5 wins this week'), findsOneWidget);
    final bosses = tester
        .widgetList<BossArt>(
          find.descendant(of: map, matching: find.byType(BossArt)),
        )
        .map((b) => b.family)
        .toList();
    // One portrait per win, in order (repeats included); the lairs ahead
    // are still unexplored.
    expect(bosses, [BossFamily.trash, BossFamily.dust, BossFamily.trash]);
    handle.dispose();
  });

  testWidgets('the Hall of Fame shows the realm by month and by year', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final db = await tester.runAsync(() async {
      final db = memoryDb();
      final profile = await db.defaultProfileId();
      final now = DateTime.now();
      // A win three weeks ago and two this week.
      for (final (f, daysAgo) in [
        (BossFamily.dust, 21),
        (BossFamily.trash, 0),
        (BossFamily.bath, 0),
      ]) {
        await db
            .into(db.fights)
            .insert(
              FightsCompanion.insert(
                profileId: profile,
                family: f,
                tier: 1,
                startedAt: now.subtract(Duration(days: daysAgo)),
                result: const Value(FightResult.won),
              ),
            );
      }
      return db;
    });
    await pumpApp(tester, db: db);
    await tester.tap(
      find.widgetWithText(NavigationDestination, 'Hall of Fame'),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Your realm'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    final strip = find.byKey(const ValueKey('realm-strip'));
    await tester.scrollUntilVisible(
      strip,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Weeks explored'), findsOneWidget);
    expect(find.text('Lairs cleared'), findsOneWidget);
    // This week shows its two cleared lairs.
    final (_, thisWeek) = isoWeek(DateTime.now());
    expect(
      find.bySemanticsLabel('Week $thisWeek: 2 of 5 lairs cleared'),
      findsOneWidget,
    );

    await tester.ensureVisible(find.text('Year'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Year'));
    await tester.pumpAndSettle();
    final year = find.byKey(const ValueKey('realm-year'));
    expect(year, findsOneWidget);
    // Opening the oldest week returns to the strip.
    final (_, firstWeek) = isoWeek(
      DateTime.now().subtract(const Duration(days: 21)),
    );
    final oldest = find.bySemanticsLabel(
      'Week $firstWeek: 1 of 5 lairs cleared',
    );
    await tester.ensureVisible(oldest);
    await tester.pumpAndSettle();
    await tester.tap(oldest);
    await tester.pumpAndSettle();
    expect(year, findsNothing);
    expect(strip, findsOneWidget);
    handle.dispose();
  });

  testWidgets('after five wins the Overlord can be fought without a token', (
    tester,
  ) async {
    final db = await tester.runAsync(() async {
      final db = memoryDb();
      final profile = await db.defaultProfileId();
      for (final f in [
        BossFamily.dust,
        BossFamily.kitchen,
        BossFamily.dust,
        BossFamily.bath,
        BossFamily.trash,
      ]) {
        await db
            .into(db.fights)
            .insert(
              FightsCompanion.insert(
                profileId: profile,
                family: f,
                tier: 1,
                startedAt: DateTime.now(),
                result: const Value(FightResult.won),
              ),
            );
      }
      return db;
    });
    await pumpApp(tester, db: db);
    await tester.tap(find.widgetWithText(NavigationDestination, 'Arena'));
    await tester.pumpAndSettle();
    final fight = find.descendant(
      of: find.byKey(const ValueKey('boss-overlord')),
      matching: find.text('Fight'),
    );
    await showInArena(tester, fight);
    await tester.pumpAndSettle();
    await tester.tap(fight);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Tier 1 · phase 1 of 3'), findsOneWidget);

    await tester.tap(find.byTooltip('Leave'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      find.text('The Overlord stays until Sunday, so you can try again.'),
      findsOneWidget,
    );
    await tester.tap(find.widgetWithText(TextButton, 'Leave'));
    await tester.pumpAndSettle();
    final fights = await tester.runAsync(() => db!.select(db.fights).get());
    expect(fights!.last.family, BossFamily.overlord);
    expect(fights.last.result, FightResult.abandoned);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('boss-overlord')),
        matching: find.text('Fight'),
      ),
      findsOneWidget,
      reason: 'it stays until beaten',
    );
  });

  testWidgets('"Fight again" keeps the gear', (tester) async {
    final db = await tester.runAsync(() async {
      final db = await richDb(10);
      await richDbAddToken(db);
      await db
          .into(db.inventory)
          .insert(
            InventoryCompanion.insert(
              profileId: 1,
              itemKey: 'rubber_gloves',
              count: 1,
            ),
          );
      return db;
    });
    await pumpApp(tester, db: db);
    await tester.tap(find.widgetWithText(NavigationDestination, 'Arena'));
    await tester.pumpAndSettle();
    final fight = find.descendant(
      of: find.byKey(const ValueKey('boss-dust')),
      matching: find.text('Fight'),
    );
    await showInArena(tester, fight);
    await tester.pumpAndSettle();
    await tester.tap(fight);
    // Never tap: the fight is lost after a few rounds.
    for (
      var i = 0;
      i < 900 && find.textContaining('got away').evaluate().isEmpty;
      i++
    ) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.ensureVisible(find.text('Fight again · 1 token left'));
    await tester.pump();
    await tester.tap(find.text('Fight again · 1 token left'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.bySemanticsLabel('Health 6 of 6'), findsOneWidget);

    await tester.tap(find.byTooltip('Leave'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.widgetWithText(TextButton, 'Leave'));
    await tester.pumpAndSettle();
  });

  testWidgets('timing calibration measures and saves the delay', (
    tester,
  ) async {
    final db = await pumpApp(tester);
    await openFightSettings(tester);
    await tester.tap(find.text('Slow mode'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Timing calibration'));
    await tester.pumpAndSettle();
    expect(find.text('Current offset: 0 ms'), findsOneWidget);

    await tester.tap(find.text('Start'));
    await tester.pump();
    var now = 0;
    for (var i = 0; i < calibrationBeats; i++) {
      final at = 1200 + i * calibrationBeatMs + 40;
      await tester.pump(Duration(milliseconds: at - now));
      now = at;
      await tester.tap(find.byKey(const ValueKey('calibrate-pad')));
    }
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Your offset: 40 ms'), findsOneWidget);
    await tester.ensureVisible(find.text('Save'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Offset 40 ms'), findsOneWidget);

    final saved = await tester.runAsync(() => SettingsRepository(db).load());
    expect(saved!.fightLatencyMs, 40);
    expect(saved.fightSlowMode, isTrue);
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

  testWidgets(
    'Today groups chores; completing moves one to "completed today"',
    (tester) async {
      await pumpApp(tester);

      // Daily built-ins are due on the first day.
      expect(find.textContaining("Today's quests ("), findsOneWidget);
      expect(find.text('Wash the dishes'), findsOneWidget);
      expect(find.textContaining('Completed today ('), findsNothing);

      await tester.tap(find.text('Wash the dishes'));
      await tester.pumpAndSettle();
      expect(find.text('Completed today (1)'), findsOneWidget);
      expect(find.text('Due tomorrow'), findsWidgets);
    },
  );

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
    await tester.tap(find.widgetWithText(NavigationDestination, 'Quest Log'));
    await tester.pumpAndSettle();

    expect(find.text('Quests'), findsWidgets);
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
    await tester.tap(find.widgetWithText(NavigationDestination, 'Quests'));
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
      'Screen time',
      'Language',
      'About',
    ]) {
      expect(find.text(entry), findsOneWidget);
    }
    expect(find.text('System'), findsOneWidget); // theme
    expect(find.text('Off'), findsNWidgets(2)); // notifications, screen time
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
