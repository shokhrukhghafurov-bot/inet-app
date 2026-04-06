import Foundation
import NetworkExtension

@objc protocol IOSSingBoxRuntime {
  func start() throws
  func stop()
}

@objc protocol IOSSingBoxRuntimeFactory {
  func createRuntime(_ context: ObjCSingBoxLaunchContext) throws -> AnyObject
}

@objcMembers
final class ObjCSingBoxLaunchContext: NSObject {
  let sessionId: String
  let configJSON: String
  let configURL: URL
  let workingDirectory: URL
  let provider: NEPacketTunnelProvider
  let packetFlow: NEPacketTunnelFlow

  init(context: SingBoxLaunchContext) {
    self.sessionId = context.sessionId
    self.configJSON = context.configJSON
    self.configURL = context.configURL
    self.workingDirectory = context.workingDirectory
    self.provider = context.provider
    self.packetFlow = context.packetFlow
    super.init()
  }
}

@objc(LibboxSingBoxBinding)
final class LibboxSingBoxBinding: NSObject, IOSSingBoxBinding {
  func start(context: SingBoxLaunchContext) throws -> IOSSingBoxSessionBox {
    try Self.initializeOptionalLibboxRuntime()
    let runtimeFactory = try Self.resolveRuntimeFactory()
    let runtimeObject = try runtimeFactory.createRuntime(ObjCSingBoxLaunchContext(context: context))
    guard let runtime = runtimeObject as? IOSSingBoxRuntime else {
      throw NSError(
        domain: "inet.vpn",
        code: -3,
        userInfo: [
          NSLocalizedDescriptionKey: "The iOS libbox runtime factory must return an object conforming to IOSSingBoxRuntime."
        ]
      )
    }

    do {
      try runtime.start()
    } catch {
      runtime.stop()
      throw error
    }

    return IOSSingBoxSessionBox {
      runtime.stop()
    }
  }

  private static func resolveRuntimeFactory() throws -> IOSSingBoxRuntimeFactory {
    let candidates = [
      Bundle.main.object(forInfoDictionaryKey: infoPlistFactoryClassKey) as? String,
      defaultFactoryClass,
      alternateFactoryClass,
      legacyFactoryClass,
    ]
      .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
      .filter { !$0.isEmpty }

    for className in candidates {
      guard let type = NSClassFromString(className) as? NSObject.Type else {
        continue
      }
      let instance = type.init()
      if let factory = instance as? IOSSingBoxRuntimeFactory {
        return factory
      }
    }

    throw NSError(
      domain: "inet.vpn",
      code: -3,
      userInfo: [
        NSLocalizedDescriptionKey:
          "No iOS libbox runtime factory found. Add a class conforming to IOSSingBoxRuntimeFactory and point \(infoPlistFactoryClassKey) to it (or use \(defaultFactoryClass))."
      ]
    )
  }

  private static func initializeOptionalLibboxRuntime() throws {
    objc_sync_enter(initLock)
    defer { objc_sync_exit(initLock) }
    if optionalInitDone {
      return
    }
    optionalInitDone = true
  }

  private static let infoPlistFactoryClassKey = "SINGBOX_RUNTIME_FACTORY_CLASS"
  private static let defaultFactoryClass = "PacketTunnel.LibboxRuntimeFactory"
  private static let alternateFactoryClass = "PacketTunnel.MobileLibboxRuntimeFactory"
  private static let legacyFactoryClass = "LibboxRuntimeFactory"
  private static let initLock = NSObject()
  private static var optionalInitDone = false
}
