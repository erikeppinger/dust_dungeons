import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

import 'app/app.dart';
import 'data/db/app_database.dart';
import 'data/providers.dart';
import 'data/repositories/settings_repository.dart';
import 'features/settings/settings_controller.dart';
import 'l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Draw behind the system bars so they follow the app's light/dark theme.
  unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
    ),
  );

  final db = AppDatabase.open();
  try {
    runApp(await bootstrap(db));
  } catch (error, stack) {
    // Never leave the user on a blank launch screen.
    FlutterError.reportError(
      FlutterErrorDetails(exception: error, stack: stack),
    );
    runApp(StartupErrorApp(error: error));
  }
}

/// Minimal fallback app shown when the database cannot be opened.
class StartupErrorApp extends StatelessWidget {
  const StartupErrorApp({super.key, required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) => MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Builder(
      builder: (context) => Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context).startupError,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                SelectableText('$error', textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// Opens [db], loads what the first frame needs and builds the app.
/// Shared with tests, which pass an in-memory database and may add
/// [overrides] (e.g. a fixed day instead of the midnight timer).
Future<Widget> bootstrap(
  AppDatabase db, {
  List<Override> overrides = const [],
}) async {
  final profileId = await db.defaultProfileId();
  final settings = await SettingsRepository(db).load();
  return ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
      currentProfileIdProvider.overrideWithValue(profileId),
      initialSettingsProvider.overrideWithValue(settings),
      ...overrides,
    ],
    child: const ChoresApp(),
  );
}
