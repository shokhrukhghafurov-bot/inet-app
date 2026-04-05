import Foundation

struct PacketTunnelConnectConfig {
  init?(_ raw: [String: Any]) {
    self.raw = raw
    let protocolName = Self.normalizedString(raw["protocol"])
    self.protocolName = protocolName.isEmpty ? "vless" : protocolName
    self.locationCode = Self.normalizedString(raw["locationCode"] ?? raw["location_code"])
    self.server = Self.normalizedString(raw["server"])
    self.port = Self.normalizedInt(raw["port"]) ?? Self.normalizedInt(raw["server_port"]) ?? 443
    self.uuid = Self.normalizedString(raw["uuid"] ?? raw["id"])

    let incomingEngine = Self.normalizedString(raw["engine"])
    self.engine = Self.resolveEngine(incomingEngine)
    self.remark = Self.optionalString(raw["remark"])
    self.transport = Self.normalizedString(raw["transport"] ?? raw["network"], defaultValue: "tcp")
    self.security = Self.normalizedString(raw["security"], defaultValue: "reality")
    self.flow = Self.optionalString(raw["flow"])
    self.sni = Self.optionalString(raw["sni"] ?? raw["serverName"] ?? raw["server_name"])
    self.host = Self.optionalString(raw["host"])
    self.path = Self.optionalString(raw["path"])
    self.serviceName = Self.optionalString(raw["serviceName"] ?? raw["service_name"])
    self.publicKey = Self.optionalString(raw["publicKey"] ?? raw["public_key"])
    self.shortId = Self.optionalString(raw["shortId"] ?? raw["short_id"])
    self.fingerprint = Self.optionalString(raw["fingerprint"])
    self.allowInsecure = Self.normalizedBool(raw["allowInsecure"]) ?? Self.normalizedBool(raw["allow_insecure"]) ?? false
    self.mtu = Self.normalizedInt(raw["mtu"]) ?? 1400

    let resolvedDnsServers = Self.normalizeStringArray(raw["dnsServers"]) + Self.normalizeStringArray(raw["dns_servers"])
    self.dnsServers = resolvedDnsServers.isEmpty ? ["1.1.1.1", "8.8.8.8"] : Self.orderedUniqueStrings(resolvedDnsServers)
    self.alpn = Self.normalizeStringArray(raw["alpn"])
    self.domainResolver = Self.optionalString(raw["domainResolver"] ?? raw["domain_resolver"])
    self.packetEncoding = Self.optionalString(raw["packetEncoding"] ?? raw["packet_encoding"])
    self.rawSingBoxConfig = Self.optionalString(raw["rawSingBoxConfig"] ?? raw["raw_sing_box_config"])
    self.rawXrayConfig = Self.optionalString(raw["rawXrayConfig"] ?? raw["raw_xray_config"])
  }

  let raw: [String: Any]
  let protocolName: String
  let locationCode: String
  let server: String
  let port: Int
  let uuid: String
  let engine: String
  let remark: String?
  let transport: String
  let security: String
  let flow: String?
  let sni: String?
  let host: String?
  let path: String?
  let serviceName: String?
  let publicKey: String?
  let shortId: String?
  let fingerprint: String?
  let allowInsecure: Bool
  let mtu: Int
  let dnsServers: [String]
  let alpn: [String]
  let domainResolver: String?
  let packetEncoding: String?
  let rawSingBoxConfig: String?
  let rawXrayConfig: String?

  private static func normalizedString(_ value: Any?, defaultValue: String = "") -> String {
    let rawText: String
    if let value = value as? String {
      rawText = value
    } else if let value {
      rawText = String(describing: value)
    } else {
      return defaultValue
    }
    let trimmed = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.isEmpty ? defaultValue : trimmed
  }

  private static func optionalString(_ value: Any?) -> String? {
    let text = normalizedString(value)
    return text.isEmpty ? nil : text
  }

  private static func normalizedInt(_ value: Any?) -> Int? {
    if let value = value as? Int { return value }
    if let value = value as? NSNumber { return value.intValue }
    if let value = value as? String {
      let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
      return trimmed.isEmpty ? nil : Int(trimmed)
    }
    return nil
  }

  private static func normalizedBool(_ value: Any?) -> Bool? {
    if let value = value as? Bool { return value }
    if let value = value as? NSNumber { return value.boolValue }
    if let value = value as? String {
      switch value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
      case "1", "true", "yes", "y", "on":
        return true
      case "0", "false", "no", "n", "off":
        return false
      default:
        return nil
      }
    }
    return nil
  }

  private static func normalizeStringArray(_ value: Any?) -> [String] {
    if let values = value as? [Any] {
      return values.compactMap { item in
        let text = normalizedString(item)
        return text.isEmpty ? nil : text
      }
    }
    if let value = value as? String {
      return value
        .split(separator: ",")
        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }
    }
    return []
  }

  private static func orderedUniqueStrings(_ values: [String]) -> [String] {
    var seen = Set<String>()
    var result: [String] = []
    for value in values where !seen.contains(value) {
      seen.insert(value)
      result.append(value)
    }
    return result
  }

  private static func resolveEngine(_ rawEngine: String) -> String {
    let normalized = rawEngine.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    if normalized.isEmpty || normalized == "xray" || normalized == "xray-core" {
      return "sing-box"
    }
    return rawEngine
  }

  var isComplete: Bool {
    !locationCode.isEmpty && !server.isEmpty && port > 0 && !uuid.isEmpty
  }

  func asProviderConfiguration() -> [String: Any] {
    var config = raw
    config["protocol"] = protocolName
    config["locationCode"] = locationCode
    config["server"] = server
    config["port"] = port
    config["uuid"] = uuid
    config["engine"] = engine
    config["remark"] = remark
    config["transport"] = transport
    config["network"] = transport
    config["security"] = security
    config["flow"] = flow
    config["sni"] = sni
    config["serverName"] = sni
    config["host"] = host
    config["path"] = path
    config["serviceName"] = serviceName
    config["publicKey"] = publicKey
    config["shortId"] = shortId
    config["fingerprint"] = fingerprint
    config["allowInsecure"] = allowInsecure
    config["mtu"] = mtu
    config["dnsServers"] = dnsServers
    config["alpn"] = alpn
    config["domainResolver"] = domainResolver
    config["packetEncoding"] = packetEncoding
    config["rawSingBoxConfig"] = rawSingBoxConfig
    config["rawXrayConfig"] = rawXrayConfig
    return config
  }
}
