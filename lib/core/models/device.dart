class Device {
  const Device({
    required this.id,
    required this.name,
    this.platform,
    this.lastActiveAt,
    this.current = false,
  });

  final String id;
  final String name;
  final String? platform;
  final DateTime? lastActiveAt;
  final bool current;

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: (json['id'] ?? json['device_id'] ?? '').toString(),
      name: (json['name'] ?? json['device_name'] ?? 'Unknown device').toString(),
      platform: json['platform']?.toString(),
      lastActiveAt: _toDate(json['last_active_at'] ?? json['last_active'] ?? json['last_seen_at']),
      current: json['current'] == true || json['is_current'] == true,
    );
  }

  static DateTime? _toDate(dynamic value) {
    if (value == null) {
      return null;
    }
    return DateTime.tryParse(value.toString());
  }
}
