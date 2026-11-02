import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homework_and_chores/data/db/app_database.dart';
import 'package:homework_and_chores/features/world/world_screen.dart';

import '../helpers.dart';

/// Gear, start screen, curses and loot in the Armory: docs/design/items.md.
void main() {
  /// A database where person 1 owns [items] (wearing [worn]) and has a
  /// dust token.
  Future<AppDatabase> gearDb(
    WidgetTester tester, {
    List<String> items = const [],
    Map<GearSlot, String> worn = const {},
    BossFamily? curse,
  }) async => (await tester.runAsync(() async {
    final db = memoryDb();
    final profile = await db.defaultProfileId();
    for (final key in items) {
      await db
          .into(db.inventory)
          .insert(
            InventoryCompanion.insert(
              profileId: profile,
              itemKey: key,
              count: 1,
            ),
          );
    }
    for (final MapEntry(key: slot, value: key) in worn.entries) {
      await db
          .into(db.equipped)
          .insert(
            EquippedCompanion.insert(
              profileId: profile,
              slot: slot,
              itemKey: key,
            ),
          );
    }
    final dusting = (await db.select(db.chores).get()).singleWhere(
      (c) => c.seedKey == 'dusting',
    );
    await db
        .into(db.completions)
        .insert(
          CompletionsCompanion.insert(
            choreId: dusting.id,
            profileId: profile,
            completedAt: DateTime.now(),
            pointsAwarded: 0,
          ),
        );
    if (curse != null) {
      await db
          .update(db.profiles)
          .write(ProfilesCompanion(curseFamily: Value(curse)));
    }
    return db;
  }))!;

  Future<void> openArena(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(NavigationDestination, 'Arena'));
    await tester.pumpAndSettle();
  }

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

  Future<Map<GearSlot, String>> worn(
    WidgetTester tester,
    AppDatabase db,
  ) async => {
    for (final e in (await tester.runAsync(
      () => db.select(db.equipped).get(),
    ))!)
      e.slot: e.itemKey,
  };

  testWidgets('a two-handed weapon takes the shield off', (tester) async {
    final db = await gearDb(
      tester,
      items: ['turbo_mop', 'sponge_shield', 'mop_of_doom'],
      worn: {GearSlot.weapon: 'turbo_mop', GearSlot.shield: 'sponge_shield'},
    );
    await pumpApp(tester, db: db);
    await openArena(tester);
    await tester.tap(find.byKey(const ValueKey('open-gear')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Turbo Mop'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('gear-weapon')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('wear-mop_of_doom')));
    await tester.pumpAndSettle();
    expect(await worn(tester, db), {GearSlot.weapon: 'mop_of_doom'});
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('gear-shield')),
        matching: find.textContaining('Two-handed'),
      ),
      findsOneWidget,
    );

    // Taking it off empties the slot.
    await tester.tap(find.byKey(const ValueKey('gear-weapon')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('gear-take-off')));
    await tester.pumpAndSettle();
    expect(await worn(tester, db), isEmpty);
  });

  testWidgets('a curse shows in the Arena and on quests; soap lifts it', (
    tester,
  ) async {
    final db = await gearDb(
      tester,
      items: ['soap_of_uncursing'],
      curse: BossFamily.laundry,
    );
    await pumpApp(tester, db: db);
    final laundry = find.ancestor(
      of: find.text('Do the laundry'),
      matching: find.byType(Card),
    );
    await tester.scrollUntilVisible(find.text('Do the laundry'), 200);
    expect(
      find.descendant(
        of: laundry,
        matching: find.byKey(const ValueKey('lifts-curse')),
      ),
      findsOneWidget,
    );

    await openArena(tester);
    expect(find.text('Cursed: Wet Socks'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('use-soap')));
    await tester.pumpAndSettle();
    expect(find.text('Curse lifted!'), findsOneWidget);
    expect(find.text('Cursed: Wet Socks'), findsNothing);
    final person = (await tester.runAsync(
      () => db.select(db.profiles).getSingle(),
    ))!;
    expect(person.curseFamily, isNull);
  });

  testWidgets('the start screen spends picked consumables', (tester) async {
    final db = await gearDb(
      tester,
      items: ['snack_break', 'feather_duster'],
      worn: {GearSlot.weapon: 'feather_duster'},
    );
    await pumpApp(tester, db: db);
    await openArena(tester);
    final fight = find.descendant(
      of: find.byKey(const ValueKey('boss-dust')),
      matching: find.text('Fight'),
    );
    await showInArena(tester, fight);
    await tester.tap(fight);
    await tester.pumpAndSettle();

    expect(find.text('Feather Duster of Fury: strong here'), findsOneWidget);
    expect(find.text('HP 5 · damage 1'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('prep-snack_break')));
    await tester.pumpAndSettle();
    expect(find.text('HP 7 · damage 1'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('prep-fight')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.bySemanticsLabel('Health 7 of 7'), findsOneWidget);
    final snacks = (await tester.runAsync(() => db.select(db.inventory).get()))!
        .singleWhere((i) => i.itemKey == 'snack_break');
    expect(snacks.count, 0);

    await tester.tap(find.byTooltip('Leave'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.widgetWithText(TextButton, 'Leave'));
    await tester.pumpAndSettle();
  });

  testWidgets('loot not found yet shows as a question mark', (tester) async {
    final db = await gearDb(tester, items: ['plunger_of_smiting']);
    await pumpApp(tester, db: db);
    await openArena(tester);
    await tester.tap(find.text('Armory'));
    await tester.pumpAndSettle();
    final plunger = find.byKey(const ValueKey('shop-plunger_of_smiting'));
    await tester.scrollUntilVisible(plunger, 200);
    expect(
      find.descendant(of: plunger, matching: find.text('Plunger of Smiting')),
      findsOneWidget,
    );
    final helm = find.byKey(const ValueKey('shop-laundry_basket_helm'));
    await tester.scrollUntilVisible(helm, -200);
    expect(
      find.descendant(of: helm, matching: find.text('???')),
      findsOneWidget,
    );
  });
}
