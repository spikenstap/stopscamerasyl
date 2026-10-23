import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stopscam/core/api/backend_client.dart';
import 'package:stopscam/core/api/api_exception.dart';

import 'support/backend_fakes.dart' show MemoryCredentials;

void main() {
  test(
    'Live backend registration, restored identity and phone check',
    () async {
      final config = {
        'BACKEND_URL': Platform.environment['STOPSCAM_TEST_BACKEND_URL'] ?? '',
        'ALLOW_INSECURE_BACKEND': 'true',
      };
      expect(config['BACKEND_URL'], isNotEmpty);
      final credentials = MemoryCredentials();
      final client = BackendClient(config: config, credentials: credentials);
      await client.initialize();
      final result = await client.post('/v1/phone/check', {
        'phoneNumber': '+12025550123',
      });
      expect(result['status'], 'unknown');
      expect(result['confirmed'], false);
      expect(
        result['expiresAt'],
        greaterThan(DateTime.now().millisecondsSinceEpoch),
      );
      final stored = Map<String, String>.from(credentials.values);
      await BackendClient(
        config: config,
        credentials: credentials,
      ).initialize();
      expect(credentials.values, stored);
      if (Platform.environment['STOPSCAM_EXPECT_AI_UNCONFIGURED'] == 'true') {
        await expectLater(
          client.post('/v1/analyze', {
            'type': 'text',
            'content': 'Hello',
            'language': 'ru',
            'localSignals': {},
          }),
          throwsA(
            isA<ApiException>().having(
              (e) => e.failure,
              'failure',
              Failure.config,
            ),
          ),
        );
      }
    },
    skip: !const bool.fromEnvironment('STOPSCAM_BACKEND_TEST'),
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
