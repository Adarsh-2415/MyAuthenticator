import 'dart:typed_data';
import 'package:base32/base32.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:authenticator/core/crypto/totp_engine.dart';

void main() {
  group('RFC 6238 Official Appendix B Test Vectors', () {
    // Official RFC 6238 Seed for SHA1: ASCII 20 bytes "12345678901234567890"
    final sha1Secret = base32.encode(Uint8List.fromList('12345678901234567890'.codeUnits));

    // Official RFC 6238 Seed for SHA256: ASCII 32 bytes "12345678901234567890123456789012"
    final sha256Secret = base32.encode(Uint8List.fromList('12345678901234567890123456789012'.codeUnits));

    // Official RFC 6238 Seed for SHA512: ASCII 64 bytes "1234567890123456789012345678901234567890123456789012345678901234"
    final sha512Secret = base32.encode(Uint8List.fromList('1234567890123456789012345678901234567890123456789012345678901234'.codeUnits));

    final testTimestamps = [
      59,
      1111111109,
      1111111111,
      1234567890,
      2000000000,
      20000000000,
    ];

    final sha1Expected8Digits = [
      '94287082',
      '07081804',
      '14050471',
      '89005924',
      '69279037',
      '65353130',
    ];

    final sha256Expected8Digits = [
      '46119246',
      '68084774',
      '67062674',
      '91819424',
      '90698825',
      '77737706',
    ];

    final sha512Expected8Digits = [
      '90693936',
      '25091201',
      '99943326',
      '93441116',
      '38618901',
      '47863826',
    ];

    test('HMAC-SHA1 RFC 6238 8-digit test vectors', () {
      for (int i = 0; i < testTimestamps.length; i++) {
        final otp = TotpEngine.generateTotp(
          secret: sha1Secret,
          algorithm: 'SHA1',
          digits: 8,
          period: 30,
          timestampSeconds: testTimestamps[i],
        );
        expect(otp, equals(sha1Expected8Digits[i]));
      }
    });

    test('HMAC-SHA256 RFC 6238 8-digit test vectors', () {
      for (int i = 0; i < testTimestamps.length; i++) {
        final otp = TotpEngine.generateTotp(
          secret: sha256Secret,
          algorithm: 'SHA256',
          digits: 8,
          period: 30,
          timestampSeconds: testTimestamps[i],
        );
        expect(otp, equals(sha256Expected8Digits[i]));
      }
    });

    test('HMAC-SHA512 RFC 6238 8-digit test vectors', () {
      for (int i = 0; i < testTimestamps.length; i++) {
        final otp = TotpEngine.generateTotp(
          secret: sha512Secret,
          algorithm: 'SHA512',
          digits: 8,
          period: 30,
          timestampSeconds: testTimestamps[i],
        );
        expect(otp, equals(sha512Expected8Digits[i]));
      }
    });
  });

  group('TotpEngine Time Window Boundary Tests', () {
    const secret = 'JBSWY3DPEHPK3PXP';

    test('exact 30-second time boundary transition', () {
      final otpWindow0End = TotpEngine.generateTotp(
        secret: secret,
        algorithm: 'SHA1',
        digits: 6,
        period: 30,
        timestampSeconds: 29,
      );

      final otpWindow1Start = TotpEngine.generateTotp(
        secret: secret,
        algorithm: 'SHA1',
        digits: 6,
        period: 30,
        timestampSeconds: 30,
      );

      final otpWindow1Next = TotpEngine.generateTotp(
        secret: secret,
        algorithm: 'SHA1',
        digits: 6,
        period: 30,
        timestampSeconds: 31,
      );

      // Window 0 (29s) must differ from Window 1 (30s)
      expect(otpWindow0End, isNot(equals(otpWindow1Start)));
      // Window 1 (30s) must match Window 1 (31s)
      expect(otpWindow1Start, equals(otpWindow1Next));
    });

    test('exact 60-second time boundary transition', () {
      final otp59s = TotpEngine.generateTotp(
        secret: secret,
        algorithm: 'SHA1',
        digits: 6,
        period: 60,
        timestampSeconds: 59,
      );

      final otp60s = TotpEngine.generateTotp(
        secret: secret,
        algorithm: 'SHA1',
        digits: 6,
        period: 60,
        timestampSeconds: 60,
      );

      expect(otp59s, isNot(equals(otp60s)));
    });
  });

  group('TotpEngine Edge Cases & Zero Padding Tests', () {
    const secret = 'JBSWY3DPEHPK3PXP';

    test('generates 6-digit zero-padded OTP', () {
      final otp = TotpEngine.generateTotp(
        secret: secret,
        algorithm: 'SHA1',
        digits: 6,
        period: 30,
        timestampSeconds: 59,
      );
      expect(otp.length, equals(6));
      expect(RegExp(r'^\d{6}$').hasMatch(otp), isTrue);
    });

    test('generates 8-digit zero-padded OTP', () {
      final otp = TotpEngine.generateTotp(
        secret: secret,
        algorithm: 'SHA1',
        digits: 8,
        period: 30,
        timestampSeconds: 59,
      );
      expect(otp.length, equals(8));
      expect(RegExp(r'^\d{8}$').hasMatch(otp), isTrue);
    });

    test('decodes Base32 secret with and without padding', () {
      // "hello" in Base32 is "NBSWY3DP"
      final otp1 = TotpEngine.generateTotp(
        secret: 'NBSWY3DP',
        algorithm: 'SHA1',
        digits: 6,
        period: 30,
        timestampSeconds: 1000,
      );
      // "foo" in Base32 is "MZXW6==="
      final otp2 = TotpEngine.generateTotp(
        secret: 'MZXW6===',
        algorithm: 'SHA1',
        digits: 6,
        period: 30,
        timestampSeconds: 1000,
      );
      expect(otp1.length, equals(6));
      expect(otp2.length, equals(6));
    });

    test('rejects invalid digit count or unsupported algorithm', () {
      expect(
        () => TotpEngine.generateTotp(
          secret: secret,
          algorithm: 'SHA1',
          digits: 7,
          period: 30,
        ),
        throwsA(isA<TotpEngineException>()),
      );

      expect(
        () => TotpEngine.generateTotp(
          secret: secret,
          algorithm: 'MD5',
          digits: 6,
          period: 30,
        ),
        throwsA(isA<TotpEngineException>()),
      );
    });
  });

  group('TotpEngine Base32 Decoding & Algorithm Normalization Verification', () {
    test('TotpEngine.decodeSecret handles valid secrets of various formats', () {
      // 1. Standard 16-char secret
      final bytes1 = TotpEngine.decodeSecret('JBSWY3DPEHPK3PXP');
      expect(bytes1.isNotEmpty, isTrue);

      // 2. Secret with hyphens
      final bytes2 = TotpEngine.decodeSecret('JBSW-Y3DP-EHPK-3PXP');
      expect(bytes2, equals(bytes1));

      // 3. Lowercase secret
      final bytes3 = TotpEngine.decodeSecret('jbswy3dpehpk3pxp');
      expect(bytes3, equals(bytes1));

      // 4. Valid padded secret
      final bytes4 = TotpEngine.decodeSecret('JBSWY3DPEHPK3PXP====');
      expect(bytes4, equals(bytes1));

      // 5. RFC-compatible Base32 strings of various valid lengths
      // 10 chars: "NBSWY3DPQI======" -> "hello!"
      final b10 = TotpEngine.decodeSecret('NBSWY3DPQI');
      expect(b10.isNotEmpty, isTrue);

      // 26 chars: "MZXW6YTBOI======="
      final b26 = TotpEngine.decodeSecret('MZXW6YTBOI');
      expect(b26.isNotEmpty, isTrue);
    });

    test('TotpEngine.generateTotp normalizes algorithm variations like SHA-1, sha-1, SHA 1', () {
      const secret = 'JBSWY3DPEHPK3PXP';
      final otp1 = TotpEngine.generateTotp(
        secret: secret,
        algorithm: 'SHA-1',
        digits: 6,
        period: 30,
        timestampSeconds: 1000,
      );

      final otp2 = TotpEngine.generateTotp(
        secret: secret,
        algorithm: 'sha-1',
        digits: 6,
        period: 30,
        timestampSeconds: 1000,
      );

      final otp3 = TotpEngine.generateTotp(
        secret: secret,
        algorithm: 'SHA 1',
        digits: 6,
        period: 30,
        timestampSeconds: 1000,
      );

      final otpStandard = TotpEngine.generateTotp(
        secret: secret,
        algorithm: 'SHA1',
        digits: 6,
        period: 30,
        timestampSeconds: 1000,
      );

      expect(otp1, equals(otpStandard));
      expect(otp2, equals(otpStandard));
      expect(otp3, equals(otpStandard));
    });
  });

  group('TotpEngine counterToBytes Verification', () {
    test('counterToBytes(0) produces 8 zero bytes', () {
      final bytes = TotpEngine.counterToBytes(0);
      expect(bytes.length, equals(8));
      expect(bytes, equals(Uint8List.fromList([0, 0, 0, 0, 0, 0, 0, 0])));
    });

    test('counterToBytes(1) produces 8-byte big-endian [0,0,0,0,0,0,0,1]', () {
      final bytes = TotpEngine.counterToBytes(1);
      expect(bytes.length, equals(8));
      expect(bytes, equals(Uint8List.fromList([0, 0, 0, 0, 0, 0, 0, 1])));
    });

    test('counterToBytes for current Unix timestamp counter', () {
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final counter = TotpEngine.calculateCounter(timestampSeconds: now, period: 30);
      final bytes = TotpEngine.counterToBytes(counter);

      expect(bytes.length, equals(8));
      expect(counter, greaterThan(0));
      // Verify big-endian byte reconstruction
      int reconstructed = 0;
      for (int i = 0; i < 8; i++) {
        reconstructed = (reconstructed * 256) + bytes[i];
      }
      expect(reconstructed, equals(counter));
    });

    test('counterToBytes throws TotpEngineException on negative counter', () {
      expect(
        () => TotpEngine.counterToBytes(-1),
        throwsA(isA<TotpEngineException>()),
      );
    });
  });
}
