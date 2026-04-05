class Subscription {
  const Subscription({
    required this.status,
    this.planCode,
    this.planName,
    this.planNameRu,
    this.planNameEn,
    this.expiresAt,
    this.deviceLimit,
    this.devicesUsed,
  });

  final String status;
  final String? planCode;
  final String? planName;
  final String? planNameRu;
  final String? planNameEn;
  final DateTime? expiresAt;
  final int? deviceLimit;
  final int? devicesUsed;

  bool get isActive => status.toLowerCase() == 'active';

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      status: (json['status'] ?? 'inactive').toString(),
      planCode: (json['plan_code'] ?? json['code'])?.toString(),
      planName: (json['plan_name'] ?? json['plan'] ?? json['name_ru'] ?? json['name_en'])?.toString(),
      planNameRu: json['name_ru']?.toString(),
      planNameEn: json['name_en']?.toString(),
      expiresAt: _toDate(json['expires_at'] ?? json['expires']),
      deviceLimit: _toInt(json['device_limit']),
      devicesUsed: _toInt(json['devices_used']),
    );
  }

  String localizedPlanName(String languageCode) {
    return switch (languageCode) {
      'en' => planNameEn ?? planName ?? planNameRu ?? '',
      _ => planNameRu ?? planName ?? planNameEn ?? '',
    };
  }

  Subscription copyWith({
    String? status,
    String? planCode,
    String? planName,
    String? planNameRu,
    String? planNameEn,
    DateTime? expiresAt,
    int? deviceLimit,
    int? devicesUsed,
  }) {
    return Subscription(
      status: status ?? this.status,
      planCode: planCode ?? this.planCode,
      planName: planName ?? this.planName,
      planNameRu: planNameRu ?? this.planNameRu,
      planNameEn: planNameEn ?? this.planNameEn,
      expiresAt: expiresAt ?? this.expiresAt,
      deviceLimit: deviceLimit ?? this.deviceLimit,
      devicesUsed: devicesUsed ?? this.devicesUsed,
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

  static DateTime? _toDate(dynamic value) {
    if (value == null) {
      return null;
    }
    return DateTime.tryParse(value.toString());
  }
}
