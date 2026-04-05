package com.example.inet_app.vpn

import android.content.Context

class VpnStateStore(context: Context) {
    private val prefs = context.applicationContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    fun snapshot(): VpnSnapshot {
        return VpnSnapshot(
            status = prefs.getString(KEY_STATUS, STATUS_DISCONNECTED) ?: STATUS_DISCONNECTED,
            error = prefs.getString(KEY_ERROR, null),
            locationCode = prefs.getString(KEY_LOCATION_CODE, null),
            connectedAt = prefs.getLong(KEY_CONNECTED_AT, 0L).takeIf { it > 0L },
            reconnectOnLaunch = prefs.getBoolean(KEY_RECONNECT, false),
            permissionRequired = prefs.getBoolean(KEY_PERMISSION_REQUIRED, false),
            protocol = prefs.getString(KEY_PROTOCOL, null),
            server = prefs.getString(KEY_SERVER, null),
            transport = prefs.getString(KEY_TRANSPORT, null),
            engine = prefs.getString(KEY_ENGINE, null),
            configJson = prefs.getString(KEY_CONFIG_JSON, null),
        )
    }

    fun setStatus(value: String) {
        prefs.edit().putString(KEY_STATUS, value).apply()
    }

    fun setError(value: String?) {
        prefs.edit().putString(KEY_ERROR, value).apply()
    }

    fun clearError() {
        prefs.edit().remove(KEY_ERROR).apply()
    }

    fun setLocationCode(value: String?) {
        prefs.edit().putString(KEY_LOCATION_CODE, value).apply()
    }

    fun setConfig(config: VpnConnectConfig?) {
        prefs.edit().apply {
            if (config == null) {
                remove(KEY_CONFIG_JSON)
                remove(KEY_PROTOCOL)
                remove(KEY_SERVER)
                remove(KEY_TRANSPORT)
                remove(KEY_ENGINE)
                remove(KEY_LOCATION_CODE)
            } else {
                putString(KEY_CONFIG_JSON, config.toJsonString())
                putString(KEY_PROTOCOL, config.protocol)
                putString(KEY_SERVER, config.server)
                putString(KEY_TRANSPORT, config.transport)
                putString(KEY_ENGINE, config.engine)
                putString(KEY_LOCATION_CODE, config.locationCode)
            }
        }.apply()
    }

    fun setConnectedAt(value: Long?) {
        prefs.edit().apply {
            if (value == null || value <= 0L) {
                remove(KEY_CONNECTED_AT)
            } else {
                putLong(KEY_CONNECTED_AT, value)
            }
        }.apply()
    }

    fun setReconnectOnLaunch(value: Boolean) {
        prefs.edit().putBoolean(KEY_RECONNECT, value).apply()
    }

    fun setPermissionRequired(value: Boolean) {
        prefs.edit().putBoolean(KEY_PERMISSION_REQUIRED, value).apply()
    }

    companion object {
        private const val PREFS_NAME = "inet_vpn_state"
        private const val KEY_STATUS = "status"
        private const val KEY_ERROR = "error"
        private const val KEY_LOCATION_CODE = "locationCode"
        private const val KEY_CONNECTED_AT = "connectedAt"
        private const val KEY_RECONNECT = "reconnectOnLaunch"
        private const val KEY_PERMISSION_REQUIRED = "permissionRequired"
        private const val KEY_PROTOCOL = "protocol"
        private const val KEY_SERVER = "server"
        private const val KEY_TRANSPORT = "transport"
        private const val KEY_ENGINE = "engine"
        private const val KEY_CONFIG_JSON = "configJson"

        const val STATUS_DISCONNECTED = "disconnected"
        const val STATUS_CONNECTING = "connecting"
        const val STATUS_CONNECTED = "connected"
        const val STATUS_DISCONNECTING = "disconnecting"
        const val STATUS_UNSUPPORTED = "unsupported"
    }
}

data class VpnSnapshot(
    val status: String,
    val error: String?,
    val locationCode: String?,
    val connectedAt: Long?,
    val reconnectOnLaunch: Boolean,
    val permissionRequired: Boolean,
    val protocol: String?,
    val server: String?,
    val transport: String?,
    val engine: String?,
    val configJson: String?,
) {
    fun toMap(): Map<String, Any?> = mapOf(
        "status" to status,
        "error" to error,
        "locationCode" to locationCode,
        "connectedAt" to connectedAt,
        "reconnectOnLaunch" to reconnectOnLaunch,
        "permissionRequired" to permissionRequired,
        "protocol" to protocol,
        "server" to server,
        "transport" to transport,
        "engine" to engine,
    )
}
