import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stopscam/app/app.dart';
import 'package:stopscam/app/router.dart';
import 'package:stopscam/core/api/backend_client.dart';
import 'package:stopscam/core/providers.dart';
import 'package:stopscam/core/storage/local_storage.dart';
import 'package:stopscam/services/scam_ai_service.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final captureKey = GlobalKey();
  Future<void> capture(String name) async {
    final boundary =
        captureKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    binding.reportData ??= <String, dynamic>{};
    binding.reportData!['screenshots'] ??= <dynamic>[];
    (binding.reportData!['screenshots'] as List<dynamic>).add({
      'screenshotName': name,
      'bytes': data!.buffer.asUint8List().toList(),
    });
  }

  testWidgets('Android: onboarding, scans, history, languages and themes', (
    tester,
  ) async {
    // Prevent real Android IME callbacks from overwriting injected test input.
    tester.testTextInput.register();
    addTearDown(tester.testTextInput.unregister);
    final prefs = await SharedPreferences.getInstance();
    // This test runs in the new StopScam app's sandbox only, never other apps.
    await prefs.setBool('onboardingCompleted', false);
    await prefs.setString('history', '[]');
    await prefs.setString('language', 'ru');
    await prefs.setString('themeMode', 'light');
    ProviderContainer createContainer() => ProviderContainer(
      overrides: [
        storageProvider.overrideWithValue(LocalStorage(prefs)),
        aiServiceProvider.overrideWithValue(
          ScamAiService(BackendClient(), config: {'USE_MOCK_AI': 'true'}),
        ),
      ],
    );
    var container = createContainer();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: RepaintBoundary(key: captureKey, child: const StopScamApp()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('Защита от мошенников'), findsOneWidget);
    await tester.tap(find.text('Пропустить'));
    await tester.pumpAndSettle();
    expect(prefs.getBool('onboardingCompleted'), true);
    await tester.pumpAndSettle();
    await capture('01-home-ru');
    await tester.tap(find.byIcon(Icons.qr_code_scanner).last);
    await tester.pumpAndSettle();
    final scan = find.widgetWithIcon(FilledButton, Icons.auto_awesome);
    await tester.ensureVisible(scan);
    await tester.tap(scan);
    await tester.pumpAndSettle();
    expect(find.text('Введите сообщение или ссылку.'), findsOneWidget);
    await tester.enterText(
      find.byType(TextFormField),
      'СРОЧНО: ваш счёт заблокирован. Перейдите на bank-verify.example и сообщите SMS-код.',
    );
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.ensureVisible(scan);
    await tester.tap(scan);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('52'), findsOneWidget);
    await capture('02-result-ru');
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Ссылка'));
    await tester.tap(find.text('Ссылка'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'not a valid link');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.ensureVisible(scan);
    await tester.tap(scan);
    await tester.pumpAndSettle();
    expect(
      find.text('Введите корректный адрес сайта с http:// или https://.'),
      findsOneWidget,
    );
    await tester.enterText(find.byType(TextFormField), 'example.com/login');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.ensureVisible(scan);
    await tester.tap(scan);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('28'), findsOneWidget);
    expect((await container.read(historyProvider.future)).length, 2);
    container.read(routerProvider).go('/settings');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Қазақша'));
    await tester.tap(find.text('Қазақша'));
    await tester.pumpAndSettle();
    expect(find.text('Тіл'), findsOneWidget);
    await tester.ensureVisible(find.byIcon(Icons.dark_mode_outlined));
    await tester.tap(find.byIcon(Icons.dark_mode_outlined));
    await tester.pumpAndSettle();
    await capture('03-settings-kk-dark');
    expect(prefs.getString('themeMode'), 'dark');
    // Destroy all providers and rebuild them from the persisted Android storage.
    await tester.pumpWidget(const SizedBox.shrink());
    container.dispose();
    await prefs.reload();
    container = createContainer();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: RepaintBoundary(key: captureKey, child: const StopScamApp()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(container.read(preferencesProvider).language, 'kk');
    expect(container.read(preferencesProvider).theme, ThemeMode.dark);
    expect(container.read(preferencesProvider).onboarded, true);
    await tester.tap(find.byIcon(Icons.history));
    await tester.pumpAndSettle();
    expect(find.text('28/100'), findsOneWidget);
    expect(find.text('52/100'), findsOneWidget);
    await capture('04-history-kk-dark');
    await tester.tap(find.text('28/100').first);
    await tester.pumpAndSettle();
    expect(find.text('28'), findsOneWidget);
    expect(
      find.text('ЖИ түсіндірмесі бастапқы тексеру тілінде сақталған.'),
      findsOneWidget,
    );
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Жою').first);
    await tester.pumpAndSettle();
    expect((await container.read(historyProvider.future)).length, 1);
    await tester.tap(find.text('Тарихты тазалау'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Бас тарту'));
    await tester.pumpAndSettle();
    expect((await container.read(historyProvider.future)).length, 1);
    await tester.tap(find.text('Тарихты тазалау'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Жою'));
    await tester.pumpAndSettle();
    expect(LocalStorage(prefs).readHistory(), isEmpty);
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byIcon(Icons.menu_book_outlined));
    await tester.tap(find.byIcon(Icons.menu_book_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Фишингті қалай тануға болады'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    // Leave the first real launch in Russian, following the user's conversation.
    await container.read(preferencesProvider.notifier).language('ru');
    await container.read(preferencesProvider.notifier).theme(ThemeMode.system);
    await tester.pumpWidget(const SizedBox.shrink());
    container.dispose();
  });
}
