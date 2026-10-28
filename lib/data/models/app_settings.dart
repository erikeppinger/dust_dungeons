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
    this.fightStoryMode = false,
    this.fightSlowMode = false,
    this.fightLatencyMs = 0,
    this.avatarSkin = 0,
    this.avatarHair = 0,
    this.avatarCape = 0,
    this.avatarHat = 0,
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

  /// Story mode: fights cannot be lost, wider timing.
  final bool fightStoryMode;

  /// Slow mode: fights play at 70 % tempo.
  final bool fightSlowMode;

  /// Calibrated tap delay in ms, subtracted from every tap in fights.
  final int fightLatencyMs;

  /// Avatar choices, as indexes into the avatar palettes.
  final int avatarSkin;
  final int avatarHair;
  final int avatarCape;

  /// 0 = no hat, otherwise 1 + the index in `hats` (shop).
  final int avatarHat;

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
    bool? fightStoryMode,
    bool? fightSlowMode,
    int? fightLatencyMs,
    int? avatarSkin,
    int? avatarHair,
    int? avatarCape,
    int? avatarHat,
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
    fightStoryMode: fightStoryMode ?? this.fightStoryMode,
    fightSlowMode: fightSlowMode ?? this.fightSlowMode,
    fightLatencyMs: fightLatencyMs ?? this.fightLatencyMs,
    avatarSkin: avatarSkin ?? this.avatarSkin,
    avatarHair: avatarHair ?? this.avatarHair,
    avatarCape: avatarCape ?? this.avatarCape,
    avatarHat: avatarHat ?? this.avatarHat,
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
      other.fightStoryMode == fightStoryMode &&
      other.fightSlowMode == fightSlowMode &&
      other.fightLatencyMs == fightLatencyMs &&
      other.avatarSkin == avatarSkin &&
      other.avatarHair == avatarHair &&
      other.avatarCape == avatarCape &&
      other.avatarHat == avatarHat;

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
    fightStoryMode,
    fightSlowMode,
    fightLatencyMs,
    avatarSkin,
    avatarHair,
    avatarCape,
    avatarHat,
  ]);
}
