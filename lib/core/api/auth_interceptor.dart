import 'dart:async';

import 'package:dio/dio.dart';

import 'api_endpoints.dart';
import '../storage/secure_storage_service.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required SecureStorageService storage,
    required Dio dio,
  })  : _storage = storage,
        _dio = dio;

  final SecureStorageService _storage;
  final Dio _dio;
  Future<String?>? _refreshFuture;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.extra['skipAuth'] == true) {
      handler.next(options);
      return;
    }

    final token = await _storage.readAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final request = err.requestOptions;
    final isUnauthorized = err.response?.statusCode == 401;
    final isRefreshRequest = request.path == ApiEndpoints.authRefresh;
    final wasRetried = request.extra['retried'] == true;

    if (!isUnauthorized || request.extra['skipAuth'] == true || isRefreshRequest || wasRetried) {
      handler.next(err);
      return;
    }

    try {
      final newAccessToken = await _refreshAccessToken();
      if (newAccessToken == null || newAccessToken.isEmpty) {
        await _storage.clearAuth();
        handler.next(err);
        return;
      }

      final response = await _retryRequest(request, newAccessToken);
      handler.resolve(response);
      return;
    } catch (_) {
      await _storage.clearAuth();
      handler.next(err);
      return;
    }
  }

  Future<String?> _refreshAccessToken() {
    final inFlight = _refreshFuture;
    if (inFlight != null) {
      return inFlight;
    }

    final completer = Completer<String?>();
    _refreshFuture = completer.future;

    () async {
      try {
        final refreshToken = await _storage.readRefreshToken();
        if (refreshToken == null || refreshToken.isEmpty) {
          completer.complete(null);
          return;
        }

        final response = await _dio.post<Map<String, dynamic>>(
          ApiEndpoints.authRefresh,
          data: {'refresh_token': refreshToken},
          options: Options(extra: {'skipAuth': true}),
        );

        final body = response.data ?? const <String, dynamic>{};
        final accessToken = (body['access_token'] ?? body['token'] ?? '').toString();
        final nextRefreshToken = (body['refresh_token'] ?? refreshToken).toString();

        if (accessToken.isEmpty) {
          completer.complete(null);
          return;
        }

        await _storage.writeAccessToken(accessToken);
        await _storage.writeRefreshToken(nextRefreshToken);
        completer.complete(accessToken);
      } catch (_) {
        completer.complete(null);
      } finally {
        _refreshFuture = null;
      }
    }();

    return completer.future;
  }

  Future<Response<dynamic>> _retryRequest(
    RequestOptions request,
    String accessToken,
  ) {
    final headers = Map<String, dynamic>.from(request.headers)
      ..['Authorization'] = 'Bearer $accessToken';

    return _dio.fetch<dynamic>(
      request.copyWith(
        headers: headers,
        extra: <String, dynamic>{
          ...request.extra,
          'retried': true,
        },
      ),
    );
  }
}
