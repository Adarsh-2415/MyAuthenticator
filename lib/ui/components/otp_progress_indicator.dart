import 'package:flutter/material.dart';
import '../tokens/app_colors.dart';

/// Smooth countdown progress ring indicating remaining time in current period.
class OtpProgressIndicator extends StatelessWidget {
  final int remainingSeconds;
  final int totalPeriod;
  final double size;

  const OtpProgressIndicator({
    super.key,
    required this.remainingSeconds,
    this.totalPeriod = 30,
    this.size = 28.0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = (remainingSeconds / totalPeriod).clamp(0.0, 1.0);

    // Color shift: Primary blue normally, shifts to Warning when < 5 seconds remain
    final activeColor = remainingSeconds <= 5 ? AppColors.warning : AppColors.blueAccent;
    final trackColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 3.0,
            valueColor: AlwaysStoppedAnimation<Color>(activeColor),
            backgroundColor: trackColor,
          ),
          Text(
            '$remainingSeconds',
            style: TextStyle(
              fontSize: size * 0.42,
              fontWeight: FontWeight.bold,
              color: activeColor,
            ),
          ),
        ],
      ),
    );
  }
}
