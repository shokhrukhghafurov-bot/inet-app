import Foundation

enum XrayConfigBuilder {
  static func build(from config: PacketTunnelConnectConfig) throws -> String {
    if let raw = config.rawXrayConfig?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty {
      return raw
    }

    var streamSettings: [String: Any] = [
      "network": transportNetwork(config.transport),
      "security": config.security.lowercased() == "reality" ? "reality" : "tls",
    ]

    if config.security.lowercased() == "reality" {
      streamSettings["realitySettings"] = [
        "serverName": config.sni ?? config.server,
        "fingerprint": config.fingerprint ?? "chrome",
        "publicKey": config.publicKey ?? "",
        "shortId": config.shortId ?? "",
      ]
    } else {
      var tlsSettings: [String: Any] = [
        "serverName": config.sni ?? config.server,
        "allowInsecure": config.allowInsecure,
      ]
      if !config.alpn.isEmpty {
        tlsSettings["alpn"] = config.alpn
      }
      streamSettings["tlsSettings"] = tlsSettings
    }

    switch transportNetwork(config.transport) {
    case "ws":
      streamSettings["wsSettings"] = [
        "path": config.path ?? "/",
        "headers": ["Host": config.host ?? config.sni ?? config.server],
      ]
    case "grpc":
      streamSettings["grpcSettings"] = ["serviceName": config.serviceName ?? "grpc"]
    default:
      break
    }

    var user: [String: Any] = [
      "id": config.uuid,
      "encryption": "none",
    ]
    if let flow = config.flow, !flow.isEmpty {
      user["flow"] = flow
    }

    let root: [String: Any] = [
      "log": ["loglevel": "warning"],
      "dns": ["servers": config.dnsServers],
      "inbounds": [[
        "tag": "tun-in-placeholder",
        "protocol": "socks",
        "listen": "127.0.0.1",
        "port": 10808,
        "settings": ["udp": true],
      ]],
      "outbounds": [
        [
          "tag": "proxy",
          "protocol": "vless",
          "settings": [
            "vnext": [[
              "address": config.server,
              "port": config.port,
              "users": [user],
            ]],
          ],
          "streamSettings": streamSettings,
        ],
        ["tag": "direct", "protocol": "freedom"],
      ],
      "routing": ["domainStrategy": "IPIfNonMatch"],
    ]

    let data = try JSONSerialization.data(withJSONObject: root, options: [.prettyPrinted])
    guard let text = String(data: data, encoding: .utf8) else {
      throw NSError(domain: "inet.vpn", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to encode xray config"])
    }
    return text
  }

  private static func transportNetwork(_ transport: String) -> String {
    switch transport.lowercased() {
    case "ws", "websocket": return "ws"
    case "grpc": return "grpc"
    default: return "tcp"
    }
  }
}
