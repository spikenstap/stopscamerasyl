import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stopscam/features/numbers/number_providers.dart';
import 'package:stopscam/features/numbers/numbers_screen.dart';
import 'package:stopscam/localization/generated/app_localizations.dart';
import 'package:stopscam/models/personal_number.dart';
import 'package:stopscam/services/number_repository.dart';

class EmptyNumbers extends NumberRepository {
  @override
  Future<List<PersonalNumber>> all() async => [];
}

void main() {
  for (final language in ['ru', 'kk']) {
    testWidgets('Number list fits small screens and keyboard $language', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            numberRepositoryProvider.overrideWithValue(EmptyNumbers()),
          ],
          child: MaterialApp(
            locale: Locale(language),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: const NumbersScreen(),
              bottomNavigationBar: const SizedBox(height: 80),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
