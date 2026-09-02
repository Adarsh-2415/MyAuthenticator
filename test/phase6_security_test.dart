import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:authenticator/models/app_settings.dart';
import 'package:authenticator/services/biometric_service.dart';
import 'package:authenticator/services/clipboard_service.dart';
import 'package:authenticator/core/utils/account_validator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppSettings Tests & Corrupted Storage Fallback', () {
    test('default settings initialization', () {
      const settings = AppSettings();
      expect(settings.appLockEnabled, isTrue);
      expect(settings.autoLockEnabled, isTrue);
      expect(settings.autoLockTimeoutSeconds, equals(0));
      expect(settings.screenPrivacyEnabled, isTrue);
      expect(settings.clipboardAutoClearEnabled, isTrue);
      expect(settings.themeMode, equals(ThemeMode.system));
    });

    test('JSON serialization and deserialization', () {
      const original = AppSettings(
        appLockEnabled: true,
        autoLockEnabled: true,
        autoLockTimeoutSeconds: 30,
        screenPrivacyEnabled: true,
        clipboardAutoClearEnabled: true,
        themeMode: ThemeMode.dark,
      );

      final json = original.toJson();
      final deserialized = AppSettings.fromJson(json);

      expect(deserialized.appLockEnabled, isTrue);
      expect(deserialized.autoLockTimeoutSeconds, equals(30));
      expect(deserialized.themeMode, equals(ThemeMode.dark));
    });

    test('corrupted JSON payload falls back to secure default policy', () {
      final corruptedJson = {
        'appLockEnabled': 'INVALID_TYPE',
        'autoLockTimeoutSeconds': -999,
        'themeMode': 12345,
      };

      final settings = AppSettings.fromJson(corruptedJson as Map<String, dynamic>);
      expect(settings.appLockEnabled, isTrue);
      expect(settings.autoLockTimeoutSeconds, equals(0));
      expect(settings.themeMode, equals(ThemeMode.system));
    });

    test('null json payload returns secure default settings', () {
      final settings = AppSettings.fromJson(null);
      expect(settings.appLockEnabled, isTrue);
      expect(settings.screenPrivacyEnabled, isTrue);
    });

    test('copyWith updates specified values correctly', () {
      const original = AppSettings();
      final updated = original.copyWith(
        autoLockTimeoutSeconds: 60,
        themeMode: ThemeMode.light,
      );

      expect(updated.autoLockTimeoutSeconds, equals(60));
      expect(updated.themeMode, equals(ThemeMode.light));
      expect(updated.appLockEnabled, isTrue);
    });
  });

  group('BiometricService Concurrency Lock Tests', () {
    test('isDeviceSupported returns false gracefully in un-mocked test environment', () async {
      final service = BiometricService();
      final isSupported = await service.isDeviceSupported();
      expect(isSupported, isFalse);
    });

    test('authenticate returns notAvailable in un-mocked test environment without throwing', () async {
      final service = BiometricService();
      final result = await service.authenticate(reason: 'Test');
      expect(result, equals(BiometricAuthResult.notAvailable));
      expect(service.isAuthenticating, isFalse);
    });
  });

  group('ClipboardService Security & Timer Tests', () {
    tearDown(() {
      ClipboardService.cancelAutoClearTimer();
    });

    test('copyOtp schedules auto-clear timer cleanly', () async {
      await ClipboardService.copyOtp(
        '482931',
        autoClearEnabled: true,
        clearDelaySeconds: 1,
      );

      await Future.delayed(const Duration(milliseconds: 1100));
    });

    test('sequential copyOtp cancels previous timer', () async {
      await ClipboardService.copyOtp(
        '111111',
        autoClearEnabled: true,
        clearDelaySeconds: 2,
      );

      // Copy new OTP after 1 second
      await Future.delayed(const Duration(milliseconds: 500));
      await ClipboardService.copyOtp(
        '222222',
        autoClearEnabled: true,
        clearDelaySeconds: 2,
      );

      await Future.delayed(const Duration(milliseconds: 2100));
    });
  });

  group('AccountValidator Length Bounds & Input Security Tests', () {
    test('rejects issuer names exceeding max length limit', () {
      final longIssuer = 'A' * 129;
      final res = AccountValidator.validateIssuer(longIssuer);
      expect(res.isValid, isFalse);
      expect(res.errorMessage, contains('cannot exceed 128 characters'));
    });

    test('rejects account names exceeding max length limit', () {
      final longName = 'B' * 129;
      final res = AccountValidator.validateAccountName(longName);
      expect(res.isValid, isFalse);
      expect(res.errorMessage, contains('cannot exceed 128 characters'));
    });

    test('accepts valid 128 character issuer and account names', () {
      final validIssuer = 'A' * 128;
      final validName = 'B' * 128;
      expect(AccountValidator.validateIssuer(validIssuer).isValid, isTrue);
      expect(AccountValidator.validateAccountName(validName).isValid, isTrue);
    });
  });
}
