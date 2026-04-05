class VlessConfig {
  const VlessConfig({
    required this.locationCode,
    required this.server,
    required this.port,
    required this.uuid,
    this.remark,
    this.transport = 'tcp',
    this.security = 'reality',
    this.flow,
    this.sni,
    this.host,
    this.path,
    this.serviceName,
    this.publicKey,
    this.shortId,
    this.fingerprint,
    this.allowInsecure = false,
    this.mtu = 1400,
    this.dnsServers = const ['1.1.1.1', '8.8.8.8'],
    this.alpn = const <String>[],
  });

  factory VlessConfig.fromJson(Map<String, dynamic> json, {String? fallbackLocationCode}) {
    final rawDns = json['dns_servers'] ?? json['dnsServers'];
    final rawAlpn = json['alpn'];

    return VlessConfig(
      locationCode: (json['location_code'] ?? json['locationCode'] ?? fallbackLocationCode ?? '').toString(),
      server: (json['server'] ?? '').toString(),
      port: int.tryParse((json['port'] ?? '').toString()) ?? 443,
      uuid: (json['uuid'] ?? '').toString(),
      remark: (json['remark'] ?? json['name'] ?? json['display_name'])?.toString(),
      transport: (json['transport'] ?? 'tcp').toString(),
      security: (json['security'] ?? 'reality').toString(),
      flow: json['flow']?.toString(),
      sni: (json['sni'] ?? json['server_name'])?.toString(),
      host: json['host']?.toString(),
      path: json['path']?.toString(),
      serviceName: (json['service_name'] ?? json['serviceName'])?.toString(),
      publicKey: (json['public_key'] ?? json['publicKey'])?.toString(),
      shortId: (json['short_id'] ?? json['shortId'])?.toString(),
      fingerprint: json['fingerprint']?.toString(),
      allowInsecure: json['allow_insecure'] == true || json['allowInsecure'] == true,
      mtu: int.tryParse((json['mtu'] ?? '').toString()) ?? 1400,
      dnsServers: rawDns is List
          ? rawDns.map((item) => item.toString()).where((item) => item.isNotEmpty).toList(growable: false)
          : const ['1.1.1.1', '8.8.8.8'],
      alpn: rawAlpn is List
          ? rawAlpn.map((item) => item.toString()).where((item) => item.isNotEmpty).toList(growable: false)
          : const <String>[],
    );
  }

  final String locationCode;
  final String server;
  final int port;
  final String uuid;
  final String? remark;
  final String transport;
  final String security;
  final String? flow;
  final String? sni;
  final String? host;
  final String? path;
  final String? serviceName;
  final String? publicKey;
  final String? shortId;
  final String? fingerprint;
  final bool allowInsecure;
  final int mtu;
  final List<String> dnsServers;
  final List<String> alpn;

  bool get isComplete =>
      locationCode.trim().isNotEmpty && server.trim().isNotEmpty && port > 0 && uuid.trim().isNotEmpty;

  String get displayName => remark?.trim().isNotEmpty == true ? remark!.trim() : locationCode;

  Map<String, dynamic> toMap() {
    return {
      'protocol': 'vless',
      'locationCode': locationCode,
      'server': server,
      'port': port,
      'uuid': uuid,
      'remark': remark,
      'transport': transport,
      'security': security,
      'flow': flow,
      'sni': sni,
      'host': host,
      'path': path,
      'serviceName': serviceName,
      'publicKey': publicKey,
      'shortId': shortId,
      'fingerprint': fingerprint,
      'allowInsecure': allowInsecure,
      'mtu': mtu,
      'dnsServers': dnsServers,
      'alpn': alpn,
    };
  }
}
