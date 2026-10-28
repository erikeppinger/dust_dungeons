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
      scrollBehavior: const _GlowScrollBehavior(),
      locale: settings.locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const HomeShell(),
    );
  }
}

/// Uses the subtle glow at the scroll edges instead of Material 3's
/// "stretch", which distorts text when scrolling past the top or bottom.
class _GlowScrollBehavior extends MaterialScrollBehavior {
  const _GlowScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => GlowingOverscrollIndicator(
    axisDirection: details.direction,
    color: Theme.of(context).colorScheme.primary,
    child: child,
  );
}
