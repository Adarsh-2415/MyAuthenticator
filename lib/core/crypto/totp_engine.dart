import 'dart:math' as math;
import 'dart:typed_data';
import 'package:base32/base32.dart';
import 'package:crypto/crypto.dart';
import '../utils/base32_util.dart';

/// Transparent, auditable RFC 6238 Time-Based One-Time Password (TOTP) engine.
/// Supports SHA1, SHA256, SHA512 algorithms, 6 or 8 digits, and custom time periods.
abstract class TotpEngine {
  /// Validates Base32 formatting for secret string.
  static bool isValidBase32Secret(String secret) {
    if (secret.trim().isEmpty) return false;
    final normalized = Base32Util.normalize(secret);
    return RegExp(r'^[A-Z2-7]+=*$').hasMatch(normalized);
  }

  /// Decodes Base32 secret string into raw secret bytes, applying padding if necessary.
  static Uint8List decodeSecret(String secret) {
    var normalized = Base32Util.normalize(secret);
    final remainder = normalized.length % 8;
    if (remainder != 0) {
      normalized = normalized.padRight(normalized.length + (8 - remainder), '=');
    }
    try {
      return base32.decode(normalized);
    } catch (_) {
      throw Exception('Invalid Base32 secret format');
    }
  }

  /// Calculates the 8-byte big-endian time counter for a given Unix timestamp and period.
  static int calculateCounter({required int timestampSeconds, required int period}) {
    if (period <= 0) throw Exception('Period must be greater than 0');
    return timestampSeconds ~/ period;
  }

  /// Converts a integer counter into an 8-byte Big-Endian byte array.
  static Uint8List counterToBytes(int counter) {
    final bytes = Uint8List(8);
    final ByteData byteData = bytes.buffer.asByteData();
    byteData.setInt64(0, counter, Endian.big);
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
    if (digits != 6 && digits != 8) {
      throw Exception('Unsupported digit length: $digits. Must be 6 or 8.');
    }

    final currentSeconds = timestampSeconds ?? (DateTime.now().millisecondsSinceEpoch ~/ 1000);
    final counter = calculateCounter(timestampSeconds: currentSeconds, period: period);
    final secretBytes = decodeSecret(secret);
    final counterBytes = counterToBytes(counter);

    List<int> hmacBytes;
    final algoUpper = algorithm.toUpperCase();

    if (algoUpper == 'SHA1') {
      hmacBytes = Hmac(sha1, secretBytes).convert(counterBytes).bytes;
    } else if (algoUpper == 'SHA256') {
      hmacBytes = Hmac(sha256, secretBytes).convert(counterBytes).bytes;
    } else if (algoUpper == 'SHA512') {
      hmacBytes = Hmac(sha512, secretBytes).convert(counterBytes).bytes;
    } else {
      throw Exception('Unsupported algorithm: $algorithm');
    }

    // RFC 4226 Dynamic Truncation
    final int offset = hmacBytes.last & 0x0f;
    final int binaryCode = ((hmacBytes[offset] & 0x7f) << 24) |
        ((hmacBytes[offset + 1] & 0xff) << 16) |
        ((hmacBytes[offset + 2] & 0xff) << 8) |
        (hmacBytes[offset + 3] & 0xff);

    final int modulus = math.pow(10, digits).toInt();
    final int otpInt = binaryCode % modulus;

    return otpInt.toString().padLeft(digits, '0');
  }
}
