import 'subscription.dart';
import 'user.dart';

class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    this.user,
    this.subscription,
    this.language,
  });

  final String accessToken;
  final String refreshToken;
  final AppUser? user;
  final Subscription? subscription;
  final String? language;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final token = (json['access_token'] ?? json['token'] ?? '').toString();
    final userMap = _mapOrNull(json['user']);
    final subMap = _mapOrNull(json['subscription']);

    return AuthSession(
      accessToken: token,
      refreshToken: (json['refresh_token'] ?? token).toString(),
      user: userMap == null ? null : AppUser.fromJson(userMap),
      subscription: subMap == null ? null : Subscription.fromJson(subMap),
      language: json['language']?.toString() ?? userMap?['language']?.toString(),
    );
  }

  AuthSession copyWith({
    String? accessToken,
    String? refreshToken,
    AppUser? user,
    Subscription? subscription,
    String? language,
  }) {
    return AuthSession(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      user: user ?? this.user,
      subscription: subscription ?? this.subscription,
      language: language ?? this.language,
    );
  }

  static Map<String, dynamic>? _mapOrNull(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return null;
  }
}
