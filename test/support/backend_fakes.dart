import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:stopscam/core/api/backend_client.dart';

class MemoryCredentials implements DeviceCredentialStore {
  final values = <String, String>{};
  bool failWrite = false;
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async {
    if (failWrite) throw StateError('storage unavailable');
    values[key] = value;
  }
}

class TestAdapter implements HttpClientAdapter {
  TestAdapter(this.status, this.body);
  final int status;
  final Object body;
  final requests = <RequestOptions>[];
  RequestOptions? request;
  int calls = 0, tokens = 0, registrations = 0, unauthorizedRequests = 0;
  int tokenStatus = 200;
  DioExceptionType? failure;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    var responseStatus = status;
    Object responseBody = body;
    if (options.path.endsWith('/auth/register')) {
      registrations++;
      responseStatus = 201;
      responseBody = {'deviceId': 'test-device', 'deviceSecret': 'test-secret'};
    } else if (options.path.endsWith('/auth/token')) {
      tokens++;
      responseStatus = tokenStatus;
      responseBody = {
        'accessToken': 'token-$tokens',
        'expiresIn': 900,
        'tokenType': 'Bearer',
      };
    } else {
      request = options;
      calls++;
      if (failure != null) {
        throw DioException(requestOptions: options, type: failure!);
      }
      if (unauthorizedRequests > 0) {
        unauthorizedRequests--;
        responseStatus = 401;
      }
    }
    return ResponseBody.fromString(
      jsonEncode(responseBody),
      responseStatus,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  BackendClient client({
    MemoryCredentials? credentials,
    DateTime Function()? now,
  }) => BackendClient(
    dio: Dio()..httpClientAdapter = this,
    config: {'BACKEND_URL': 'https://example.com'},
    credentials: credentials ?? MemoryCredentials(),
    now: now,
  );
  @override
  void close({bool force = false}) {}
}

const safeResult = {
  'riskScore': 12,
  'confidence': .8,
  'riskLevel': 'safe',
  'isScam': false,
  'category': 'unknown',
  'summary': 'Few signs',
  'reasons': <String>[],
  'recommendations': ['Stay cautious'],
};
