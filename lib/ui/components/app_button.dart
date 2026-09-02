import 'package:flutter/material.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_dimensions.dart';
import '../tokens/app_radius.dart';

enum AppButtonVariant { primary, secondary, destructive }

/// Standardized app button component following design system rules.
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color bg;
    Color fg;
    BorderSide border = BorderSide.none;

    switch (variant) {
      case AppButtonVariant.primary:
        bg = AppColors.blueAccent;
        fg = Colors.white;
        break;
      case AppButtonVariant.secondary:
        bg = isDark ? AppColors.darkSecondarySurface : AppColors.lightSecondarySurface;
        fg = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
        border = BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder);
        break;
      case AppButtonVariant.destructive:
        bg = AppColors.error.withValues(alpha: 0.12);
        fg = AppColors.error;
        border = BorderSide(color: AppColors.error.withValues(alpha: 0.3));
        break;
    }

    final buttonChild = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 20.0, color: fg),
          const SizedBox(width: 8.0),
        ],
        Text(
          label,
          style: TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.w600,
            color: fg,
          ),
        ),
      ],
    );

    return SizedBox(
      height: AppDimensions.buttonHeight,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.mediumBorder,
            side: border,
          ),
          minimumSize: const Size.fromHeight(AppDimensions.minTouchTarget),
        ),
        onPressed: onPressed,
        child: buttonChild,
      ),
    );
  }
}
