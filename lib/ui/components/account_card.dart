import 'package:flutter/material.dart';
import '../../models/totp_account.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_dimensions.dart';
import '../tokens/app_spacing.dart';
import 'otp_display.dart';
import 'otp_progress_indicator.dart';

/// Reusable account card displaying service identity, mock OTP, progress indicator, and copy action.
class AccountCard extends StatelessWidget {
  final TotpAccount account;
  final String mockOtp;
  final int remainingSeconds;
  final VoidCallback onTap;
  final VoidCallback onCopy;

  const AccountCard({
    super.key,
    required this.account,
    required this.mockOtp,
    required this.remainingSeconds,
    required this.onTap,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cardBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      constraints: const BoxConstraints(minHeight: AppDimensions.cardMinHeight),
      margin: const EdgeInsets.only(bottom: AppSpacing.md12),
      child: Material(
        color: cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
          side: BorderSide(color: borderColor, width: 1.0),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.sm8),
                            decoration: BoxDecoration(
                              color: AppColors.blueAccent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: const Icon(
                              Icons.security,
                              size: 20.0,
                              color: AppColors.blueAccent,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  account.issuer,
                                  style: theme.textTheme.titleMedium,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  account.accountName,
                                  style: theme.textTheme.bodyMedium,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    OtpProgressIndicator(
                      remainingSeconds: remainingSeconds,
                      totalPeriod: account.period,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    OtpDisplay(rawOtp: mockOtp),
                    IconButton(
                      icon: const Icon(Icons.copy_outlined, size: 20.0),
                      onPressed: onCopy,
                      tooltip: 'Copy OTP Code',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
