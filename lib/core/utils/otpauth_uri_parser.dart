import 'account_validator.dart';
import 'base32_util.dart';

/// Representation of parsed OTPAuth provisioning data.
/// Raw secrets are held strictly in memory during onboarding and excluded from UI rendering.
class ParsedOtpAuthData {
  final String issuer;
  final String accountName;
  final String secret;
  final String algorithm;
  final int digits;
  final int period;

  const ParsedOtpAuthData({
    required this.issuer,
    required this.accountName,
    required this.secret,
    this.algorithm = 'SHA1',
    this.digits = 6,
    this.period = 30,
  });
}

/// Utility for parsing and validating OTPAuth provisioning URIs (`otpauth://totp/...`).
abstract class OtpAuthUriParser {
  static const int maxQrLength = 2048;

  /// Parses a raw QR string into [ParsedOtpAuthData].
  /// Throws user-friendly exception messages on invalid input.
  static ParsedOtpAuthData parse(String rawString) {
    if (rawString.trim().isEmpty) {
      throw Exception('QR content is empty.');
    }
    if (rawString.length > maxQrLength) {
      throw Exception('QR content exceeds maximum supported length.');
    }

    final Uri? uri = Uri.tryParse(rawString.trim());
    if (uri == null || uri.scheme.toLowerCase() != 'otpauth') {
      throw Exception('This QR code is not a supported authenticator code.');
    }

    final hostType = uri.host.toLowerCase();
    if (hostType == 'hotp') {
      throw Exception('Only TOTP authenticator codes are currently supported.');
    }
    if (hostType != 'totp') {
      throw Exception('Unsupported OTP type in QR code.');
    }

    // Decode path (e.g. "/Google:user@example.com" or "/user@example.com")
    final rawPath = Uri.decodeComponent(uri.path).replaceAll(RegExp(r'^/+'), '').trim();
    String? labelIssuer;
    String accountName = '';

    if (rawPath.contains(':')) {
      final parts = rawPath.split(':');
      labelIssuer = parts[0].trim();
      accountName = parts.sublist(1).join(':').trim();
    } else {
      accountName = rawPath;
    }

    final queryIssuer = uri.queryParameters['issuer']?.trim();

    String finalIssuer = '';
    if (labelIssuer != null && labelIssuer.isNotEmpty && queryIssuer != null && queryIssuer.isNotEmpty) {
      if (labelIssuer.toLowerCase() != queryIssuer.toLowerCase()) {
        throw Exception('Issuer mismatch in QR code.');
      }
      finalIssuer = queryIssuer;
    } else if (queryIssuer != null && queryIssuer.isNotEmpty) {
      finalIssuer = queryIssuer;
    } else if (labelIssuer != null && labelIssuer.isNotEmpty) {
      finalIssuer = labelIssuer;
    }

    final issuerRes = AccountValidator.validateIssuer(finalIssuer);
    if (!issuerRes.isValid) {
      throw Exception('Missing or invalid issuer in QR code.');
    }

    final nameRes = AccountValidator.validateAccountName(accountName);
    if (!nameRes.isValid) {
      throw Exception('Missing or invalid account name in QR code.');
    }

    final secretParam = uri.queryParameters['secret'];
    if (secretParam == null || secretParam.trim().isEmpty) {
      throw Exception('This authenticator QR code is incomplete (missing secret key).');
    }

    final normalizedSecret = Base32Util.normalize(secretParam);
    final secretRes = AccountValidator.validateSecret(normalizedSecret);
    if (!secretRes.isValid) {
      throw Exception('This authenticator code contains an invalid secret key.');
    }

    final algoParam = (uri.queryParameters['algorithm'] ?? 'SHA1').toUpperCase();
    final algoRes = AccountValidator.validateAlgorithm(algoParam);
    if (!algoRes.isValid) {
      throw Exception('Unsupported algorithm in QR code.');
    }

    final digitsParam = int.tryParse(uri.queryParameters['digits'] ?? '6') ?? 6;
    final digitsRes = AccountValidator.validateDigits(digitsParam);
    if (!digitsRes.isValid) {
      throw Exception('Unsupported digit count in QR code.');
    }

    final periodParam = int.tryParse(uri.queryParameters['period'] ?? '30') ?? 30;
    final periodRes = AccountValidator.validatePeriod(periodParam);
    if (!periodRes.isValid) {
      throw Exception('Unsupported time period in QR code.');
    }

    return ParsedOtpAuthData(
      issuer: finalIssuer.trim(),
      accountName: accountName.trim(),
      secret: normalizedSecret,
      algorithm: algoParam,
      digits: digitsParam,
      period: periodParam,
    );
  }
}
