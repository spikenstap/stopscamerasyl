import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stopscam/core/api/backend_client.dart';
import 'package:stopscam/services/keyword_dictionary.dart';

import 'support/backend_fakes.dart';

class DictionaryBackend extends BackendClient {
  DictionaryBackend() : super(config: {});
  Map<String, dynamic> envelope = {};
  int calls = 0;
  String? lastEtag;
  int? lastVersion;
  @override
  Future<Map<String, dynamic>> keywords(
    String lang,
    int version,
    String? etag,
  ) async {
    calls++;
    lastEtag = etag;
    lastVersion = version;
    return envelope;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SimpleKeyPair pair;
  late String publicKey;
  late Map<String, dynamic> bundled;
  late DictionaryBackend backend;
  late MemoryCredentials storage;
  late KeywordDictionaryStore store;
  Future<String> readAsset(String path) async => path.endsWith('public_key.txt')
      ? publicKey
      : jsonEncode({
          ...bundled,
          'lang': path.endsWith('kk.json') ? 'kk' : 'ru',
        });
  Future<Map<String, dynamic>> sign(
    Map<String, dynamic> value, {
    SimpleKeyPair? signer,
  }) async {
    final bytes = utf8.encode(jsonEncode(value));
    final signature = await Ed25519().sign(bytes, keyPair: signer ?? pair);
    return {
      'payload': base64Encode(bytes),
      'signature': base64Encode(signature.bytes),
    };
  }

  setUp(() async {
    pair = await Ed25519().newKeyPair();
    publicKey = base64Encode((await pair.extractPublicKey()).bytes);
    bundled = jsonDecode(
      File('assets/call_keywords/ru.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    backend = DictionaryBackend();
    storage = MemoryCredentials();
    store = KeywordDictionaryStore(
      backend,
      storage: storage,
      readAsset: readAsset,
    );
  });
  test(
    'Signed upgrade persists, restores and uses ETag without re-registration',
    () async {
      backend.envelope = await sign({...bundled, 'version': 2});
      expect((await store.update('ru')).version, 2);
      backend.envelope = {'notModified': true};
      expect((await store.update('ru')).version, 2);
      expect(backend.lastVersion, 2);
      expect(backend.lastEtag, startsWith('"'));
      final restored = KeywordDictionaryStore(
        backend,
        storage: storage,
        readAsset: readAsset,
      );
      expect((await restored.load('ru')).version, 2);
    },
  );
  test(
    'Wrong signature, tampered bytes, old version and wrong language rejected',
    () async {
      final valid = await sign({...bundled, 'version': 2});
      for (final bad in [
        {
          ...valid,
          'payload': base64Encode(
            utf8.encode(jsonEncode({...bundled, 'version': 3})),
          ),
        },
        await sign({
          ...bundled,
          'version': 2,
        }, signer: await Ed25519().newKeyPair()),
        await sign({...bundled, 'version': 1}),
        await sign({...bundled, 'version': 2, 'lang': 'kk'}),
      ]) {
        await expectLater(store.verify(bad, 'ru', 1), throwsFormatException);
      }
    },
  );
  test('Same signed content is accepted; same version with changed rules is rejected', () async {
    backend.envelope = await sign(bundled);
    expect((await store.update('ru')).version, 1);
    backend.envelope = await sign({...bundled, 'cautionThreshold': 7});
    await expectLater(store.update('ru'), throwsFormatException);
    expect((await store.load('ru')).data['cautionThreshold'], 6);
  });
  test('Rollback cannot replace installed version, storage failure leaves current intact', () async {
    backend.envelope = await sign({...bundled, 'version': 3});
    await store.update('ru');
    backend.envelope = await sign({...bundled, 'version': 2});
    await expectLater(store.update('ru'), throwsFormatException);
    backend.envelope = await sign({...bundled, 'version': 4});
    storage.failWrite = true;
    await expectLater(store.update('ru'), throwsStateError);
    expect((await store.load('ru')).version, 3);
  });
  test(
    'Malformed local cache falls back to bundled dictionary; Kazakh is empty',
    () async {
      storage.values['stopscam.keywords.v1:ru'] = 'invalid';
      expect((await store.load('ru')).version, 1);
      final kk = KeywordDictionary.parse(
        jsonDecode(File('assets/call_keywords/kk.json').readAsStringSync()),
      );
      expect(kk.isEmpty, true);
    },
  );
  test(
    'Dictionary GET has no speech/body and refreshes token once on 401',
    () async {
      final adapter = TestAdapter(304, {})..unauthorizedRequests = 1;
      final result = await adapter.client().keywords('ru', 2, '"test"');
      expect(result, {'notModified': true});
      expect(adapter.request!.method, 'GET');
      expect(adapter.request!.data, isNull);
      expect(adapter.request!.queryParameters, {'lang': 'ru', 'version': 2});
      expect(adapter.request!.headers['If-None-Match'], '"test"');
      expect(adapter.calls, 2);
      expect(adapter.tokens, 2);
    },
  );
}
