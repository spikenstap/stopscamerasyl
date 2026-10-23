import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stopscam/core/api/backend_client.dart';
import 'package:stopscam/services/keyword_dictionary.dart';

import 'support/backend_fakes.dart';

void main() {
  test(
    'Live Python Ed25519 signature verifies in Dart; conditional GET returns 304',
    () async {
      final backend = BackendClient(
        config: {
          'BACKEND_URL':
              Platform.environment['STOPSCAM_TEST_BACKEND_URL'] ?? '',
          'ALLOW_INSECURE_BACKEND': 'true',
        },
        credentials: MemoryCredentials(),
      );
      final store = KeywordDictionaryStore(
        backend,
        storage: MemoryCredentials(),
        readAsset: (path) => File(path).readAsString(),
      );
      final envelope = await backend.keywords('ru', 0, null);
      final dictionary = await store.verify(envelope, 'ru', 0);
      expect(dictionary.isEmpty, false);
      final hash = await Sha256().hash(
        base64Decode(envelope['payload'] as String),
      );
      final etag =
          '"${hash.bytes.map((v) => v.toRadixString(16).padLeft(2, '0')).join()}"';
      expect(await backend.keywords('ru', dictionary.version, etag), {
        'notModified': true,
      });
      final kk = await store.verify(
        await backend.keywords('kk', 0, null),
        'kk',
        0,
      );
      expect(kk.isEmpty, true);
    },
    skip: !const bool.fromEnvironment('STOPSCAM_KEYWORDS_TEST'),
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
