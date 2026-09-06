import 'dart:convert';
import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'models/app_settings.dart';
import 'features/app_lock/app_lock_screen.dart';
import 'features/accounts/accounts_home_screen.dart';
import 'features/add_account/add_account_choice_sheet.dart';
import 'features/qr_scanner/qr_scanner_screen.dart';
import 'features/manual_setup/manual_setup_screen.dart';
import 'features/account_detail/account_detail_screen.dart';
import 'features/settings/settings_screen.dart';
import 'repositories/account_repository.dart';
import 'services/biometric_service.dart';
import 'services/privacy_service.dart';
import 'services/secure_storage_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyAuthenticatorApp());
}

/// Root application widget for MyAuthenticator.
class MyAuthenticatorApp extends StatefulWidget {
  final AccountRepository? accountRepository;
  final SecureStorageService? storageService;
  final BiometricService? biometricService;

  const MyAuthenticatorApp({
    super.key,
    this.accountRepository,
    this.storageService,
    this.biometricService,
  });

  @override
  State<MyAuthenticatorApp> createState() => _MyAuthenticatorAppState();
}

class _MyAuthenticatorAppState extends State<MyAuthenticatorApp>
    with WidgetsBindingObserver {
  final ValueNotifier<ThemeMode> _themeNotifier = ValueNotifier(ThemeMode.system);
  late final AccountRepository _accountRepository;
  late final SecureStorageService _storageService;
  late final BiometricService _biometricService;
  final GlobalKey<AccountsHomeScreenState> _homeKey = GlobalKey<AccountsHomeScreenState>();

  AppSettings _appSettings = const AppSettings();
  bool _isUnlocked = false; // Secure initial default: locked until app settings verified
  bool _isPrivacyOverlayActive = false;
  DateTime? _backgroundTimestamp;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _storageService = widget.storageService ?? SecureStorageService();
    _accountRepository = widget.accountRepository ?? AccountRepository(storageService: _storageService);
    _biometricService = widget.biometricService ?? BiometricService();
    _loadAppSettings();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _themeNotifier.dispose();
    super.dispose();
  }

  Future<void> _loadAppSettings() async {
    try {
      final jsonString = await _storageService.readAppSettings();
      if (jsonString != null && jsonString.isNotEmpty) {
        final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
        final loadedSettings = AppSettings.fromJson(jsonMap);
        if (mounted) {
          setState(() {
            _appSettings = loadedSettings;
            _themeNotifier.value = loadedSettings.themeMode;
            _isUnlocked = !loadedSettings.appLockEnabled;
          });
          return;
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _appSettings = const AppSettings();
        _isUnlocked = !_appSettings.appLockEnabled;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;

    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      _backgroundTimestamp ??= DateTime.now();
      if (_appSettings.screenPrivacyEnabled) {
        setState(() {
          _isPrivacyOverlayActive = true;
        });
      }
    } else if (state == AppLifecycleState.inactive) {
      if (_appSettings.screenPrivacyEnabled) {
        setState(() {
          _isPrivacyOverlayActive = true;
        });
      }
    } else if (state == AppLifecycleState.resumed) {
      final backgroundTime = _backgroundTimestamp;
      _backgroundTimestamp = null;

      // Check auto-lock duration criteria atomically
      if (_appSettings.appLockEnabled && _appSettings.autoLockEnabled && backgroundTime != null) {
        final elapsedSeconds = DateTime.now().difference(backgroundTime).inSeconds;
        if (elapsedSeconds >= _appSettings.autoLockTimeoutSeconds) {
          setState(() {
            _isUnlocked = false;
            _isPrivacyOverlayActive = false;
          });
          return;
        }
      }

      setState(() {
        _isPrivacyOverlayActive = false;
      });
    }
  }

  void _onUnlockSuccess() {
    setState(() {
      _isUnlocked = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: _themeNotifier,
      builder: (context, themeMode, child) {
        return MaterialApp(
          title: 'MyAuthenticator',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeMode,
          builder: (context, child) {
            return PrivacyService(
              isPrivacyActive: _isPrivacyOverlayActive,
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: Builder(
            builder: (context) {
              if (!_isUnlocked && _appSettings.appLockEnabled) {
                return AppLockScreen(
                  biometricService: _biometricService,
                  onUnlockSuccess: _onUnlockSuccess,
                );
              }
              return AccountsHomeScreen(
                key: _homeKey,
                accountRepository: _accountRepository,
                onAddAccountRequested: () => _showAddAccountChoices(context),
                onSettingsRequested: () => _navigateToSettings(context),
                onAccountSelected: (accountId) =>
                    _navigateToAccountDetail(context, accountId),
              );
            },
          ),
        );
      },
    );
  }

  void _showAddAccountChoices(BuildContext context) {
    AddAccountChoiceSheet.show(
      context,
      onScanQrSelected: () async {
        final result = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (context) => QrScannerScreen(
              accountRepository: _accountRepository,
            ),
          ),
        );
        if (result == true) {
          _homeKey.currentState?.refreshAccounts();
        }
      },
      onManualSetupSelected: () async {
        final result = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (context) => ManualSetupScreen(
              accountRepository: _accountRepository,
            ),
          ),
        );
        if (result == true) {
          _homeKey.currentState?.refreshAccounts();
        }
      },
    );
  }

  void _navigateToSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SettingsScreen(
          currentThemeMode: _themeNotifier.value,
          storageService: _storageService,
          onThemeModeChanged: (newMode) {
            _themeNotifier.value = newMode;
            _loadAppSettings();
          },
        ),
      ),
    );
  }

  void _navigateToAccountDetail(BuildContext context, String accountId) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => AccountDetailScreen(
          accountId: accountId,
          accountRepository: _accountRepository,
        ),
      ),
    );
    if (result == true) {
      _homeKey.currentState?.refreshAccounts();
    }
  }
}
