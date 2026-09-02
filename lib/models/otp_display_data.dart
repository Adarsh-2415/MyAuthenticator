/// Data model representing OTP display state for the UI layer.
/// Raw secrets are strictly excluded from this model.
class OtpDisplayData {
  final String accountId;
  final String otpCode;
  final int remainingSeconds;
  final int period;
  final double progress;

  const OtpDisplayData({
    required this.accountId,
    required this.otpCode,
    required this.remainingSeconds,
    this.period = 30,
    required this.progress,
  });
}
