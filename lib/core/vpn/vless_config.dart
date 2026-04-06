class VlessConfig {
  const VlessConfig({
    required this.locationCode,
    required this.server,
    required this.port,
    required this.uuid,
    this.engine = 'sing-box',
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
    this.domainResolver,
    this.packetEncoding,
    this.rawSingBoxConfig,
    this.rawXrayConfig,
  });

  factory VlessConfig.fromJson(Map<String, dynamic> json, {String? fallbackLocationCode}) {
    final rawDns = json['dns_servers'] ?? json['dnsServers'];
    final rawAlpn = json['alpn'];
    final resolvedDnsServers = rawDns is List
        ? rawDns
            .map((item) => item.toString().trim())
            .where((item) => item.isNotEmpty)
            .toList(growable: false)
        : const <String>[];
    final resolvedAlpn = rawAlpn is List
        ? rawAlpn
            .map((item) => item.toString().trim())
            .where((item) => item.isNotEmpty)
            .toList(growable: false)
        : const <String>[];
    final resolvedEngine = _resolveEngine(
      (json['engine'] ?? 'sing-box').toString(),
      rawSingBoxConfig: (json['raw_sing_box_config'] ?? json['rawSingBoxConfig'])?.toString(),
      rawXrayConfig: (json['raw_xray_config'] ?? json['rawXrayConfig'])?.toString(),
    );

    return VlessConfig(
      locationCode: (json['location_code'] ?? json['locationCode'] ?? fallbackLocationCode ?? '').toString(),
      server: (json['server'] ?? '').toString(),
      port: int.tryParse((json['port'] ?? '').toString()) ?? 443,
      uuid: (json['uuid'] ?? '').toString(),
      engine: resolvedEngine,
      remark: (json['remark'] ?? json['name'] ?? json['display_name'])?.toString(),
      transport: (json['transport'] ?? json['network'] ?? 'tcp').toString(),
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
      dnsServers: resolvedDnsServers.isEmpty ? const ['1.1.1.1', '8.8.8.8'] : resolvedDnsServers,
      alpn: resolvedAlpn,
      domainResolver: (json['domain_resolver'] ?? json['domainResolver'])?.toString(),
      packetEncoding: (json['packet_encoding'] ?? json['packetEncoding'])?.toString(),
      rawSingBoxConfig: (json['raw_sing_box_config'] ?? json['rawSingBoxConfig'])?.toString(),
      rawXrayConfig: (json['raw_xray_config'] ?? json['rawXrayConfig'])?.toString(),
    );
  }

  final String locationCode;
  final String server;
  final int port;
  final String uuid;
  final String engine;
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
  final String? domainResolver;
  final String? packetEncoding;
  final String? rawSingBoxConfig;
  final String? rawXrayConfig;
  static String _resolveEngine(
    String rawEngine, {
    String? rawSingBoxConfig,
    String? rawXrayConfig,
  }) {
    final normalized = rawEngine.trim().toLowerCase();
    if (normalized == 'xray' || normalized == 'xray-core') {
      return 'sing-box';
    }
    if (normalized.isEmpty) {
      return 'sing-box';
    }
    return rawEngine;
  }

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
      'engine': engine,
      'remark': remark,
      'transport': transport,
      'network': transport,
      'security': security,
      'flow': flow,
      'sni': sni,
      'serverName': sni,
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
      'domainResolver': domainResolver,
      'packetEncoding': packetEncoding,
      'rawSingBoxConfig': rawSingBoxConfig,
      'rawXrayConfig': rawXrayConfig,
    };
  }
}
