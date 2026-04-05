import Foundation
import NetworkExtension

final class IOSSingBoxSessionBox {
  let stopHandler: () -> Void

  init(stopHandler: @escaping () -> Void) {
    self.stopHandler = stopHandler
  }

  func stop() {
    stopHandler()
  }
}

struct SingBoxLaunchContext {
  let sessionId: String
  let configJSON: String
  let configURL: URL
  let workingDirectory: URL
  let packetFlow: NEPacketTunnelFlow
}

protocol IOSSingBoxBinding {
  func start(context: SingBoxLaunchContext) throws -> IOSSingBoxSessionBox
}

enum EmbeddedCoreBridgeError: LocalizedError {
  case missingSingBoxBinding
  case failedToCreateRuntimeDirectory

  var errorDescription: String? {
    switch self {
    case .missingSingBoxBinding:
      return "No iOS sing-box binding found. Add a class named LibboxSingBoxBinding that conforms to IOSSingBoxBinding and starts the embedded core."
    case .failedToCreateRuntimeDirectory:
      return "Unable to create the iOS sing-box runtime directory."
    }
  }
}

enum EmbeddedCoreBridge {
  private static var bindingOverride: IOSSingBoxBinding?
  private static var sessions: [String: IOSSingBoxSessionBox] = [:]
  private static let defaultBindingClassNames = [
    "LibboxSingBoxBinding",
    "PacketTunnel.LibboxSingBoxBinding",
    "Runner.LibboxSingBoxBinding",
  ]

  static func installSingBoxBinding(_ binding: IOSSingBoxBinding) {
    bindingOverride = binding
  }

  static func clearSingBoxBindingOverride() {
    bindingOverride = nil
  }

  static func startSingBox(configJSON: String, packetFlow: NEPacketTunnelFlow) throws -> String {
    let binding = try resolveSingBoxBinding()
    let sessionId = UUID().uuidString
    let runtimeDirectory = try prepareRuntimeDirectory(sessionId: sessionId)
    let configURL = runtimeDirectory.appendingPathComponent("sing-box.json")
    try configJSON.write(to: configURL, atomically: true, encoding: .utf8)

    do {
      let session = try binding.start(
        context: SingBoxLaunchContext(
          sessionId: sessionId,
          configJSON: configJSON,
          configURL: configURL,
          workingDirectory: runtimeDirectory,
          packetFlow: packetFlow
        )
      )
      sessions[sessionId] = session
      return sessionId
    } catch {
      try? FileManager.default.removeItem(at: runtimeDirectory)
      throw error
    }
  }

  static func stopSingBox(sessionId: String) {
    let session = sessions.removeValue(forKey: sessionId)
    session?.stop()
  }

  static func startXray(configJSON: String, packetFlow: NEPacketTunnelFlow) throws -> String {
    throw NSError(domain: "inet.vpn", code: -2, userInfo: [NSLocalizedDescriptionKey: "Xray bridge is not implemented in this patch. Keep engine=sing-box."])
  }

  static func stopXray(sessionId: String) {
    // Intentionally left blank until an Xray binding exists.
  }

  private static func prepareRuntimeDirectory(sessionId: String) throws -> URL {
    let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
      ?? FileManager.default.temporaryDirectory
    let runtime = base
      .appendingPathComponent("inet-singbox", isDirectory: true)
      .appendingPathComponent(sessionId, isDirectory: true)
    do {
      try FileManager.default.createDirectory(at: runtime, withIntermediateDirectories: true)
      return runtime
    } catch {
      throw EmbeddedCoreBridgeError.failedToCreateRuntimeDirectory
    }
  }

  private static func resolveSingBoxBinding() throws -> IOSSingBoxBinding {
    if let bindingOverride {
      return bindingOverride
    }

    for className in defaultBindingClassNames {
      if let type = NSClassFromString(className) as? NSObject.Type,
         let instance = type.init() as? IOSSingBoxBinding {
        return instance
      }
    }

    throw EmbeddedCoreBridgeError.missingSingBoxBinding
  }
}
