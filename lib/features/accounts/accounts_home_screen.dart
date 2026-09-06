import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/otp_display_data.dart';
import '../../models/totp_account.dart';
import '../../repositories/account_repository.dart';
import '../../services/clipboard_service.dart';
import '../../services/otp_time_service.dart';
import '../../ui/components/account_card.dart';
import '../../ui/components/app_search_field.dart';
import '../../ui/components/empty_state.dart';
import '../../ui/tokens/app_spacing.dart';

/// Screen 2 — Accounts Home (Phase 5 Real-Time RFC 6238 TOTP Generation & Ticker Integration).
class AccountsHomeScreen extends StatefulWidget {
  final AccountRepository accountRepository;
  final VoidCallback onAddAccountRequested;
  final VoidCallback onSettingsRequested;
  final Function(String accountId) onAccountSelected;

  const AccountsHomeScreen({
    super.key,
    required this.accountRepository,
    required this.onAddAccountRequested,
    required this.onSettingsRequested,
    required this.onAccountSelected,
  });

  @override
  State<AccountsHomeScreen> createState() => AccountsHomeScreenState();
}

class AccountsHomeScreenState extends State<AccountsHomeScreen> {
  bool _isLoading = true;
  bool _isSearchActive = false;
  final TextEditingController _searchController = TextEditingController();
  List<TotpAccount> _accounts = [];

  // Centralized OTP display data cache keyed by account ID
  final Map<String, OtpDisplayData> _otpDisplayCache = {};
  StreamSubscription<int>? _tickerSubscription;

  @override
  void initState() {
    super.initState();
    OtpTimeService().ensureLifecycleObserver();
    _subscribeToTicker();
    refreshAccounts();
  }

  void _subscribeToTicker() {
    _tickerSubscription = OtpTimeService().timestampStream.listen((timestampSeconds) {
      _recalculateOtps(timestampSeconds: timestampSeconds);
    });
  }

  @override
  void dispose() {
    _tickerSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  /// Reloads real accounts from encrypted repository storage and computes current OTPs.
  Future<void> refreshAccounts() async {
    setState(() => _isLoading = true);
    final loaded = await widget.accountRepository.getAllAccounts();
    if (mounted) {
      _accounts = loaded;
      await _recalculateOtps();
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Recalculates OTP display data for all loaded accounts using central Unix timestamp.
  Future<void> _recalculateOtps({int? timestampSeconds}) async {
    final nowSec = timestampSeconds ?? OtpTimeService().currentUnixTime;
    for (final account in _accounts) {
      final displayData = await widget.accountRepository.generateOtpDisplayData(
        account,
        timestampSeconds: nowSec,
      );
      _otpDisplayCache[account.id] = displayData;
    }
    if (mounted) {
      setState(() {});
    }
  }

  List<TotpAccount> get _filteredAccounts {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _accounts;
    return _accounts.where((acc) {
      return acc.issuer.toLowerCase().contains(query) ||
          acc.accountName.toLowerCase().contains(query);
    }).toList();
  }

  void _copyOtp(String otpCode, String issuer) {
    ClipboardService.copyOtp(otpCode);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied $issuer OTP code to clipboard'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accounts = _filteredAccounts;

    return Scaffold(
      appBar: AppBar(
        title: _isSearchActive
            ? AppSearchField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                onClear: () => setState(() {}),
              )
            : const Text('MyAuthenticator'),
        actions: [
          IconButton(
            icon: Icon(_isSearchActive ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearchActive = !_isSearchActive;
                if (!_isSearchActive) {
                  _searchController.clear();
                }
              });
            },
            tooltip: _isSearchActive ? 'Close Search' : 'Search Accounts',
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: widget.onSettingsRequested,
            tooltip: 'Settings',
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : (accounts.isEmpty
                ? EmptyState(
                    title: _searchController.text.isNotEmpty
                        ? 'No Matching Accounts'
                        : 'No Accounts Added Yet',
                    subtitle: _searchController.text.isNotEmpty
                        ? 'No authenticator accounts match "${_searchController.text}".'
                        : 'Add your first authenticator account to securely generate 2FA verification codes offline.',
                    actionLabel: 'Add Account',
                    onActionPressed: widget.onAddAccountRequested,
                  )
                : RefreshIndicator(
                    onRefresh: refreshAccounts,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(AppSpacing.lg16),
                      itemCount: accounts.length,
                      itemBuilder: (context, index) {
                        final account = accounts[index];
                        final displayData = _otpDisplayCache[account.id] ??
                            OtpDisplayData(
                              accountId: account.id,
                              otpCode: '••••••',
                              remainingSeconds: account.period,
                              period: account.period,
                              progress: 1.0,
                            );

                        return AccountCard(
                          account: account,
                          mockOtp: displayData.otpCode,
                          remainingSeconds: displayData.remainingSeconds,
                          failureCategory: displayData.failureCategory,
                          onTap: () => widget.onAccountSelected(account.id),
                          onCopy: () => _copyOtp(displayData.otpCode, account.issuer),
                        );
                      },
                    ),
                  )),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: widget.onAddAccountRequested,
        icon: const Icon(Icons.add),
        label: const Text('Add Account'),
      ),
    );
  }
}
