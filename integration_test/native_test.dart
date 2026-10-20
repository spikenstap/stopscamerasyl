import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stopscam/app/app.dart';
import 'package:stopscam/app/router.dart';
import 'package:stopscam/core/api/api_client.dart';
import 'package:stopscam/core/providers.dart';
import 'package:stopscam/core/storage/local_storage.dart';
import 'package:stopscam/services/scam_ai_service.dart';
import 'package:stopscam/services/call_bridge.dart';

import 'qr_fixtures.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Android native QR decoder, phone flow and ungranted call role', (
    tester,
  ) async {
    tester.testTextInput.register();
    addTearDown(tester.testTextInput.unregister);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboardingCompleted', true);
    await prefs.setString('language', 'ru');
    final container = ProviderContainer(
      overrides: [
        storageProvider.overrideWithValue(LocalStorage(prefs)),
        aiServiceProvider.overrideWithValue(
          ScamAiService(ApiClient(), config: {'USE_MOCK_AI': 'true'}),
        ),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const StopScamApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    final controller = MobileScannerController(autoStart: false);
    for (var i = 0; i < qrFixtures.length; i++) {
      final fixture = qrFixtures[i];
      final file = File('${Directory.systemTemp.path}/stopscam-qr-$i.png');
      await file.writeAsBytes(base64Decode(fixture.$2));
      final decoded = await controller.analyzeImage(
        file.path,
        formats: [BarcodeFormat.qrCode],
      );
      expect(decoded?.barcodes.map((b) => b.rawValue), contains(fixture.$1));
      await file.delete();
    }
    await controller.dispose();
    const bridge = CallBridge();
    final status = await bridge.status();
    expect(status['available'], isA<bool>());
    expect(status['held'], false);
    container.read(routerProvider).push('/phone');
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, '87001234567');
    FocusManager.instance.primaryFocus?.unfocus();
    final submit = find.widgetWithText(FilledButton, 'Начать проверку');
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(find.text('Недостаточно данных'), findsOneWidget);
    expect(find.text('+77001234567'), findsOneWidget);
    expect(tester.takeException(), isNull);
    final saved = await container.read(historyProvider.future);
    expect(saved.first.type, 'phone');
    expect(saved.first.analysis.riskScore, isNull);
  });
  testWidgets('Android camera preview starts with test permission', (
    tester,
  ) async {
    if (!const bool.fromEnvironment('TEST_CAMERA')) return;
    final camera = MobileScannerController(
      autoStart: false,
      formats: [BarcodeFormat.qrCode],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: MobileScanner(controller: camera)),
      ),
    );
    await tester.pump();
    await camera.start();
    await tester.pump(const Duration(seconds: 2));
    expect(camera.value.isRunning, true);
    expect(camera.value.hasCameraPermission, true);
    await camera.stop();
    await tester.pumpWidget(const SizedBox.shrink());
    await camera.dispose();
  });
}
