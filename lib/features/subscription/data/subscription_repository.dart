import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_endpoints.dart';
import '../../../core/api/backend_api.dart';
import '../../../core/mock/mock_backend_service.dart';
import '../../../core/models/subscription.dart';

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  return SubscriptionRepository(
    ref.watch(backendApiProvider),
    ref.watch(mockBackendProvider),
  );
});

final subscriptionProvider = FutureProvider<Subscription?>((ref) async {
  return ref.watch(subscriptionRepositoryProvider).fetchMine();
});

final plansProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(subscriptionRepositoryProvider).fetchPlans();
});

class SubscriptionRepository {
  SubscriptionRepository(this._api, this._mock);

  final BackendApi _api;
  final MockBackendService _mock;

  Future<Subscription?> fetchMine() async {
    if (_mock.isEnabled) {
      return _mock.fetchSubscription();
    }

    try {
      final data = await _api.get(ApiEndpoints.subscriptionMine);
    final subscriptionData = data['subscription'];
    if (subscriptionData is Map<String, dynamic>) {
      return Subscription.fromJson(subscriptionData).copyWith(
        status: data['is_active'] == true
            ? 'active'
            : (subscriptionData['status'] ?? 'inactive').toString(),
        deviceLimit: _toInt(data['device_limit']) ?? _toInt(subscriptionData['device_limit']),
        devicesUsed: _toInt(data['devices_used']) ?? _toInt(subscriptionData['devices_used']),
      );
    }
    if (subscriptionData is Map) {
      final mapped = Map<String, dynamic>.from(subscriptionData);
      return Subscription.fromJson(mapped).copyWith(
        status: data['is_active'] == true
            ? 'active'
            : (mapped['status'] ?? 'inactive').toString(),
        deviceLimit: _toInt(data['device_limit']) ?? _toInt(mapped['device_limit']),
        devicesUsed: _toInt(data['devices_used']) ?? _toInt(mapped['devices_used']),
      );
    }
    if (data.isEmpty) {
      return null;
    }
    return null;
    } catch (_) {
      _mock.enable();
      return _mock.fetchSubscription();
    }
  }

  Future<List<Map<String, dynamic>>> fetchPlans() async {
    if (_mock.isEnabled) {
      return _mock.fetchPlans();
    }

    try {
      final data = await _api.getList(ApiEndpoints.plans, skipAuth: true);
      return data
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    } catch (_) {
      _mock.enable();
      return _mock.fetchPlans();
    }
  }

  int? _toInt(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value;
    }
    return int.tryParse(value.toString());
  }
}
