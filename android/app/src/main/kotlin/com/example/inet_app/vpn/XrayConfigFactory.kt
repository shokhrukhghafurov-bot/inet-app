package com.example.inet_app.vpn

import org.json.JSONArray
import org.json.JSONObject

object XrayConfigFactory {
    fun build(config: VpnConnectConfig): String {
        val rawOverride = config.rawXrayConfig?.trim()
        if (!rawOverride.isNullOrEmpty()) {
            return rawOverride
        }

        val streamSettings = JSONObject().apply {
            put("network", when (config.transport.trim().lowercase()) {
                "ws", "websocket" -> "ws"
                "grpc" -> "grpc"
                else -> "tcp"
            })
            put("security", if (config.security.equals("reality", ignoreCase = true)) "reality" else "tls")
            if (config.security.equals("reality", ignoreCase = true)) {
                put("realitySettings", JSONObject().apply {
                    put("serverName", config.sni ?: config.server)
                    put("fingerprint", config.fingerprint ?: "chrome")
                    put("publicKey", config.publicKey ?: "")
                    put("shortId", config.shortId ?: "")
                })
            } else {
                put("tlsSettings", JSONObject().apply {
                    put("serverName", config.sni ?: config.server)
                    put("allowInsecure", config.allowInsecure)
                    if (config.alpn.isNotEmpty()) {
                        put("alpn", JSONArray(config.alpn))
                    }
                })
            }
            when (config.transport.trim().lowercase()) {
                "ws", "websocket" -> put("wsSettings", JSONObject().apply {
                    put("path", config.path ?: "/")
                    put("headers", JSONObject().apply {
                        put("Host", config.host ?: config.sni ?: config.server)
                    })
                })
                "grpc" -> put("grpcSettings", JSONObject().apply {
                    put("serviceName", config.serviceName ?: "grpc")
                })
            }
        }

        val root = JSONObject().apply {
            put("log", JSONObject().apply { put("loglevel", "warning") })
            put("dns", JSONObject().apply {
                put("servers", JSONArray(config.dnsServers.ifEmpty { listOf("1.1.1.1") }))
            })
            put("inbounds", JSONArray().put(JSONObject().apply {
                put("tag", "tun-in-placeholder")
                put("protocol", "socks")
                put("listen", "127.0.0.1")
                put("port", 10808)
                put("settings", JSONObject().apply { put("udp", true) })
            }))
            put("outbounds", JSONArray().put(JSONObject().apply {
                put("tag", "proxy")
                put("protocol", "vless")
                put("settings", JSONObject().apply {
                    put("vnext", JSONArray().put(JSONObject().apply {
                        put("address", config.server)
                        put("port", config.port)
                        put("users", JSONArray().put(JSONObject().apply {
                            put("id", config.uuid)
                            put("encryption", "none")
                            if (!config.flow.isNullOrBlank()) {
                                put("flow", config.flow)
                            }
                        }))
                    }))
                })
                put("streamSettings", streamSettings)
            }).put(JSONObject().apply {
                put("tag", "direct")
                put("protocol", "freedom")
            }))
            put("routing", JSONObject().apply {
                put("domainStrategy", "IPIfNonMatch")
            })
        }
        return root.toString()
    }
}
