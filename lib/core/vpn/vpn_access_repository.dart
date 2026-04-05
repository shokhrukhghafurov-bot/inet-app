import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_endpoints.dart';
import '../api/backend_api.dart';
import '../mock/mock_backend_service.dart';
import 'vless_config.dart';

final vpnAccessRepositoryProvider = Provider<VpnAccessRepository>((ref) {
  return VpnAccessRepository(
    ref.watch(backendApiProvider),
    ref.watch(mockBackendProvider),
  );
});

class VpnAccessRepository {
  VpnAccessRepository(this._api, this._mock);

  final BackendApi _api;
  final MockBackendService _mock;

  Future<VlessConfig> fetchVlessConfig(String locationCode) async {
    if (_mock.isEnabled) {
      return _mock.fetchVlessConfig(locationCode);
    }

    final payload = await _api.get(ApiEndpoints.vpnConfig(locationCode));
    final config = payload['config'];
    if (config is Map<String, dynamic>) {
      final parsed = VlessConfig.fromJson(config, fallbackLocationCode: locationCode);
      if (!parsed.isComplete) {
        throw StateError('Incomplete VLESS config for $locationCode');
      }
      return parsed;
    }
    if (config is Map) {
      final parsed = VlessConfig.fromJson(
        Map<String, dynamic>.from(config),
        fallbackLocationCode: locationCode,
      );
      if (!parsed.isComplete) {
        throw StateError('Incomplete VLESS config for $locationCode');
      }
      return parsed;
    }
    throw StateError('VPN config response is empty for $locationCode');
  }
}
