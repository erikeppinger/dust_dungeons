import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homework_and_chores/app/art/art.dart';
import 'package:homework_and_chores/data/db/app_database.dart';
import 'package:homework_and_chores/data/models/fight_progress.dart';
import 'package:homework_and_chores/domain/fight/boss.dart';
import 'package:homework_and_chores/domain/fight/echo_duel.dart';
import 'package:homework_and_chores/features/fight/boss_art.dart';
import 'package:homework_and_chores/features/world/sleeping_bosses.dart';
import 'package:homework_and_chores/l10n/app_localizations.dart';

import '../../data/fight_progress_test.dart' show chore, fight;

Future<AppLocalizations> l10nFor(WidgetTester tester, Locale locale) async {
  late AppLocalizations l10n;
  await tester.pumpWidget(
    Localizations(
      locale: locale,
      delegates: AppLocalizations.localizationsDelegates,
      child: Builder(
        builder: (context) {
          l10n = AppLocalizations.of(context);
          return const SizedBox();
        },
      ),
    ),
  );
  return l10n;
}

void main() {
  group('forms', () {
    test('every chore boss has two forms; the Overlord none', () {
      for (final family in choreFamilies) {
        expect(bossForm(family, 1), isNull, reason: family.name);
        expect(bossForm(family, 2), isNotNull, reason: family.name);
        expect(bossForm(family, 3), isNotNull, reason: family.name);
        expect(bossForm(family, 2), isNot(same(bossForm(family, 3))));
        for (final tier in [2, 3]) {
          final sprite = Sprites.all['bosses/forms/${family.name}_$tier'];
          expect(sprite, isNotNull, reason: '${family.name} $tier');
          expect(sprite!.$1, hasLength(4));
        }
      }
      expect(bossForm(BossFamily.overlord, 3), isNull);
    });

    test('the new bosses have a strip of four frames', () {
      for (final family in [
        BossFamily.homework,
        BossFamily.pets,
        BossFamily.garden,
        BossFamily.cooking,
      ]) {
        expect(Sprites.all['bosses/${family.name}']!.$1, hasLength(4));
      }
    });

    test('a form swaps exactly its boss colors', () {
      for (final family in choreFamilies) {
        final colors = bossFormColors(family, 3);
        final changed = [
          for (var i = 0; i < colors.length; i++)
            if (colors[i] != bosses.colors[i]) i,
        ];
        expect(changed, hasLength(4), reason: family.name);
        expect(changed.last - changed.first, 3, reason: family.name);
      }
      expect(bossFormColors(BossFamily.dust, 1), bosses.colors);
    });

    test('cards take the form colors', () {
      expect(
        bossFormColorPair(BossFamily.dust, 1),
        bossColors(BossFamily.dust),
      );
      final form = bossForm(BossFamily.dust, 3)!;
      expect(bossFormColorPair(BossFamily.dust, 3), (
        Color(form.main),
        Color(form.light),
      ));
    });

    test('a form changes how the boss plays', () {
      final hero = HeroStats.forLevel(1);
      EchoDuel duel(int tier) =>
          EchoDuel(family: BossFamily.dust, tier: tier, hero: hero, seed: 7);
      expect(duel(1).extraBeats, 0);
      expect(duel(3).extraBeats, bossForm(BossFamily.dust, 3)!.trait.beats);
      expect(
        duel(2).styleOf(BossFamily.dust).eighthChance,
        greaterThan(bossStyles[BossFamily.dust]!.eighthChance),
      );
    });

    testWidgets('names in English and German, by tier', (tester) async {
      final en = await l10nFor(tester, const Locale('en'));
      final de = await l10nFor(tester, const Locale('de'));
      expect(bossName(en, BossFamily.dust), 'Dust Bunny King');
      expect(bossName(en, BossFamily.dust, null, 2), 'Dust Bunny Emperor');
      expect(
        bossName(de, BossFamily.dust, null, 3),
        'Staubhasen-Tyrann des Teppichs',
      );
      expect(bossName(en, BossFamily.pets), 'Fur Ball Beast');
      for (final family in choreFamilies) {
        for (final tier in [2, 3]) {
          expect(
            bossName(en, family, null, tier),
            isNot(bossName(en, family)),
            reason: '${family.name} $tier',
          );
          expect(
            bossName(de, family, null, tier),
            isNot(bossName(de, family)),
            reason: '${family.name} $tier',
          );
        }
      }
    });

    testWidgets('every boss draws at every tier and mood', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Wrap(
            children: [
              for (final family in choreFamilies)
                for (final tier in [1, 2, 3])
                  for (final mood in BossMood.values)
                    BossArt(family: family, tier: tier, mood: mood, size: 24),
            ],
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('progress by tier', () {
    test('the best tier and the week\'s tiers', () {
      final progress = FightProgress(
        completions: const [],
        chores: const [],
        fights: [
          fight(BossFamily.dust, result: FightResult.won, tier: 1),
          fight(BossFamily.dust, result: FightResult.won, tier: 2),
          fight(BossFamily.dust, result: FightResult.lost, tier: 3),
          fight(BossFamily.pets, result: FightResult.won, tier: 1),
        ],
      );
      expect(progress.bestTier(BossFamily.dust), 2);
      expect(progress.bestTier(BossFamily.pets), 1);
      expect(progress.bestTier(BossFamily.garden), 0);
      expect(progress.weekWinTiers(DateTime(2026, 10, 28)), [1, 2, 1]);
    });
  });

  group('sleeping bosses', () {
    test('no tokens and no active quest feeding them', () {
      final chores = [
        chore(1, seedKey: 'dusting'),
        chore(2, seedKey: 'feed_pets').copyWith(isArchived: true),
        chore(3, family: BossFamily.garden),
      ];
      final progress = FightProgress(
        completions: const [],
        chores: chores,
        fights: const [],
      );
      final sleeping = sleepingBosses(progress, chores);
      expect(sleeping, contains(BossFamily.pets));
      expect(sleeping, contains(BossFamily.homework));
      expect(sleeping, isNot(contains(BossFamily.dust)));
      expect(sleeping, isNot(contains(BossFamily.garden)));
      expect(suggestionsFor(BossFamily.pets, chores).map((c) => c.id), [2]);
      expect(suggestionsFor(BossFamily.garden, chores), isEmpty);
    });
  });
}
