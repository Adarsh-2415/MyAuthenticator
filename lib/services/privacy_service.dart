import 'package:flutter/material.dart';
import '../ui/tokens/app_colors.dart';

/// Service and widget overlay wrapper providing iOS/Android app switcher privacy protection.
class PrivacyService extends StatelessWidget {
  final Widget child;
  final bool isPrivacyActive;

  const PrivacyService({
    super.key,
    required this.child,
    required this.isPrivacyActive,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Stack(
      children: [
        child,
        if (isPrivacyActive)
          Positioned.fill(
            child: Material(
              color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
              child: SafeArea(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.shield,
                        size: 64.0,
                        color: AppColors.blueAccent,
                      ),
                      const SizedBox(height: 16.0),
                      Text(
                        'MyAuthenticator',
                        style: theme.textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        'Protected',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
