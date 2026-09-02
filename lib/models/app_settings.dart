import 'package:flutter/material.dart';

/// Application configuration and security preferences data model.
/// Strictly excludes any sensitive authentication secrets or hardware credentials.
class AppSettings {
  final bool appLockEnabled;
  final bool autoLockEnabled;
  final int autoLockTimeoutSeconds; // e.g. 0 (Immediately), 15, 30, 60, 300
  final bool screenPrivacyEnabled;
  final bool clipboardAutoClearEnabled;
  final ThemeMode themeMode;

  const AppSettings({
    this.appLockEnabled = true,
    this.autoLockEnabled = true,
    this.autoLockTimeoutSeconds = 0,
    this.screenPrivacyEnabled = true,
    this.clipboardAutoClearEnabled = true,
    this.themeMode = ThemeMode.system,
  });

  AppSettings copyWith({
    bool? appLockEnabled,
    bool? autoLockEnabled,
    int? autoLockTimeoutSeconds,
    bool? screenPrivacyEnabled,
    bool? clipboardAutoClearEnabled,
    ThemeMode? themeMode,
  }) {
    return AppSettings(
      appLockEnabled: appLockEnabled ?? this.appLockEnabled,
      autoLockEnabled: autoLockEnabled ?? this.autoLockEnabled,
      autoLockTimeoutSeconds:
          autoLockTimeoutSeconds ?? this.autoLockTimeoutSeconds,
      screenPrivacyEnabled: screenPrivacyEnabled ?? this.screenPrivacyEnabled,
      clipboardAutoClearEnabled:
          clipboardAutoClearEnabled ?? this.clipboardAutoClearEnabled,
      themeMode: themeMode ?? this.themeMode,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'appLockEnabled': appLockEnabled,
      'autoLockEnabled': autoLockEnabled,
      'autoLockTimeoutSeconds': autoLockTimeoutSeconds,
      'screenPrivacyEnabled': screenPrivacyEnabled,
      'clipboardAutoClearEnabled': clipboardAutoClearEnabled,
      'themeMode': themeMode.name,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const AppSettings();

    try {
      ThemeMode parsedTheme = ThemeMode.system;
      final themeStr = json['themeMode'] as String?;
      if (themeStr == 'light') parsedTheme = ThemeMode.light;
      if (themeStr == 'dark') parsedTheme = ThemeMode.dark;

      final timeout = (json['autoLockTimeoutSeconds'] as num?)?.toInt() ?? 0;
      final safeTimeout = timeout >= 0 ? timeout : 0;

      return AppSettings(
        appLockEnabled: json['appLockEnabled'] as bool? ?? true,
        autoLockEnabled: json['autoLockEnabled'] as bool? ?? true,
        autoLockTimeoutSeconds: safeTimeout,
        screenPrivacyEnabled: json['screenPrivacyEnabled'] as bool? ?? true,
        clipboardAutoClearEnabled: json['clipboardAutoClearEnabled'] as bool? ?? true,
        themeMode: parsedTheme,
      );
    } catch (_) {
      // Safe fallback on corrupted JSON payload to secure default policy
      return const AppSettings();
    }
  }
}
