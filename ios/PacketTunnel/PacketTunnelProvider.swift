import NetworkExtension

final class PacketTunnelProvider: NEPacketTunnelProvider {
  private var engine: EmbeddedPacketTunnelEngine?

  override func startTunnel(
    options: [String : NSObject]?,
    completionHandler: @escaping (Error?) -> Void
  ) {
    let savedConfiguration = (protocolConfiguration as? NETunnelProviderProtocol)?.providerConfiguration ?? [:]
    let runtimeOptions = options ?? [:]
    let mergedConfiguration = savedConfiguration.merging(runtimeOptions.mapValues { $0 as Any }) { _, new in new }

    guard let config = PacketTunnelConnectConfig(mergedConfiguration), config.isComplete else {
      completionHandler(NSError(domain: "inet.vpn", code: -1, userInfo: [NSLocalizedDescriptionKey: "Complete VLESS config is required."]))
      return
    }

    do {
      let selectedEngine = EmbeddedPacketTunnelEngineFactory.make(config: config)
      try selectedEngine.start(provider: self, config: config)
      self.engine = selectedEngine
      completionHandler(nil)
    } catch {
      self.engine?.stop()
      self.engine = nil
      completionHandler(error)
    }
  }

  override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
    engine?.stop()
    engine = nil
    completionHandler()
  }
}
