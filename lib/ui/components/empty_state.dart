import 'package:flutter/material.dart';
import '../tokens/app_spacing.dart';
import 'app_button.dart';

/// Clean illustration-free empty view for first-time onboarding.
class EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onActionPressed;
  final IconData icon;

  const EmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onActionPressed,
    this.icon = Icons.shield_outlined,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64.0,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: AppSpacing.xl20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.sm8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.xxxl32),
            AppButton(
              label: actionLabel,
              onPressed: onActionPressed,
              icon: Icons.add,
            ),
          ],
        ),
      ),
    );
  }
}
