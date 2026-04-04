import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_endpoints.dart';
import '../../../core/api/backend_api.dart';
import '../../../core/mock/mock_backend_service.dart';
import '../../../core/models/location.dart';

final locationsRepositoryProvider = Provider<LocationsRepository>((ref) {
  return LocationsRepository(
    ref.watch(backendApiProvider),
    ref.watch(mockBackendProvider),
  );
});

final locationsProvider = FutureProvider<List<VpnLocation>>((ref) async {
  final locations = await ref.watch(locationsRepositoryProvider).fetchLocations();
  ref.read(selectedLocationControllerProvider).ensureSelected(locations);
  return locations;
});

final selectedLocationControllerProvider =
    ChangeNotifierProvider<SelectedLocationController>((ref) {
  return SelectedLocationController();
});

class LocationsRepository {
  LocationsRepository(this._api, this._mock);

  final BackendApi _api;
  final MockBackendService _mock;

  Future<List<VpnLocation>> fetchLocations() async {
    if (_mock.isEnabled) {
      return _mock.fetchLocations();
    }

    try {
      final results = await Future.wait([
        _api.getList(ApiEndpoints.locations),
        _api.getList(ApiEndpoints.locationsStatus),
      ]);

      final locations = results[0]
          .map((item) => VpnLocation.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();

      final statuses = <String, String>{};
      for (final item in results[1]) {
        final data = Map<String, dynamic>.from(item as Map);
        final code = (data['code'] ?? data['id'] ?? '').toString();
        final status = (data['status'] ?? '').toString();
        if (code.isNotEmpty && status.isNotEmpty) {
          statuses[code] = status;
        }
      }

      return locations
          .map((location) => location.copyWith(status: statuses[location.code] ?? location.status))
          .toList();
    } catch (_) {
      _mock.enable();
      return _mock.fetchLocations();
    }
  }
}

class SelectedLocationController extends ChangeNotifier {
  String? _selectedCode;

  String? get selectedCode => _selectedCode;

  void ensureSelected(List<VpnLocation> locations) {
    if (locations.isEmpty) {
      return;
    }
    final stillExists = locations.any((location) => location.code == _selectedCode);
    if (stillExists) {
      return;
    }

    _selectedCode = locations
            .firstWhere(
              (location) => location.recommended,
              orElse: () => locations.first,
            )
            .code;
    notifyListeners();
  }

  void select(String code) {
    if (_selectedCode == code) {
      return;
    }
    _selectedCode = code;
    notifyListeners();
  }

  VpnLocation? current(List<VpnLocation> locations) {
    if (_selectedCode == null) {
      return null;
    }
    try {
      return locations.firstWhere((location) => location.code == _selectedCode);
    } catch (_) {
      return null;
    }
  }
}
