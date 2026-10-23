import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stopscam/core/api/backend_client.dart';
import 'package:stopscam/core/providers.dart';
import 'package:stopscam/core/storage/local_storage.dart';
import 'package:stopscam/features/call_listening/call_listening_screen.dart';
import 'package:stopscam/localization/generated/app_localizations.dart';
import 'package:stopscam/models/scam_analysis.dart';
import 'package:stopscam/services/call_listening_bridge.dart';
import 'package:stopscam/services/keyword_dictionary.dart';
import 'package:stopscam/services/scam_ai_service.dart';

import 'support/backend_fakes.dart';

class FakeListening extends CallListeningBridge {
  final controller = StreamController<Map<String, dynamic>>.broadcast();
  bool permitted = true;
  int starts = 0, stops = 0, permissionRequests = 0;
  bool? save;
  @override
  Stream<Map<String, dynamic>> get events => controller.stream;
  @override
  Future<Map<String, dynamic>> status() async => {
    'available': true,
    'active': false,
  };
  @override
  Future<bool> permission() async {
    permissionRequests++;
    return permitted;
  }

  @override
  Future<void> start(KeywordDictionary dictionary, bool saveTranscript) async {
    starts++;
    save = saveTranscript;
    controller.add({
      'active': true,
      'level': 'NONE',
      'text': 'private recognition text',
      'phrases': [],
    });
  }

  @override
  Future<void> stop() async {
    stops++;
    controller.add({'active': false, 'level': 'NONE', 'text': ''});
  }
}

class RecordingDescriptionAi extends ScamAiService {
  RecordingDescriptionAi() : super(BackendClient(config: {}), config: {});
  String? sent;
  @override
  Future<ScamAnalysis> analyze({
    required String text,
    required String type,
    required String language,
    required AppLocalizations l,
    List<String> signals = const [],
    Map<String, dynamic> localSignals = const {},
  }) async {
    sent = text;
    expect(type, 'phone');
    expect(localSignals, isEmpty);
    return ScamAnalysis.fromJson(Map<String, dynamic>.from(safeResult));
  }
}

void main() {
  Future<SharedPreferences> mount(
    WidgetTester tester,
    FakeListening bridge, {
    String locale = 'ru',
    RecordingDescriptionAi? ai,
  }) async {
    SharedPreferences.setMockInitialValues({'language': locale});
    final prefs = await SharedPreferences.getInstance();
    final dictionaries = KeywordDictionaryStore(
      BackendClient(config: {}),
      storage: MemoryCredentials(),
      readAsset: (path) async => File(path).readAsStringSync(),
    );
    await dictionaries.load(locale);
    await tester.pumpWidget(
      ProviderScope(
        key: UniqueKey(),
        overrides: [
          storageProvider.overrideWithValue(LocalStorage(prefs)),
          callListeningProvider.overrideWithValue(bridge),
          keywordDictionaryProvider.overrideWithValue(dictionaries),
          if (ai != null) aiServiceProvider.overrideWithValue(ai),
        ],
        child: MaterialApp(
          locale: Locale(locale),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const CallListeningScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    addTearDown(bridge.controller.close);
    return prefs;
  }

  testWidgets(
    'No permission or microphone before explicit consent; transcript default off',
    (tester) async {
      final bridge = FakeListening();
      final prefs = await mount(tester, bridge);
      expect(bridge.starts, 0);
      expect(bridge.permissionRequests, 0);
      expect(
        tester
            .widget<SwitchListTile>(
              find.byKey(const ValueKey('save-call-transcript')),
            )
            .value,
        false,
      );
      final start = find.byKey(const ValueKey('start-call-listening'));
      await tester.ensureVisible(start);
      await tester.tap(start);
      await tester.pumpAndSettle();
      expect(find.byType(ListeningConsentScreen), findsOneWidget);
      expect(bridge.permissionRequests, 0);
      final accept = find.byKey(const ValueKey('listening-consent'));
      await tester.ensureVisible(accept);
      await tester.tap(accept);
      await tester.pumpAndSettle();
      expect(bridge.starts, 1);
      expect(bridge.save, false);
      expect(prefs.getBool('listeningConsentV1'), true);
      expect(find.text('private recognition text'), findsOneWidget);
      bridge.controller.add({
        'active': true,
        'level': 'DANGER',
        'text': 'private recognition text',
      });
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('call-danger-fullscreen')),
        findsOneWidget,
      );
      await tester.tap(find.text('Остановить микрофон'));
      await tester.pumpAndSettle();
      expect(bridge.stops, 1);
      expect(find.text('private recognition text'), findsNothing);
    },
  );
  testWidgets(
    'Consent cancellation and denied permission never start microphone',
    (tester) async {
      final bridge = FakeListening()..permitted = false;
      final prefs = await mount(tester, bridge);
      expect(prefs.getBool('listeningConsentV1'), isNull);
      final start = find.byKey(const ValueKey('start-call-listening'));
      expect(tester.widget<FilledButton>(start).onPressed, isNotNull);
      await tester.ensureVisible(start);
      await tester.tap(start);
      await tester.pumpAndSettle();
      expect(find.byType(ListeningConsentScreen), findsOneWidget);
      final cancel = find.text('Отмена');
      await tester.ensureVisible(cancel);
      await tester.tap(cancel);
      await tester.pumpAndSettle();
      expect(bridge.permissionRequests, 0);
      await tester.ensureVisible(start);
      await tester.tap(start);
      await tester.pumpAndSettle();
      final accept = find.byKey(const ValueKey('listening-consent'));
      await tester.ensureVisible(accept);
      await tester.tap(accept);
      await tester.pumpAndSettle();
      expect(bridge.permissionRequests, 1);
      expect(bridge.starts, 0);
    },
  );
  testWidgets(
    'AI receives only typed brief; recognition text never copied automatically',
    (tester) async {
      final bridge = FakeListening();
      final ai = RecordingDescriptionAi();
      await mount(tester, bridge, ai: ai);
      bridge.controller.add({
        'active': false,
        'level': 'NONE',
        'text': 'sensitive full transcript',
      });
      await tester.pumpAndSettle();
      final field = find.byKey(const ValueKey('call-ai-description'));
      await tester.ensureVisible(field);
      expect(tester.widget<TextField>(field).controller!.text, isEmpty);
      await tester.enterText(field, 'Caller asked for a transfer');
      final button = find.text('Проверить описание с AI');
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(ai.sent, 'Caller asked for a transfer');
    },
  );
  testWidgets('Kazakh dictionary stays empty pending native speaker review', (
    tester,
  ) async {
    final bridge = FakeListening();
    await mount(tester, bridge, locale: 'kk');
    final button = tester.widget<FilledButton>(
      find.byKey(const ValueKey('start-call-listening')),
    );
    expect(button.onPressed, isNull);
    expect(bridge.permissionRequests, 0);
    expect(find.byType(ErrorWidget), findsNothing);
  });
  testWidgets('Kazakh consent screen renders and requires explicit action', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('kk'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const ListeningConsentScreen(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Микрофонды қоспас бұрын'), findsOneWidget);
    expect(find.byKey(const ValueKey('listening-consent')), findsOneWidget);
  });
}
