import NetworkExtension

final class PacketTunnelProvider: NEPacketTunnelProvider {
  override func startTunnel(
    options: [String : NSObject]?,
    completionHandler: @escaping (Error?) -> Void
  ) {
    let raw = (protocolConfiguration as? NETunnelProviderProtocol)?.providerConfiguration ?? [:]
    let locationCode = (raw["locationCode"] as? String) ?? "auto"
    let server = (raw["server"] as? String) ?? locationCode
    let mtu = raw["mtu"] as? Int ?? 1400
    let dnsServers = raw["dnsServers"] as? [String] ?? ["1.1.1.1", "8.8.8.8"]

    let settings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: server)
    let ipv4 = NEIPv4Settings(addresses: ["10.200.0.2"], subnetMasks: ["255.255.255.255"])
    ipv4.includedRoutes = [
      NEIPv4Route.default(),
    ]
    settings.ipv4Settings = ipv4

    let ipv6 = NEIPv6Settings(addresses: ["fd00:200::2"], networkPrefixLengths: [128])
    ipv6.includedRoutes = [
      NEIPv6Route.default(),
    ]
    settings.ipv6Settings = ipv6
    settings.dnsSettings = NEDNSSettings(servers: dnsServers)
    settings.mtu = NSNumber(value: mtu)

    setTunnelNetworkSettings(settings) { [weak self] error in
      guard let self else {
        completionHandler(error)
        return
      }
      if let error {
        completionHandler(error)
        return
      }

      // TODO: attach VLESS engine here (xray-core / sing-box / custom transport)
      // and forward packets between packetFlow and the configured outbound.
      _ = locationCode
      completionHandler(nil)
    }
  }

  override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
    completionHandler()
  }
}
