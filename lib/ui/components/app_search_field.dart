import 'package:flutter/material.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';

/// Reusable search bar input widget for accounts filtering.
class AppSearchField extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;

  const AppSearchField({
    super.key,
    this.controller,
    this.onChanged,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final fillBg = isDark ? AppColors.darkSecondarySurface : AppColors.lightSecondarySurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: theme.textTheme.bodyLarge,
      decoration: InputDecoration(
        hintText: 'Search accounts or issuers...',
        hintStyle: theme.textTheme.bodyMedium,
        prefixIcon: const Icon(Icons.search, size: 20.0),
        suffixIcon: controller != null && controller!.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, size: 18.0),
                onPressed: () {
                  controller!.clear();
                  if (onClear != null) onClear!();
                },
              )
            : null,
        filled: true,
        fillColor: fillBg,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg16,
          vertical: AppSpacing.sm8,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.mediumBorder,
          borderSide: BorderSide(color: borderColor, width: 1.0),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: AppRadius.mediumBorder,
          borderSide: BorderSide(color: AppColors.blueAccent, width: 1.5),
        ),
      ),
    );
  }
}
