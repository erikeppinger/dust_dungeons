import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/notifications/notification_planner.dart';

/// Bottom navigation tabs, in display order.
enum HomeTab { today, plan, world, stats, settings }

/// The selected tab; notifications can switch it (e.g. a recap opens Stats).
class HomeTabController extends Notifier<HomeTab> {
  @override
  HomeTab build() => HomeTab.today;

  void select(HomeTab tab) => state = tab;

  void openFor(NotificationTarget target) => state = switch (target) {
    NotificationTarget.today => HomeTab.today,
    NotificationTarget.stats => HomeTab.stats,
  };
}

final homeTabProvider = NotifierProvider<HomeTabController, HomeTab>(
  HomeTabController.new,
);
