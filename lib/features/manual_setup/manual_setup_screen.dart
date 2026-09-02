import 'package:flutter/material.dart';
import '../../repositories/account_repository.dart';
import '../../ui/components/app_button.dart';
import '../../ui/components/app_input_field.dart';
import '../../ui/tokens/app_colors.dart';
import '../../ui/tokens/app_radius.dart';
import '../../ui/tokens/app_spacing.dart';

/// Screen 5 — Manual Setup Screen (Phase 3 Real Account Creation & Persistence).
class ManualSetupScreen extends StatefulWidget {
  final AccountRepository accountRepository;

  const ManualSetupScreen({
    super.key,
    required this.accountRepository,
  });

  @override
  State<ManualSetupScreen> createState() => _ManualSetupScreenState();
}

class _ManualSetupScreenState extends State<ManualSetupScreen> {
  final _issuerController = TextEditingController();
  final _accountController = TextEditingController();
  final _secretController = TextEditingController();

  bool _isSaving = false;
  bool _isAdvancedExpanded = false;
  String _selectedAlgorithm = 'SHA1';
  int _selectedDigits = 6;
  int _selectedPeriod = 30;

  String? _issuerError;
  String? _accountError;
  String? _secretError;

  @override
  void dispose() {
    _issuerController.dispose();
    _accountController.dispose();
    _secretController.dispose();
    super.dispose();
  }

  Future<void> _onSavePressed() async {
    setState(() {
      _issuerError = null;
      _accountError = null;
      _secretError = null;
    });

    final issuer = _issuerController.text;
    final accountName = _accountController.text;
    final secret = _secretController.text;

    if (issuer.trim().isEmpty) {
      setState(() => _issuerError = 'Issuer / Service name is required.');
      return;
    }
    if (accountName.trim().isEmpty) {
      setState(() => _accountError = 'Account name or email is required.');
      return;
    }
    if (secret.trim().isEmpty) {
      setState(() => _secretError = 'Secret key is required.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final createdAccount = await widget.accountRepository.createAccount(
        issuer: issuer,
        accountName: accountName,
        secret: secret,
        algorithm: _selectedAlgorithm,
        digits: _selectedDigits,
        period: _selectedPeriod,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved "${createdAccount.issuer}" account successfully.'),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        // Show safe error message without exposing secrets
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final tileBg = isDark ? AppColors.darkSecondarySurface : AppColors.lightSecondarySurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Enter Setup Key'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xxl24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppInputField(
                label: 'Service / Issuer Name',
                hint: 'e.g. Google, GitHub, AWS',
                controller: _issuerController,
                errorText: _issuerError,
                enabled: !_isSaving,
              ),
              const SizedBox(height: AppSpacing.lg16),
              AppInputField(
                label: 'Account Name or Email',
                hint: 'e.g. alex.developer@example.com',
                controller: _accountController,
                errorText: _accountError,
                enabled: !_isSaving,
              ),
              const SizedBox(height: AppSpacing.lg16),
              AppInputField(
                label: 'Secret Key (Base32)',
                hint: 'e.g. JBSWY3DPEHPK3PXP',
                controller: _secretController,
                errorText: _secretError,
                enabled: !_isSaving,
              ),
              const SizedBox(height: AppSpacing.xxl24),

              // Expandable Advanced Options
              Material(
                color: tileBg,
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.mediumBorder,
                  side: BorderSide(color: borderColor, width: 1.0),
                ),
                child: ExpansionTile(
                  title: Text('Advanced Settings', style: theme.textTheme.titleMedium),
                  subtitle: Text(
                    '$_selectedAlgorithm • $_selectedDigits Digits • ${_selectedPeriod}s Period',
                    style: theme.textTheme.bodyMedium,
                  ),
                  initiallyExpanded: _isAdvancedExpanded,
                  onExpansionChanged: (expanded) {
                    setState(() {
                      _isAdvancedExpanded = expanded;
                    });
                  },
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Algorithm', style: theme.textTheme.bodyLarge),
                              DropdownButton<String>(
                                value: _selectedAlgorithm,
                                items: const [
                                  DropdownMenuItem(value: 'SHA1', child: Text('SHA1 (Default)')),
                                  DropdownMenuItem(value: 'SHA256', child: Text('SHA256')),
                                  DropdownMenuItem(value: 'SHA512', child: Text('SHA512')),
                                ],
                                onChanged: _isSaving
                                    ? null
                                    : (val) {
                                        if (val != null) setState(() => _selectedAlgorithm = val);
                                      },
                              ),
                            ],
                          ),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Digits', style: theme.textTheme.bodyLarge),
                              DropdownButton<int>(
                                value: _selectedDigits,
                                items: const [
                                  DropdownMenuItem(value: 6, child: Text('6 Digits')),
                                  DropdownMenuItem(value: 8, child: Text('8 Digits')),
                                ],
                                onChanged: _isSaving
                                    ? null
                                    : (val) {
                                        if (val != null) setState(() => _selectedDigits = val);
                                      },
                              ),
                            ],
                          ),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Time Period', style: theme.textTheme.bodyLarge),
                              DropdownButton<int>(
                                value: _selectedPeriod,
                                items: const [
                                  DropdownMenuItem(value: 30, child: Text('30 Seconds')),
                                  DropdownMenuItem(value: 60, child: Text('60 Seconds')),
                                ],
                                onChanged: _isSaving
                                    ? null
                                    : (val) {
                                        if (val != null) setState(() => _selectedPeriod = val);
                                      },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xxxl32),

              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Cancel',
                      variant: AppButtonVariant.secondary,
                      onPressed: _isSaving ? null : () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md12),
                  Expanded(
                    child: AppButton(
                      label: _isSaving ? 'Saving...' : 'Save Account',
                      onPressed: _isSaving ? null : _onSavePressed,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
