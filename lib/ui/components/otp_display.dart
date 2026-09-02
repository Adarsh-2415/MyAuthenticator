import 'package:flutter/material.dart';
import '../../core/theme/app_typography.dart';

/// High-contrast OTP display text widget with tabular figures to prevent layout jitter.
class OtpDisplay extends StatelessWidget {
  final String rawOtp;
  final double? fontSize;
  final Color? color;

  const OtpDisplay({
    super.key,
    required this.rawOtp,
    this.fontSize,
    this.color,
  });

  /// Formats raw string e.g. "482931" -> "482 931" or "48293819" -> "4829 3819"
  static String formatOtp(String raw) {
    final clean = raw.replaceAll(' ', '');
    if (clean.length == 6) {
      return '${clean.substring(0, 3)} ${clean.substring(3)}';
    } else if (clean.length == 8) {
      return '${clean.substring(0, 4)} ${clean.substring(4)}';
    }
    return clean;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final formatted = formatOtp(rawOtp);
    final baseStyle = AppTypography.otpStyle(isDark: isDark);

    return Text(
      formatted,
      style: baseStyle.copyWith(
        fontSize: fontSize ?? baseStyle.fontSize,
        color: color ?? baseStyle.color,
      ),
    );
  }
}
