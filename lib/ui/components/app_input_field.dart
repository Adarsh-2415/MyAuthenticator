import 'package:flutter/material.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_dimensions.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';

/// Standardized form text input field for MyAuthenticator.
class AppInputField extends StatelessWidget {
  final String label;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType keyboardType;
  final bool enabled;

  const AppInputField({
    super.key,
    required this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.controller,
    this.onChanged,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType = TextInputType.text,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final fillBg = isDark ? AppColors.darkSecondarySurface : AppColors.lightSecondarySurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: theme.textTheme.labelLarge,
        ),
        const SizedBox(height: AppSpacing.sm8),
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppDimensions.inputHeight),
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            obscureText: obscureText,
            keyboardType: keyboardType,
            enabled: enabled,
            style: theme.textTheme.bodyLarge,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: theme.textTheme.bodyMedium,
              helperText: helperText,
              errorText: errorText,
              filled: true,
              fillColor: fillBg,
              suffixIcon: suffixIcon,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg16,
                vertical: AppSpacing.md12,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppRadius.mediumBorder,
                borderSide: BorderSide(color: borderColor, width: 1.0),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: AppRadius.mediumBorder,
                borderSide: BorderSide(color: AppColors.blueAccent, width: 1.5),
              ),
              errorBorder: const OutlineInputBorder(
                borderRadius: AppRadius.mediumBorder,
                borderSide: BorderSide(color: AppColors.error, width: 1.0),
              ),
              focusedErrorBorder: const OutlineInputBorder(
                borderRadius: AppRadius.mediumBorder,
                borderSide: BorderSide(color: AppColors.error, width: 1.5),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
