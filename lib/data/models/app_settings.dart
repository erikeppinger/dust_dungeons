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
      other.monthlyRecap == monthlyRecap;

  @override
  int get hashCode => Object.hash(
    themeMode,
    colorblindSafe,
    locale,
    notificationsEnabled,
    dailySummary,
    dailySummaryMinutes,
    choreReminders,
    weeklyRecap,
    monthlyRecap,
  );
}
