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

/// The current time to the minute, for quests with times of day ("18:00 to
/// 20:00"). Updates at each full minute and whenever the app resumes.
class NowNotifier extends Notifier<DateTime> {
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
    final minute = DateTime(now.year, now.month, now.day, now.hour, now.minute);
    _timer?.cancel();
    _timer = Timer(
      minute.add(const Duration(minutes: 1)).difference(now),
      _refresh,
    );
    return minute;
  }

  void _refresh() {
    final now = _scheduleNext();
    if (now != state) state = now;
  }
}

final nowProvider = NotifierProvider<NowNotifier, DateTime>(NowNotifier.new);
