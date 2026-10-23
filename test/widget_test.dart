import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stopscam/app/app.dart';
import 'package:stopscam/core/api/backend_client.dart';
import 'package:stopscam/core/providers.dart';
import 'package:stopscam/core/storage/local_storage.dart';
import 'package:stopscam/services/scam_ai_service.dart';

void main() {
  for (final locale in ['ru', 'kk']) {
    for (final size in [
      const Size(360, 640),
      const Size(390, 844),
      const Size(412, 915),
    ]) {
      testWidgets('Navigation, scan and settings $locale $size', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        SharedPreferences.setMockInitialValues({
          'onboardingCompleted': true,
          'language': locale,
        });
        final prefs = await SharedPreferences.getInstance();
        final container = ProviderContainer(
          overrides: [
            storageProvider.overrideWithValue(LocalStorage(prefs)),
            aiServiceProvider.overrideWithValue(
              ScamAiService(BackendClient(), config: {'USE_MOCK_AI': 'true'}),
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
        expect(find.text('StopScam'), findsOneWidget);
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.tap(find.byIcon(Icons.qr_code_scanner).last);
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byType(TextFormField),
          'Your bank account is blocked. Send OTP now.',
        );
        final scanButton = find.widgetWithIcon(
          FilledButton,
          Icons.auto_awesome,
        );
        await tester.ensureVisible(scanButton);
        await tester.tap(scanButton);
        await tester.pump();
        await tester.pump(const Duration(seconds: 2));
        await tester.pumpAndSettle();
        expect(find.text('52'), findsOneWidget);
        expect(tester.takeException(), isNull);
        expect((await container.read(historyProvider.future)).length, 1);
        expect(LocalStorage(prefs).readHistory().single.analysis.riskScore, 52);
        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.settings_outlined));
        await tester.pumpAndSettle();
        final sharing = find.byKey(const ValueKey('share-number-reports'));
        await tester.ensureVisible(sharing);
        expect(tester.widget<SwitchListTile>(sharing).value, false);
        await tester.tap(sharing);
        await tester.pumpAndSettle();
        expect(tester.widget<SwitchListTile>(sharing).value, true);
        expect(prefs.getBool('shareReports'), true);
        final targetLanguage = locale == 'ru' ? 'kk' : 'ru';
        await tester.ensureVisible(
          find.text(locale == 'ru' ? 'Қазақша' : 'Русский'),
        );
        await tester.tap(find.text(locale == 'ru' ? 'Қазақша' : 'Русский'));
        await tester.pumpAndSettle();
        expect(container.read(preferencesProvider).language, targetLanguage);
        expect(prefs.getString('language'), targetLanguage);
        await tester.ensureVisible(find.byIcon(Icons.dark_mode_outlined));
        await tester.tap(find.byIcon(Icons.dark_mode_outlined));
        await tester.pumpAndSettle();
        expect(container.read(preferencesProvider).theme, ThemeMode.dark);
        expect(prefs.getString('themeMode'), 'dark');
        expect(tester.takeException(), isNull);
        await tester.tap(find.byIcon(Icons.history));
        await tester.pumpAndSettle();
        expect(find.text('52/100'), findsOneWidget);
        await tester.tap(find.text('52/100'));
        await tester.pumpAndSettle();
        expect(find.text('52'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
