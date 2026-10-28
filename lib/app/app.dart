import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/settings/settings_controller.dart';
import '../l10n/app_localizations.dart';
import 'home_shell.dart';
import 'theme/app_theme.dart';

class ChoresApp extends ConsumerWidget {
  const ChoresApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(
        brightness: Brightness.light,
        colorblindSafe: settings.colorblindSafe,
      ),
      darkTheme: buildAppTheme(
        brightness: Brightness.dark,
        colorblindSafe: settings.colorblindSafe,
      ),
      themeMode: settings.themeMode,
      locale: settings.locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const HomeShell(),
    );
  }
}
