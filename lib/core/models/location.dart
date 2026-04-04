class VpnLocation {
  const VpnLocation({
    required this.code,
    required this.name,
    required this.status,
    this.nameRu,
    this.nameEn,
    this.recommended = false,
    this.reserve = false,
  });

  final String code;
  final String name;
  final String status;
  final String? nameRu;
  final String? nameEn;
  final bool recommended;
  final bool reserve;

  bool get isOnline => status.toLowerCase() == 'online';

  factory VpnLocation.fromJson(Map<String, dynamic> json) {
    final nameRu = (json['display_name_ru'] ?? json['name_ru'])?.toString();
    final nameEn = (json['display_name_en'] ?? json['name_en'])?.toString();

    return VpnLocation(
      code: (json['code'] ?? json['id'] ?? '').toString(),
      name: (json['name'] ?? nameRu ?? nameEn ?? json['title'] ?? 'Location').toString(),
      status: (json['status'] ?? 'offline').toString(),
      nameRu: nameRu,
      nameEn: nameEn,
      recommended: json['recommended'] == true || json['is_recommended'] == true,
      reserve: json['reserve'] == true || json['is_reserve'] == true,
    );
  }

  String localizedName(String languageCode) {
    return switch (languageCode) {
      'en' => nameEn ?? nameRu ?? name,
      _ => nameRu ?? nameEn ?? name,
    };
  }

  VpnLocation copyWith({
    String? code,
    String? name,
    String? status,
    String? nameRu,
    String? nameEn,
    bool? recommended,
    bool? reserve,
  }) {
    return VpnLocation(
      code: code ?? this.code,
      name: name ?? this.name,
      status: status ?? this.status,
      nameRu: nameRu ?? this.nameRu,
      nameEn: nameEn ?? this.nameEn,
      recommended: recommended ?? this.recommended,
      reserve: reserve ?? this.reserve,
    );
  }
}
