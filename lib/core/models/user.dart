class AppUser {
  const AppUser({
    required this.id,
    this.telegramId,
    required this.displayName,
    this.username,
    this.language,
    this.blocked = false,
  });

  final String id;
  final int? telegramId;
  final String displayName;
  final String? username;
  final String? language;
  final bool blocked;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    final firstName = json['first_name']?.toString().trim() ?? '';
    final lastName = json['last_name']?.toString().trim() ?? '';
    final fullName = [firstName, lastName].where((item) => item.isNotEmpty).join(' ').trim();
    final displayName = (json['display_name'] ??
            json['name'] ??
            (fullName.isNotEmpty ? fullName : null) ??
            json['username'] ??
            'User')
        .toString();

    return AppUser(
      id: (json['id'] ?? json['user_id'] ?? '').toString(),
      telegramId: _toInt(json['telegram_id']),
      displayName: displayName,
      username: json['username']?.toString(),
      language: json['language']?.toString(),
      blocked: json['blocked'] == true || json['is_blocked'] == true || json['status'] == 'blocked',
    );
  }

  AppUser copyWith({
    String? id,
    int? telegramId,
    String? displayName,
    String? username,
    String? language,
    bool? blocked,
  }) {
    return AppUser(
      id: id ?? this.id,
      telegramId: telegramId ?? this.telegramId,
      displayName: displayName ?? this.displayName,
      username: username ?? this.username,
      language: language ?? this.language,
      blocked: blocked ?? this.blocked,
    );
  }

  static int? _toInt(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value;
    }
    return int.tryParse(value.toString());
  }
}
