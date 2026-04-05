package com.example.inet_app.vpn

import android.net.VpnService

interface EmbeddedVpnEngine {
    val name: String

    @Throws(Exception::class)
    fun start(service: VpnService, tunFd: Int, config: VpnConnectConfig)

    fun stop()

    companion object {
        fun fromConfig(config: VpnConnectConfig): EmbeddedVpnEngine {
            return SingBoxRunner()
        }
    }
}
