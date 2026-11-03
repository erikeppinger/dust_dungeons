import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homework_and_chores/data/backup/backup_file.dart';
import 'package:homework_and_chores/data/db/app_database.dart';
import 'package:homework_and_chores/features/backup/backup_screen.dart';
import 'package:homework_and_chores/features/backup/backups.dart';

import 'helpers.dart';

/// Settings → Backup, with the system pickers faked
/// (docs/design/data-safety.md).
void main() {
  late Directory tmp;

  setUp(() => tmp = Directory.systemTemp.createTempSync('backup_screen'));
  tearDown(() => tmp.deleteSync(recursive: true));

  Future<void> openBackupPage(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(NavigationDestination, 'Settings'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Backup'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('Backup'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Backup'));
    await tester.pumpAndSettle();
  }

  /// A backup file from "another phone" with one completed chore.
  Future<String> otherPhoneBackup(WidgetTester tester) async {
    final path = '${tmp.path}/other.sqlite';
    await tester.runAsync(() async {
      final other = memoryDb();
      final dusting = await (other.select(
        other.chores,
      )..where((c) => c.seedKey.equals('dusting'))).getSingle();
      final at = DateTime.now().subtract(const Duration(days: 3));
      final id = await other
          .into(other.completions)
          .insert(
            CompletionsCompanion.insert(
              choreId: dusting.id,
              profileId: await other.defaultProfileId(),
              completedAt: at,
              pointsAwarded: 15,
            ),
          );
      await other
          .into(other.pointLedger)
          .insert(
            PointLedgerCompanion.insert(
              profileId: await other.defaultProfileId(),
              delta: 15,
              reason: LedgerReason.completion,
              completionId: Value(id),
              createdAt: at,
            ),
          );
      await writeSnapshot(other, path);
      await other.close();
    });
    return path;
  }

  Future<int> completions(WidgetTester tester, AppDatabase db) async =>
      (await tester.runAsync(() => db.select(db.completions).get()))!.length;

  /// Runs work that touches files and the database outside the fake clock,
  /// then lets the UI catch up.
  Future<void> tapAndWait(WidgetTester tester, Finder target) async {
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    await tester.runAsync(() => tester.tap(target));
    // The page shows a progress bar while it works; wait until it's done.
    for (var i = 0; i < 100; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
      if (find.byType(LinearProgressIndicator).evaluate().isEmpty) break;
    }
    await tester.pumpAndSettle();
  }

  testWidgets('Settings shows the backup entry, off at first', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.widgetWithText(NavigationDestination, 'Settings'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('No automatic backup'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('No automatic backup'), findsOneWidget);
  });

  testWidgets('saving a backup hands a real backup file to Android', (
    tester,
  ) async {
    final backup = FakeBackupService();
    await pumpApp(tester, backup: backup);
    await openBackupPage(tester);
    await tapAndWait(tester, find.byKey(const ValueKey('backup-export')));

    expect(find.text('Backup saved'), findsOneWidget);
    final MapEntry(key: name, value: bytes) = backup.saved.entries.single;
    expect(name, startsWith('homework-chores-backup-'));
    final copy = File('${tmp.path}/saved.sqlite')..writeAsBytesSync(bytes);
    expect(checkBackup(copy.path, currentSchema: 10), 10);
  });

  testWidgets('importing shows what it adds, merges, and can be undone', (
    tester,
  ) async {
    final backup = FakeBackupService()..pick = await otherPhoneBackup(tester);
    final db = await pumpApp(tester, backup: backup);
    await openBackupPage(tester);
    await tapAndWait(tester, find.byKey(const ValueKey('backup-import')));

    expect(find.text('Import this backup?'), findsOneWidget);
    expect(find.text('• 1 completed quest'), findsOneWidget);
    // This phone has no history yet: the backup's settings are offered.
    final useSettings = tester.widget<CheckboxListTile>(
      find.byKey(const ValueKey('backup-use-settings')),
    );
    expect(useSettings.value, isTrue);

    await tapAndWait(
      tester,
      find.byKey(const ValueKey('backup-import-confirm')),
    );
    expect(find.text('Backup imported'), findsOneWidget);
    expect(await completions(tester, db), 1);

    // The undo entry appears once the safety copy is found on disk.
    for (var i = 0; i < 50; i++) {
      if (find.byKey(const ValueKey('backup-undo')).evaluate().isNotEmpty) {
        break;
      }
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }
    await tapAndWait(tester, find.byKey(const ValueKey('backup-undo')));
    expect(find.text('Import undone'), findsOneWidget);
    expect(await completions(tester, db), 0);
    expect(find.byKey(const ValueKey('backup-undo')), findsNothing);
  });

  testWidgets('cancelling the import changes nothing', (tester) async {
    final backup = FakeBackupService()..pick = await otherPhoneBackup(tester);
    final db = await pumpApp(tester, backup: backup);
    await openBackupPage(tester);
    await tapAndWait(tester, find.byKey(const ValueKey('backup-import')));
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(await completions(tester, db), 0);
    expect(find.byKey(const ValueKey('backup-undo')), findsNothing);
  });

  testWidgets('a file that is not a backup is refused', (tester) async {
    final notes = File('${tmp.path}/notes.txt')..writeAsStringSync('milk');
    final backup = FakeBackupService()..pick = notes.path;
    await pumpApp(tester, backup: backup);
    await openBackupPage(tester);
    await tapAndWait(tester, find.byKey(const ValueKey('backup-import')));
    expect(
      find.text("This file isn't a Homework & Chores backup."),
      findsOneWidget,
    );
  });

  testWidgets('choosing a folder writes the first automatic backup', (
    tester,
  ) async {
    final backup = FakeBackupService();
    await pumpApp(tester, backup: backup);
    await openBackupPage(tester);
    await tapAndWait(
      tester,
      find.byKey(const ValueKey('backup-choose-folder')),
    );

    final name = backup.folder.keys.single;
    expect(name, startsWith('homework-chores-auto-'));
    expect(backup.prunes.single, ('homework-chores-auto-', 7));
    expect(find.text('Folder: Backups'), findsOneWidget);
    expect(find.textContaining('Last backup:'), findsOneWidget);

    // At most one a day: a second run writes nothing new.
    final container = ProviderScope.containerOf(
      tester.element(find.byType(BackupScreen)),
    );
    backup.folder.clear();
    await tester.runAsync(() => container.read(backupsProvider).autoBackup());
    expect(backup.folder, isEmpty);
  });

  testWidgets('a lost folder is shown and can be chosen again', (tester) async {
    final backup = FakeBackupService();
    await pumpApp(tester, backup: backup);
    await openBackupPage(tester);
    await tapAndWait(
      tester,
      find.byKey(const ValueKey('backup-choose-folder')),
    );
    backup.folderOk = false;
    final container = ProviderScope.containerOf(
      tester.element(find.byType(BackupScreen)),
    );
    container.invalidate(backupFolderNameProvider);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pumpAndSettle();
    expect(
      find.text("The folder can't be reached any more. Choose it again."),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('backup-now')), findsNothing);

    // The Settings overview says so too, instead of "No automatic backup".
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text("Folder can't be reached"), findsOneWidget);
  });

  testWidgets('stopping automatic backups forgets the folder', (tester) async {
    final backup = FakeBackupService();
    await pumpApp(tester, backup: backup);
    await openBackupPage(tester);
    await tapAndWait(
      tester,
      find.byKey(const ValueKey('backup-choose-folder')),
    );
    await tapAndWait(tester, find.byKey(const ValueKey('backup-stop')));
    expect(find.byKey(const ValueKey('backup-choose-folder')), findsOneWidget);
  });
}
