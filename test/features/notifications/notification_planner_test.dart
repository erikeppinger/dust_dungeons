import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homework_and_chores/data/db/app_database.dart';
import 'package:homework_and_chores/data/models/app_settings.dart';
import 'package:homework_and_chores/data/models/scheduled_chore.dart';
import 'package:homework_and_chores/features/notifications/notification_planner.dart';
import 'package:homework_and_chores/l10n/app_localizations.dart';

final l10n = lookupAppLocalizations(const Locale('en'));

// Wednesday 2026-10-28, 07:00.
final now = DateTime(2026, 10, 28, 7);
final today = DateTime(2026, 10, 28);

const on = AppSettings(notificationsEnabled: true);

Chore chore(
  int id,
  String title,
  RepeatType type, {
  int interval = 1,
  int? reminder,
}) => Chore(
  id: id,
  customTitle: title,
  iconKey: 'star',
  colorKey: 0,
  basePoints: 10,
  isArchived: false,
  assignment: Assignment.anyone,
  sortOrder: id,
  createdAt: DateTime(2026, 10, 1),
  repeatType: type,
  repeatInterval: interval,
  repeatWeekdays: 0,
  repeatStart: DateTime(2026, 10, 1),
  reminderMinutes: reminder,
);

ScheduledChore scheduled(Chore c, {DateTime? lastDone}) =>
    ScheduledChore(chore: c, lastDone: lastDone, doneToday: 0, today: today);

Completion done(DateTime at, int points) => Completion(
  id: at.millisecondsSinceEpoch,
  choreId: 1,
  profileId: 1,
  completedAt: at,
  pointsAwarded: points,
);

List<PlannedNotification> plan({
  AppSettings settings = on,
  List<ScheduledChore> chores = const [],
  List<Completion> completions = const [],
  DateTime? at,
  (int, int)? screenYesterday,
}) => planNotifications(
  now: at ?? now,
  settings: settings,
  chores: chores,
  completions: completions,
  l10n: l10n,
  screenYesterday: screenYesterday,
);

void main() {
  final dishes = scheduled(
    chore(1, 'Dishes', RepeatType.daily),
    lastDone: DateTime(2026, 10, 27, 20),
  );
  final trash = scheduled(
    chore(2, 'Trash', RepeatType.afterDone, interval: 3, reminder: 19 * 60),
    lastDone: DateTime(2026, 10, 20),
  ); // overdue since the 23rd
  final plants = scheduled(chore(3, 'Plants', RepeatType.anytime));

  test('nothing is planned while notifications are off', () {
    expect(
      plan(settings: const AppSettings(), chores: [dishes, trash]),
      isEmpty,
    );
  });

  test('daily summary lists overdue and due chores at the chosen time', () {
    final summaries = plan(
      settings: on.copyWith(weeklyRecap: false, monthlyRecap: false),
      chores: [dishes, trash, plants],
    ).where((n) => n.channel == NotificationChannel.summary).toList();

    expect(summaries, hasLength(planDays));
    final first = summaries.first;
    expect(first.when, DateTime(2026, 10, 28, 8));
    expect(first.title, '2 chores today');
    expect(first.body, '1 overdue · Trash, Dishes');
    expect(first.target, NotificationTarget.today);
  });

  test('no summary today once its time has passed', () {
    final summaries = plan(
      at: DateTime(2026, 10, 28, 9),
      chores: [dishes],
    ).where((n) => n.channel == NotificationChannel.summary);
    expect(summaries.first.when, DateTime(2026, 10, 29, 8));
  });

  test('days without open chores get no summary', () {
    final weekly = scheduled(
      chore(4, 'Windows', RepeatType.afterDone, interval: 30),
      lastDone: DateTime(2026, 10, 27),
    );
    expect(
      plan(chores: [weekly])
          .where((n) => n.channel == NotificationChannel.summary),
      isEmpty,
    );
  });

  test('chore reminders fire at the chore time on open days only', () {
    final reminders = plan(chores: [dishes, trash])
        .where((n) => n.channel == NotificationChannel.reminder)
        .toList();
    // Trash stays overdue until done: one reminder per day at 19:00.
    expect(reminders, hasLength(planDays));
    expect(reminders.first.when, DateTime(2026, 10, 28, 19));
    expect(reminders.first.title, 'Trash');
    expect(reminders.first.body, 'Overdue · 10 points');
  });

  test('reminders can be turned off globally', () {
    expect(
      plan(
        settings: on.copyWith(choreReminders: false),
        chores: [trash],
      ).where((n) => n.channel == NotificationChannel.reminder),
      isEmpty,
    );
  });

  test('weekly recap on Sunday 18:00 counts this week so far', () {
    final recap = plan(
      completions: [
        done(DateTime(2026, 10, 25, 10), 99), // last Sunday: previous week
        done(DateTime(2026, 10, 26, 10), 15),
        done(DateTime(2026, 10, 27, 10), 20),
      ],
    ).singleWhere((n) => n.title == 'Your week');
    expect(recap.when, DateTime(2026, 11, 1, 18));
    expect(recap.body, 'This week: 2 chores done, 35 points earned.');
    expect(recap.target, NotificationTarget.stats);
  });

  test('monthly recap on the 1st covers the current month', () {
    final recap = plan(
      completions: [done(DateTime(2026, 9, 30), 50), done(today, 10)],
    ).singleWhere((n) => n.title == 'Your month');
    expect(recap.when, DateTime(2026, 11, 1, 10));
    expect(recap.body, 'This month: 1 chore done, 10 points earned.');
  });

  test('on the 1st before 10:00 the recap is about the month that ended', () {
    final recap = plan(
      at: DateTime(2026, 11, 1, 8),
      completions: [
        done(DateTime(2026, 10, 15), 20),
        done(DateTime(2026, 11, 1, 7), 5),
      ],
    ).singleWhere((n) => n.title == 'Your month');
    expect(recap.when, DateTime(2026, 11, 1, 10));
    expect(recap.body, 'This month: 1 chore done, 20 points earned.');
  });

  test('ids are unique and everything is in the future', () {
    final all = plan(chores: [dishes, trash, plants]);
    expect(all.map((n) => n.id).toSet(), hasLength(all.length));
    expect(all.every((n) => n.when.isAfter(now)), isTrue);
  });

  test('chore reminders are capped', () {
    final many = [
      for (var i = 0; i < 30; i++)
        scheduled(
          chore(100 + i, 'C$i', RepeatType.daily, reminder: 20 * 60),
          lastDone: DateTime(2026, 10, 27),
        ),
    ];
    expect(
      plan(chores: many)
          .where((n) => n.channel == NotificationChannel.reminder),
      hasLength(maxChoreReminders),
    );
  });

  test("today's summary adds yesterday's screen time when it is on", () {
    List<PlannedNotification> summaries(AppSettings settings) => plan(
      settings: settings,
      chores: [dishes],
      screenYesterday: (74, 90),
    ).where((n) => n.channel == NotificationChannel.summary).toList();
    final withScreen = summaries(on.copyWith(screenTime: true));
    expect(
      withScreen.first.body,
      'Dishes\nScreen time yesterday: 74 of 90 min',
    );
    expect(withScreen[1].body, 'Dishes', reason: 'later days are unknown yet');
    expect(summaries(on).first.body, 'Dishes', reason: 'screen time off');
    expect(
      summaries(on.copyWith(screenTime: true, screenSummary: false)).first.body,
      'Dishes',
    );
  });
}
