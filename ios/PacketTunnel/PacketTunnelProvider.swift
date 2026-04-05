import NetworkExtension

final class PacketTunnelProvider: NEPacketTunnelProvider {
  private var engine: EmbeddedPacketTunnelEngine?

  override func startTunnel(
    options: [String : NSObject]?,
    completionHandler: @escaping (Error?) -> Void
  ) {
    let raw = (protocolConfiguration as? NETunnelProviderProtocol)?.providerConfiguration ?? [:]
    guard let config = PacketTunnelConnectConfig(raw), config.isComplete else {
      completionHandler(NSError(domain: "inet.vpn", code: -1, userInfo: [NSLocalizedDescriptionKey: "Complete VLESS config is required."]))
      return
    }

    let settings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: config.server)
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
    settings.dnsSettings = NEDNSSettings(servers: config.dnsServers)
    settings.mtu = NSNumber(value: config.mtu)

    setTunnelNetworkSettings(settings) { [weak self] error in
      guard let self else {
        completionHandler(error)
        return
      }
      if let error {
        completionHandler(error)
        return
      }

      do {
        let selectedEngine = EmbeddedPacketTunnelEngineFactory.make(config: config)
        try selectedEngine.start(packetFlow: self.packetFlow, config: config)
        self.engine = selectedEngine
        completionHandler(nil)
      } catch {
        self.engine?.stop()
        self.engine = nil
        completionHandler(error)
      }
    }
  }

  override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
    engine?.stop()
    engine = nil
    completionHandler()
  }
}
