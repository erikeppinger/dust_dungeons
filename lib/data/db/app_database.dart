import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

import '../../domain/default_chores.dart';
import 'tables.dart';

export 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Profiles, Chores, Completions, PointLedger, Settings])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  /// The on-device database file in the app's private support directory.
  AppDatabase.open()
    : super(
        driftDatabase(
          name: 'chores',
          native: const DriftNativeOptions(
            databaseDirectory: getApplicationSupportDirectory,
          ),
        ),
      );

  /// Bump on every schema change and add a step to [migration].
  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
      await _ensureDefaults();
    },
  );

  /// Creates the default profile and inserts built-in chores that are missing.
  /// Runs on every start, so chores added to [defaultChores] in later versions
  /// appear after an update. Existing rows (including archived or edited ones)
  /// are never touched.
  Future<void> _ensureDefaults() => transaction(() async {
    final hasProfile = await (select(profiles)..limit(1)).getSingleOrNull();
    if (hasProfile == null) {
      await into(profiles).insert(ProfilesCompanion.insert(name: 'Me'));
    }
    for (final (i, seed) in defaultChores.indexed) {
      await into(chores).insert(
        ChoresCompanion.insert(
          seedKey: Value(seed.key),
          iconKey: seed.iconKey,
          colorKey: seed.colorKey,
          basePoints: seed.basePoints,
          sortOrder: Value(i),
        ),
        mode: InsertMode.insertOrIgnore,
      );
    }
  });

  /// The profile used until profile switching exists (0.8).
  Future<int> defaultProfileId() async {
    final first =
        await (select(profiles)
              ..orderBy([(p) => OrderingTerm.asc(p.id)])
              ..limit(1))
            .getSingle();
    return first.id;
  }
}
