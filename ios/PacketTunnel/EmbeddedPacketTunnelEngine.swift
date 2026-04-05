import Foundation
import NetworkExtension

protocol EmbeddedPacketTunnelEngine: AnyObject {
  var name: String { get }
  func start(provider: NEPacketTunnelProvider, config: PacketTunnelConnectConfig) throws
  func stop()
}

enum EmbeddedPacketTunnelEngineFactory {
  static func make(config: PacketTunnelConnectConfig) -> EmbeddedPacketTunnelEngine {
    return SingBoxRunner()
  }
}
