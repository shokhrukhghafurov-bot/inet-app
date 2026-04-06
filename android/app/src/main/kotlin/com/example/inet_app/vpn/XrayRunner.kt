package com.example.inet_app.vpn

import android.net.VpnService

class XrayRunner : EmbeddedVpnEngine {
    override val name: String = "xray-core"
    private var sessionId: String? = null

    override fun start(service: VpnService, tunFd: Int, config: VpnConnectConfig) {
        val configJson = XrayConfigFactory.build(config)
        sessionId = EmbeddedCoreBridge.startXray(
            configJson = configJson,
            tunFd = tunFd,
            protectSocket = { socketFd -> service.protect(socketFd) },
        )
    }

    override fun stop() {
        val current = sessionId ?: return
        EmbeddedCoreBridge.stopXray(current)
        sessionId = null
    }
}
