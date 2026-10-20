import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stopscam/app/app.dart';
import 'package:stopscam/app/router.dart';
import 'package:stopscam/core/providers.dart';
import 'package:stopscam/core/storage/local_storage.dart';
import 'package:stopscam/localization/generated/app_localizations.dart';
import 'package:stopscam/features/numbers/numbers_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:stopscam/models/personal_number.dart';
import 'package:stopscam/services/number_repository.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  dotenv.loadFromString(envString: 'USE_MOCK_AI=false');
  for (final locale in ['ru', 'kk']) {
    testWidgets('Number editor, search and complaints UI $locale', (
      tester,
    ) async {
      tester.testTextInput.register();
      addTearDown(tester.testTextInput.unregister);
      const repo = NumberRepository(), phone = '+77001234567';
      await repo.delete(phone);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboardingCompleted', true);
      await prefs.setString('language', locale);
      final container = ProviderContainer(
        overrides: [storageProvider.overrideWithValue(LocalStorage(prefs))],
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
      container.read(routerProvider).go('/numbers');
      await tester.pumpAndSettle();
      final l = AppLocalizations.of(
        tester.element(find.byType(NumbersScreen)),
      )!;
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('saved-number-phone')),
        '87001234567',
      );
      await tester.enterText(
        find.byKey(const ValueKey('saved-number-label')),
        'QA local',
      );
      FocusManager.instance.primaryFocus?.unfocus();
      final save = find.widgetWithText(FilledButton, l.numberSave);
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect((await repo.find(phone))!.label, 'QA local');
      await tester.enterText(find.byType(TextField), 'missing');
      await tester.pumpAndSettle();
      expect(find.text(l.numbersNoMatch), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'QA');
      await tester.pumpAndSettle();
      await tester.tap(find.text('QA local'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(OutlinedButton, l.numberReport));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('report-note')),
        'QA complaint',
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.ensureVisible(
        find.widgetWithText(FilledButton, l.numberSave),
      );
      await tester.tap(find.widgetWithText(FilledButton, l.numberSave));
      await tester.pumpAndSettle();
      expect((await repo.find(phone))!.rule, NumberRule.watch);
      expect((await repo.reports(phone)).single.note, 'QA complaint');
      await tester.ensureVisible(
        find.widgetWithText(TextButton, l.numberDelete),
      );
      await tester.tap(find.widgetWithText(TextButton, l.numberDelete));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, l.delete));
      await tester.pumpAndSettle();
      expect(await repo.find(phone), isNull);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('Native SQLite CRUD, rules, complaints and atomic import', (
    tester,
  ) async {
    const repo = NumberRepository();
    const first = '+77001234567',
        second = '+77011234567',
        third = '+77021234567';
    for (final phone in [first, second, third]) {
      await repo.delete(phone);
    }
    await repo.report(first, ReportCategory.advertising, 'Личная жалоба QA');
    expect((await repo.find(first))!.rule, NumberRule.watch);
    expect((await repo.find(first))!.reportCount, 1);
    await repo.save(
      phone: second,
      originalPhone: first,
      label: 'QA',
      rule: NumberRule.blocked,
      category: ReportCategory.advertising,
      note: 'Заметка',
    );
    expect(await repo.find(first), isNull);
    expect((await repo.reports(second)).single.phone, second);
    expect(
      (await const NumberRepository().find(second))!.rule,
      NumberRule.blocked,
    );
    await expectLater(
      repo.save(
        phone: second,
        label: 'Duplicate',
        rule: NumberRule.trusted,
        category: ReportCategory.other,
        note: '',
      ),
      throwsA(
        isA<PlatformException>().having((e) => e.code, 'code', 'duplicate'),
      ),
    );
    final entry = PersonalNumber(
      phone: third,
      label: 'CSV QA',
      rule: NumberRule.blocked,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    expect(await repo.importNumbers([entry], restoreRules: false), {
      'added': 1,
      'skipped': 0,
    });
    expect((await repo.find(third))!.rule, NumberRule.watch);
    expect(await repo.importNumbers([entry], restoreRules: true), {
      'added': 0,
      'skipped': 1,
    });
    await repo.delete(third);
    await repo.importNumbers([entry], restoreRules: true);
    expect((await repo.find(third))!.rule, NumberRule.blocked);
    await expectLater(
      NumberRepository.channel.invokeMethod('import', {
        'restoreRules': true,
        'items': [
          entry.toJson()..['phone'] = first,
          entry.toJson()..['phone'] = 'bad',
        ],
      }),
      throwsA(isA<PlatformException>()),
    );
    expect(await repo.find(first), isNull);
    await repo.report(second, ReportCategory.other, 'Вторая');
    expect((await repo.find(second))!.rule, NumberRule.blocked);
    await repo.deleteReport((await repo.reports(second)).first.id);
    expect((await repo.find(second))!.reportCount, 1);
    await repo.delete(second);
    expect(await repo.reports(second), isEmpty);
    await repo.delete(third);
  });
}
