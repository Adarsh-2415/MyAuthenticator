import 'package:flutter/material.dart';
import '../../services/biometric_service.dart';
import '../../ui/components/app_button.dart';
import '../../ui/tokens/app_colors.dart';
import '../../ui/tokens/app_spacing.dart';

/// Screen 1 — App Lock Screen (Phase 6 Hardware Biometric & OS Credential Lock).
class AppLockScreen extends StatefulWidget {
  final BiometricService? biometricService;
  final VoidCallback onUnlockSuccess;

  const AppLockScreen({
    super.key,
    this.biometricService,
    required this.onUnlockSuccess,
  });

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  late final BiometricService _biometricService;
  bool _isAuthenticating = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _biometricService = widget.biometricService ?? BiometricService();
  }

  Future<void> _triggerAuthentication() async {
    if (_isAuthenticating) return;

    setState(() {
      _isAuthenticating = true;
      _errorMessage = null;
    });

    final result = await _biometricService.authenticate(
      reason: 'Unlock MyAuthenticator to access your 2FA accounts',
    );

    if (!mounted) return;

    setState(() {
      _isAuthenticating = false;
    });

    switch (result) {
      case BiometricAuthResult.success:
        widget.onUnlockSuccess();
        break;
      case BiometricAuthResult.cancelled:
        setState(() {
          _errorMessage = 'Authentication cancelled.';
        });
        break;
      case BiometricAuthResult.failed:
        setState(() {
          _errorMessage = 'Authentication failed. Please try again.';
        });
        break;
      case BiometricAuthResult.notAvailable:
        _showDeviceSecurityNotConfiguredDialog();
        break;
    }
  }

  void _showDeviceSecurityNotConfiguredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Device Security Required'),
        content: const Text(
          'Device security is not configured. Please set up a screen lock, PIN, or biometric authentication in system settings to protect MyAuthenticator.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(AppSpacing.xxl24),
                decoration: BoxDecoration(
                  color: AppColors.blueAccent.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  size: 64.0,
                  color: AppColors.blueAccent,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl24),
              Text(
                'MyAuthenticator',
                style: theme.textTheme.headlineLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm8),
              Text(
                'Protected by Hardware & Device Security',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: AppSpacing.lg16),
                Text(
                  _errorMessage!,
                  style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.error),
                  textAlign: TextAlign.center,
                ),
              ],
              const Spacer(),
              if (_isAuthenticating)
                const CircularProgressIndicator()
              else ...[
                AppButton(
                  label: 'Unlock MyAuthenticator',
                  icon: Icons.fingerprint,
                  onPressed: _triggerAuthentication,
                ),
                const SizedBox(height: AppSpacing.md12),
                AppButton(
                  label: 'Use Device Passcode',
                  icon: Icons.pin_outlined,
                  variant: AppButtonVariant.secondary,
                  onPressed: _triggerAuthentication,
                ),
              ],
              const SizedBox(height: AppSpacing.xl20),
            ],
          ),
        ),
      ),
    );
  }
}
