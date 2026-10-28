import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homework_and_chores/data/db/app_database.dart';
import 'package:homework_and_chores/data/repositories/chore_repository.dart';
import 'package:homework_and_chores/data/repositories/progress_repository.dart';
import 'package:homework_and_chores/data/repositories/settings_repository.dart';
import 'package:homework_and_chores/domain/default_chores.dart';
import 'package:homework_and_chores/data/models/app_settings.dart';

import '../helpers.dart';

void main() {
  late AppDatabase db;
  late ChoreRepository chores;
  late ProgressRepository progress;
  late int profileId;
  var now = DateTime(2026, 10, 28, 9);

  setUp(() async {
    db = memoryDb();
    chores = ChoreRepository(db);
    progress = ProgressRepository(db, clock: () => now);
    profileId = await db.defaultProfileId();
  });

  tearDown(() => db.close());

  group('seeding', () {
    test('creates one profile and all built-in chores in order', () async {
      final profiles = await db.select(db.profiles).get();
      expect(profiles, hasLength(1));

      final active = await chores.watchActive().first;
      expect(active.map((c) => c.seedKey), defaultChores.map((s) => s.key));
    });

    test('a restart neither duplicates nor revives chores', () async {
      final dir = await Directory.systemTemp.createTemp('chores_test');
      addTearDown(() => dir.delete(recursive: true));
      final file = File('${dir.path}/chores.sqlite');

      var fileDb = AppDatabase(NativeDatabase(file));
      final firstRun = ChoreRepository(fileDb);
      final first = (await firstRun.watchActive().first).first;
      await firstRun.setArchived(first.id, archived: true);
      await fileDb.close();

      fileDb = AppDatabase(NativeDatabase(file));
      addTearDown(fileDb.close);
      final all = await ChoreRepository(fileDb).watchAll().first;
      expect(all, hasLength(defaultChores.length));
      expect(all.singleWhere((c) => c.id == first.id).isArchived, isTrue);
      expect(await fileDb.select(fileDb.profiles).get(), hasLength(1));
    });
  });

  group('chores', () {
    test('titles keep umlauts, accents, other scripts and emoji', () async {
      const titles = [
        'Wäsche größer falten, Straße fegen – ÄÖÜ äöü ß',
        'Nettoyer la fenêtre, café, garçon, œuvre',
        'Убрать квартиру',
        'Ξεσκόνισμα',
        '掃除する 打扫卫生 청소',
        'تنظيف المطبخ',
        'Pflanzen 🌱 gießen 🧺👨‍👩‍👧',
        'Quotes \' " ` and %_\\ symbols',
      ];
      for (final title in titles) {
        final id = await chores.add(
          title: title,
          iconKey: 'star',
          colorKey: 0,
          basePoints: 10,
        );
        final stored = (await chores.watchAll().first).singleWhere(
          (c) => c.id == id,
        );
        expect(stored.customTitle, title);
      }
    });

    test('add appends a custom chore at the end', () async {
      final id = await chores.add(
        title: 'Feed the cat',
        iconKey: 'pets',
        colorKey: 2,
        basePoints: 10,
      );
      final active = await chores.watchActive().first;
      expect(active.last.id, id);
      expect(active.last.customTitle, 'Feed the cat');
      expect(active.last.seedKey, isNull);
    });

    test('update changes fields and can reset to the built-in title', () async {
      final chore = (await chores.watchActive().first).first;
      await chores.update(
        chore.id,
        customTitle: 'Renamed',
        iconKey: 'star',
        colorKey: 3,
        basePoints: 50,
      );
      var updated = (await chores.watchActive().first).first;
      expect(updated.customTitle, 'Renamed');
      expect(updated.basePoints, 50);

      await chores.update(
        chore.id,
        customTitle: null,
        iconKey: 'star',
        colorKey: 3,
        basePoints: 50,
      );
      updated = (await chores.watchActive().first).first;
      expect(updated.customTitle, isNull);
    });

    test('archived chores leave the active list and can be restored', () async {
      final chore = (await chores.watchActive().first).first;
      await chores.setArchived(chore.id, archived: true);
      expect(
        (await chores.watchActive().first).map((c) => c.id),
        isNot(contains(chore.id)),
      );
      final all = await chores.watchAll().first;
      expect(all.last.id, chore.id, reason: 'archived chores sort last');

      await chores.setArchived(chore.id, archived: false);
      expect((await chores.watchActive().first).first.id, chore.id);
    });
  });

  group('progress', () {
    test('completing awards points and undo takes them back', () async {
      final chore = (await chores.watchActive().first).first;
      final result = await progress.complete(
        choreId: chore.id,
        profileId: profileId,
      );
      expect(result.points, chore.basePoints);
      expect(await progress.watchBalance(profileId).first, chore.basePoints);

      expect(await progress.undo(result.completionId), isTrue);
      expect(await progress.watchBalance(profileId).first, 0);

      // A second undo (double tap) changes nothing.
      expect(await progress.undo(result.completionId), isFalse);
      expect(await progress.watchBalance(profileId).first, 0);

      final ledger = await db.select(db.pointLedger).get();
      expect(ledger.map((e) => e.reason), [
        LedgerReason.completion,
        LedgerReason.undo,
      ]);
    });

    test('today counts exclude undone and earlier completions', () async {
      final chore = (await chores.watchActive().first).first;
      final today = DateTime(2026, 10, 28);

      now = DateTime(2026, 10, 27, 23, 59);
      await progress.complete(choreId: chore.id, profileId: profileId);
      now = DateTime(2026, 10, 28, 8);
      await progress.complete(choreId: chore.id, profileId: profileId);
      final undone = await progress.complete(
        choreId: chore.id,
        profileId: profileId,
      );
      await progress.undo(undone.completionId);

      final counts = await progress
          .watchCompletionCounts(profileId, today)
          .first;
      expect(counts, {chore.id: 1});
    });
  });

  group('settings', () {
    test('round-trip through the database', () async {
      final repo = SettingsRepository(db);
      expect(await repo.load(), const AppSettings());

      const custom = AppSettings(
        themeMode: ThemeMode.dark,
        colorblindSafe: true,
        locale: Locale('de'),
      );
      await repo.save(custom);
      expect(await repo.load(), custom);

      await repo.save(custom.copyWith(locale: () => null));
      expect((await repo.load()).locale, isNull);
    });
  });
}
