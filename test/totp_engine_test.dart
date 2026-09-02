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

    test('rejects invalid digit count or unsupported algorithm', () {
      expect(
        () => TotpEngine.generateTotp(
          secret: secret,
          algorithm: 'SHA1',
          digits: 7,
          period: 30,
        ),
        throwsA(isA<Exception>()),
      );

      expect(
        () => TotpEngine.generateTotp(
          secret: secret,
          algorithm: 'MD5',
          digits: 6,
          period: 30,
        ),
        throwsA(isA<Exception>()),
      );
    });
  });
}
