import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homework_and_chores/features/notifications/notification_planner.dart';
import 'package:homework_and_chores/features/notifications/notification_service.dart';
import 'package:homework_and_chores/features/notifications/notification_sync.dart';

/// replaceAll only completes when the test says so.
class SlowService implements NotificationService {
  final calls = <List<PlannedNotification>>[];
  final pending = <Completer<void>>[];
  var active = 0;
  var maxActive = 0;

  @override
  Future<void> replaceAll(List<PlannedNotification> plan, ChannelNames n) {
    calls.add(plan);
    active++;
    if (active > maxActive) maxActive = active;
    final c = Completer<void>();
    pending.add(c);
    return c.future.whenComplete(() => active--);
  }

  @override
  Future<void> init({required void Function(NotificationTarget) onTap}) async {}
  @override
  Future<NotificationTarget?> launchTarget() async => null;
  @override
  Future<bool> requestPermission() async => true;
  @override
  Future<bool> permissionGranted() async => true;
  @override
  Future<void> showNow(PlannedNotification n, ChannelNames names) async {}
}

class _Plan extends Notifier<NotificationPlan?> {
  @override
  NotificationPlan? build() => null;
  void set(NotificationPlan plan) => state = plan;
}

final _planProvider = NotifierProvider<_Plan, NotificationPlan?>(_Plan.new);

NotificationPlan planWith(int id) => NotificationPlan([
  PlannedNotification(
    id: id,
    when: DateTime(2030),
    channel: NotificationChannel.summary,
    title: 't$id',
    body: '',
    target: NotificationTarget.today,
  ),
], const {});

void main() {
  test('updates never overlap and the newest plan wins', () async {
    final service = SlowService();
    final container = ProviderContainer(
      overrides: [
        notificationServiceProvider.overrideWithValue(service),
        notificationPlanProvider.overrideWith(
          (ref) => ref.watch(_planProvider),
        ),
      ],
    );
    addTearDown(container.dispose);
    final sub = syncNotifications(container);
    addTearDown(sub.close);
    final plans = container.read(_planProvider.notifier);

    plans.set(planWith(1));
    await Future<void>.delayed(Duration.zero);
    plans.set(planWith(2)); // arrives while 1 is still being applied
    await Future<void>.delayed(Duration.zero);
    plans.set(planWith(3)); // replaces 2 before it was applied
    await Future<void>.delayed(Duration.zero);
    expect(service.calls, hasLength(1));

    service.pending.removeAt(0).complete();
    await Future<void>.delayed(Duration.zero);
    expect(service.calls.map((c) => c.single.id), [1, 3]);

    service.pending.removeAt(0).complete();
    await Future<void>.delayed(Duration.zero);
    expect(service.maxActive, 1);
  });
}
