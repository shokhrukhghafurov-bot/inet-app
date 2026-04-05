package com.example.inet_app.vpn

import org.json.JSONArray
import org.json.JSONObject

object SingBoxConfigFactory {
    fun build(config: VpnConnectConfig): String {
        val rawOverride = config.rawSingBoxConfig?.trim()
        if (!rawOverride.isNullOrEmpty()) {
            return rawOverride
        }

        val tls = JSONObject().apply {
            put("enabled", config.security.equals("tls", ignoreCase = true) || config.security.equals("reality", ignoreCase = true))
            put("server_name", config.sni ?: config.server)
            put("insecure", config.allowInsecure)
            if (!config.fingerprint.isNullOrBlank()) {
                put("utls", JSONObject().apply {
                    put("enabled", true)
                    put("fingerprint", config.fingerprint)
                })
            }
            if (config.security.equals("reality", ignoreCase = true)) {
                put("reality", JSONObject().apply {
                    put("enabled", true)
                    put("public_key", config.publicKey ?: "")
                    if (!config.shortId.isNullOrBlank()) {
                        put("short_id", config.shortId)
                    }
                })
            }
            if (config.alpn.isNotEmpty()) {
                put("alpn", JSONArray(config.alpn))
            }
        }

        val outbound = JSONObject().apply {
            put("type", "vless")
            put("tag", "proxy")
            put("server", config.server)
            put("server_port", config.port)
            put("uuid", config.uuid)
            if (!config.flow.isNullOrBlank()) {
                put("flow", config.flow)
            }
            put("packet_encoding", config.packetEncoding ?: "xudp")
            put("domain_resolver", config.domainResolver ?: "dns-remote")
            put("tls", tls)
            when (config.transport.trim().lowercase()) {
                "ws", "websocket" -> put("transport", JSONObject().apply {
                    put("type", "ws")
                    put("path", config.path ?: "/")
                    if (!config.host.isNullOrBlank()) {
                        put("headers", JSONObject().apply { put("Host", config.host) })
                    }
                })
                "grpc" -> put("transport", JSONObject().apply {
                    put("type", "grpc")
                    put("service_name", config.serviceName ?: "grpc")
                })
                else -> put("network", "tcp")
            }
        }

        val tunInbound = JSONObject().apply {
            put("type", "tun")
            put("tag", "tun-in")
            put("interface_name", "inet0")
            put("inet4_address", JSONArray().put("10.200.0.1/30"))
            put("inet6_address", JSONArray().put("fd00:200::1/126"))
            put("mtu", config.mtu)
            put("auto_route", true)
            put("strict_route", true)
        }

        val dnsServers = JSONArray().apply {
            val preferred = config.dnsServers.ifEmpty { listOf("1.1.1.1") }
            preferred.forEachIndexed { index, value ->
                put(JSONObject().apply {
                    put("tag", if (index == 0) "dns-remote" else "dns-$index")
                    put("address", value)
                })
            }
        }

        val root = JSONObject().apply {
            put("log", JSONObject().apply { put("level", "info") })
            put("dns", JSONObject().apply { put("servers", dnsServers) })
            put("inbounds", JSONArray().put(tunInbound))
            put("outbounds", JSONArray().put(outbound).put(JSONObject().apply {
                put("type", "direct")
                put("tag", "direct")
            }))
            put("route", JSONObject().apply { put("final", "proxy") })
            put("experimental", JSONObject().apply {
                put("cache_file", JSONObject().apply { put("enabled", false) })
            })
        }
        return root.toString()
    }
}
