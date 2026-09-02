import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:authenticator/main.dart';
import 'package:authenticator/services/biometric_service.dart';
import 'package:authenticator/services/otp_time_service.dart';

class FakeBiometricService extends BiometricService {
  @override
  Future<bool> isDeviceSupported() async => true;

  @override
  Future<BiometricAuthResult> authenticate({String reason = ''}) async {
    return BiometricAuthResult.success;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  tearDown(() {
    OtpTimeService().stopTimer();
  });

  testWidgets('MyAuthenticator Phase 6 UI navigation and app lock screen test',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MyAuthenticatorApp(
        biometricService: FakeBiometricService(),
      ),
    );
    await tester.pumpAndSettle();

    // 1. App Lock Screen Initial View
    expect(find.text('MyAuthenticator'), findsOneWidget);
    expect(find.text('Protected by Hardware & Device Security'), findsOneWidget);
    expect(find.text('Unlock MyAuthenticator'), findsOneWidget);
    expect(find.text('Use Device Passcode'), findsOneWidget);

    // 2. Unlock & Navigate to Accounts Home Screen
    await tester.tap(find.text('Unlock MyAuthenticator'));
    await tester.pumpAndSettle();

    expect(find.text('No Accounts Added Yet'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);

    // 3. Open Settings
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Theme Preference'), findsOneWidget);
    expect(find.text('Biometric & Passcode Lock'), findsOneWidget);
    expect(find.text('Screen Privacy Protection'), findsOneWidget);
    expect(find.text('Clipboard Auto-Clear'), findsOneWidget);

    // Go back to Home
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    // 4. Open Add Account Choice Sheet
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('Add Authenticator Account'), findsOneWidget);
    expect(find.text('Scan QR Code'), findsOneWidget);
    expect(find.text('Enter Setup Key Manually'), findsOneWidget);
  });
}
