import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/env/app_env.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/backend_api.dart';
import '../../../core/mock/mock_backend_service.dart';
import '../../../core/models/app_config.dart';

final appConfigRepositoryProvider = Provider<AppConfigRepository>((ref) {
  return AppConfigRepository(
    api: ref.watch(backendApiProvider),
    env: ref.watch(appEnvProvider),
    mock: ref.watch(mockBackendProvider),
  );
});

final appConfigProvider = FutureProvider<AppConfig>((ref) async {
  return ref.watch(appConfigRepositoryProvider).fetchConfig();
});

class AppConfigRepository {
  AppConfigRepository({
    required BackendApi api,
    required AppEnv env,
    required MockBackendService mock,
  })  : _api = api,
        _env = env,
        _mock = mock;

  final BackendApi _api;
  final AppEnv _env;
  final MockBackendService _mock;

  Future<AppConfig> fetchConfig() async {
    try {
      final data = await _api.get(ApiEndpoints.appConfig, skipAuth: true);
      return AppConfig.fromJson(data);
    } on DioException catch (_) {
      if (_mock.isEnabled) {
        return _mock.fetchAppConfig();
      }
      return _fallback();
    }
  }

  String fallbackBotUrl() => _env.botUrl;

  AppConfig _fallback() {
    return AppConfig(
      appName: _env.appName,
      supportUrl: _env.supportUrl,
      botUrl: _env.botUrl,
      maintenanceMode: false,
      paymentsEnabled: true,
      defaultDeviceLimit: 2,
      featureFlags: const <String, dynamic>{},
    );
  }
}
