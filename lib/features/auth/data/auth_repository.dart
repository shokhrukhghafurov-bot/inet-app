import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_endpoints.dart';
import '../../../core/api/backend_api.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/models/auth_session.dart';
import '../../../core/mock/mock_backend_service.dart';
import '../../../core/models/user.dart';
import '../../../core/storage/secure_storage_service.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    api: ref.watch(backendApiProvider),
    storage: ref.watch(secureStorageProvider),
    mock: ref.watch(mockBackendProvider),
  );
});

class AuthRepository {
  AuthRepository({
    required BackendApi api,
    required SecureStorageService storage,
    required MockBackendService mock,
  })  : _api = api,
        _storage = storage,
        _mock = mock;

  final BackendApi _api;
  final SecureStorageService _storage;
  final MockBackendService _mock;

  Future<AuthSession> exchangeCode(String code) async {
    final normalized = code.trim();
    if (_mock.shouldUseMockCode(normalized)) {
      return _loginToMockShell();
    }

    try {
      final data = await _api.post(
        ApiEndpoints.authCode,
        skipAuth: true,
        data: {'code': normalized},
      );
      final session = AuthSession.fromJson(data);
      await persistTokens(accessToken: session.accessToken, refreshToken: session.refreshToken);
      if (session.language case final language?) {
        await _storage.writeLocale(language);
      }
      _mock.disable();
      return session;
    } on Exception {
      if (_mock.shouldUseMockCode(normalized)) {
        return _loginToMockShell();
      }
      rethrow;
    }
  }

  Future<AuthSession> loginWithToken(String token) async {
    if (_mock.isMockToken(token)) {
      return _loginToMockShell(token: token);
    }

    await persistTokens(accessToken: token, refreshToken: token);
    final user = await fetchMe();
    if (user.language case final language?) {
      await _storage.writeLocale(language);
    }
    _mock.disable();
    return AuthSession(
      accessToken: token,
      refreshToken: token,
      user: user,
      language: user.language,
    );
  }

  Future<AppUser> fetchMe() async {
    final accessToken = await _storage.readAccessToken();
    if (_mock.isMockToken(accessToken) || _mock.isEnabled) {
      return _mock.fetchMe();
    }

    final data = await _api.get(ApiEndpoints.authMe);
    final userMap = data['user'];
    if (userMap is Map<String, dynamic>) {
      return AppUser.fromJson(userMap);
    }
    if (userMap is Map) {
      return AppUser.fromJson(Map<String, dynamic>.from(userMap));
    }
    return AppUser.fromJson(data);
  }

  Future<void> logout() async {
    final accessToken = await _storage.readAccessToken();
    try {
      if (!_mock.isMockToken(accessToken)) {
        await _api.post(ApiEndpoints.authLogout);
      }
    } catch (_) {
      // Backend logout is optional for MVP.
    } finally {
      _mock.disable();
      await clearTokens();
    }
  }

  Future<AuthSession> _loginToMockShell({String token = MockBackendService.mockToken}) async {
    final session = _mock.createMockSession();
    await persistTokens(accessToken: token, refreshToken: token);
    if (session.language case final language?) {
      await _storage.writeLocale(language);
    }
    return session.copyWith(
      accessToken: token,
      refreshToken: token,
    );
  }

  Future<void> persistTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.writeAccessToken(accessToken);
    await _storage.writeRefreshToken(refreshToken);
  }

  Future<(String?, String?)> readTokens() async {
    final accessToken = await _storage.readAccessToken();
    final refreshToken = await _storage.readRefreshToken();
    return (accessToken, refreshToken);
  }

  Future<bool> hasTokens() async {
    final (accessToken, _) = await readTokens();
    return accessToken?.isNotEmpty ?? false;
  }

  Future<void> clearTokens() => _storage.clearAuth();
}
