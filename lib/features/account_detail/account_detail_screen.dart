import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/otp_display_data.dart';
import '../../models/totp_account.dart';
import '../../repositories/account_repository.dart';
import '../../services/clipboard_service.dart';
import '../../services/otp_time_service.dart';
import '../../ui/components/app_button.dart';
import '../../ui/components/app_input_field.dart';
import '../../ui/components/confirmation_dialog.dart';
import '../../ui/components/otp_display.dart';
import '../../ui/components/otp_progress_indicator.dart';
import '../../ui/tokens/app_colors.dart';
import '../../ui/tokens/app_radius.dart';
import '../../ui/tokens/app_spacing.dart';

/// Screen 6 — Account Details Screen (Phase 5 Real-Time Synchronized TOTP Display).
class AccountDetailScreen extends StatefulWidget {
  final String accountId;
  final AccountRepository accountRepository;

  const AccountDetailScreen({
    super.key,
    required this.accountId,
    required this.accountRepository,
  });

  @override
  State<AccountDetailScreen> createState() => _AccountDetailScreenState();
}

class _AccountDetailScreenState extends State<AccountDetailScreen> {
  bool _isLoading = true;
  TotpAccount? _account;
  OtpDisplayData? _otpDisplayData;
  StreamSubscription<int>? _tickerSubscription;

  @override
  void initState() {
    super.initState();
    OtpTimeService().ensureLifecycleObserver();
    _loadAccount();
    _subscribeToTicker();
  }

  void _subscribeToTicker() {
    _tickerSubscription = OtpTimeService().timestampStream.listen((timestampSeconds) {
      if (_account != null) {
        _recalculateOtp(timestampSeconds: timestampSeconds);
      }
    });
  }

  @override
  void dispose() {
    _tickerSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadAccount() async {
    setState(() => _isLoading = true);
    final loaded = await widget.accountRepository.getAccountById(widget.accountId);
    if (mounted) {
      _account = loaded;
      if (_account != null) {
        await _recalculateOtp();
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _recalculateOtp({int? timestampSeconds}) async {
    if (_account == null) return;
    final data = await widget.accountRepository.generateOtpDisplayData(
      _account!,
      timestampSeconds: timestampSeconds,
    );
    if (mounted) {
      setState(() {
        _otpDisplayData = data;
      });
    }
  }

  void _copyOtp() {
    if (_otpDisplayData == null || _account == null) return;
    ClipboardService.copyOtp(_otpDisplayData!.otpCode);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied ${_account!.issuer} OTP code to clipboard'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showEditMetadataDialog() {
    if (_account == null) return;
    final issuerController = TextEditingController(text: _account!.issuer);
    final accountNameController = TextEditingController(text: _account!.accountName);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: AppRadius.cardBorder),
          title: const Text('Edit Account Metadata'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppInputField(
                label: 'Issuer Name',
                controller: issuerController,
              ),
              const SizedBox(height: AppSpacing.md12),
              AppInputField(
                label: 'Account Identifier',
                controller: accountNameController,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newIssuer = issuerController.text.trim();
                final newName = accountNameController.text.trim();
                if (newIssuer.isEmpty || newName.isEmpty) return;

                final navState = Navigator.of(context);
                final messengerState = ScaffoldMessenger.of(context);

                try {
                  final updated = await widget.accountRepository.updateAccountMetadata(
                    widget.accountId,
                    issuer: newIssuer,
                    accountName: newName,
                  );
                  if (mounted) {
                    navState.pop();
                    setState(() {
                      _account = updated;
                    });
                    messengerState.showSnackBar(
                      const SnackBar(content: Text('Account updated successfully.')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    messengerState.showSnackBar(
                      SnackBar(
                        content: Text(e.toString().replaceAll('Exception: ', '')),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              },
              child: const Text('Save Changes'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete() async {
    if (_account == null) return;

    final confirmed = await AppConfirmationDialog.show(
      context,
      title: 'Delete Account?',
      message:
          'Are you sure you want to delete ${_account!.issuer} (${_account!.accountName})? This action cannot be undone.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );

    if (confirmed == true && mounted) {
      try {
        await widget.accountRepository.deleteAccount(widget.accountId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Account "${_account!.issuer}" deleted.'),
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to delete account. Please try again.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final tileBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Account Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_account == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Account Details')),
        body: const Center(child: Text('Account not found.')),
      );
    }

    final account = _account!;
    final otpCode = _otpDisplayData?.otpCode ?? '••••••';
    final remainingSeconds = _otpDisplayData?.remainingSeconds ?? account.period;

    return Scaffold(
      appBar: AppBar(
        title: Text(account.issuer),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: _showEditMetadataDialog,
            tooltip: 'Edit Metadata',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xxl24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero OTP Card
              Material(
                color: tileBg,
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.cardBorder,
                  side: BorderSide(color: borderColor, width: 1.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xxl24),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(account.issuer, style: theme.textTheme.headlineMedium),
                                Text(account.accountName, style: theme.textTheme.bodyMedium),
                              ],
                            ),
                          ),
                          OtpProgressIndicator(
                            remainingSeconds: remainingSeconds,
                            totalPeriod: account.period,
                            size: 36.0,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xxl24),
                      OtpDisplay(
                        rawOtp: otpCode,
                        fontSize: 38.0,
                      ),
                      const SizedBox(height: AppSpacing.lg16),
                      AppButton(
                        label: 'Copy OTP Code',
                        icon: Icons.copy,
                        onPressed: _copyOtp,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.xxl24),

              // Configuration Details Metadata
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Account Configuration', style: theme.textTheme.titleMedium),
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18.0),
                    onPressed: _showEditMetadataDialog,
                    tooltip: 'Edit Issuer & Name',
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md12),

              Material(
                color: tileBg,
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.mediumBorder,
                  side: BorderSide(color: borderColor, width: 1.0),
                ),
                child: Column(
                  children: [
                    ListTile(
                      title: const Text('Algorithm'),
                      trailing: Text(account.algorithm),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      title: const Text('Digits'),
                      trailing: Text('${account.digits} Digits'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      title: const Text('Period'),
                      trailing: Text('${account.period} Seconds'),
                    ),
                    const Divider(height: 1),
                    const ListTile(
                      title: Text('Secret Key'),
                      trailing: Text('••••••••••••••••'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xxxl32),

              AppButton(
                label: 'Delete Account',
                icon: Icons.delete_outline,
                variant: AppButtonVariant.destructive,
                onPressed: _confirmDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
