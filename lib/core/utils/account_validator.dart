import 'base32_util.dart';

/// Validation result class for user form input feedback.
class ValidationResult {
  final bool isValid;
  final String? errorMessage;

  const ValidationResult.success()
      : isValid = true,
        errorMessage = null;

  const ValidationResult.failure(this.errorMessage) : isValid = false;
}

/// Centralized validation logic for authenticator account creation and metadata editing.
abstract class AccountValidator {
  static const int maxFieldLength = 128;
  static const int minSecretLength = 8;
  static final RegExp _base32Regex = RegExp(r'^[A-Z2-7]+=*$');

  static ValidationResult validateIssuer(String? issuer) {
    if (issuer == null || issuer.trim().isEmpty) {
      return const ValidationResult.failure('Issuer / Service name is required.');
    }
    final trimmed = issuer.trim();
    if (trimmed.length > maxFieldLength) {
      return ValidationResult.failure(
          'Issuer name cannot exceed $maxFieldLength characters.');
    }
    return const ValidationResult.success();
  }

  static ValidationResult validateAccountName(String? accountName) {
    if (accountName == null || accountName.trim().isEmpty) {
      return const ValidationResult.failure('Account name or email is required.');
    }
    final trimmed = accountName.trim();
    if (trimmed.length > maxFieldLength) {
      return ValidationResult.failure(
          'Account name cannot exceed $maxFieldLength characters.');
    }
    return const ValidationResult.success();
  }

  static ValidationResult validateSecret(String? secret) {
    if (secret == null || secret.trim().isEmpty) {
      return const ValidationResult.failure('Secret key is required.');
    }
    final normalized = Base32Util.normalize(secret);
    if (normalized.length < minSecretLength) {
      return const ValidationResult.failure(
          'Secret key must be at least $minSecretLength characters.');
    }
    if (!_base32Regex.hasMatch(normalized)) {
      return const ValidationResult.failure(
          'Invalid Base32 secret key format. Allowed characters: A-Z, 2-7.');
    }
    return const ValidationResult.success();
  }

  static ValidationResult validateAlgorithm(String algorithm) {
    const allowed = ['SHA1', 'SHA256', 'SHA512'];
    if (!allowed.contains(algorithm.toUpperCase())) {
      return const ValidationResult.failure('Unsupported algorithm.');
    }
    return const ValidationResult.success();
  }

  static ValidationResult validateDigits(int digits) {
    if (digits != 6 && digits != 8) {
      return const ValidationResult.failure('Digits must be 6 or 8.');
    }
    return const ValidationResult.success();
  }

  static ValidationResult validatePeriod(int period) {
    if (period < 1 || period > 120) {
      return const ValidationResult.failure('Period must be between 1 and 120 seconds.');
    }
    return const ValidationResult.success();
  }
}
