import 'package:flutter_test/flutter_test.dart';
import 'package:authenticator/core/utils/otpauth_uri_parser.dart';

void main() {
  group('OtpAuthUriParser Tests', () {
    test('parses standard TOTP URI with label issuer', () {
      const uri = 'otpauth://totp/Google:user@gmail.com?secret=JBSWY3DPEHPK3PXP';
      final parsed = OtpAuthUriParser.parse(uri);

      expect(parsed.issuer, equals('Google'));
      expect(parsed.accountName, equals('user@gmail.com'));
      expect(parsed.secret, equals('JBSWY3DPEHPK3PXP'));
      expect(parsed.algorithm, equals('SHA1'));
      expect(parsed.digits, equals(6));
      expect(parsed.period, equals(30));
    });

    test('parses TOTP URI with query issuer parameter', () {
      const uri = 'otpauth://totp/user@gmail.com?secret=JBSWY3DPEHPK3PXP&issuer=GitHub';
      final parsed = OtpAuthUriParser.parse(uri);

      expect(parsed.issuer, equals('GitHub'));
      expect(parsed.accountName, equals('user@gmail.com'));
    });

    test('parses algorithms SHA256 and SHA512', () {
      const uri256 = 'otpauth://totp/AWS:admin?secret=JBSWY3DPEHPK3PXP&algorithm=SHA256';
      final parsed256 = OtpAuthUriParser.parse(uri256);
      expect(parsed256.algorithm, equals('SHA256'));

      const uri512 = 'otpauth://totp/AWS:admin?secret=JBSWY3DPEHPK3PXP&algorithm=SHA512';
      final parsed512 = OtpAuthUriParser.parse(uri512);
      expect(parsed512.algorithm, equals('SHA512'));
    });

    test('parses 8 digits and 60s period', () {
      const uri = 'otpauth://totp/Bank:user?secret=JBSWY3DPEHPK3PXP&digits=8&period=60';
      final parsed = OtpAuthUriParser.parse(uri);

      expect(parsed.digits, equals(8));
      expect(parsed.period, equals(60));
    });

    test('rejects empty, whitespace, and oversized inputs', () {
      expect(() => OtpAuthUriParser.parse(''), throwsA(isA<Exception>()));
      expect(() => OtpAuthUriParser.parse('   '), throwsA(isA<Exception>()));
      final oversized = 'otpauth://totp/A:${'x' * 2050}?secret=JBSWY3DPEHPK3PXP';
      expect(() => OtpAuthUriParser.parse(oversized), throwsA(isA<Exception>()));
    });

    test('rejects non-otpauth schemes and random QR data', () {
      expect(() => OtpAuthUriParser.parse('https://example.com'), throwsA(isA<Exception>()));
      expect(() => OtpAuthUriParser.parse('WIFI:S:MyWifi;P:pass;;'), throwsA(isA<Exception>()));
      expect(() => OtpAuthUriParser.parse('Hello World'), throwsA(isA<Exception>()));
    });

    test('rejects HOTP URIs', () {
      const hotp = 'otpauth://hotp/Google:user@gmail.com?secret=JBSWY3DPEHPK3PXP&counter=1';
      expect(() => OtpAuthUriParser.parse(hotp), throwsA(isA<Exception>()));
    });

    test('rejects missing secret or invalid Base32 secret', () {
      const missingSecret = 'otpauth://totp/Google:user@gmail.com';
      expect(() => OtpAuthUriParser.parse(missingSecret), throwsA(isA<Exception>()));

      const invalidSecret = 'otpauth://totp/Google:user@gmail.com?secret=INVALID_189';
      expect(() => OtpAuthUriParser.parse(invalidSecret), throwsA(isA<Exception>()));
    });

    test('rejects unsupported algorithm, digits, or period', () {
      const badAlgo = 'otpauth://totp/Google:user?secret=JBSWY3DPEHPK3PXP&algorithm=MD5';
      expect(() => OtpAuthUriParser.parse(badAlgo), throwsA(isA<Exception>()));

      const badDigits = 'otpauth://totp/Google:user?secret=JBSWY3DPEHPK3PXP&digits=4';
      expect(() => OtpAuthUriParser.parse(badDigits), throwsA(isA<Exception>()));

      const badPeriod = 'otpauth://totp/Google:user?secret=JBSWY3DPEHPK3PXP&period=300';
      expect(() => OtpAuthUriParser.parse(badPeriod), throwsA(isA<Exception>()));
    });

    test('rejects mismatched label issuer and query issuer', () {
      const mismatch = 'otpauth://totp/Google:user@gmail.com?secret=JBSWY3DPEHPK3PXP&issuer=GitHub';
      expect(() => OtpAuthUriParser.parse(mismatch), throwsA(isA<Exception>()));
    });
  });
}
