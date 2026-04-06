package com.example.inet_app.vpn

import android.net.VpnService

class SingBoxRunner : EmbeddedVpnEngine {
    override val name: String = "sing-box"
    private var sessionId: String? = null

    override fun start(service: VpnService, tunFd: Int, config: VpnConnectConfig) {
        val configJson = SingBoxConfigFactory.build(config)
        sessionId = EmbeddedCoreBridge.startSingBox(
            context = service.applicationContext,
            configJson = configJson,
            tunFd = tunFd,
            protectSocket = { socketFd -> service.protect(socketFd) },
        )
    }

    override fun stop() {
        val current = sessionId ?: return
        EmbeddedCoreBridge.stopSingBox(current)
        sessionId = null
    }
}
