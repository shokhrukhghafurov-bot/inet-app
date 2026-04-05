import Foundation
import NetworkExtension

final class XrayRunner: EmbeddedPacketTunnelEngine {
  let name = "xray-core"
  private var sessionId: String?

  func start(packetFlow: NEPacketTunnelFlow, config: PacketTunnelConnectConfig) throws {
    let configJSON = try XrayConfigBuilder.build(from: config)
    sessionId = try EmbeddedCoreBridge.startXray(configJSON: configJSON, packetFlow: packetFlow)
  }

  func stop() {
    guard let sessionId else { return }
    EmbeddedCoreBridge.stopXray(sessionId: sessionId)
    self.sessionId = nil
  }
}
