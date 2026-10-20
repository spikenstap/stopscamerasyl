import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stopscam/core/providers.dart';
import 'package:stopscam/core/storage/local_storage.dart';
import 'package:stopscam/features/settings/call_protection.dart';
import 'package:stopscam/localization/generated/app_localizations.dart';
import 'package:stopscam/services/call_bridge.dart';

void main() {
  testWidgets(
    'Incoming events are durable before ACK and replay does not duplicate',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final storage = LocalStorage(await SharedPreferences.getInstance());
      final container = ProviderContainer(
        overrides: [storageProvider.overrideWithValue(storage)],
      );
      addTearDown(container.dispose);
      var acknowledgements = 0;
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(CallBridge.channel, (call) async {
        if (call.method == 'events') {
          return jsonEncode([
            {
              'id': 'event-1',
              'number': '+77001234567',
              'timestamp': 1000,
              'blocked': false,
              'reputation': {'status': 'unknown'},
            },
          ]);
        }
        if (call.method == 'ack') {
          expect(storage.readHistory().single.id, 'call:event-1');
          expect(storage.readHistory().single.analysis.riskScore, isNull);
          acknowledgements++;
        }
        return null;
      });
      addTearDown(
        () => messenger.setMockMethodCallHandler(CallBridge.channel, null),
      );
      for (var iteration = 0; iteration < 2; iteration++) {
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              locale: const Locale('ru'),
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              home: CallEventSync(
                key: ValueKey(iteration),
                child: const SizedBox.shrink(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
      }
      expect(acknowledgements, 2);
      expect(storage.readHistory().length, 1);
      expect(tester.takeException(), isNull);
    },
  );
}
