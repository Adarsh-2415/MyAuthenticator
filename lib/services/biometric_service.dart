import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

/// Result type representing the status of hardware/OS credential authentication.
enum BiometricAuthResult {
  success,
  cancelled,
  failed,
  notAvailable,
}

/// Service abstraction for hardware biometric & OS device credential authentication using local_auth.
class BiometricService {
  final LocalAuthentication _auth;
  bool _isAuthenticating = false;

  BiometricService({LocalAuthentication? auth})
      : _auth = auth ?? LocalAuthentication();

  /// Indicates whether an authentication prompt is currently active.
  bool get isAuthenticating => _isAuthenticating;

  /// Checks if hardware biometrics or device passcode authentication is available.
  Future<bool> isDeviceSupported() async {
    if (kIsWeb) return true;
    try {
      final bool canCheckBiometrics = await _auth.canCheckBiometrics;
      final bool isDeviceSupported = await _auth.isDeviceSupported();
      return canCheckBiometrics || isDeviceSupported;
    } catch (_) {
      return false;
    }
  }

  /// Triggers OS local authentication (Hardware biometrics + Native Device Credential fallback).
  /// Includes concurrency lock to prevent simultaneous duplicate prompt launches.
  Future<BiometricAuthResult> authenticate({
    String reason = 'Authenticate to access MyAuthenticator',
  }) async {
    if (kIsWeb) {
      return BiometricAuthResult.success;
    }

    if (_isAuthenticating) {
      return BiometricAuthResult.cancelled;
    }

    _isAuthenticating = true;
    try {
      final isSupported = await isDeviceSupported();
      if (!isSupported) {
        return BiometricAuthResult.notAvailable;
      }

      final authenticated = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: false, // Allows hardware biometrics AND OS device credential fallback
          useErrorDialogs: true,
          stickyAuth: true,
        ),
      );

      return authenticated
          ? BiometricAuthResult.success
          : BiometricAuthResult.failed;
    } on PlatformException catch (e) {
      if (e.code == 'NotAvailable' || e.code == 'NotEnrolled') {
        return BiometricAuthResult.notAvailable;
      }
      if (e.code == 'UserCanceled' || e.code == 'SystemCanceled') {
        return BiometricAuthResult.cancelled;
      }
      return BiometricAuthResult.failed;
    } catch (_) {
      return BiometricAuthResult.failed;
    } finally {
      _isAuthenticating = false;
    }
  }
}
