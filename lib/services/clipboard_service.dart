import 'dart:async';
import 'package:flutter/services.dart';

/// Service abstraction for user-initiated OTP copy actions and automatic clipboard clearing.
class ClipboardService {
  static String? _lastCopiedOtp;
  static Timer? _autoClearTimer;

  /// Copies generated OTP code to system clipboard and schedules 30-second auto-clear.
  /// Base32 secrets and storage keys are strictly prohibited.
  static Future<void> copyOtp(
    String code, {
    bool autoClearEnabled = true,
    int clearDelaySeconds = 30,
  }) async {
    final cleanCode = code.replaceAll(' ', '').trim();
    if (cleanCode.isEmpty) return;

    await Clipboard.setData(ClipboardData(text: cleanCode));
    _lastCopiedOtp = cleanCode;

    // Reset previous auto-clear timer if active
    _autoClearTimer?.cancel();

    if (autoClearEnabled) {
      _autoClearTimer = Timer(Duration(seconds: clearDelaySeconds), () async {
        await _clearIfUnchanged(cleanCode);
      });
    }
  }

  /// Clears clipboard ONLY if the system clipboard still contains the exact OTP code copied by MyAuthenticator.
  static Future<void> _clearIfUnchanged(String expectedOtp) async {
    try {
      if (_lastCopiedOtp != expectedOtp) return;
      final currentData = await Clipboard.getData(Clipboard.kTextPlain);
      if (currentData?.text == expectedOtp) {
        await Clipboard.setData(const ClipboardData(text: ''));
        _lastCopiedOtp = null;
      }
    } catch (_) {}
  }

  /// Cancels active auto-clear timer (used in tests or service cleanup).
  static void cancelAutoClearTimer() {
    _autoClearTimer?.cancel();
    _autoClearTimer = null;
    _lastCopiedOtp = null;
  }
}
