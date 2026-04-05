import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dio_client.dart';

final backendApiProvider = Provider<BackendApi>((ref) {
  return BackendApi(ref.watch(dioProvider));
});

class BackendApi {
  BackendApi(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> get(
    String path, {
    bool skipAuth = false,
    Map<String, dynamic>? queryParameters,
  }) async {
    final response = await _dio.get<dynamic>(
      path,
      queryParameters: queryParameters,
      options: Options(extra: {'skipAuth': skipAuth}),
    );

    final data = response.data;
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return <String, dynamic>{};
  }

  Future<List<dynamic>> getList(
    String path, {
    bool skipAuth = false,
    Map<String, dynamic>? queryParameters,
  }) async {
    final response = await _dio.get<dynamic>(
      path,
      queryParameters: queryParameters,
      options: Options(extra: {'skipAuth': skipAuth}),
    );

    final data = response.data;
    if (data is List) {
      return data;
    }
    if (data is Map<String, dynamic>) {
      final items = data['items'];
      return items is List ? items : <dynamic>[];
    }
    if (data is Map) {
      final mapped = Map<String, dynamic>.from(data);
      final items = mapped['items'];
      return items is List ? items : <dynamic>[];
    }
    return <dynamic>[];
  }

  Future<Map<String, dynamic>> post(
    String path, {
    bool skipAuth = false,
    Object? data,
  }) async {
    final response = await _dio.post<dynamic>(
      path,
      data: data,
      options: Options(extra: {'skipAuth': skipAuth}),
    );

    final body = response.data;
    if (body is Map<String, dynamic>) {
      return body;
    }
    if (body is Map) {
      return Map<String, dynamic>.from(body);
    }
    return <String, dynamic>{};
  }

  Future<void> delete(
    String path, {
    bool skipAuth = false,
    Object? data,
  }) async {
    await _dio.delete<void>(
      path,
      data: data,
      options: Options(extra: {'skipAuth': skipAuth}),
    );
  }
}
