/// Global application constants and configuration defaults.
abstract class AppConstants {
  static const String appName = 'MyAuthenticator';
  static const String appVersion = '1.0.0';

  // Validation Limits
  static const int maxQrDataLength = 2048;
  static const int defaultPeriodSeconds = 30;
  static const List<int> supportedDigits = [6, 8];
  static const List<int> supportedPeriods = [30, 60];
  static const List<String> supportedAlgorithms = ['SHA1', 'SHA256', 'SHA512'];

  // Security Limits
  static const int maxAccountNameLength = 128;
  static const int maxIssuerLength = 128;
}
