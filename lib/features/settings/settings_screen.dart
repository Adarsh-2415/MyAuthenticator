import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../models/app_settings.dart';
import '../../services/secure_storage_service.dart';
import '../../ui/components/settings_tile.dart';

/// Screen 7 — Settings Screen (Phase 6 Security & Privacy Preferences Integration).
class SettingsScreen extends StatefulWidget {
  final ThemeMode currentThemeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final SecureStorageService? storageService;

  const SettingsScreen({
    super.key,
    required this.currentThemeMode,
    required this.onThemeModeChanged,
    this.storageService,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final SecureStorageService _storageService;
  AppSettings _settings = const AppSettings();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _storageService = widget.storageService ?? SecureStorageService();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final jsonString = await _storageService.readAppSettings();
      if (jsonString != null && jsonString.isNotEmpty) {
        final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
        setState(() {
          _settings = AppSettings.fromJson(jsonMap);
          _isLoading = false;
        });
        return;
      }
    } catch (_) {}

    setState(() {
      _settings = AppSettings(themeMode: widget.currentThemeMode);
      _isLoading = false;
    });
  }

  Future<void> _saveSettings(AppSettings newSettings) async {
    setState(() {
      _settings = newSettings;
    });
    try {
      final jsonString = jsonEncode(newSettings.toJson());
      await _storageService.writeAppSettings(jsonString);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SafeArea(
        child: ListView(
          children: [
            const SectionHeader(title: 'Appearance'),
            SettingsTile(
              icon: Icons.palette_outlined,
              title: 'Theme Preference',
              subtitle: widget.currentThemeMode == ThemeMode.system
                  ? 'System Default'
                  : (widget.currentThemeMode == ThemeMode.dark
                      ? 'Dark Theme'
                      : 'Light Theme'),
              trailing: DropdownButton<ThemeMode>(
                value: widget.currentThemeMode,
                underline: const SizedBox.shrink(),
                items: const [
                  DropdownMenuItem(
                    value: ThemeMode.system,
                    child: Text('System'),
                  ),
                  DropdownMenuItem(
                    value: ThemeMode.light,
                    child: Text('Light'),
                  ),
                  DropdownMenuItem(
                    value: ThemeMode.dark,
                    child: Text('Dark'),
                  ),
                ],
                onChanged: (mode) {
                  if (mode != null) {
                    widget.onThemeModeChanged(mode);
                    _saveSettings(_settings.copyWith(themeMode: mode));
                  }
                },
              ),
            ),
            const Divider(),
            const SectionHeader(title: 'Security & App Protection'),
            SettingsTile(
              icon: Icons.fingerprint,
              title: 'Biometric & Passcode Lock',
              subtitle: 'Require hardware or OS credential authentication on launch',
              trailing: Switch(
                value: _settings.appLockEnabled,
                onChanged: (enabled) {
                  _saveSettings(_settings.copyWith(appLockEnabled: enabled));
                },
              ),
            ),
            SettingsTile(
              icon: Icons.timer_outlined,
              title: 'Auto-Lock Timeout',
              subtitle: 'Lock when backgrounded after timeout',
              trailing: DropdownButton<int>(
                value: _settings.autoLockTimeoutSeconds,
                underline: const SizedBox.shrink(),
                items: const [
                  DropdownMenuItem(value: 0, child: Text('Immediately')),
                  DropdownMenuItem(value: 15, child: Text('15 Seconds')),
                  DropdownMenuItem(value: 30, child: Text('30 Seconds')),
                  DropdownMenuItem(value: 60, child: Text('1 Minute')),
                  DropdownMenuItem(value: 300, child: Text('5 Minutes')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    _saveSettings(_settings.copyWith(
                      autoLockEnabled: true,
                      autoLockTimeoutSeconds: val,
                    ));
                  }
                },
              ),
            ),
            SettingsTile(
              icon: Icons.visibility_off_outlined,
              title: 'Screen Privacy Protection',
              subtitle: 'Prevent screenshots and recent app switcher previews',
              trailing: Switch(
                value: _settings.screenPrivacyEnabled,
                onChanged: (enabled) {
                  _saveSettings(_settings.copyWith(screenPrivacyEnabled: enabled));
                },
              ),
            ),
            SettingsTile(
              icon: Icons.content_paste_off_outlined,
              title: 'Clipboard Auto-Clear',
              subtitle: 'Automatically clear copied OTP codes after 30 seconds',
              trailing: Switch(
                value: _settings.clipboardAutoClearEnabled,
                onChanged: (enabled) {
                  _saveSettings(_settings.copyWith(clipboardAutoClearEnabled: enabled));
                },
              ),
            ),
            const Divider(),
            const SectionHeader(title: 'Application Info'),
            SettingsTile(
              icon: Icons.info_outline,
              title: 'About ${AppConstants.appName}',
              subtitle: 'Version ${AppConstants.appVersion} • Offline-First TOTP',
            ),
            SettingsTile(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy & Security Baseline',
              subtitle: 'Zero analytics, zero remote servers, 100% local storage',
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName: AppConstants.appName,
                  applicationVersion: AppConstants.appVersion,
                  applicationIcon: const Icon(Icons.shield, size: 48.0),
                  children: const [
                    Text(
                      'MyAuthenticator is a security-focused authenticator that generates TOTP codes strictly on device without transmitting data anywhere.',
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
