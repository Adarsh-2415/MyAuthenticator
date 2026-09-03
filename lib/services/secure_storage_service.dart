import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Low-level storage service interfacing with platform-protected secure storage
/// (Android Keystore / iOS Keychain / WebStorage) with transparent in-memory fallback.
class SecureStorageService {
  static const String _accountsMetadataKey = 'myauthenticator_accounts';
  static const String _settingsKey = 'myauthenticator_settings';
  static const String _secretKeyPrefix = 'myauthenticator_secret_';

  final FlutterSecureStorage _storage;
  final Map<String, String> _inMemoryFallbackStorage = {};

  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(
                encryptedSharedPreferences: true,
                resetOnError: true,
              ),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock_this_device,
              ),
              webOptions: WebOptions(
                dbName: 'MyAuthenticatorSecureStorage',
                publicKey: 'MyAuthenticatorApp',
              ),
            );

  /// Saves serialized account metadata JSON string.
  Future<void> writeAccountMetadata(String jsonString) async {
    _inMemoryFallbackStorage[_accountsMetadataKey] = jsonString;
    try {
      await _storage.write(key: _accountsMetadataKey, value: jsonString);
    } catch (_) {}
  }

  /// Reads serialized account metadata JSON string.
  Future<String?> readAccountMetadata() async {
    try {
      final val = await _storage.read(key: _accountsMetadataKey);
      if (val != null && val.isNotEmpty) {
        _inMemoryFallbackStorage[_accountsMetadataKey] = val;
        return val;
      }
    } catch (_) {}
    return _inMemoryFallbackStorage[_accountsMetadataKey];
  }

  /// Saves non-sensitive application settings JSON string.
  Future<void> writeAppSettings(String jsonString) async {
    _inMemoryFallbackStorage[_settingsKey] = jsonString;
    try {
      await _storage.write(key: _settingsKey, value: jsonString);
    } catch (_) {}
  }

  /// Reads non-sensitive application settings JSON string.
  Future<String?> readAppSettings() async {
    try {
      final val = await _storage.read(key: _settingsKey);
      if (val != null && val.isNotEmpty) {
        _inMemoryFallbackStorage[_settingsKey] = val;
        return val;
      }
    } catch (_) {}
    return _inMemoryFallbackStorage[_settingsKey];
  }

  /// Saves a TOTP secret bound strictly to an account ID.
  Future<void> writeAccountSecret(String accountId, String secret) async {
    final key = '$_secretKeyPrefix$accountId';
    _inMemoryFallbackStorage[key] = secret;
    try {
      await _storage.write(key: key, value: secret);
    } catch (_) {}
  }

  /// Reads a TOTP secret for a given account ID.
  Future<String?> readAccountSecret(String accountId) async {
    final key = '$_secretKeyPrefix$accountId';
    try {
      final val = await _storage.read(key: key);
      if (val != null && val.isNotEmpty) {
        _inMemoryFallbackStorage[key] = val;
        return val;
      }
    } catch (_) {}
    return _inMemoryFallbackStorage[key];
  }

  /// Deletes a TOTP secret for a given account ID.
  Future<void> deleteAccountSecret(String accountId) async {
    final key = '$_secretKeyPrefix$accountId';
    _inMemoryFallbackStorage.remove(key);
    try {
      await _storage.delete(key: key);
    } catch (_) {}
  }

  /// Clears all stored data (used for security reset/tests).
  Future<void> deleteAllData() async {
    _inMemoryFallbackStorage.clear();
    try {
      await _storage.deleteAll();
    } catch (_) {}
  }
}
