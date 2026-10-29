import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// User-facing app settings, stored by `SettingsRepository`.
@immutable
class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.colorblindSafe = false,
    this.locale,
    this.notificationsEnabled = false,
    this.dailySummary = true,
    this.dailySummaryMinutes = 8 * 60,
    this.choreReminders = true,
    this.weeklyRecap = true,
    this.monthlyRecap = true,
    this.fightSound = true,
    this.fightHaptics = true,
    this.fightLatencyMs = 0,
    this.onboardingDone = false,
    this.screenTime = false,
    this.screenBaseMinutes = 60,
    this.screenEarnCap = 30,
    this.screenApps = const [],
    this.screenWarn = true,
    this.screenOver = true,
    this.screenSummary = true,
  });

  final ThemeMode themeMode;
  final bool colorblindSafe;

  /// `null` follows the device language.
  final Locale? locale;

  /// Master switch; off until the user turns it on (and grants permission).
  final bool notificationsEnabled;
  final bool dailySummary;

  /// Time of the daily summary, minutes after midnight.
  final int dailySummaryMinutes;
  final bool choreReminders;
  final bool weeklyRecap;
  final bool monthlyRecap;

  /// Fight sounds (on by default).
  final bool fightSound;

  /// Vibration on each beat.
  final bool fightHaptics;

  /// Calibrated tap delay in ms, subtracted from every tap in fights.
  final int fightLatencyMs;

  /// Whether the first-start introduction was finished or skipped.
  final bool onboardingDone;

  /// Soft screen-time budget (see docs/design/screen-time.md).
  final bool screenTime;

  /// Daily base budget in minutes, before quests and vouchers.
  final int screenBaseMinutes;

  /// Most minutes quests can earn in one day.
  final int screenEarnCap;

  /// Package names of the apps that count against the budget.
  final List<String> screenApps;

  /// Notify when 10 minutes are left / when the budget is used up.
  final bool screenWarn;
  final bool screenOver;

  /// Yesterday's result in the daily summary.
  final bool screenSummary;

  AppSettings copyWith({
    ThemeMode? themeMode,
    bool? colorblindSafe,
    Locale? Function()? locale,
    bool? notificationsEnabled,
    bool? dailySummary,
    int? dailySummaryMinutes,
    bool? choreReminders,
    bool? weeklyRecap,
    bool? monthlyRecap,
    bool? fightSound,
    bool? fightHaptics,
    int? fightLatencyMs,
    bool? onboardingDone,
    bool? screenTime,
    int? screenBaseMinutes,
    int? screenEarnCap,
    List<String>? screenApps,
    bool? screenWarn,
    bool? screenOver,
    bool? screenSummary,
  }) => AppSettings(
    themeMode: themeMode ?? this.themeMode,
    colorblindSafe: colorblindSafe ?? this.colorblindSafe,
    locale: locale != null ? locale() : this.locale,
    notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    dailySummary: dailySummary ?? this.dailySummary,
    dailySummaryMinutes: dailySummaryMinutes ?? this.dailySummaryMinutes,
    choreReminders: choreReminders ?? this.choreReminders,
    weeklyRecap: weeklyRecap ?? this.weeklyRecap,
    monthlyRecap: monthlyRecap ?? this.monthlyRecap,
    fightSound: fightSound ?? this.fightSound,
    fightHaptics: fightHaptics ?? this.fightHaptics,
    fightLatencyMs: fightLatencyMs ?? this.fightLatencyMs,
    onboardingDone: onboardingDone ?? this.onboardingDone,
    screenTime: screenTime ?? this.screenTime,
    screenBaseMinutes: screenBaseMinutes ?? this.screenBaseMinutes,
    screenEarnCap: screenEarnCap ?? this.screenEarnCap,
    screenApps: screenApps ?? this.screenApps,
    screenWarn: screenWarn ?? this.screenWarn,
    screenOver: screenOver ?? this.screenOver,
    screenSummary: screenSummary ?? this.screenSummary,
  );

  @override
  bool operator ==(Object other) =>
      other is AppSettings &&
      other.themeMode == themeMode &&
      other.colorblindSafe == colorblindSafe &&
      other.locale == locale &&
      other.notificationsEnabled == notificationsEnabled &&
      other.dailySummary == dailySummary &&
      other.dailySummaryMinutes == dailySummaryMinutes &&
      other.choreReminders == choreReminders &&
      other.weeklyRecap == weeklyRecap &&
      other.monthlyRecap == monthlyRecap &&
      other.fightSound == fightSound &&
      other.fightHaptics == fightHaptics &&
      other.fightLatencyMs == fightLatencyMs &&
      other.onboardingDone == onboardingDone &&
      other.screenTime == screenTime &&
      other.screenBaseMinutes == screenBaseMinutes &&
      other.screenEarnCap == screenEarnCap &&
      listEquals(other.screenApps, screenApps) &&
      other.screenWarn == screenWarn &&
      other.screenOver == screenOver &&
      other.screenSummary == screenSummary;

  @override
  int get hashCode => Object.hashAll([
    themeMode,
    colorblindSafe,
    locale,
    notificationsEnabled,
    dailySummary,
    dailySummaryMinutes,
    choreReminders,
    weeklyRecap,
    monthlyRecap,
    fightSound,
    fightHaptics,
    fightLatencyMs,
    onboardingDone,
    screenTime,
    screenBaseMinutes,
    screenEarnCap,
    Object.hashAll(screenApps),
    screenWarn,
    screenOver,
    screenSummary,
  ]);
}
