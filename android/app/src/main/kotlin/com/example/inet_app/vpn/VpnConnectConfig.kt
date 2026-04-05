package com.example.inet_app.vpn

import org.json.JSONArray
import org.json.JSONObject

data class VpnConnectConfig(
    val protocol: String = "vless",
    val locationCode: String,
    val server: String,
    val port: Int,
    val uuid: String,
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
) {
    fun isComplete(): Boolean =
        locationCode.isNotBlank() && server.isNotBlank() && port > 0 && uuid.isNotBlank()

    fun toJsonString(): String = JSONObject().apply {
        put("protocol", protocol)
        put("locationCode", locationCode)
        put("server", server)
        put("port", port)
        put("uuid", uuid)
        put("remark", remark)
        put("transport", transport)
        put("security", security)
        put("flow", flow)
        put("sni", sni)
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
            val locationCode = map["locationCode"]?.toString()?.trim().orEmpty()
            val server = map["server"]?.toString()?.trim().orEmpty()
            val port = map["port"]?.toString()?.toIntOrNull() ?: 443
            val uuid = map["uuid"]?.toString()?.trim().orEmpty()
            val dnsServers = (map["dnsServers"] as? List<*>)?.mapNotNull { it?.toString() } ?: listOf("1.1.1.1", "8.8.8.8")
            val alpn = (map["alpn"] as? List<*>)?.mapNotNull { it?.toString() } ?: emptyList()
            val config = VpnConnectConfig(
                protocol = protocol,
                locationCode = locationCode,
                server = server,
                port = port,
                uuid = uuid,
                remark = map["remark"]?.toString(),
                transport = map["transport"]?.toString() ?: "tcp",
                security = map["security"]?.toString() ?: "reality",
                flow = map["flow"]?.toString(),
                sni = map["sni"]?.toString(),
                host = map["host"]?.toString(),
                path = map["path"]?.toString(),
                serviceName = map["serviceName"]?.toString(),
                publicKey = map["publicKey"]?.toString(),
                shortId = map["shortId"]?.toString(),
                fingerprint = map["fingerprint"]?.toString(),
                allowInsecure = map["allowInsecure"] == true,
                mtu = map["mtu"]?.toString()?.toIntOrNull() ?: 1400,
                dnsServers = dnsServers.ifEmpty { listOf("1.1.1.1", "8.8.8.8") },
                alpn = alpn,
            )
            return config.takeIf { it.isComplete() }
        }

        private fun fromJsonObject(json: JSONObject): VpnConnectConfig? {
            fun jsonArray(name: String): List<String> {
                val value = json.optJSONArray(name) ?: return emptyList()
                return List(value.length()) { idx -> value.optString(idx) }.filter { it.isNotBlank() }
            }

            val config = VpnConnectConfig(
                protocol = json.optString("protocol", "vless"),
                locationCode = json.optString("locationCode", "").trim(),
                server = json.optString("server", "").trim(),
                port = json.optInt("port", 443),
                uuid = json.optString("uuid", "").trim(),
                remark = json.optString("remark", null),
                transport = json.optString("transport", "tcp"),
                security = json.optString("security", "reality"),
                flow = json.optString("flow", null),
                sni = json.optString("sni", null),
                host = json.optString("host", null),
                path = json.optString("path", null),
                serviceName = json.optString("serviceName", null),
                publicKey = json.optString("publicKey", null),
                shortId = json.optString("shortId", null),
                fingerprint = json.optString("fingerprint", null),
                allowInsecure = json.optBoolean("allowInsecure", false),
                mtu = json.optInt("mtu", 1400),
                dnsServers = jsonArray("dnsServers").ifEmpty { listOf("1.1.1.1", "8.8.8.8") },
                alpn = jsonArray("alpn"),
            )
            return config.takeIf { it.isComplete() }
        }
    }
}
