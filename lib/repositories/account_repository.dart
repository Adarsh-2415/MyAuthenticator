import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../core/crypto/totp_engine.dart';
import '../core/utils/account_validator.dart';
import '../core/utils/base32_util.dart';
import '../models/otp_display_data.dart';
import '../models/totp_account.dart';
import '../services/secure_storage_service.dart';

class _OtpCacheEntry {
  final int timeWindowCounter;
  final String otpCode;

  const _OtpCacheEntry({
    required this.timeWindowCounter,
    required this.otpCode,
  });
}

/// Repository responsible for high-level account management, secure secret separation,
/// duplicate detection, rollback integrity, and optimized TOTP generation execution.
class AccountRepository {
  final SecureStorageService _storageService;
  final Uuid _uuid;

  // In-memory window cache mapping accountId -> current time window OTP code.
  // Invalidated automatically whenever time window changes or account is edited/deleted.
  final Map<String, _OtpCacheEntry> _otpWindowCache = {};

  AccountRepository({
    SecureStorageService? storageService,
    Uuid? uuid,
  })  : _storageService = storageService ?? SecureStorageService(),
        _uuid = uuid ?? const Uuid();

  /// Retrieves all persisted account metadata sorted by creation date (newest first).
  Future<List<TotpAccount>> getAllAccounts() async {
    try {
      final jsonString = await _storageService.readAccountMetadata();
      if (jsonString == null || jsonString.trim().isEmpty) {
        return const [];
      }
      final List<dynamic> jsonList = jsonDecode(jsonString) as List<dynamic>;
      final accounts = jsonList
          .map((item) => TotpAccount.fromJson(item as Map<String, dynamic>))
          .toList();
      accounts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return accounts;
    } catch (_) {
      // Safe fallback on corrupted storage read
      return const [];
    }
  }

  /// Retrieves a specific account's metadata by unique ID.
  Future<TotpAccount?> getAccountById(String id) async {
    final accounts = await getAllAccounts();
    try {
      return accounts.firstWhere((acc) => acc.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Generates a real-time [OtpDisplayData] object for a given [TotpAccount].
  /// Uses window-level caching so secure storage reads & HMAC calculations occur ONLY ONCE
  /// per TOTP time window (e.g. once every 30 seconds), providing ~97% performance optimization.
  Future<OtpDisplayData> generateOtpDisplayData(
    TotpAccount account, {
    int? timestampSeconds,
  }) async {
    final currentUnix = timestampSeconds ?? (DateTime.now().millisecondsSinceEpoch ~/ 1000);
    final period = account.period > 0 ? account.period : 30;

    final remainingSeconds = period - (currentUnix % period);
    final progress = remainingSeconds / period;
    final currentCounter = currentUnix ~/ period;

    // 1. Return cached OTP code if time window counter has not changed
    final cached = _otpWindowCache[account.id];
    if (cached != null && cached.timeWindowCounter == currentCounter) {
      return OtpDisplayData(
        accountId: account.id,
        otpCode: cached.otpCode,
        remainingSeconds: remainingSeconds,
        period: period,
        progress: progress,
      );
    }

    // 2. Window changed or first fetch: Read secret & generate new TOTP
    try {
      final secret = await _storageService.readAccountSecret(account.id);
      if (secret == null || secret.isEmpty) {
        return OtpDisplayData(
          accountId: account.id,
          otpCode: '••••••',
          remainingSeconds: remainingSeconds,
          period: period,
          progress: progress,
        );
      }

      final otpCode = TotpEngine.generateTotp(
        secret: secret,
        algorithm: account.algorithm,
        digits: account.digits,
        period: period,
        timestampSeconds: currentUnix,
      );

      // Store in window cache for current counter window
      _otpWindowCache[account.id] = _OtpCacheEntry(
        timeWindowCounter: currentCounter,
        otpCode: otpCode,
      );

      return OtpDisplayData(
        accountId: account.id,
        otpCode: otpCode,
        remainingSeconds: remainingSeconds,
        period: period,
        progress: progress,
      );
    } catch (_) {
      return OtpDisplayData(
        accountId: account.id,
        otpCode: '••••••',
        remainingSeconds: remainingSeconds,
        period: period,
        progress: progress,
      );
    }
  }

  /// Creates a new authenticator account configuration and securely stores its secret separately.
  Future<TotpAccount> createAccount({
    required String issuer,
    required String accountName,
    required String secret,
    String algorithm = 'SHA1',
    int digits = 6,
    int period = 30,
  }) async {
    // 1. Input Validation
    final issuerRes = AccountValidator.validateIssuer(issuer);
    if (!issuerRes.isValid) throw Exception(issuerRes.errorMessage);

    final nameRes = AccountValidator.validateAccountName(accountName);
    if (!nameRes.isValid) throw Exception(nameRes.errorMessage);

    final secretRes = AccountValidator.validateSecret(secret);
    if (!secretRes.isValid) throw Exception(secretRes.errorMessage);

    final algoRes = AccountValidator.validateAlgorithm(algorithm);
    if (!algoRes.isValid) throw Exception(algoRes.errorMessage);

    final digitsRes = AccountValidator.validateDigits(digits);
    if (!digitsRes.isValid) throw Exception(digitsRes.errorMessage);

    final periodRes = AccountValidator.validatePeriod(period);
    if (!periodRes.isValid) throw Exception(periodRes.errorMessage);

    final trimmedIssuer = issuer.trim();
    final trimmedName = accountName.trim();

    // 2. Duplicate Account Detection (Case-insensitive Issuer + Account Name)
    final currentAccounts = await getAllAccounts();
    final isDuplicate = currentAccounts.any((acc) =>
        acc.issuer.toLowerCase() == trimmedIssuer.toLowerCase() &&
        acc.accountName.toLowerCase() == trimmedName.toLowerCase());

    if (isDuplicate) {
      throw Exception('An account for "$trimmedIssuer" ($trimmedName) already exists.');
    }

    // 3. Normalize Secret & Generate Unique ID
    final normalizedSecret = Base32Util.normalize(secret);
    final newId = _uuid.v4();
    final now = DateTime.now();

    // 4. Create Metadata Model
    final newAccount = TotpAccount(
      id: newId,
      issuer: trimmedIssuer,
      accountName: trimmedName,
      algorithm: algorithm.toUpperCase(),
      digits: digits,
      period: period,
      createdAt: now,
      updatedAt: now,
    );

    // 5. Atomic Storage Strategy with Rollback
    await _storageService.writeAccountSecret(newId, normalizedSecret);

    try {
      final updatedList = [newAccount, ...currentAccounts];
      final jsonString = jsonEncode(updatedList.map((a) => a.toJson()).toList());
      await _storageService.writeAccountMetadata(jsonString);
    } catch (e) {
      await _storageService.deleteAccountSecret(newId);
      throw Exception('Unable to save account metadata. Creation rolled back.');
    }

    return newAccount;
  }

  /// Updates non-sensitive metadata (Issuer and Account Name) for an existing account.
  Future<TotpAccount> updateAccountMetadata(
    String id, {
    required String issuer,
    required String accountName,
  }) async {
    final issuerRes = AccountValidator.validateIssuer(issuer);
    if (!issuerRes.isValid) throw Exception(issuerRes.errorMessage);

    final nameRes = AccountValidator.validateAccountName(accountName);
    if (!nameRes.isValid) throw Exception(nameRes.errorMessage);

    final trimmedIssuer = issuer.trim();
    final trimmedName = accountName.trim();

    final accounts = await getAllAccounts();
    final index = accounts.indexWhere((acc) => acc.id == id);
    if (index == -1) {
      throw Exception('Account not found');
    }

    final isDuplicate = accounts.any((acc) =>
        acc.id != id &&
        acc.issuer.toLowerCase() == trimmedIssuer.toLowerCase() &&
        acc.accountName.toLowerCase() == trimmedName.toLowerCase());

    if (isDuplicate) {
      throw Exception('Another account for "$trimmedIssuer" ($trimmedName) already exists.');
    }

    final existing = accounts[index];
    final updatedAccount = existing.copyWith(
      issuer: trimmedIssuer,
      accountName: trimmedName,
      updatedAt: DateTime.now(),
    );

    accounts[index] = updatedAccount;
    final jsonString = jsonEncode(accounts.map((a) => a.toJson()).toList());
    await _storageService.writeAccountMetadata(jsonString);

    // Invalidate window cache for this account
    _otpWindowCache.remove(id);

    return updatedAccount;
  }

  /// Safely deletes an account and its associated secret with consistency checks.
  Future<void> deleteAccount(String id) async {
    final existing = await getAccountById(id);
    if (existing == null) return;

    try {
      await _storageService.deleteAccountSecret(id);
    } catch (_) {}

    final accounts = await getAllAccounts();
    final updatedList = accounts.where((acc) => acc.id != id).toList();
    final jsonString = jsonEncode(updatedList.map((a) => a.toJson()).toList());
    await _storageService.writeAccountMetadata(jsonString);

    // Invalidate window cache for deleted account
    _otpWindowCache.remove(id);
  }
}
