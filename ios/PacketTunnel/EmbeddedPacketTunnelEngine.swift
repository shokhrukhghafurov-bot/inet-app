import Foundation
import NetworkExtension

protocol EmbeddedPacketTunnelEngine: AnyObject {
  var name: String { get }
  func start(packetFlow: NEPacketTunnelFlow, config: PacketTunnelConnectConfig) throws
  func stop()
}

enum EmbeddedPacketTunnelEngineFactory {
  static func make(config: PacketTunnelConnectConfig) -> EmbeddedPacketTunnelEngine {
    switch config.engine.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
    case "xray", "xray-core":
      return XrayRunner()
    default:
      return SingBoxRunner()
    }
  }
}
