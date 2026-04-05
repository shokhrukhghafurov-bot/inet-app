class AppConfig {
  const AppConfig({
    required this.appName,
    required this.supportUrl,
    required this.botUrl,
    required this.maintenanceMode,
    required this.paymentsEnabled,
    required this.defaultDeviceLimit,
    required this.featureFlags,
  });

  final String appName;
  final String supportUrl;
  final String botUrl;
  final bool maintenanceMode;
  final bool paymentsEnabled;
  final int defaultDeviceLimit;
  final Map<String, dynamic> featureFlags;

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    return AppConfig(
      appName: (json['app_name'] ?? 'INET').toString(),
      supportUrl: (json['support_url'] ?? '').toString(),
      botUrl: (json['bot_url'] ?? '').toString(),
      maintenanceMode: json['maintenance_mode'] == true,
      paymentsEnabled: json['payments_enabled'] != false,
      defaultDeviceLimit: _toInt(json['device_limit_default']) ?? 1,
      featureFlags: Map<String, dynamic>.from(
        json['feature_flags'] as Map? ?? const <String, dynamic>{},
      ),
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
