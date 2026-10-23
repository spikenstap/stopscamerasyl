import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stopscam/core/api/backend_client.dart';
import 'package:stopscam/core/api/api_exception.dart';
import 'package:stopscam/services/scam_ai_service.dart';
import 'package:stopscam/localization/generated/app_localizations_ru.dart';

import 'support/backend_fakes.dart';

Matcher fails(Failure value) =>
    throwsA(isA<ApiException>().having((e) => e.failure, 'failure', value));
void main() {
  test('HTTP errors mapped without exposing server content', () async {
    for (final e in {
      401: Failure.auth,
      403: Failure.auth,
      429: Failure.rate,
      503: Failure.server,
      504: Failure.timeout,
    }.entries) {
      final adapter = TestAdapter(e.key, {'secret': 'not displayed'});
      await expectLater(
        adapter.client().post('/v1/analyze', {}),
        fails(e.value),
      );
      expect(adapter.calls, e.key == 401 ? 2 : 1);
    }
  });
  test('Backend request uses device token and strict result parsing', () async {
    final adapter = TestAdapter(200, safeResult);
    final result = await ScamAiService(adapter.client(), config: {}).analyze(
      text: 'hello',
      type: 'text',
      language: 'ru',
      l: AppLocalizationsRu(),
      localSignals: {'urls': []},
    );
    expect(result.riskScore, 12);
    expect(adapter.request!.followRedirects, false);
    expect(adapter.request!.uri.path, '/v1/analyze');
    expect(adapter.request!.data, {
      'type': 'text',
      'content': 'hello',
      'language': 'ru',
      'localSignals': {'urls': []},
    });
    expect(adapter.request!.headers['Authorization'], 'Bearer token-1');
    expect(adapter.requests.first.data, {
      'platform': 'android',
      'appVersion': '2.3.0+5',
    });
  });
  test('Missing backend is configuration error', () async {
    await expectLater(
      ScamAiService(BackendClient(config: {}), config: {}).analyze(
        text: 'x',
        type: 'text',
        language: 'ru',
        l: AppLocalizationsRu(),
      ),
      fails(Failure.config),
    );
  });
  test('Malformed backend JSON never produces mock verdict', () async {
    for (final body in [
      <String, dynamic>{'riskScore': 87},
      ['invalid'],
    ]) {
      await expectLater(
        ScamAiService(TestAdapter(200, body).client(), config: {}).analyze(
          text: 'ordinary message',
          type: 'text',
          language: 'ru',
          l: AppLocalizationsRu(),
        ),
        fails(Failure.json),
      );
    }
  });
  test('AI errors preserve config and JSON failures', () async {
    for (final e in {
      'ai_not_configured': Failure.config,
      'ai_invalid_response': Failure.json,
    }.entries) {
      await expectLater(
        TestAdapter(502, {
          'error': {'code': e.key},
        }).client().post('/v1/analyze', {}),
        fails(e.value),
      );
    }
  });
  test('Network and timeout errors', () async {
    for (final e in {
      DioExceptionType.connectionError: Failure.network,
      DioExceptionType.receiveTimeout: Failure.timeout,
    }.entries) {
      final adapter = TestAdapter(200, {})..failure = e.key;
      await expectLater(
        adapter.client().post('/v1/analyze', {}),
        fails(e.value),
      );
    }
  });
  test(
    'Credentials persist, tokens in memory, concurrent startup registers once',
    () async {
      final store = MemoryCredentials();
      final adapter = TestAdapter(200, {});
      final first = adapter.client(credentials: store);
      await Future.wait(List.generate(8, (_) => first.initialize()));
      expect(adapter.registrations, 1);
      expect(adapter.tokens, 1);
      expect(store.values.values.single, isNot(contains('token')));
      await adapter.client(credentials: store).initialize();
      expect(adapter.registrations, 1);
      expect(adapter.tokens, 2);
    },
  );
  test(
    'Concurrent 401s share one refresh and retry each request once',
    () async {
      final adapter = TestAdapter(200, {})..unauthorizedRequests = 8;
      final client = adapter.client();
      await client.initialize();
      await Future.wait(
        List.generate(8, (_) => client.post('/v1/phone/check', {})),
      );
      expect(adapter.calls, 16);
      expect(adapter.tokens, 2);
      expect(adapter.registrations, 1);
    },
  );
  test('Repeated 401 stops; blocked device never re-registers', () async {
    final adapter = TestAdapter(401, {});
    await expectLater(
      adapter.client().post('/v1/analyze', {}),
      fails(Failure.auth),
    );
    expect(adapter.calls, 2);
    expect(adapter.tokens, 2);
    final blocked = TestAdapter(200, {})..tokenStatus = 403;
    final client = blocked.client();
    await expectLater(client.initialize(), fails(Failure.auth));
    await expectLater(client.initialize(), fails(Failure.auth));
    expect(blocked.registrations, 1);
    expect(blocked.calls, 0);
  });
  test('Expiry renews token before protected request', () async {
    var now = DateTime(2026);
    final adapter = TestAdapter(200, {});
    final client = adapter.client(now: () => now);
    await client.initialize();
    now = now.add(const Duration(minutes: 16));
    await client.post('/v1/phone/check', {});
    expect(adapter.tokens, 2);
    expect(adapter.request!.headers['Authorization'], 'Bearer token-2');
  });
  test('Storage failure prevents token and protected requests', () async {
    final adapter = TestAdapter(200, {});
    await expectLater(
      adapter
          .client(credentials: MemoryCredentials()..failWrite = true)
          .initialize(),
      fails(Failure.storage),
    );
    expect(adapter.tokens, 0);
    expect(adapter.calls, 0);
  });
  test('Corrupt saved identity does not re-register', () async {
    final adapter = TestAdapter(200, {});
    final store = MemoryCredentials()
      ..values['stopscam.device.v1:https://example.com'] = 'invalid';
    await expectLater(
      adapter.client(credentials: store).initialize(),
      fails(Failure.storage),
    );
    expect(adapter.registrations, 0);
  });
  test(
    'Rejects public HTTP, credentials in URL, query, fragment and redirects',
    () async {
      for (final url in [
        'http://example.com',
        'https://user:secret@example.com',
        'https://example.com?token=x',
        'https://example.com#x',
        'file:///tmp',
      ]) {
        final adapter = TestAdapter(200, {});
        final client = BackendClient(
          config: {'BACKEND_URL': url, 'ALLOW_INSECURE_BACKEND': 'true'},
          dio: Dio()..httpClientAdapter = adapter,
          credentials: MemoryCredentials(),
        );
        await expectLater(client.initialize(), fails(Failure.config));
        expect(adapter.requests, isEmpty);
      }
      await expectLater(
        TestAdapter(302, {}).client().post('/v1/analyze', {}),
        fails(Failure.unknown),
      );
    },
  );
  test('Private HTTP requires explicit debug option', () async {
    for (final allow in [false, true]) {
      final adapter = TestAdapter(200, {});
      final client = BackendClient(
        config: {
          'BACKEND_URL': 'http://192.168.1.2:8000',
          'ALLOW_INSECURE_BACKEND': allow.toString(),
        },
        credentials: MemoryCredentials(),
        dio: Dio()..httpClientAdapter = adapter,
      );
      if (allow) {
        await client.initialize();
        expect(adapter.registrations, 1);
      } else {
        await expectLater(client.initialize(), fails(Failure.config));
      }
    }
  });
}
