import 'package:flutter/material.dart';
import '../tokens/app_spacing.dart';

/// Section header for settings and configuration grouping.
class SectionHeader extends StatelessWidget {
  final String title;

  const SectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.lg16,
        right: AppSpacing.lg16,
        top: AppSpacing.xl20,
        bottom: AppSpacing.sm8,
      ),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.labelLarge?.copyWith(
          fontSize: 12.0,
          letterSpacing: 1.0,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

/// Standardized settings list tile component.
class SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, size: 22.0),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: trailing,
      onTap: onTap,
    );
  }
}
