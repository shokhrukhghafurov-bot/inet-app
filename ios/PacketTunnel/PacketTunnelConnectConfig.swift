import Foundation

struct PacketTunnelConnectConfig {
  init?(_ raw: [String: Any]) {
    self.raw = raw
    self.protocolName = (raw["protocol"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false ? (raw["protocol"] as? String)! : "vless"
    self.locationCode = ((raw["locationCode"] ?? raw["location_code"]) as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    self.server = (raw["server"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    self.port = raw["port"] as? Int ?? Int((raw["port"] as? String) ?? "") ?? raw["server_port"] as? Int ?? Int((raw["server_port"] as? String) ?? "") ?? 443
    self.uuid = ((raw["uuid"] ?? raw["id"]) as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    let incomingEngine = (raw["engine"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    self.engine = Self.resolveEngine(incomingEngine)
    self.remark = raw["remark"] as? String
    self.transport = (raw["transport"] as? String) ?? (raw["network"] as? String) ?? "tcp"
    self.security = raw["security"] as? String ?? "reality"
    self.flow = raw["flow"] as? String
    self.sni = (raw["sni"] as? String) ?? (raw["serverName"] as? String) ?? (raw["server_name"] as? String)
    self.host = raw["host"] as? String
    self.path = raw["path"] as? String
    self.serviceName = (raw["serviceName"] as? String) ?? (raw["service_name"] as? String)
    self.publicKey = (raw["publicKey"] as? String) ?? (raw["public_key"] as? String)
    self.shortId = (raw["shortId"] as? String) ?? (raw["short_id"] as? String)
    self.fingerprint = raw["fingerprint"] as? String
    self.allowInsecure = (raw["allowInsecure"] as? Bool) ?? (raw["allow_insecure"] as? Bool) ?? false
    self.mtu = raw["mtu"] as? Int ?? Int((raw["mtu"] as? String) ?? "") ?? 1400
    self.dnsServers = (raw["dnsServers"] as? [String]) ?? (raw["dns_servers"] as? [String]) ?? ["1.1.1.1", "8.8.8.8"]
    self.alpn = raw["alpn"] as? [String] ?? []
    self.domainResolver = (raw["domainResolver"] as? String) ?? (raw["domain_resolver"] as? String)
    self.packetEncoding = (raw["packetEncoding"] as? String) ?? (raw["packet_encoding"] as? String)
    self.rawSingBoxConfig = (raw["rawSingBoxConfig"] as? String) ?? (raw["raw_sing_box_config"] as? String)
    self.rawXrayConfig = (raw["rawXrayConfig"] as? String) ?? (raw["raw_xray_config"] as? String)
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
