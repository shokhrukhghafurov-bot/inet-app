import Foundation
import NetworkExtension
import Flutter

final class IOSVpnBridge {
  private let stateStore = IOSVpnStateStore()
  private let providerBundleIdentifier = IOSVpnBridge.resolveProviderBundleIdentifier()
  private static let providerBundleIdentifierKey = "INetPacketTunnelBundleIdentifier"

  init() {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(vpnStatusDidChange(_:)),
      name: .NEVPNStatusDidChange,
      object: nil
    )
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "connect":
      guard
        let args = call.arguments as? [String: Any],
        let rawConfig = args["config"] as? [String: Any],
        let config = RunnerVpnConnectConfig(rawConfig),
        config.isComplete
      else {
        result(FlutterError(code: "missing_config", message: "Complete VLESS config is required.", details: nil))
        return
      }
      connect(config: config, result: result)
    case "disconnect":
      disconnect(result: result)
    case "status":
      snapshot(result: { snapshot in
        result(snapshot["status"] ?? IOSVpnStateStore.Status.disconnected.rawValue)
      })
    case "snapshot":
      snapshot(result: result)
    case "appResumed":
      appResumed(result: result)
    case "appBackgrounded":
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func connect(config: RunnerVpnConnectConfig, result: @escaping FlutterResult) {
    stateStore.setStatus(.connecting)
    stateStore.setConfig(config)
    stateStore.setReconnectOnLaunch(true)
    stateStore.setPermissionRequired(false)
    stateStore.clearError()

    loadManager { [weak self] manager, error in
      guard let self else { return }
      if let error {
        self.fail(error, result: result)
        return
      }
      guard let manager else {
        self.failMessage("Unable to create VPN manager.", result: result)
        return
      }

      let proto = NETunnelProviderProtocol()
      proto.providerBundleIdentifier = self.providerBundleIdentifier
      proto.serverAddress = config.server
      proto.providerConfiguration = config.asProviderConfiguration()
      proto.disconnectOnSleep = false

      manager.localizedDescription = "INET VPN"
      manager.protocolConfiguration = proto
      manager.isEnabled = true
      manager.isOnDemandEnabled = false

      manager.saveToPreferences { [weak self] error in
        guard let self else { return }
        if let error {
          self.fail(error, result: result)
          return
        }

        manager.loadFromPreferences { [weak self] error in
          guard let self else { return }
          if let error {
            self.fail(error, result: result)
            return
          }

          do {
            try manager.connection.startVPNTunnel()
            self.stateStore.setStatus(.connecting)
            result(nil)
          } catch {
            self.fail(error, result: result)
          }
        }
      }
    }
  }

  private func disconnect(result: @escaping FlutterResult) {
    loadManager { [weak self] manager, _ in
      guard let self else { return }
      manager?.connection.stopVPNTunnel()
      self.stateStore.setStatus(.disconnected)
      self.stateStore.setReconnectOnLaunch(false)
      self.stateStore.setConnectedAt(nil)
      self.stateStore.clearError()
      result(nil)
    }
  }

  private func snapshot(result: @escaping FlutterResult) {
    loadManager { [weak self] manager, _ in
      guard let self else { return }
      let current = self.stateStore.snapshot(overridingStatus: manager.map { self.mapStatus($0.connection.status) })
      if current["status"] as? String == IOSVpnStateStore.Status.connected.rawValue,
         current["connectedAt"] is NSNull {
        self.stateStore.setConnectedAt(Date())
      }
      result(self.stateStore.snapshot(overridingStatus: manager.map { self.mapStatus($0.connection.status) }))
    }
  }

  private func appResumed(result: @escaping FlutterResult) {
    let snapshot = stateStore.snapshot(overridingStatus: nil)
    if
      (snapshot["reconnectOnLaunch"] as? Bool) == true,
      (snapshot["status"] as? String) == IOSVpnStateStore.Status.disconnected.rawValue,
      let rawConfig = snapshot["config"] as? [String: Any],
      let config = RunnerVpnConnectConfig(rawConfig),
      config.isComplete
    {
      connect(config: config, result: result)
      return
    }
    result(nil)
  }

  @objc private func vpnStatusDidChange(_ notification: Notification) {
    guard let connection = notification.object as? NEVPNConnection else {
      return
    }
    let mappedStatus = mapStatus(connection.status)
    stateStore.setStatus(mappedStatus)
    switch mappedStatus {
    case .connected:
      if stateStore.snapshot(overridingStatus: nil)["connectedAt"] is NSNull {
        stateStore.setConnectedAt(Date())
      }
      stateStore.clearError()
    case .connecting, .disconnecting:
      break
    case .disconnected:
      stateStore.setConnectedAt(nil)
    }
  }

  private func loadManager(completion: @escaping (NETunnelProviderManager?, Error?) -> Void) {
    NETunnelProviderManager.loadAllFromPreferences { [weak self] managers, error in
      if let error {
        completion(nil, error)
        return
      }
      guard let self else {
        completion(nil, nil)
        return
      }

      let tunnelManagers = (managers ?? []).filter { manager in
        manager.protocolConfiguration is NETunnelProviderProtocol
      }

      let exactMatch = tunnelManagers.first(where: { manager in
        guard let proto = manager.protocolConfiguration as? NETunnelProviderProtocol else {
          return false
        }
        return proto.providerBundleIdentifier == self.providerBundleIdentifier
      })
      if let exactMatch {
        completion(exactMatch, nil)
        return
      }

      let legacyMatch = tunnelManagers.first(where: { manager in
        guard let proto = manager.protocolConfiguration as? NETunnelProviderProtocol,
              let bundleIdentifier = proto.providerBundleIdentifier else {
          return false
        }
        return bundleIdentifier.hasSuffix(".PacketTunnel") && manager.localizedDescription == "INET VPN"
      })
      if let legacyMatch {
        completion(legacyMatch, nil)
        return
      }

      completion(NETunnelProviderManager(), nil)
    }
  }

  private func fail(_ error: Error, result: @escaping FlutterResult) {
    stateStore.setStatus(.disconnected)
    stateStore.setConnectedAt(nil)
    stateStore.setError(error.localizedDescription)
    result(FlutterError(code: "vpn_error", message: error.localizedDescription, details: nil))
  }

  private func failMessage(_ message: String, result: @escaping FlutterResult) {
    stateStore.setStatus(.disconnected)
    stateStore.setConnectedAt(nil)
    stateStore.setError(message)
    result(FlutterError(code: "vpn_error", message: message, details: nil))
  }

  private func mapStatus(_ status: NEVPNStatus) -> IOSVpnStateStore.Status {
    switch status {
    case .connected:
      return .connected
    case .connecting, .reasserting:
      return .connecting
    case .disconnecting:
      return .disconnecting
    case .invalid, .disconnected:
      return .disconnected
    @unknown default:
      return .disconnected
    }
  }

  private static func resolveProviderBundleIdentifier() -> String {
    if let explicitValue = Bundle.main.object(forInfoDictionaryKey: providerBundleIdentifierKey) as? String {
      let trimmed = explicitValue.trimmingCharacters(in: .whitespacesAndNewlines)
      if !trimmed.isEmpty {
        return trimmed
      }
    }
    if let appBundleIdentifier = Bundle.main.bundleIdentifier?.trimmingCharacters(in: .whitespacesAndNewlines), !appBundleIdentifier.isEmpty {
      return appBundleIdentifier + ".PacketTunnel"
    }
    return "PacketTunnel"
  }
}

private final class IOSVpnStateStore {
  enum Status: String {
    case disconnected
    case connecting
    case connected
    case disconnecting
    case unsupported
  }

  private let defaults = UserDefaults.standard
  private let prefix = "inet.vpn."

  func setStatus(_ value: Status) {
    defaults.set(value.rawValue, forKey: prefix + "status")
  }

  func setConfig(_ value: RunnerVpnConnectConfig?) {
    if let value {
      defaults.set(value.asProviderConfiguration(), forKey: prefix + "config")
      defaults.set(value.locationCode, forKey: prefix + "locationCode")
      defaults.set(value.protocolName, forKey: prefix + "protocol")
      defaults.set(value.server, forKey: prefix + "server")
      defaults.set(value.transport, forKey: prefix + "transport")
      defaults.set(value.engine, forKey: prefix + "engine")
    } else {
      defaults.removeObject(forKey: prefix + "config")
      defaults.removeObject(forKey: prefix + "locationCode")
      defaults.removeObject(forKey: prefix + "protocol")
      defaults.removeObject(forKey: prefix + "server")
      defaults.removeObject(forKey: prefix + "transport")
      defaults.removeObject(forKey: prefix + "engine")
    }
  }

  func setConnectedAt(_ value: Date?) {
    if let value {
      defaults.set(Int64(value.timeIntervalSince1970 * 1000.0), forKey: prefix + "connectedAt")
    } else {
      defaults.removeObject(forKey: prefix + "connectedAt")
    }
  }

  func setReconnectOnLaunch(_ value: Bool) {
    defaults.set(value, forKey: prefix + "reconnectOnLaunch")
  }

  func setPermissionRequired(_ value: Bool) {
    defaults.set(value, forKey: prefix + "permissionRequired")
  }

  func setError(_ value: String?) {
    defaults.set(value, forKey: prefix + "error")
  }

  func clearError() {
    defaults.removeObject(forKey: prefix + "error")
  }

  func snapshot(overridingStatus status: Status?) -> [String: Any] {
    let rawStatus = status?.rawValue ?? defaults.string(forKey: prefix + "status") ?? Status.disconnected.rawValue
    let connectedAt = defaults.object(forKey: prefix + "connectedAt") as? Int64
    return [
      "status": rawStatus,
      "error": defaults.string(forKey: prefix + "error") ?? NSNull(),
      "locationCode": defaults.string(forKey: prefix + "locationCode") ?? NSNull(),
      "connectedAt": connectedAt ?? NSNull(),
      "reconnectOnLaunch": defaults.bool(forKey: prefix + "reconnectOnLaunch"),
      "permissionRequired": defaults.bool(forKey: prefix + "permissionRequired"),
      "protocol": defaults.string(forKey: prefix + "protocol") ?? NSNull(),
      "server": defaults.string(forKey: prefix + "server") ?? NSNull(),
      "transport": defaults.string(forKey: prefix + "transport") ?? NSNull(),
      "engine": defaults.string(forKey: prefix + "engine") ?? NSNull(),
      "config": defaults.dictionary(forKey: prefix + "config") ?? NSNull(),
    ]
  }
}
