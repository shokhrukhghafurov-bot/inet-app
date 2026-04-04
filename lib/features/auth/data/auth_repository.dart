import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_endpoints.dart';
import '../../../core/api/backend_api.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/models/auth_session.dart';
import '../../../core/models/user.dart';
import '../../../core/storage/secure_storage_service.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    api: ref.watch(backendApiProvider),
    storage: ref.watch(secureStorageProvider),
  );
});

class AuthRepository {
  AuthRepository({
    required BackendApi api,
    required SecureStorageService storage,
  })  : _api = api,
        _storage = storage;

  final BackendApi _api;
  final SecureStorageService _storage;

  Future<AuthSession> exchangeCode(String code) async {
    final data = await _api.post(
      ApiEndpoints.authCode,
      skipAuth: true,
      data: {'code': code},
    );
    final session = AuthSession.fromJson(data);
    await persistTokens(accessToken: session.accessToken, refreshToken: session.refreshToken);
    if (session.language case final language?) {
      await _storage.writeLocale(language);
    }
    return session;
  }

  Future<AuthSession> loginWithToken(String token) async {
    await persistTokens(accessToken: token, refreshToken: token);
    final user = await fetchMe();
    if (user.language case final language?) {
      await _storage.writeLocale(language);
    }
    return AuthSession(
      accessToken: token,
      refreshToken: token,
      user: user,
      language: user.language,
    );
  }

  Future<AppUser> fetchMe() async {
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
    try {
      await _api.post(ApiEndpoints.authLogout);
    } catch (_) {
      // Backend logout is optional for MVP.
    } finally {
      await clearTokens();
    }
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
