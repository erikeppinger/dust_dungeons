import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Midnight (local time) at the start of [time]'s day.
DateTime startOfDay(DateTime time) => DateTime(time.year, time.month, time.day);

/// Start of the current local day. Updates at midnight and whenever the app
/// resumes, because timers can fire late after the device slept.
class TodayNotifier extends Notifier<DateTime> {
  Timer? _timer;

  @override
  DateTime build() {
    final listener = AppLifecycleListener(onResume: _refresh);
    ref.onDispose(() {
      listener.dispose();
      _timer?.cancel();
    });
    return _scheduleNext();
  }

  DateTime _scheduleNext() {
    final now = DateTime.now();
    final today = startOfDay(now);
    // Calendar arithmetic handles DST changes correctly.
    final tomorrow = DateTime(today.year, today.month, today.day + 1);
    _timer?.cancel();
    _timer = Timer(tomorrow.difference(now), _refresh);
    return today;
  }

  void _refresh() {
    final today = _scheduleNext();
    if (today != state) state = today;
  }
}

final todayProvider = NotifierProvider<TodayNotifier, DateTime>(
  TodayNotifier.new,
);
