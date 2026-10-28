import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/chores/today_screen.dart';
import '../features/plan/plan_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/stats/stats_screen.dart';
import '../features/world/world_screen.dart';
import '../l10n/app_localizations.dart';
import 'home_tab.dart';

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
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) =>
            ref.read(homeTabProvider.notifier).select(HomeTab.values[i]),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.checklist_outlined),
            selectedIcon: const Icon(Icons.checklist),
            label: titles[0],
          ),
          NavigationDestination(
            icon: const Icon(Icons.menu_book_outlined),
            selectedIcon: const Icon(Icons.menu_book),
            label: titles[1],
          ),
          NavigationDestination(
            icon: const Icon(Icons.shield_outlined),
            selectedIcon: const Icon(Icons.shield),
            label: titles[2],
          ),
          NavigationDestination(
            icon: const Icon(Icons.emoji_events_outlined),
            selectedIcon: const Icon(Icons.emoji_events),
            label: titles[3],
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: titles[4],
          ),
        ],
      ),
    );
  }
}
