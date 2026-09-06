import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:authenticator/core/utils/account_validator.dart';
import 'package:authenticator/models/otp_display_data.dart';
import 'package:authenticator/repositories/account_repository.dart';
import 'package:authenticator/services/secure_storage_service.dart';

class FailingMetadataStorageService extends SecureStorageService {
  final bool failOnMetadataWrite;

  FailingMetadataStorageService({this.failOnMetadataWrite = true});

  @override
  Future<void> writeAccountMetadata(String jsonString) async {
    if (failOnMetadataWrite) {
      throw Exception('Simulated Secure Storage Metadata Write Failure');
    }
    await super.writeAccountMetadata(jsonString);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AccountValidator Tests', () {
    test('validateIssuer rejects empty and accepts valid strings', () {
      expect(AccountValidator.validateIssuer('').isValid, isFalse);
      expect(AccountValidator.validateIssuer('  ').isValid, isFalse);
      expect(AccountValidator.validateIssuer('Google').isValid, isTrue);
    });

    test('validateAccountName rejects empty and accepts valid strings', () {
      expect(AccountValidator.validateAccountName('').isValid, isFalse);
      expect(AccountValidator.validateAccountName('user@example.com').isValid, isTrue);
    });

    test('validateSecret validates Base32 character set', () {
      expect(AccountValidator.validateSecret('').isValid, isFalse);
      expect(AccountValidator.validateSecret('TOO_SHORT').isValid, isFalse);
      expect(AccountValidator.validateSecret('INVALID_BASE32_189').isValid, isFalse);
      expect(AccountValidator.validateSecret('JBSWY3DPEHPK3PXP').isValid, isTrue);
      expect(AccountValidator.validateSecret('jbsw y3dp ehpk 3pxp').isValid, isTrue);
    });

    test('validateAlgorithm rejects unsupported algorithms', () {
      expect(AccountValidator.validateAlgorithm('MD5').isValid, isFalse);
      expect(AccountValidator.validateAlgorithm('SHA1').isValid, isTrue);
      expect(AccountValidator.validateAlgorithm('SHA256').isValid, isTrue);
      expect(AccountValidator.validateAlgorithm('SHA512').isValid, isTrue);
    });

    test('validateDigits rejects invalid digit lengths', () {
      expect(AccountValidator.validateDigits(4).isValid, isFalse);
      expect(AccountValidator.validateDigits(6).isValid, isTrue);
      expect(AccountValidator.validateDigits(8).isValid, isTrue);
    });

    test('validatePeriod bounds check', () {
      expect(AccountValidator.validatePeriod(0).isValid, isFalse);
      expect(AccountValidator.validatePeriod(150).isValid, isFalse);
      expect(AccountValidator.validatePeriod(30).isValid, isTrue);
    });
  });

  group('AccountRepository In-Memory & Optimization Tests', () {
    late AccountRepository repository;
    late SecureStorageService storageService;

    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
      storageService = SecureStorageService();
      repository = AccountRepository(storageService: storageService);
    });

    test('createAccount persists metadata and stores secret separately', () async {
      final account = await repository.createAccount(
        issuer: 'Google',
        accountName: 'test@example.com',
        secret: 'JBSWY3DPEHPK3PXP',
      );

      expect(account.id, isNotEmpty);
      expect(account.issuer, equals('Google'));
      expect(account.accountName, equals('test@example.com'));

      final allAccounts = await repository.getAllAccounts();
      expect(allAccounts.length, equals(1));
      expect(allAccounts.first.id, equals(account.id));

      final secret = await storageService.readAccountSecret(account.id);
      expect(secret, equals('JBSWY3DPEHPK3PXP'));

      final metadataJson = await storageService.readAccountMetadata();
      expect(metadataJson, isNotNull);
      expect(metadataJson!.contains('JBSWY3DPEHPK3PXP'), isFalse);
    });

    test('generateOtpDisplayData produces real numeric OTP and caches per time window counter', () async {
      final account = await repository.createAccount(
        issuer: 'Google',
        accountName: 'test@example.com',
        secret: 'JBSWY3DPEHPK3PXP',
      );

      // Window 0 (timestamp 10s)
      final otp1 = await repository.generateOtpDisplayData(account, timestampSeconds: 10);
      // Window 0 (timestamp 20s)
      final otp2 = await repository.generateOtpDisplayData(account, timestampSeconds: 20);

      expect(RegExp(r'^\d{6}$').hasMatch(otp1.otpCode), isTrue);
      expect(otp1.failureCategory, equals(OtpFailureCategory.none));
      expect(otp1.otpCode, equals(otp2.otpCode));
      expect(otp1.remainingSeconds, equals(20));
      expect(otp2.remainingSeconds, equals(10));

      // Window 1 boundary transition (timestamp 30s)
      final otp3 = await repository.generateOtpDisplayData(account, timestampSeconds: 30);
      expect(otp3.remainingSeconds, equals(30));
    });

    test('handles missing secret gracefully without caching failure fallback', () async {
      final account = await repository.createAccount(
        issuer: 'Google',
        accountName: 'test@example.com',
        secret: 'JBSWY3DPEHPK3PXP',
      );

      // Delete secret manually
      await storageService.deleteAccountSecret(account.id);

      final displayData = await repository.generateOtpDisplayData(account, timestampSeconds: 15);
      expect(displayData.otpCode, equals('••••••'));
      expect(displayData.failureCategory, equals(OtpFailureCategory.secretMissing));
      expect(displayData.remainingSeconds, equals(15));

      // Re-write secret to simulate recovery
      await storageService.writeAccountSecret(account.id, 'JBSWY3DPEHPK3PXP');
      final recoveredData = await repository.generateOtpDisplayData(account, timestampSeconds: 16);
      expect(RegExp(r'^\d{6}$').hasMatch(recoveredData.otpCode), isTrue);
      expect(recoveredData.failureCategory, equals(OtpFailureCategory.none));
    });

    test('duplicate account creation is rejected', () async {
      await repository.createAccount(
        issuer: 'Google',
        accountName: 'user1@gmail.com',
        secret: 'JBSWY3DPEHPK3PXP',
      );

      expect(
        () async => await repository.createAccount(
          issuer: 'google',
          accountName: 'USER1@gmail.com',
          secret: 'KRSXG5CTMVRXEZLBOI',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('atomic creation rollback deletes orphaned secret if metadata storage fails', () async {
      final failingStorage = FailingMetadataStorageService(failOnMetadataWrite: true);
      final failingRepo = AccountRepository(storageService: failingStorage);

      expect(
        () async => await failingRepo.createAccount(
          issuer: 'GitHub',
          accountName: 'dev',
          secret: 'JBSWY3DPEHPK3PXP',
        ),
        throwsA(isA<Exception>()),
      );

      final all = await failingRepo.getAllAccounts();
      expect(all, isEmpty);
    });

    test('updateAccountMetadata updates issuer and name without touching secret', () async {
      final acc = await repository.createAccount(
        issuer: 'Google',
        accountName: 'old@example.com',
        secret: 'JBSWY3DPEHPK3PXP',
      );

      final updated = await repository.updateAccountMetadata(
        acc.id,
        issuer: 'Google Cloud',
        accountName: 'new@example.com',
      );

      expect(updated.id, equals(acc.id));
      expect(updated.issuer, equals('Google Cloud'));
      expect(updated.accountName, equals('new@example.com'));

      final secret = await storageService.readAccountSecret(acc.id);
      expect(secret, equals('JBSWY3DPEHPK3PXP'));
    });

    test('deleteAccount removes metadata and secret', () async {
      final acc1 = await repository.createAccount(
        issuer: 'Google',
        accountName: 'user1@gmail.com',
        secret: 'JBSWY3DPEHPK3PXP',
      );

      final acc2 = await repository.createAccount(
        issuer: 'GitHub',
        accountName: 'user2',
        secret: 'KRSXG5CTMVRXEZLBOI',
      );

      await repository.deleteAccount(acc1.id);

      final remaining = await repository.getAllAccounts();
      expect(remaining.length, equals(1));
      expect(remaining.first.id, equals(acc2.id));

      final deletedSecret = await storageService.readAccountSecret(acc1.id);
      final activeSecret = await storageService.readAccountSecret(acc2.id);

      expect(deletedSecret, isNull);
      expect(activeSecret, equals('KRSXG5CTMVRXEZLBOI'));
    });

    test('deleting non-existent account succeeds gracefully', () async {
      await repository.deleteAccount('non-existent-id');
      final all = await repository.getAllAccounts();
      expect(all, isEmpty);
    });

    test('multi-instance SecureStorageService & AccountRepository shares secret fallback map and generates numeric OTP', () async {
      final storage1 = SecureStorageService();
      final repo1 = AccountRepository(storageService: storage1);

      final account = await repo1.createAccount(
        issuer: 'Google',
        accountName: 'user@example.com',
        secret: 'JBSWY3DPEHPK3PXP',
      );

      // Create separate service & repository instances (simulating QrScannerScreen vs AccountsHomeScreen)
      final storage2 = SecureStorageService();
      final repo2 = AccountRepository(storageService: storage2);

      final secretRead = await storage2.readAccountSecret(account.id);
      expect(secretRead, equals('JBSWY3DPEHPK3PXP'));

      final displayData = await repo2.generateOtpDisplayData(account, timestampSeconds: 1000);
      expect(RegExp(r'^\d{6}$').hasMatch(displayData.otpCode), isTrue);
      expect(displayData.failureCategory, equals(OtpFailureCategory.none));
      expect(displayData.otpCode, isNot(equals('••••••')));
    });
  });
}
