import 'dart:io';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_endpoints.dart';
import '../../../core/api/backend_api.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/models/device.dart';
import '../../../core/mock/mock_backend_service.dart';
import '../../../core/storage/secure_storage_service.dart';

final devicesRepositoryProvider = Provider<DevicesRepository>((ref) {
  return DevicesRepository(
    ref.watch(backendApiProvider),
    ref.watch(secureStorageProvider),
    ref.watch(mockBackendProvider),
  );
});

final devicesProvider = FutureProvider<List<Device>>((ref) async {
  return ref.watch(devicesRepositoryProvider).fetchDevices();
});

class DevicesRepository {
  DevicesRepository(this._api, this._storage, this._mock);

  final BackendApi _api;
  final SecureStorageService _storage;
  final MockBackendService _mock;

  Future<List<Device>> fetchDevices() async {
    if (_mock.isEnabled) {
      return _mock.fetchDevices();
    }

    try {
      final data = await _api.getList(ApiEndpoints.devices);
      return data
          .map((item) => Device.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    } catch (_) {
      _mock.enable();
      return _mock.fetchDevices();
    }
  }

  Future<Device?> registerCurrentDevice() async {
    final deviceName = _deviceName();
    final platform = Platform.operatingSystem;
    final fingerprint = await _deviceFingerprint();

    if (_mock.isEnabled) {
      return _mock.registerDevice(
        platform: platform,
        deviceName: deviceName,
        deviceFingerprint: fingerprint,
      );
    }

    try {
      final response = await _api.post(
        ApiEndpoints.registerDevice,
        data: {
          'device_name': deviceName,
          'platform': platform,
          'device_fingerprint': fingerprint,
        },
      );

      final device = response['device'];
      if (device is Map<String, dynamic>) {
        return Device.fromJson(device);
      }
      if (device is Map) {
        return Device.fromJson(Map<String, dynamic>.from(device));
      }
      return null;
    } catch (_) {
      _mock.enable();
      return _mock.registerDevice(
        platform: platform,
        deviceName: deviceName,
        deviceFingerprint: fingerprint,
      );
    }
  }

  Future<void> removeDevice(String id) async {
    if (_mock.isEnabled) {
      _mock.removeDevice(id);
      return;
    }

    try {
      await _api.delete('${ApiEndpoints.devices}/$id');
    } catch (_) {
      _mock.enable();
      _mock.removeDevice(id);
    }
  }

  String _deviceName() {
    final platform = Platform.operatingSystem;
    return 'INET ${platform[0].toUpperCase()}${platform.substring(1)}';
  }

  Future<String> _deviceFingerprint() async {
    final existing = await _storage.readDeviceFingerprint();
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    final rng = Random.secure();
    final chars = List.generate(32, (_) => rng.nextInt(16).toRadixString(16)).join();
    final value = '${Platform.operatingSystem}-$chars';
    await _storage.writeDeviceFingerprint(value);
    return value;
  }
}
