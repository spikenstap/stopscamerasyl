import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'api_exception.dart';

abstract interface class DeviceCredentialStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
}

class SecureDeviceCredentialStore implements DeviceCredentialStore {
  const SecureDeviceCredentialStore();
  static const _storage = FlutterSecureStorage();
  @override
  Future<String?> read(String key) => _storage.read(key: key);
  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);
}

class BackendClient {
  BackendClient({
    Dio? dio,
    Map<String, String>? config,
    DeviceCredentialStore? credentials,
    DateTime Function()? now,
  }) : config = config ?? (dotenv.isInitialized ? dotenv.env : {}),
       _dio = dio ?? Dio(),
       _credentials = credentials ?? const SecureDeviceCredentialStore(),
       _now = now ?? DateTime.now {
    _dio.options.connectTimeout = const Duration(seconds: 15);
  }

  final Map<String, String> config;
  final Dio _dio;
  final DeviceCredentialStore _credentials;
  final DateTime Function() _now;
  Map<String, dynamic>? _device;
  String? _token;
  DateTime? _expires;
  Future<void>? _authenticating;

  String get baseUrl {
    const compiled = String.fromEnvironment('BACKEND_URL');
    return (compiled.isNotEmpty ? compiled : config['BACKEND_URL'] ?? '')
        .trim()
        .replaceFirst(RegExp(r'/+$'), '');
  }

  bool get isConfigured => baseUrl.isNotEmpty;

  void _validateUrl() {
    final uri = Uri.tryParse(baseUrl);
    final host = uri?.host ?? '';
    final octets = host.split('.').map(int.tryParse).toList();
    final privateIpv4 =
        octets.length == 4 &&
        octets.every((n) => n != null && n >= 0 && n <= 255) &&
        (octets[0] == 10 ||
            octets[0] == 127 ||
            (octets[0] == 192 && octets[1] == 168) ||
            (octets[0] == 172 && octets[1]! >= 16 && octets[1]! <= 31));
    final allowLocal =
        kDebugMode &&
        (const bool.fromEnvironment('ALLOW_INSECURE_BACKEND') ||
            config['ALLOW_INSECURE_BACKEND'] == 'true') &&
        (privateIpv4 || host == 'localhost' || host == '::1');
    if (uri == null ||
        host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        (uri.scheme != 'https' && !(uri.scheme == 'http' && allowLocal))) {
      throw const ApiException(Failure.config);
    }
  }

  Future<void> initialize() async {
    if (isConfigured) await _authenticate();
  }

  Future<void> _authenticate({String? rejectedToken}) async {
    _validateUrl();
    if (_token != null &&
        _token != rejectedToken &&
        _expires!.isAfter(_now().add(const Duration(seconds: 15)))) {
      return;
    }
    final pending = _authenticating;
    if (pending != null) return pending;
    final operation = _loadToken();
    _authenticating = operation;
    try {
      await operation;
    } finally {
      _authenticating = null;
    }
  }

  Future<void> _loadToken() async {
    final key = 'stopscam.device.v1:$baseUrl';
    if (_device == null) {
      String? saved;
      try {
        saved = await _credentials.read(key);
        if (saved != null) {
          final parsed = jsonDecode(saved) as Map<String, dynamic>;
          _checkDevice(parsed);
          _device = parsed;
        }
      } on Object {
        throw const ApiException(Failure.storage);
      }
      if (saved == null) {
        final registered = await _request('/v1/auth/register', {
          'platform': defaultTargetPlatform == TargetPlatform.iOS
              ? 'ios'
              : 'android',
          'appVersion': '2.2.0+4',
        });
        _checkDevice(registered);
        final device = {
          'deviceId': registered['deviceId'],
          'deviceSecret': registered['deviceSecret'],
        };
        try {
          await _credentials.write(key, jsonEncode(device));
        } on Object {
          throw const ApiException(Failure.storage);
        }
        _device = device;
      }
    }
    final result = await _request('/v1/auth/token', _device!);
    final token = result['accessToken'];
    final seconds = result['expiresIn'];
    if (token is! String ||
        token.trim().isEmpty ||
        seconds is! int ||
        seconds <= 0 ||
        seconds > 86400 ||
        result['tokenType'] != 'Bearer') {
      throw const ApiException(Failure.json);
    }
    _token = token;
    _expires = _now().add(Duration(seconds: seconds));
  }

  void _checkDevice(Map<String, dynamic> value) {
    for (final field in ['deviceId', 'deviceSecret']) {
      if (value[field] is! String || (value[field] as String).trim().isEmpty) {
        throw const ApiException(Failure.json);
      }
    }
  }

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body,
  ) async {
    // Only fixed API paths are accepted; credentials never follow redirects.
    if (!const [
      '/v1/analyze',
      '/v1/phone/check',
      '/v1/phone/report',
    ].contains(path)) {
      throw const ApiException(Failure.config);
    }
    await _authenticate();
    final usedToken = _token!;
    try {
      return await _request(path, body, token: usedToken, expose401: true);
    } on _Unauthorized {
      await _authenticate(rejectedToken: usedToken);
      return _request(path, body, token: _token);
    }
  }

  Future<Map<String, dynamic>> keywords(
    String lang,
    int version,
    String? etag,
  ) async {
    await _authenticate();
    final usedToken = _token!;
    Future<Map<String, dynamic>> fetch(String token, bool retry) => _request(
      '/v1/keywords',
      {},
      token: token,
      expose401: retry,
      method: 'GET',
      query: {'lang': lang, 'version': version},
      headers: {'If-None-Match': ?etag},
    );
    try {
      return await fetch(usedToken, true);
    } on _Unauthorized {
      await _authenticate(rejectedToken: usedToken);
      return fetch(_token!, false);
    }
  }

  Future<Map<String, dynamic>> _request(
    String path,
    Map<String, dynamic> body, {
    String? token,
    bool expose401 = false,
    String method = 'POST',
    Map<String, dynamic>? query,
    Map<String, dynamic> headers = const {},
  }) async {
    try {
      final response = await _dio.request<dynamic>(
        '$baseUrl$path',
        data: method == 'GET' ? null : body,
        queryParameters: query,
        options: Options(
          method: method,
          headers: {
            ...headers,
            if (token != null) 'Authorization': 'Bearer $token',
          },
          contentType: Headers.jsonContentType,
          followRedirects: false,
          validateStatus: (status) =>
              status != null &&
              ((status >= 200 && status < 300) ||
                  (method == 'GET' && status == 304)),
          sendTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 60),
        ),
      );
      if (response.statusCode == 304) return {'notModified': true};
      if (response.data is! Map<String, dynamic>) {
        throw const ApiException(Failure.json);
      }
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 401 && expose401) throw const _Unauthorized();
      if (status == 401 || status == 403) {
        throw const ApiException(Failure.auth);
      }
      if (status == 429) throw const ApiException(Failure.rate);
      final data = e.response?.data;
      final error = data is Map ? data['error'] : null;
      final code = error is Map ? error['code'] : null;
      if (code == 'ai_not_configured') throw const ApiException(Failure.config);
      if (code == 'ai_invalid_response') throw const ApiException(Failure.json);
      if (status == 504) throw const ApiException(Failure.timeout);
      if (status != null && status >= 500) {
        throw const ApiException(Failure.server);
      }
      if (const [
        DioExceptionType.connectionTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.receiveTimeout,
      ].contains(e.type)) {
        throw const ApiException(Failure.timeout);
      }
      if (e.type == DioExceptionType.connectionError) {
        throw const ApiException(Failure.network);
      }
      if (e.error is FormatException) throw const ApiException(Failure.json);
      throw const ApiException(Failure.unknown);
    }
  }
}

class _Unauthorized implements Exception {
  const _Unauthorized();
}
