import 'package:flutter/material.dart';
import '../../core/utils/otpauth_uri_parser.dart';
import '../../ui/components/app_button.dart';
import '../../ui/tokens/app_colors.dart';
import '../../ui/tokens/app_radius.dart';
import '../../ui/tokens/app_spacing.dart';

/// Modal dialog presented after scanning a valid QR code to confirm account addition.
/// Displays non-sensitive metadata only; raw secret is never shown.
class QrConfirmationDialog extends StatelessWidget {
  final ParsedOtpAuthData parsedData;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const QrConfirmationDialog({
    super.key,
    required this.parsedData,
    required this.onConfirm,
    required this.onCancel,
  });

  static Future<bool?> show(
    BuildContext context, {
    required ParsedOtpAuthData parsedData,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => QrConfirmationDialog(
        parsedData: parsedData,
        onConfirm: () => Navigator.of(context).pop(true),
        onCancel: () => Navigator.of(context).pop(false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkSecondarySurface : AppColors.lightSecondarySurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: AppRadius.cardBorder),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm8),
            decoration: BoxDecoration(
              color: AppColors.blueAccent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: const Icon(Icons.qr_code_2, color: AppColors.blueAccent),
          ),
          const SizedBox(width: AppSpacing.md12),
          Expanded(
            child: Text(
              'Add Authenticator Account',
              style: theme.textTheme.titleLarge,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Confirm adding this authenticator account to MyAuthenticator:',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.lg16),
          Material(
            color: cardBg,
            shape: RoundedRectangleBorder(
              borderRadius: AppRadius.mediumBorder,
              side: BorderSide(color: borderColor, width: 1.0),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md12),
              child: Column(
                children: [
                  _MetaRow(label: 'Service / Issuer', value: parsedData.issuer),
                  const Divider(height: 12),
                  _MetaRow(label: 'Account Name', value: parsedData.accountName),
                  const Divider(height: 12),
                  _MetaRow(label: 'Algorithm', value: parsedData.algorithm),
                  const Divider(height: 12),
                  _MetaRow(label: 'Digits', value: '${parsedData.digits} Digits'),
                  const Divider(height: 12),
                  _MetaRow(label: 'Time Period', value: '${parsedData.period} Seconds'),
                ],
              ),
            ),
          ),
        ],
      ),
      actionsPadding: const EdgeInsets.all(AppSpacing.lg16),
      actions: [
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: 'Cancel',
                variant: AppButtonVariant.secondary,
                onPressed: onCancel,
              ),
            ),
            const SizedBox(width: AppSpacing.md12),
            Expanded(
              child: AppButton(
                label: 'Add Account',
                onPressed: onConfirm,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MetaRow extends StatelessWidget {
  final String label;
  final String value;

  const _MetaRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: theme.textTheme.bodyMedium),
        const SizedBox(width: AppSpacing.sm8),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
