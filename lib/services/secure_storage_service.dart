import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Low-level storage service interfacing with platform-protected secure storage
/// (Android Keystore / iOS Keychain).
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
              ),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock_this_device,
              ),
            );

  /// Saves serialized account metadata JSON string.
  Future<void> writeAccountMetadata(String jsonString) async {
    await _storage.write(key: _accountsMetadataKey, value: jsonString);
  }

  /// Reads serialized account metadata JSON string.
  Future<String?> readAccountMetadata() async {
    return await _storage.read(key: _accountsMetadataKey);
  }

  /// Saves non-sensitive application settings JSON string.
  Future<void> writeAppSettings(String jsonString) async {
    await _storage.write(key: _settingsKey, value: jsonString);
  }

  /// Reads non-sensitive application settings JSON string.
  Future<String?> readAppSettings() async {
    return await _storage.read(key: _settingsKey);
  }

  /// Saves a TOTP secret bound strictly to an account ID.
  Future<void> writeAccountSecret(String accountId, String secret) async {
    final key = '$_secretKeyPrefix$accountId';
    await _storage.write(key: key, value: secret);
  }

  /// Reads a TOTP secret for a given account ID.
  Future<String?> readAccountSecret(String accountId) async {
    final key = '$_secretKeyPrefix$accountId';
    return await _storage.read(key: key);
  }

  /// Deletes a TOTP secret for a given account ID.
  Future<void> deleteAccountSecret(String accountId) async {
    final key = '$_secretKeyPrefix$accountId';
    await _storage.delete(key: key);
  }

  /// Clears all stored data (used for security reset/tests).
  Future<void> deleteAllData() async {
    await _storage.deleteAll();
  }
}
