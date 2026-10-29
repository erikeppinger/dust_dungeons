import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/chores/today_screen.dart';
import '../features/plan/plan_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/stats/stats_screen.dart';
import '../features/world/world_screen.dart';
import '../l10n/app_localizations.dart';
import 'home_tab.dart';
import 'theme/pixel.dart';

/// Main scaffold with bottom navigation between the top-level screens.
class HomeShell extends ConsumerWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final index = ref.watch(homeTabProvider).index;
    final titles = [
      l10n.navToday,
      l10n.navPlan,
      l10n.navWorld,
      l10n.navStats,
      l10n.navSettings,
    ];

    return Scaffold(
      appBar: AppBar(title: Text(titles[index])),
      body: IndexedStack(
        index: index,
        children: [
          const TodayScreen(),
          const PlanScreen(),
          const WorldScreen(),
          const StatsScreen(),
          const SettingsScreen(),
        ],
      ),
      // The frame line on top sets the tabs apart like a game's menu bar.
      bottomNavigationBar: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: PixelColors.of(context).frame,
              width: pixelUnit,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: (i) =>
              ref.read(homeTabProvider.notifier).select(HomeTab.values[i]),
          destinations: [
            NavigationDestination(
              icon: const PixelIcon(PixelArt.quests),
              label: titles[0],
            ),
            NavigationDestination(
              icon: const PixelIcon(PixelArt.questLog),
              label: titles[1],
            ),
            NavigationDestination(
              icon: const PixelIcon(PixelArt.arena),
              label: titles[2],
            ),
            NavigationDestination(
              icon: const PixelIcon(PixelArt.hallOfFame),
              label: titles[3],
            ),
            NavigationDestination(
              icon: const PixelIcon(PixelArt.settings),
              label: titles[4],
            ),
          ],
        ),
      ),
    );
  }
}
