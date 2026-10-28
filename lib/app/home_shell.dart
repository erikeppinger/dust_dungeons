import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/widgets/coming_soon.dart';
import '../features/chores/today_screen.dart';
import '../features/plan/plan_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/stats/stats_screen.dart';
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
          ComingSoon(
            icon: Icons.public,
            message: l10n.worldPlaceholder,
            version: '0.5.0',
          ),
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
            icon: const Icon(Icons.calendar_month_outlined),
            selectedIcon: const Icon(Icons.calendar_month),
            label: titles[1],
          ),
          NavigationDestination(
            icon: const Icon(Icons.public_outlined),
            selectedIcon: const Icon(Icons.public),
            label: titles[2],
          ),
          NavigationDestination(
            icon: const Icon(Icons.insights_outlined),
            selectedIcon: const Icon(Icons.insights),
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
