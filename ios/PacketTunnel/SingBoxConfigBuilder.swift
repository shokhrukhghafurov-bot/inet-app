import Foundation

enum SingBoxConfigBuilder {
  static func build(from config: PacketTunnelConnectConfig) throws -> String {
    if let raw = config.rawSingBoxConfig?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty {
      return raw
    }

    var tls: [String: Any] = [
      "enabled": config.security.lowercased() == "tls" || config.security.lowercased() == "reality",
      "server_name": config.sni ?? config.server,
      "insecure": config.allowInsecure,
    ]
    if let fingerprint = config.fingerprint, !fingerprint.isEmpty {
      tls["utls"] = [
        "enabled": true,
        "fingerprint": fingerprint,
      ]
    }
    if config.security.lowercased() == "reality" {
      tls["reality"] = [
        "enabled": true,
        "public_key": config.publicKey ?? "",
        "short_id": config.shortId ?? "",
      ]
    }
    if !config.alpn.isEmpty {
      tls["alpn"] = config.alpn
    }

    var outbound: [String: Any] = [
      "type": "vless",
      "tag": "proxy",
      "server": config.server,
      "server_port": config.port,
      "uuid": config.uuid,
      "tls": tls,
      "packet_encoding": config.packetEncoding ?? "xudp",
      "domain_resolver": config.domainResolver ?? "dns-remote",
    ]
    if let flow = config.flow, !flow.isEmpty {
      outbound["flow"] = flow
    }

    switch config.transport.lowercased() {
    case "ws", "websocket":
      var transport: [String: Any] = [
        "type": "ws",
        "path": config.path ?? "/",
      ]
      if let host = config.host, !host.isEmpty {
        transport["headers"] = ["Host": host]
      }
      outbound["transport"] = transport
    case "grpc":
      outbound["transport"] = [
        "type": "grpc",
        "service_name": config.serviceName ?? "grpc",
      ]
    default:
      outbound["network"] = "tcp"
    }

    let root: [String: Any] = [
      "log": ["level": "info"],
      "dns": [
        "servers": config.dnsServers.enumerated().map { index, server in
          ["tag": index == 0 ? "dns-remote" : "dns-\(index)", "address": server]
        }
      ],
      "inbounds": [[
        "type": "tun",
        "tag": "tun-in",
        "interface_name": "inet0",
        "inet4_address": ["10.200.0.1/30"],
        "inet6_address": ["fd00:200::1/126"],
        "mtu": config.mtu,
        "auto_route": true,
        "strict_route": true,
      ]],
      "outbounds": [
        outbound,
        ["type": "direct", "tag": "direct"],
      ],
      "route": ["final": "proxy"],
    ]

    let data = try JSONSerialization.data(withJSONObject: root, options: [.prettyPrinted])
    guard let text = String(data: data, encoding: .utf8) else {
      throw NSError(domain: "inet.vpn", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to encode sing-box config"])
    }
    return text
  }
}
