class VpnSnapshot {
  const VpnSnapshot({
    required this.status,
    this.errorMessage,
    this.locationCode,
    this.connectedAt,
    this.reconnectOnLaunch = false,
    this.permissionRequired = false,
    this.protocol,
    this.server,
    this.transport,
    this.engine,
  });

  factory VpnSnapshot.fromMap(Map<Object?, Object?>? map) {
    if (map == null) {
      return const VpnSnapshot(status: 'disconnected');
    }

    final rawStatus = map['status']?.toString().trim();
    final rawError = map['error']?.toString().trim();
    final rawLocation = map['locationCode']?.toString().trim();
    final rawConnectedAt = map['connectedAt'];
    final rawReconnectOnLaunch = map['reconnectOnLaunch'];
    final rawPermissionRequired = map['permissionRequired'];
    final rawProtocol = map['protocol']?.toString().trim();
    final rawServer = map['server']?.toString().trim();
    final rawTransport = map['transport']?.toString().trim();
    final rawEngine = map['engine']?.toString().trim();

    DateTime? connectedAt;
    if (rawConnectedAt is int && rawConnectedAt > 0) {
      connectedAt = DateTime.fromMillisecondsSinceEpoch(rawConnectedAt, isUtc: true).toLocal();
    } else if (rawConnectedAt is String && rawConnectedAt.isNotEmpty) {
      connectedAt = DateTime.tryParse(rawConnectedAt)?.toLocal();
    }

    return VpnSnapshot(
      status: rawStatus == null || rawStatus.isEmpty ? 'disconnected' : rawStatus,
      errorMessage: rawError == null || rawError.isEmpty ? null : rawError,
      locationCode: rawLocation == null || rawLocation.isEmpty ? null : rawLocation,
      connectedAt: connectedAt,
      reconnectOnLaunch: rawReconnectOnLaunch == true,
      permissionRequired: rawPermissionRequired == true,
      protocol: rawProtocol == null || rawProtocol.isEmpty ? null : rawProtocol,
      server: rawServer == null || rawServer.isEmpty ? null : rawServer,
      transport: rawTransport == null || rawTransport.isEmpty ? null : rawTransport,
      engine: rawEngine == null || rawEngine.isEmpty ? null : rawEngine,
    );
  }

  final String status;
  final String? errorMessage;
  final String? locationCode;
  final DateTime? connectedAt;
  final bool reconnectOnLaunch;
  final bool permissionRequired;
  final String? protocol;
  final String? server;
  final String? transport;
  final String? engine;
}
