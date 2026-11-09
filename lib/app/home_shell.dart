import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/chores/today_screen.dart';
import '../features/people/people_screen.dart';
import '../features/plan/plan_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/stats/stats_screen.dart';
import '../features/world/world_screen.dart';
import '../l10n/app_localizations.dart';
import 'art/art.dart';
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
      appBar: AppBar(
        title: Text(titles[index]),
        // Who is playing; tap to switch.
        actions: const [PersonButton(), SizedBox(width: 4)],
      ),
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
        // Tab labels grow with the font size only up to 110 %: then every
        // label fits on one line (German too) and the icons stay large.
        child: MediaQuery.withClampedTextScaling(
          maxScaleFactor: navLabelMaxScale,
          child: NavigationBar(
            selectedIndex: index,
            onDestinationSelected: (i) =>
                ref.read(homeTabProvider.notifier).select(HomeTab.values[i]),
            destinations: [
              NavigationDestination(
                icon: const PixelIcon(Sprites.tabQuests),
                label: titles[0],
              ),
              NavigationDestination(
                icon: const PixelIcon(Sprites.tabQuestLog),
                label: titles[1],
              ),
              NavigationDestination(
                icon: const PixelIcon(Sprites.tabArena),
                label: titles[2],
              ),
              NavigationDestination(
                icon: const PixelIcon(Sprites.tabHallOfFame),
                label: titles[3],
              ),
              NavigationDestination(
                icon: const PixelIcon(Sprites.tabSettings),
                // Its own, shorter label: "Einstellungen" doesn't fit a tab.
                label: l10n.navSettingsTab,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The largest text scale for the tab labels.
const navLabelMaxScale = 1.1;
