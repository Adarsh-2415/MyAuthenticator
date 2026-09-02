import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/utils/otpauth_uri_parser.dart';
import '../../repositories/account_repository.dart';
import '../../ui/tokens/app_colors.dart';
import '../../ui/tokens/app_dimensions.dart';
import '../../ui/tokens/app_radius.dart';
import '../../ui/tokens/app_spacing.dart';
import 'qr_confirmation_dialog.dart';

/// Screen 4 — QR Scanner Screen (Phase 4 Real Camera Scanning & Secure OTPAuth Processing).
class QrScannerScreen extends StatefulWidget {
  final AccountRepository? accountRepository;

  const QrScannerScreen({
    super.key,
    this.accountRepository,
  });

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen>
    with WidgetsBindingObserver {
  late final MobileScannerController _controller;
  bool _isProcessingScan = false;
  bool _isTorchOn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    if (state == AppLifecycleState.resumed) {
      _controller.start();
    } else if (state == AppLifecycleState.paused) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  void _toggleTorch() async {
    await _controller.toggleTorch();
    if (mounted) {
      setState(() {
        _isTorchOn = !_isTorchOn;
      });
    }
  }

  Future<void> _handleBarcodeDetected(BarcodeCapture capture) async {
    if (_isProcessingScan) return;

    final rawData = capture.barcodes.firstOrNull?.rawValue;
    if (rawData == null || rawData.trim().isEmpty) return;

    setState(() {
      _isProcessingScan = true;
    });

    await _controller.stop();

    if (!mounted) return;

    final navState = Navigator.of(context);
    final messengerState = ScaffoldMessenger.of(context);

    try {
      final parsedData = OtpAuthUriParser.parse(rawData);

      final confirmed = await QrConfirmationDialog.show(
        context,
        parsedData: parsedData,
      );

      if (confirmed == true && mounted) {
        final repo = widget.accountRepository ?? AccountRepository();
        await repo.createAccount(
          issuer: parsedData.issuer,
          accountName: parsedData.accountName,
          secret: parsedData.secret,
          algorithm: parsedData.algorithm,
          digits: parsedData.digits,
          period: parsedData.period,
        );

        if (mounted) {
          messengerState.showSnackBar(
            SnackBar(
              content: Text('Saved "${parsedData.issuer}" account successfully.'),
            ),
          );
          navState.pop(true);
          return;
        }
      }
    } catch (e) {
      if (mounted) {
        messengerState.showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }

    // Resume scanning if cancelled or error occurred
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() {
        _isProcessingScan = false;
      });
      await _controller.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Scan QR Code',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isTorchOn ? Icons.flash_on : Icons.flash_off,
              color: Colors.white,
            ),
            onPressed: _toggleTorch,
            tooltip: 'Toggle Flashlight',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  MobileScanner(
                    controller: _controller,
                    onDetect: _handleBarcodeDetected,
                    errorBuilder: (context, error, child) {
                      return Container(
                        color: Colors.grey.shade900,
                        padding: const EdgeInsets.all(AppSpacing.xxl24),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.videocam_off_outlined,
                                size: 64.0,
                                color: Colors.white54,
                              ),
                              const SizedBox(height: AppSpacing.lg16),
                              Text(
                                'Camera Access Required',
                                style: theme.textTheme.titleLarge
                                    ?.copyWith(color: Colors.white),
                              ),
                              const SizedBox(height: AppSpacing.sm8),
                              Text(
                                'Please grant camera permission in system settings to scan authenticator QR codes.',
                                style: theme.textTheme.bodyMedium
                                    ?.copyWith(color: Colors.white70),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  // Scanner frame target overlay
                  Container(
                    width: AppDimensions.qrOverlaySize,
                    height: AppDimensions.qrOverlaySize,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.blueAccent, width: 3.0),
                      borderRadius: AppRadius.cardBorder,
                    ),
                  ),

                  if (_isProcessingScan)
                    Container(
                      color: Colors.black54,
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                ],
              ),
            ),
            Container(
              color: AppColors.darkSurface,
              padding: const EdgeInsets.all(AppSpacing.xxl24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Position the 2FA setup QR code within the frame',
                    style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
