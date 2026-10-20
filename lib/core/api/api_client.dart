import 'package:dio/dio.dart';

import 'api_exception.dart';

class ApiClient {
  ApiClient({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 15),
              sendTimeout: const Duration(seconds: 20),
              receiveTimeout: const Duration(seconds: 60),
              followRedirects: false,
            ),
          );
  final Dio _dio;
  Future<Map<String, dynamic>> complete({
    required String url,
    required String key,
    required Map<String, dynamic> body,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        url,
        data: body,
        options: Options(
          headers: {
            'Authorization': 'Bearer $key',
            'Content-Type': 'application/json',
          },
          followRedirects: false,
        ),
      );
      if (response.data is! Map<String, dynamic>) {
        throw const ApiException(Failure.json);
      }
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == 401 || code == 403) throw const ApiException(Failure.auth);
      if (code == 429) throw const ApiException(Failure.rate);
      if (code != null && code >= 500) throw const ApiException(Failure.server);
      if ([
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
