import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Low-level storage service interfacing with platform-protected secure storage
/// (Android Keystore / iOS Keychain / WebStorage).
class SecureStorageService {
  static const String _accountsMetadataKey = 'myauthenticator_accounts';
  static const String _settingsKey = 'myauthenticator_settings';
  static const String _secretKeyPrefix = 'myauthenticator_secret_';

  final FlutterSecureStorage _storage;

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
    try {
      await _storage.write(key: _accountsMetadataKey, value: jsonString);
    } catch (_) {
      // Fallback on platform storage error
    }
  }

  /// Reads serialized account metadata JSON string.
  Future<String?> readAccountMetadata() async {
    try {
      return await _storage.read(key: _accountsMetadataKey);
    } catch (_) {
      return null;
    }
  }

  /// Saves non-sensitive application settings JSON string.
  Future<void> writeAppSettings(String jsonString) async {
    try {
      await _storage.write(key: _settingsKey, value: jsonString);
    } catch (_) {}
  }

  /// Reads non-sensitive application settings JSON string.
  Future<String?> readAppSettings() async {
    try {
      return await _storage.read(key: _settingsKey);
    } catch (_) {
      return null;
    }
  }

  /// Saves a TOTP secret bound strictly to an account ID.
  Future<void> writeAccountSecret(String accountId, String secret) async {
    final key = '$_secretKeyPrefix$accountId';
    try {
      await _storage.write(key: key, value: secret);
    } catch (_) {}
  }

  /// Reads a TOTP secret for a given account ID.
  Future<String?> readAccountSecret(String accountId) async {
    final key = '$_secretKeyPrefix$accountId';
    try {
      return await _storage.read(key: key);
    } catch (_) {
      return null;
    }
  }

  /// Deletes a TOTP secret for a given account ID.
  Future<void> deleteAccountSecret(String accountId) async {
    final key = '$_secretKeyPrefix$accountId';
    try {
      await _storage.delete(key: key);
    } catch (_) {}
  }

  /// Clears all stored data (used for security reset/tests).
  Future<void> deleteAllData() async {
    try {
      await _storage.deleteAll();
    } catch (_) {}
  }
}
