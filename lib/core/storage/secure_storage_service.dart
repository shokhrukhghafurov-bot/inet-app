import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  SecureStorageService() : _storage = const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _accessTokenKey = 'auth.access_token';
  static const _refreshTokenKey = 'auth.refresh_token';
  static const _localeKey = 'app.locale';
  static const _deviceFingerprintKey = 'device.fingerprint';

  Future<void> writeAccessToken(String value) {
    return _storage.write(key: _accessTokenKey, value: value);
  }

  Future<void> writeRefreshToken(String value) {
    return _storage.write(key: _refreshTokenKey, value: value);
  }

  Future<String?> readAccessToken() {
    return _storage.read(key: _accessTokenKey);
  }

  Future<String?> readRefreshToken() {
    return _storage.read(key: _refreshTokenKey);
  }

  Future<void> writeLocale(String value) {
    return _storage.write(key: _localeKey, value: value);
  }

  Future<String?> readLocale() {
    return _storage.read(key: _localeKey);
  }

  Future<void> writeDeviceFingerprint(String value) {
    return _storage.write(key: _deviceFingerprintKey, value: value);
  }

  Future<String?> readDeviceFingerprint() {
    return _storage.read(key: _deviceFingerprintKey);
  }

  Future<void> clearAuth() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }
}
