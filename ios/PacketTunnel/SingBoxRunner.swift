import Foundation
import NetworkExtension

final class SingBoxRunner: EmbeddedPacketTunnelEngine {
  let name = "sing-box"
  private var sessionId: String?

  func start(packetFlow: NEPacketTunnelFlow, config: PacketTunnelConnectConfig) throws {
    let configJSON = try SingBoxConfigBuilder.build(from: config)
    sessionId = try EmbeddedCoreBridge.startSingBox(configJSON: configJSON, packetFlow: packetFlow)
  }

  func stop() {
    guard let sessionId else { return }
    EmbeddedCoreBridge.stopSingBox(sessionId: sessionId)
    self.sessionId = nil
  }
}
