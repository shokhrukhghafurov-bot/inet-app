import 'dart:io';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_endpoints.dart';
import '../../../core/api/backend_api.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/models/device.dart';
import '../../../core/storage/secure_storage_service.dart';

final devicesRepositoryProvider = Provider<DevicesRepository>((ref) {
  return DevicesRepository(
    ref.watch(backendApiProvider),
    ref.watch(secureStorageProvider),
  );
});

final devicesProvider = FutureProvider<List<Device>>((ref) async {
  return ref.watch(devicesRepositoryProvider).fetchDevices();
});

class DevicesRepository {
  DevicesRepository(this._api, this._storage);

  final BackendApi _api;
  final SecureStorageService _storage;

  Future<List<Device>> fetchDevices() async {
    final data = await _api.getList(ApiEndpoints.devices);
    return data
        .map((item) => Device.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<Device?> registerCurrentDevice() async {
    final response = await _api.post(
      ApiEndpoints.registerDevice,
      data: {
        'device_name': _deviceName(),
        'platform': Platform.operatingSystem,
        'device_fingerprint': await _deviceFingerprint(),
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
  }

  Future<void> removeDevice(String id) {
    return _api.delete('${ApiEndpoints.devices}/$id');
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
