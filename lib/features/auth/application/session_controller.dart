import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/auth_session.dart';
import '../../../core/models/user.dart';
import '../data/auth_repository.dart';

enum SessionStatus {
  initializing,
  authenticated,
  unauthenticated,
}

final sessionControllerProvider = ChangeNotifierProvider<SessionController>((ref) {
  return SessionController(ref.watch(authRepositoryProvider));
});

class SessionController extends ChangeNotifier {
  SessionController(this._repository);

  final AuthRepository _repository;

  SessionStatus _status = SessionStatus.initializing;
  AuthSession? _session;
  String? _errorMessage;
  bool _didInitialize = false;

  SessionStatus get status => _status;
  AuthSession? get session => _session;
  AppUser? get user => _session?.user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == SessionStatus.authenticated;

  Future<void> ensureInitialized() async {
    if (_didInitialize) {
      return;
    }
    _didInitialize = true;
    await initialize();
  }

  Future<void> initialize() async {
    _status = SessionStatus.initializing;
    _errorMessage = null;
    notifyListeners();

    final hasTokens = await _repository.hasTokens();
    if (!hasTokens) {
      _status = SessionStatus.unauthenticated;
      notifyListeners();
      return;
    }

    try {
      final (accessToken, refreshToken) = await _repository.readTokens();
      final user = await _repository.fetchMe();
      _session = AuthSession(
        accessToken: accessToken ?? '',
        refreshToken: refreshToken ?? accessToken ?? '',
        user: user,
        language: user.language,
      );
      _status = SessionStatus.authenticated;
    } catch (error) {
      await _repository.clearTokens();
      _session = null;
      _status = SessionStatus.unauthenticated;
      _errorMessage = _humanize(error);
    }

    notifyListeners();
  }

  Future<void> loginWithCode(String code) async {
    final normalized = code.trim();
    if (_looksLikeJwt(normalized)) {
      await loginWithToken(normalized);
      return;
    }

    _status = SessionStatus.initializing;
    _errorMessage = null;
    notifyListeners();

    try {
      final session = await _repository.exchangeCode(normalized);
      final user = session.user ?? await _repository.fetchMe();
      _session = session.copyWith(user: user, language: session.language ?? user.language);
      _status = SessionStatus.authenticated;
    } catch (error) {
      _session = null;
      _status = SessionStatus.unauthenticated;
      _errorMessage = _humanize(error);
      notifyListeners();
      rethrow;
    }

    notifyListeners();
  }

  Future<void> loginWithToken(String token) async {
    _status = SessionStatus.initializing;
    _errorMessage = null;
    notifyListeners();

    try {
      _session = await _repository.loginWithToken(token);
      _status = SessionStatus.authenticated;
    } catch (error) {
      _session = null;
      _status = SessionStatus.unauthenticated;
      _errorMessage = _humanize(error);
      notifyListeners();
      rethrow;
    }

    notifyListeners();
  }

  Future<void> logout() async {
    await _repository.logout();
    _session = null;
    _status = SessionStatus.unauthenticated;
    notifyListeners();
  }

  bool _looksLikeJwt(String value) {
    final parts = value.split('.');
    return parts.length == 3 && parts.every((part) => part.isNotEmpty);
  }

  String _humanize(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        final message = data['detail'] ?? data['message'] ?? error.message;
        return (message ?? 'Network error').toString();
      }
      if (data is Map) {
        final mapped = Map<String, dynamic>.from(data);
        final message = mapped['detail'] ?? mapped['message'] ?? error.message;
        return (message ?? 'Network error').toString();
      }
      return (error.message ?? 'Network error').toString();
    }
    return error.toString();
  }
}
