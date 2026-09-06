/// Categories for safe internal error diagnosis when OTP generation cannot complete.
/// Excludes all sensitive payload data (secrets, URIs, user identities).
enum OtpFailureCategory {
  none,
  secretMissing,
  storageReadError,
  secretInvalid,
  base32DecodeError,
  invalidDecodedSecret,
  invalidAlgorithm,
  invalidPeriod,
  counterError,
  hmacGenerationError,
  dynamicTruncationError,
  otpFormattingError,
  totpEngineError,
}

/// Data model representing OTP display state for the UI layer.
/// Raw secrets are strictly excluded from this model.
class OtpDisplayData {
  final String accountId;
  final String otpCode;
  final int remainingSeconds;
  final int period;
  final double progress;
  final OtpFailureCategory failureCategory;

  const OtpDisplayData({
    required this.accountId,
    required this.otpCode,
    required this.remainingSeconds,
    this.period = 30,
    required this.progress,
    this.failureCategory = OtpFailureCategory.none,
  });
}
