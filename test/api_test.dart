import 'dart:typed_data';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stopscam/core/api/api_client.dart';
import 'package:stopscam/core/api/api_exception.dart';
import 'package:stopscam/services/scam_ai_service.dart';
import 'package:stopscam/localization/generated/app_localizations_ru.dart';

class TestAdapter implements HttpClientAdapter {
  TestAdapter(this.status, this.body);
  final int status;
  final Object body;
  RequestOptions? request;
  int calls = 0;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    request = options;
    calls++;
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test('Maps HTTP errors without leaking server content', () async {
    for (final e in {
      401: Failure.auth,
      403: Failure.auth,
      429: Failure.rate,
      503: Failure.server,
    }.entries) {
      final dio = Dio()
        ..httpClientAdapter = TestAdapter(e.key, {'secret': 'not displayed'});
      await expectLater(
        ApiClient(dio: dio)
            .complete(url: 'https://example.com', key: 'test', body: {}),
        throwsA(
          isA<ApiException>().having((e) => e.failure, 'failure', e.value),
        ),
      );
    }
  });
  test('OpenAI-compatible request and strict response parsing', () async {
    final adapter = TestAdapter(200, {
      'choices': [
        {
          'finish_reason': 'stop',
          'message': {
            'content': jsonEncode({
              'riskScore': 12,
              'confidence': .8,
              'riskLevel': 'safe',
              'isScam': false,
              'category': 'unknown',
              'summary': 'Признаков мало',
              'reasons': [],
              'recommendations': ['Сохраняйте осторожность'],
            }),
          },
        },
      ],
    });
    final service = ScamAiService(
      ApiClient(dio: Dio()..httpClientAdapter = adapter),
      config: {
        'AI_API_KEY': 'test-only',
        'AI_API_URL': 'https://example.com/v1/chat/completions',
      },
    );
    final result = await service.analyze(
      text: 'hello',
      type: 'text',
      language: 'ru',
      l: AppLocalizationsRu(),
    );
    expect(result.riskScore, 12);
    expect(adapter.request!.followRedirects, false);
    expect(
      (adapter.request!.data
          as Map)['response_format']['json_schema']['strict'],
      true,
    );
  });
  test('Missing key fails with configuration error', () async {
    final service = ScamAiService(ApiClient(), config: {});
    await expectLater(
      service.analyze(
        text: 'x',
        type: 'text',
        language: 'ru',
        l: AppLocalizationsRu(),
      ),
      throwsA(
        isA<ApiException>().having((e) => e.failure, 'failure', Failure.config),
      ),
    );
  });
  test('Malformed provider JSON is an error, never a mock verdict', () async {
    final service = ScamAiService(
      ApiClient(
        dio: Dio()
          ..httpClientAdapter = TestAdapter(200, {
            'choices': [
              {
                'finish_reason': 'stop',
                'message': {'content': '{"riskScore":87}'},
              },
            ],
          }),
      ),
      config: {
        'AI_API_KEY': 'test',
        'AI_API_URL': 'https://example.com',
        'USE_MOCK_AI': 'false',
      },
    );
    await expectLater(
      service.analyze(
        text: 'ordinary message',
        type: 'text',
        language: 'ru',
        l: AppLocalizationsRu(),
      ),
      throwsA(
        isA<ApiException>().having((e) => e.failure, 'failure', Failure.json),
      ),
    );
  });
}
