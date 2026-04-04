import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/env/app_env.dart';
import '../models/app_config.dart';
import '../models/auth_session.dart';
import '../models/device.dart';
import '../models/location.dart';
import '../models/subscription.dart';
import '../models/user.dart';

final mockBackendProvider = Provider<MockBackendService>((ref) {
  return MockBackendService(ref.watch(appEnvProvider));
});

class MockBackendService {
  MockBackendService(this._env);

  final AppEnv _env;

  static const mockCodeValues = <String>{'111111', 'mock', 'demo', 'dev'};
  static const mockTokenPrefix = 'mock:';
  static const mockToken = '${mockTokenPrefix}dev-shell';

  bool _enabled = false;
  List<_MockDeviceRecord>? _devices;

  bool get isEnabled => _enabled;

  bool isMockToken(String? value) => value?.startsWith(mockTokenPrefix) ?? false;

  bool shouldUseMockCode(String code) => mockCodeValues.contains(code.trim().toLowerCase());

  void enable() {
    _enabled = true;
    _devices ??= _seedDevices();
  }

  void disable() {
    _enabled = false;
  }

  AuthSession createMockSession() {
    enable();
    final user = fetchMe();
    return AuthSession(
      accessToken: mockToken,
      refreshToken: mockToken,
      user: user,
      subscription: fetchSubscription(),
      language: user.language,
    );
  }

  AppUser fetchMe() {
    enable();
    return const AppUser(
      id: 'dev-user',
      telegramId: 100001,
      displayName: 'INET Dev User',
      username: 'inet_dev',
      language: 'ru',
      blocked: false,
    );
  }

  AppConfig fetchAppConfig() {
    enable();
    return AppConfig(
      appName: _env.appName,
      supportUrl: _env.supportUrl,
      botUrl: _env.botUrl,
      maintenanceMode: false,
      paymentsEnabled: true,
      defaultDeviceLimit: 3,
      featureFlags: const {
        'mock_backend': true,
        'vpn_shell': true,
      },
    );
  }

  Subscription fetchSubscription() {
    enable();
    return Subscription(
      status: 'active',
      planCode: 'monthly',
      planName: '30 дней',
      planNameRu: '30 дней',
      planNameEn: '30 days',
      expiresAt: DateTime.now().add(const Duration(days: 30)),
      deviceLimit: 3,
      devicesUsed: (_devices ?? _seedDevices()).length,
    );
  }

  List<Map<String, dynamic>> fetchPlans() {
    enable();
    return [
      {
        'code': 'daily',
        'name_ru': '1 день',
        'name_en': '1 day',
        'price_rub': 10,
        'duration_days': 1,
        'device_limit': 2,
        'is_active': true,
      },
      {
        'code': 'monthly',
        'name_ru': '30 дней',
        'name_en': '30 days',
        'price_rub': 999,
        'duration_days': 30,
        'device_limit': 3,
        'is_active': true,
      },
    ];
  }

  List<VpnLocation> fetchLocations() {
    enable();
    return const [
      VpnLocation(
        code: 'auto-fastest',
        name: 'Авто | Самый быстрый',
        status: 'online',
        nameRu: 'Авто | Самый быстрый',
        nameEn: 'Auto | Fastest',
        recommended: true,
      ),
      VpnLocation(
        code: 'auto-reserve',
        name: 'Авто | Резервный',
        status: 'online',
        nameRu: 'Авто | Резервный',
        nameEn: 'Auto | Reserve',
        reserve: true,
      ),
      VpnLocation(
        code: 'fi-1',
        name: 'Финляндия',
        status: 'online',
        nameRu: 'Финляндия',
        nameEn: 'Finland',
      ),
      VpnLocation(
        code: 'de-1',
        name: 'Германия',
        status: 'online',
        nameRu: 'Германия',
        nameEn: 'Germany',
      ),
      VpnLocation(
        code: 'nl-1',
        name: 'Нидерланды',
        status: 'online',
        nameRu: 'Нидерланды',
        nameEn: 'Netherlands',
      ),
    ];
  }

  List<Device> fetchDevices() {
    enable();
    return (_devices ?? _seedDevices()).map((item) => item.toDevice()).toList(growable: false);
  }

  Device registerDevice({
    required String platform,
    required String deviceName,
    required String deviceFingerprint,
  }) {
    enable();
    final devices = _devices ??= _seedDevices();
    final existingIndex = devices.indexWhere((item) => item.fingerprint == deviceFingerprint);
    if (existingIndex >= 0) {
      final existing = devices.removeAt(existingIndex).copyWith(
        platform: platform,
        name: deviceName,
        current: true,
        lastActiveAt: DateTime.now(),
      );
      devices.insert(0, existing);
      return existing.toDevice();
    }

    final currentCount = devices.length;
    final record = _MockDeviceRecord(
      id: 'mock-device-${currentCount + 1}',
      name: deviceName,
      platform: platform,
      fingerprint: deviceFingerprint,
      lastActiveAt: DateTime.now(),
      current: true,
    );

    for (var index = 0; index < devices.length; index += 1) {
      devices[index] = devices[index].copyWith(current: false);
    }
    devices.insert(0, record);

    final limit = fetchSubscription().deviceLimit ?? 3;
    if (devices.length > limit) {
      devices.removeRange(limit, devices.length);
    }

    return record.toDevice();
  }

  void removeDevice(String id) {
    enable();
    final devices = _devices ??= _seedDevices();
    devices.removeWhere((item) => item.id == id);
    if (devices.isEmpty) {
      _devices = _seedDevices();
    }
  }

  List<_MockDeviceRecord> _seedDevices() {
    return [
      _MockDeviceRecord(
        id: 'mock-device-1',
        name: 'INET Android',
        platform: 'android',
        fingerprint: 'mock-android-fingerprint',
        lastActiveAt: DateTime.now().subtract(const Duration(minutes: 5)),
        current: true,
      ),
      _MockDeviceRecord(
        id: 'mock-device-2',
        name: 'INET iPhone',
        platform: 'ios',
        fingerprint: 'mock-ios-fingerprint',
        lastActiveAt: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
        current: false,
      ),
    ];
  }
}

class _MockDeviceRecord {
  const _MockDeviceRecord({
    required this.id,
    required this.name,
    required this.platform,
    required this.fingerprint,
    required this.lastActiveAt,
    required this.current,
  });

  final String id;
  final String name;
  final String platform;
  final String fingerprint;
  final DateTime lastActiveAt;
  final bool current;

  _MockDeviceRecord copyWith({
    String? id,
    String? name,
    String? platform,
    String? fingerprint,
    DateTime? lastActiveAt,
    bool? current,
  }) {
    return _MockDeviceRecord(
      id: id ?? this.id,
      name: name ?? this.name,
      platform: platform ?? this.platform,
      fingerprint: fingerprint ?? this.fingerprint,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      current: current ?? this.current,
    );
  }

  Device toDevice() {
    return Device(
      id: id,
      name: name,
      platform: platform,
      lastActiveAt: lastActiveAt,
      current: current,
    );
  }
}
