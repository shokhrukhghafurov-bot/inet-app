package com.example.inet_app.vpn

import org.json.JSONArray
import org.json.JSONObject

data class VpnConnectConfig(
    val protocol: String = "vless",
    val locationCode: String,
    val server: String,
    val port: Int,
    val uuid: String,
    val engine: String = "sing-box",
    val remark: String? = null,
    val transport: String = "tcp",
    val security: String = "reality",
    val flow: String? = null,
    val sni: String? = null,
    val host: String? = null,
    val path: String? = null,
    val serviceName: String? = null,
    val publicKey: String? = null,
    val shortId: String? = null,
    val fingerprint: String? = null,
    val allowInsecure: Boolean = false,
    val mtu: Int = 1400,
    val dnsServers: List<String> = listOf("1.1.1.1", "8.8.8.8"),
    val alpn: List<String> = emptyList(),
    val domainResolver: String? = null,
    val packetEncoding: String? = null,
    val rawSingBoxConfig: String? = null,
    val rawXrayConfig: String? = null,
) {
    fun isComplete(): Boolean =
        locationCode.isNotBlank() && server.isNotBlank() && port > 0 && uuid.isNotBlank()

    fun toJsonString(): String = JSONObject().apply {
        put("protocol", protocol)
        put("locationCode", locationCode)
        put("server", server)
        put("port", port)
        put("uuid", uuid)
        put("engine", engine)
        put("remark", remark)
        put("transport", transport)
        put("network", transport)
        put("security", security)
        put("flow", flow)
        put("sni", sni)
        put("serverName", sni)
        put("host", host)
        put("path", path)
        put("serviceName", serviceName)
        put("publicKey", publicKey)
        put("shortId", shortId)
        put("fingerprint", fingerprint)
        put("allowInsecure", allowInsecure)
        put("mtu", mtu)
        put("dnsServers", JSONArray(dnsServers))
        put("alpn", JSONArray(alpn))
        put("domainResolver", domainResolver)
        put("packetEncoding", packetEncoding)
        put("rawSingBoxConfig", rawSingBoxConfig)
        put("rawXrayConfig", rawXrayConfig)
    }.toString()

    companion object {
        fun fromMethodArguments(arguments: Map<*, *>?): VpnConnectConfig? {
            val config = arguments?.get("config") as? Map<*, *> ?: return null
            return fromMap(config)
        }

        fun fromJsonString(raw: String?): VpnConnectConfig? {
            if (raw.isNullOrBlank()) return null
            val json = try {
                JSONObject(raw)
            } catch (_: Exception) {
                return null
            }
            return fromJsonObject(json)
        }

        private fun fromMap(map: Map<*, *>): VpnConnectConfig? {
            val protocol = map["protocol"]?.toString()?.ifBlank { "vless" } ?: "vless"
            val locationCode = (map["locationCode"] ?: map["location_code"])?.toString()?.trim().orEmpty()
            val server = map["server"]?.toString()?.trim().orEmpty()
            val port = (map["port"] ?: map["server_port"])?.toString()?.toIntOrNull() ?: 443
            val uuid = (map["uuid"] ?: map["id"])?.toString()?.trim().orEmpty()
            val dnsRaw = (map["dnsServers"] ?: map["dns_servers"]) as? List<*>
            val dnsServers = dnsRaw?.mapNotNull { it?.toString() } ?: listOf("1.1.1.1", "8.8.8.8")
            val alpn = (map["alpn"] as? List<*>)?.mapNotNull { it?.toString() } ?: emptyList()
            val rawSingBoxConfig = (map["rawSingBoxConfig"] ?: map["raw_sing_box_config"])?.toString()
            val rawXrayConfig = (map["rawXrayConfig"] ?: map["raw_xray_config"])?.toString()
            val config = VpnConnectConfig(
                protocol = protocol,
                locationCode = locationCode,
                server = server,
                port = port,
                uuid = uuid,
                engine = resolveEngine(map["engine"]?.toString(), rawSingBoxConfig, rawXrayConfig),
                remark = map["remark"]?.toString(),
                transport = (map["transport"] ?: map["network"])?.toString() ?: "tcp",
                security = map["security"]?.toString() ?: "reality",
                flow = map["flow"]?.toString(),
                sni = (map["sni"] ?: map["serverName"] ?: map["server_name"])?.toString(),
                host = map["host"]?.toString(),
                path = map["path"]?.toString(),
                serviceName = (map["serviceName"] ?: map["service_name"])?.toString(),
                publicKey = (map["publicKey"] ?: map["public_key"])?.toString(),
                shortId = (map["shortId"] ?: map["short_id"])?.toString(),
                fingerprint = map["fingerprint"]?.toString(),
                allowInsecure = map["allowInsecure"] == true || map["allow_insecure"] == true,
                mtu = map["mtu"]?.toString()?.toIntOrNull() ?: 1400,
                dnsServers = dnsServers.ifEmpty { listOf("1.1.1.1", "8.8.8.8") },
                alpn = alpn,
                domainResolver = (map["domainResolver"] ?: map["domain_resolver"])?.toString(),
                packetEncoding = (map["packetEncoding"] ?: map["packet_encoding"])?.toString(),
                rawSingBoxConfig = rawSingBoxConfig,
                rawXrayConfig = rawXrayConfig,
            )
            return config.takeIf { it.isComplete() }
        }

        private fun fromJsonObject(json: JSONObject): VpnConnectConfig? {
            fun jsonArray(name: String): List<String> {
                val value = json.optJSONArray(name) ?: return emptyList()
                return List(value.length()) { idx -> value.optString(idx) }.filter { it.isNotBlank() }
            }

            val rawSingBoxConfig = if (json.has("rawSingBoxConfig")) json.optString("rawSingBoxConfig", null) else json.optString("raw_sing_box_config", null)
            val rawXrayConfig = if (json.has("rawXrayConfig")) json.optString("rawXrayConfig", null) else json.optString("raw_xray_config", null)
            val config = VpnConnectConfig(
                protocol = json.optString("protocol", "vless"),
                locationCode = json.optString("locationCode", json.optString("location_code", "")).trim(),
                server = json.optString("server", "").trim(),
                port = if (json.has("port")) json.optInt("port", 443) else json.optInt("server_port", 443),
                uuid = json.optString("uuid", json.optString("id", "")).trim(),
                engine = resolveEngine(json.optString("engine", "sing-box"), rawSingBoxConfig, rawXrayConfig),
                remark = json.optString("remark", null),
                transport = if (json.has("transport")) json.optString("transport", "tcp") else json.optString("network", "tcp"),
                security = json.optString("security", "reality"),
                flow = json.optString("flow", null),
                sni = if (json.has("sni")) json.optString("sni", null) else if (json.has("serverName")) json.optString("serverName", null) else json.optString("server_name", null),
                host = json.optString("host", null),
                path = json.optString("path", null),
                serviceName = if (json.has("serviceName")) json.optString("serviceName", null) else json.optString("service_name", null),
                publicKey = if (json.has("publicKey")) json.optString("publicKey", null) else json.optString("public_key", null),
                shortId = if (json.has("shortId")) json.optString("shortId", null) else json.optString("short_id", null),
                fingerprint = json.optString("fingerprint", null),
                allowInsecure = json.optBoolean("allowInsecure", json.optBoolean("allow_insecure", false)),
                mtu = json.optInt("mtu", 1400),
                dnsServers = (jsonArray("dnsServers") + jsonArray("dns_servers")).ifEmpty { listOf("1.1.1.1", "8.8.8.8") },
                alpn = jsonArray("alpn"),
                domainResolver = if (json.has("domainResolver")) json.optString("domainResolver", null) else json.optString("domain_resolver", null),
                packetEncoding = if (json.has("packetEncoding")) json.optString("packetEncoding", null) else json.optString("packet_encoding", null),
                rawSingBoxConfig = rawSingBoxConfig,
                rawXrayConfig = rawXrayConfig,
            )
            return config.takeIf { it.isComplete() }
        }

        private fun resolveEngine(rawEngine: String?, rawSingBoxConfig: String?, rawXrayConfig: String?): String {
            val normalized = rawEngine?.trim()?.lowercase().orEmpty()
            return when {
                normalized.isEmpty() -> "sing-box"
                normalized == "xray" || normalized == "xray-core" -> "sing-box"
                else -> rawEngine!!.trim()
            }
        }
    }
}
