import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stopscam/app/app.dart';
import 'package:stopscam/app/router.dart';
import 'package:stopscam/app/theme/app_colors.dart';
import 'package:stopscam/app/theme/app_theme.dart';
import 'package:stopscam/core/providers.dart';
import 'package:stopscam/core/storage/local_storage.dart';
import 'package:stopscam/services/call_listening_bridge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final previewDir = Platform.environment['STOPSCAM_PREVIEW_DIR'];
  setUpAll(() async {
    final fontDir = Platform.environment['STOPSCAM_FONT_DIR'];
    if (fontDir == null) return;
    final loader = FontLoader('Roboto');
    for (final name in [
      'roboto-regular.ttf',
      'roboto-medium.ttf',
      'roboto-bold.ttf',
    ]) {
      loader.addFont(
        Future.value(
          ByteData.sublistView(File('$fontDir/$name').readAsBytesSync()),
        ),
      );
    }
    await loader.load();
    final icons = FontLoader('MaterialIcons');
    icons.addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });

  test('Text and brand colors meet normal-text contrast in both themes', () {
    double contrast(Color a, Color b) {
      final x = a.computeLuminance(), y = b.computeLuminance();
      return x > y ? (x + .05) / (y + .05) : (y + .05) / (x + .05);
    }

    for (final brightness in Brightness.values) {
      final theme = AppTheme.build(brightness);
      final c = theme.colorScheme;
      for (final pair in [
        (c.onSurface, c.surface),
        (c.onSurfaceVariant, c.surface),
        (c.onSurface, theme.scaffoldBackgroundColor),
        (c.onSurfaceVariant, theme.scaffoldBackgroundColor),
        (c.primary, c.surface),
        (c.onPrimary, c.primary),
        (c.onPrimaryContainer, c.primaryContainer),
        (c.onSurfaceVariant, c.primaryContainer),
        (AppColors.onHero, AppColors.hero),
        (AppColors.heroMuted, AppColors.hero),
        (AppColors.hero, AppColors.accent),
      ]) {
        expect(contrast(pair.$1, pair.$2), greaterThanOrEqualTo(4.5));
      }
    }
  });

  for (final locale in ['ru', 'kk']) {
    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      for (final layout in [
        (const Size(360, 640), 1.0),
        (const Size(390, 844), 1.0),
        (const Size(844, 390), 1.0),
        (const Size(360, 640), 2.0),
        (const Size(800, 1024), 1.3),
      ]) {
        testWidgets(
          'Design $locale ${mode.name} ${layout.$1} text ${layout.$2}',
          (tester) async {
            tester.view.physicalSize = layout.$1;
            tester.view.devicePixelRatio = 1;
            tester.platformDispatcher.textScaleFactorTestValue = layout.$2;
            tester.platformDispatcher.accessibilityFeaturesTestValue =
                const FakeAccessibilityFeatures(disableAnimations: true);
            addTearDown(() {
              tester.view.resetPhysicalSize();
              tester.view.resetDevicePixelRatio();
              tester.platformDispatcher.clearAllTestValues();
            });
            SharedPreferences.setMockInitialValues({
              'onboardingCompleted': true,
              'language': locale,
              'themeMode': mode.name,
            });
            final prefs = await SharedPreferences.getInstance();
            final container = ProviderContainer(
              overrides: [
                storageProvider.overrideWithValue(LocalStorage(prefs)),
                callListeningEventsProvider.overrideWith(
                  (ref) => const Stream.empty(),
                ),
              ],
            );
            addTearDown(container.dispose);
            final boundary = GlobalKey();
            await tester.pumpWidget(
              UncontrolledProviderScope(
                container: container,
                child: RepaintBoundary(
                  key: boundary,
                  child: const StopScamApp(),
                ),
              ),
            );
            await tester.pump(const Duration(seconds: 1));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            final start = find.byKey(const ValueKey('home-start-check'));
            await tester.ensureVisible(start);
            expect(tester.getSize(start).height, greaterThanOrEqualTo(48));
            await tester.tap(start);
            await tester.pumpAndSettle();
            expect(find.byType(TextFormField), findsOneWidget);
            expect(tester.takeException(), isNull);

            if (previewDir != null && layout.$1 == const Size(390, 844)) {
              for (final route in ['/home', '/scan', '/history', '/settings']) {
                container.read(routerProvider).go(route);
                await tester.pumpAndSettle();
                // Each capture begins at the top of the active page.
                final scrolls = find.descendant(
                  of: find.byType(Scaffold).first,
                  matching: find.byType(Scrollable),
                );
                if (scrolls.evaluate().isNotEmpty) {
                  tester
                      .state<ScrollableState>(scrolls.first)
                      .position
                      .jumpTo(0);
                  await tester.pumpAndSettle();
                }
                expect(tester.takeException(), isNull);
                await tester.runAsync(() async {
                  final render =
                      boundary.currentContext!.findRenderObject()
                          as RenderRepaintBoundary;
                  final image = await render.toImage(pixelRatio: 2);
                  final bytes = await image.toByteData(
                    format: ui.ImageByteFormat.png,
                  );
                  image.dispose();
                  final path =
                      '$previewDir/${route.substring(1)}-$locale-${mode.name}.png';
                  await File(path).parent.create(recursive: true);
                  await File(path).writeAsBytes(bytes!.buffer.asUint8List());
                });
              }
            }
          },
        );
      }
    }
  }
}
