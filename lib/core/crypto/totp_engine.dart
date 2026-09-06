import 'dart:math' as math;
import 'dart:typed_data';
import 'package:base32/base32.dart';
import 'package:crypto/crypto.dart';
import '../../models/otp_display_data.dart';
import '../utils/base32_util.dart';

/// Exception thrown specifically during TOTP generation stages with non-sensitive diagnostic categorization.
class TotpEngineException implements Exception {
  final OtpFailureCategory category;
  final String message;

  const TotpEngineException(this.category, [this.message = '']);

  @override
  String toString() => 'TotpEngineException($category): $message';
}

/// Transparent, auditable RFC 6238 Time-Based One-Time Password (TOTP) engine.
/// Supports SHA1, SHA256, SHA512 algorithms, 6 or 8 digits, and custom time periods.
abstract class TotpEngine {
  /// Validates Base32 formatting for secret string.
  static bool isValidBase32Secret(String secret) {
    if (secret.trim().isEmpty) return false;
    final clean = Base32Util.normalize(secret).replaceAll('=', '');
    if (clean.isEmpty) return false;
    return RegExp(r'^[A-Z2-7]+$').hasMatch(clean);
  }

  /// Decodes Base32 secret string into raw secret bytes, applying padding if necessary.
  static Uint8List decodeSecret(String secret) {
    final clean = Base32Util.normalize(secret).replaceAll('=', '');
    if (clean.isEmpty) {
      throw const TotpEngineException(
        OtpFailureCategory.secretInvalid,
        'Base32 secret is empty after normalization',
      );
    }

    if (!RegExp(r'^[A-Z2-7]+$').hasMatch(clean)) {
      throw const TotpEngineException(
        OtpFailureCategory.secretInvalid,
        'Base32 secret contains invalid characters',
      );
    }

    var padded = clean;
    final remainder = clean.length % 8;
    if (remainder != 0) {
      padded = clean.padRight(clean.length + (8 - remainder), '=');
    }

    Uint8List bytes;
    try {
      bytes = base32.decode(clean);
    } catch (_) {
      try {
        bytes = base32.decode(padded);
      } catch (_) {
        throw const TotpEngineException(
          OtpFailureCategory.base32DecodeError,
          'Base32 package decode failed',
        );
      }
    }

    if (bytes.isEmpty) {
      throw const TotpEngineException(
        OtpFailureCategory.invalidDecodedSecret,
        'Decoded secret bytes array is empty',
      );
    }

    return bytes;
  }

  /// Calculates the 8-byte big-endian time counter for a given Unix timestamp and period.
  static int calculateCounter({required int timestampSeconds, required int period}) {
    if (period <= 0) {
      throw const TotpEngineException(
        OtpFailureCategory.invalidPeriod,
        'Period must be greater than 0',
      );
    }
    return timestampSeconds ~/ period;
  }

  /// Converts an integer counter into an 8-byte Big-Endian byte array without relying on Web-unsupported setInt64.
  static Uint8List counterToBytes(int counter) {
    if (counter < 0) {
      throw const TotpEngineException(
        OtpFailureCategory.counterError,
        'Invalid TOTP counter',
      );
    }

    final bytes = Uint8List(8);
    var value = counter;

    for (int i = 7; i >= 0; i--) {
      bytes[i] = value & 0xFF;
      value = value ~/ 256;
    }

    return bytes;
  }

  /// Generates mathematically verified RFC 6238 TOTP code string.
  static String generateTotp({
    required String secret,
    required String algorithm,
    required int digits,
    required int period,
    int? timestampSeconds,
  }) {
    // 1. Digits validation
    if (digits != 6 && digits != 8) {
      throw const TotpEngineException(
        OtpFailureCategory.otpFormattingError,
        'Unsupported digit length. Must be 6 or 8.',
      );
    }

    // 2. Period validation & Counter calculation
    if (period <= 0) {
      throw const TotpEngineException(
        OtpFailureCategory.invalidPeriod,
        'Period must be greater than 0.',
      );
    }

    final currentSeconds = timestampSeconds ?? (DateTime.now().millisecondsSinceEpoch ~/ 1000);
    final counter = calculateCounter(timestampSeconds: currentSeconds, period: period);
    final counterBytes = counterToBytes(counter);

    // 3. Base32 Secret decoding
    final secretBytes = decodeSecret(secret);

    // 4. Algorithm normalization & validation
    final algoClean = algorithm.replaceAll('-', '').replaceAll(' ', '').toUpperCase();
    int expectedHmacLength;

    if (algoClean == 'SHA1') {
      expectedHmacLength = 20;
    } else if (algoClean == 'SHA256') {
      expectedHmacLength = 32;
    } else if (algoClean == 'SHA512') {
      expectedHmacLength = 64;
    } else {
      throw const TotpEngineException(
        OtpFailureCategory.invalidAlgorithm,
        'Unsupported algorithm.',
      );
    }

    // 5. HMAC Generation
    List<int> hmacBytes;
    try {
      if (algoClean == 'SHA1') {
        hmacBytes = Hmac(sha1, secretBytes).convert(counterBytes).bytes;
      } else if (algoClean == 'SHA256') {
        hmacBytes = Hmac(sha256, secretBytes).convert(counterBytes).bytes;
      } else {
        hmacBytes = Hmac(sha512, secretBytes).convert(counterBytes).bytes;
      }
    } catch (_) {
      throw const TotpEngineException(
        OtpFailureCategory.hmacGenerationError,
        'HMAC computation failed.',
      );
    }

    if (hmacBytes.length < expectedHmacLength) {
      throw const TotpEngineException(
        OtpFailureCategory.hmacGenerationError,
        'HMAC byte array shorter than expected algorithm digest length.',
      );
    }

    // 6. Dynamic Truncation
    final int offset = hmacBytes.last & 0x0f;
    if (offset + 3 >= hmacBytes.length) {
      throw const TotpEngineException(
        OtpFailureCategory.dynamicTruncationError,
        'Dynamic truncation offset out of byte array bounds.',
      );
    }

    final int binaryCode = ((hmacBytes[offset] & 0x7f) << 24) |
        ((hmacBytes[offset + 1] & 0xff) << 16) |
        ((hmacBytes[offset + 2] & 0xff) << 8) |
        (hmacBytes[offset + 3] & 0xff);

    // 7. Modulus & Output Formatting
    try {
      final int modulus = math.pow(10, digits).toInt();
      final int otpInt = binaryCode % modulus;
      final otpStr = otpInt.toString().padLeft(digits, '0');
      if (otpStr.length != digits) {
        throw const TotpEngineException(
          OtpFailureCategory.otpFormattingError,
          'Formatted OTP digit count mismatch.',
        );
      }
      return otpStr;
    } catch (e) {
      if (e is TotpEngineException) rethrow;
      throw const TotpEngineException(
        OtpFailureCategory.otpFormattingError,
        'OTP formatting calculation failed.',
      );
    }
  }
}
