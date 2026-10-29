import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

import 'app/app.dart';
import 'app/home_tab.dart';
import 'data/db/app_database.dart';
import 'data/providers.dart';
import 'data/repositories/settings_repository.dart';
import 'features/notifications/notification_planner.dart';
import 'features/notifications/notification_service.dart';
import 'features/notifications/notification_sync.dart';
import 'features/screen_time/screen_time_providers.dart';
import 'features/settings/settings_controller.dart';
import 'l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // The bundled pixel font ships with its license (SIL OFL 1.1).
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(const [
      'Press Start 2P',
    ], await rootBundle.loadString('assets/fonts/OFL.txt'));
  });
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
/// Shared with tests, which pass an in-memory database, a fake
/// [notifications] service and may add [overrides] (e.g. a fixed day).
Future<Widget> bootstrap(
  AppDatabase db, {
  NotificationService? notifications,
  List<Override> overrides = const [],
}) async {
  final profileId = await db.defaultProfileId();
  final settings = await SettingsRepository(db).load();
  final service = notifications ?? LocalNotificationService();
  final container = ProviderContainer(
    overrides: [
      databaseProvider.overrideWithValue(db),
      currentProfileIdProvider.overrideWithValue(profileId),
      initialSettingsProvider.overrideWithValue(settings),
      notificationServiceProvider.overrideWithValue(service),
      ...overrides,
    ],
  );
  void open(NotificationTarget target) =>
      container.read(homeTabProvider.notifier).openFor(target);
  try {
    await service.init(onTap: open);
    final launchedBy = await service.launchTarget();
    if (launchedBy != null) open(launchedBy);
  } catch (error, stack) {
    // Notifications are optional: the app must start without them.
    FlutterError.reportError(
      FlutterErrorDetails(exception: error, stack: stack),
    );
  }
  return _AppRoot(container: container);
}

/// Owns the provider container for the app's lifetime.
class _AppRoot extends StatefulWidget {
  const _AppRoot({required this.container});

  final ProviderContainer container;

  @override
  State<_AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<_AppRoot> {
  /// Keeps scheduled notifications in line with the data.
  late final ProviderSubscription<Object?> _sync;

  /// Keeps the screen-time background check and daily totals up to date.
  late final ProviderSubscription<Object?> _screenSync;

  @override
  void initState() {
    super.initState();
    _sync = syncNotifications(widget.container);
    _screenSync = syncScreenTime(widget.container);
  }

  @override
  void dispose() {
    _sync.close();
    _screenSync.close();
    widget.container.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => UncontrolledProviderScope(
    container: widget.container,
    child: const ChoresApp(),
  );
}
