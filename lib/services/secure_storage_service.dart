import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Low-level storage service interfacing with platform-protected secure storage
/// (Android Keystore / iOS Keychain).
class SecureStorageService {
  static const String _accountsMetadataKey = 'myauthenticator_accounts';
  static const String _settingsKey = 'myauthenticator_settings';
  static const String _secretKeyPrefix = 'myauthenticator_secret_';

  final FlutterSecureStorage _storage;
  static final Map<String, String> _memoryStorageFallback = {};

  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(
                encryptedSharedPreferences: true,
              ),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock_this_device,
              ),
              webOptions: WebOptions(
                dbName: 'MyAuthenticatorWeb',
                publicKey: 'MyAuthenticatorWebKey',
              ),
            );

  /// Saves serialized account metadata JSON string.
  Future<void> writeAccountMetadata(String jsonString) async {
    if (kIsWeb) {
      _memoryStorageFallback[_accountsMetadataKey] = jsonString;
      return;
    }
    try {
      await _storage.write(key: _accountsMetadataKey, value: jsonString);
    } catch (_) {
      _memoryStorageFallback[_accountsMetadataKey] = jsonString;
    }
  }

  /// Reads serialized account metadata JSON string.
  Future<String?> readAccountMetadata() async {
    if (kIsWeb) {
      return _memoryStorageFallback[_accountsMetadataKey];
    }
    try {
      return await _storage.read(key: _accountsMetadataKey);
    } catch (_) {
      return _memoryStorageFallback[_accountsMetadataKey];
    }
  }

  /// Saves non-sensitive application settings JSON string.
  Future<void> writeAppSettings(String jsonString) async {
    if (kIsWeb) {
      _memoryStorageFallback[_settingsKey] = jsonString;
      return;
    }
    try {
      await _storage.write(key: _settingsKey, value: jsonString);
    } catch (_) {
      _memoryStorageFallback[_settingsKey] = jsonString;
    }
  }

  /// Reads non-sensitive application settings JSON string.
  Future<String?> readAppSettings() async {
    if (kIsWeb) {
      return _memoryStorageFallback[_settingsKey];
    }
    try {
      return await _storage.read(key: _settingsKey);
    } catch (_) {
      return _memoryStorageFallback[_settingsKey];
    }
  }

  /// Saves a TOTP secret bound strictly to an account ID.
  Future<void> writeAccountSecret(String accountId, String secret) async {
    final key = '$_secretKeyPrefix$accountId';
    if (kIsWeb) {
      _memoryStorageFallback[key] = secret;
      return;
    }
    try {
      await _storage.write(key: key, value: secret);
    } catch (_) {
      _memoryStorageFallback[key] = secret;
    }
  }

  /// Reads a TOTP secret for a given account ID.
  Future<String?> readAccountSecret(String accountId) async {
    final key = '$_secretKeyPrefix$accountId';
    if (kIsWeb) {
      return _memoryStorageFallback[key];
    }
    try {
      return await _storage.read(key: key);
    } catch (_) {
      return _memoryStorageFallback[key];
    }
  }

  /// Deletes a TOTP secret for a given account ID.
  Future<void> deleteAccountSecret(String accountId) async {
    final key = '$_secretKeyPrefix$accountId';
    _memoryStorageFallback.remove(key);
    if (kIsWeb) return;
    try {
      await _storage.delete(key: key);
    } catch (_) {}
  }

  /// Clears all stored data (used for security reset/tests).
  Future<void> deleteAllData() async {
    _memoryStorageFallback.clear();
    if (kIsWeb) return;
    try {
      await _storage.deleteAll();
    } catch (_) {}
  }
}
