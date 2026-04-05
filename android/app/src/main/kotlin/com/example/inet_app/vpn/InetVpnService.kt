package com.example.inet_app.vpn

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.ConnectivityManager
import android.net.Network
import android.net.VpnService
import android.os.Build
import android.os.ParcelFileDescriptor
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import com.example.inet_app.MainActivity
import java.io.IOException

class InetVpnService : VpnService() {
    private lateinit var stateStore: VpnStateStore
    private var vpnInterface: ParcelFileDescriptor? = null
    private var connectivityManager: ConnectivityManager? = null
    private var networkCallbackRegistered = false
    private var engine: EmbeddedVpnEngine? = null

    private val networkCallback = object : ConnectivityManager.NetworkCallback() {
        override fun onAvailable(network: Network) {
            val snapshot = stateStore.snapshot()
            val config = VpnConnectConfig.fromJsonString(snapshot.configJson)
            if (
                snapshot.status == VpnStateStore.STATUS_CONNECTING &&
                snapshot.reconnectOnLaunch &&
                config != null &&
                vpnInterface == null
            ) {
                beginConnect(config)
                return
            }
            if (snapshot.status == VpnStateStore.STATUS_CONNECTED) {
                stateStore.clearError()
                updateNotification("Connected")
            }
        }

        override fun onLost(network: Network) {
            val snapshot = stateStore.snapshot()
            if (snapshot.status == VpnStateStore.STATUS_CONNECTED && snapshot.reconnectOnLaunch) {
                pauseForReconnect("Underlying network was lost. Waiting to reconnect.")
            }
        }
    }

    override fun onCreate() {
        super.onCreate()
        stateStore = VpnStateStore(this)
        connectivityManager = getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
        registerNetworkCallbackIfNeeded()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        startForeground(NOTIFICATION_ID, buildNotification("Starting VPN"))

        return when (intent?.action ?: ACTION_RESTORE) {
            ACTION_CONNECT, ACTION_RESTORE -> {
                val config = VpnConnectConfig.fromJsonString(intent?.getStringExtra(EXTRA_CONFIG_JSON))
                    ?: VpnConnectConfig.fromJsonString(stateStore.snapshot().configJson)
                if (config == null) {
                    disconnectInternal(
                        userRequested = false,
                        errorMessage = "No VLESS config selected for VPN reconnect.",
                    )
                    START_NOT_STICKY
                } else {
                    beginConnect(config)
                    START_STICKY
                }
            }
            ACTION_DISCONNECT -> {
                disconnectInternal(userRequested = true, errorMessage = null)
                START_NOT_STICKY
            }
            else -> START_NOT_STICKY
        }
    }

    override fun onDestroy() {
        unregisterNetworkCallbackIfNeeded()
        closeTunnel()
        super.onDestroy()
    }

    override fun onRevoke() {
        disconnectInternal(
            userRequested = false,
            errorMessage = "VPN permission was revoked by the system.",
        )
        super.onRevoke()
    }

    private fun beginConnect(config: VpnConnectConfig) {
        stateStore.setStatus(VpnStateStore.STATUS_CONNECTING)
        stateStore.setConfig(config)
        stateStore.setReconnectOnLaunch(true)
        stateStore.setPermissionRequired(false)
        stateStore.clearError()
        updateNotification("Connecting ${config.engine} ${config.locationCode}")

        try {
            if (vpnInterface == null) {
                val builder = Builder()
                    .setSession(config.remark ?: "INET ${config.locationCode}")
                    .setMtu(config.mtu)
                    .addAddress("10.200.0.2", 32)
                    .addRoute("0.0.0.0", 0)

                config.dnsServers.forEach { dns ->
                    if (dns.isNotBlank()) {
                        builder.addDnsServer(dns)
                    }
                }

                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                    builder.addAddress("fd00:200::2", 128)
                    builder.addRoute("::", 0)
                }

                vpnInterface = builder.establish()
            }

            val fd = vpnInterface?.fd ?: throw IOException("Failed to establish VPN interface.")
            val selectedEngine = EmbeddedVpnEngine.fromConfig(config)
            selectedEngine.start(this, fd, config)
            engine = selectedEngine

            stateStore.setStatus(VpnStateStore.STATUS_CONNECTED)
            stateStore.setConnectedAt(System.currentTimeMillis())
            stateStore.clearError()
            updateNotification("Connected ${selectedEngine.name} ${config.locationCode}")
        } catch (error: Exception) {
            disconnectInternal(
                userRequested = false,
                errorMessage = error.message ?: "Unable to establish VPN interface.",
            )
        }
    }

    private fun pauseForReconnect(message: String) {
        closeTunnel()
        stateStore.setStatus(VpnStateStore.STATUS_CONNECTING)
        stateStore.setConnectedAt(null)
        stateStore.setError(message)
        updateNotification("Waiting for network")
    }

    private fun disconnectInternal(userRequested: Boolean, errorMessage: String?) {
        stateStore.setStatus(VpnStateStore.STATUS_DISCONNECTING)
        updateNotification("Disconnecting")
        closeTunnel()
        stateStore.setStatus(VpnStateStore.STATUS_DISCONNECTED)
        stateStore.setConnectedAt(null)
        stateStore.setPermissionRequired(false)
        if (userRequested) {
            stateStore.setReconnectOnLaunch(false)
            stateStore.clearError()
        } else {
            stateStore.setReconnectOnLaunch(errorMessage != null)
            if (errorMessage.isNullOrBlank()) {
                stateStore.clearError()
            } else {
                stateStore.setError(errorMessage)
            }
        }
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    private fun closeTunnel() {
        try {
            engine?.stop()
        } catch (_: Exception) {
        }
        engine = null
        try {
            vpnInterface?.close()
        } catch (_: IOException) {
        }
        vpnInterface = null
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            return
        }

        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val channel = NotificationChannel(
            NOTIFICATION_CHANNEL_ID,
            "INET VPN",
            NotificationManager.IMPORTANCE_LOW,
        )
        channel.description = "Foreground status for active INET VPN sessions."
        manager.createNotificationChannel(channel)
    }

    private fun buildNotification(contentText: String): Notification {
        val launchIntent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        return NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
            .setContentTitle("INET VPN")
            .setContentText(contentText)
            .setSmallIcon(android.R.drawable.stat_sys_warning)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setSilent(true)
            .build()
    }

    private fun updateNotification(contentText: String) {
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.notify(NOTIFICATION_ID, buildNotification(contentText))
    }

    private fun registerNetworkCallbackIfNeeded() {
        val manager = connectivityManager ?: return
        if (networkCallbackRegistered) {
            return
        }
        try {
            manager.registerDefaultNetworkCallback(networkCallback)
            networkCallbackRegistered = true
        } catch (_: Exception) {
        }
    }

    private fun unregisterNetworkCallbackIfNeeded() {
        val manager = connectivityManager ?: return
        if (!networkCallbackRegistered) {
            return
        }
        try {
            manager.unregisterNetworkCallback(networkCallback)
        } catch (_: Exception) {
        }
        networkCallbackRegistered = false
    }

    companion object {
        private const val ACTION_CONNECT = "com.example.inet_app.vpn.CONNECT"
        private const val ACTION_DISCONNECT = "com.example.inet_app.vpn.DISCONNECT"
        private const val ACTION_RESTORE = "com.example.inet_app.vpn.RESTORE"
        private const val EXTRA_CONFIG_JSON = "configJson"
        private const val NOTIFICATION_CHANNEL_ID = "inet_vpn_status"
        private const val NOTIFICATION_ID = 2007

        fun connect(context: Context, config: VpnConnectConfig) {
            val intent = Intent(context, InetVpnService::class.java).apply {
                action = ACTION_CONNECT
                putExtra(EXTRA_CONFIG_JSON, config.toJsonString())
            }
            ContextCompat.startForegroundService(context, intent)
        }

        fun disconnect(context: Context) {
            val intent = Intent(context, InetVpnService::class.java).apply {
                action = ACTION_DISCONNECT
            }
            ContextCompat.startForegroundService(context, intent)
        }

        fun onAppResumed(context: Context) {
            val snapshot = VpnStateStore(context).snapshot()
            val config = VpnConnectConfig.fromJsonString(snapshot.configJson)
            if (
                snapshot.reconnectOnLaunch &&
                snapshot.status == VpnStateStore.STATUS_DISCONNECTED &&
                config != null
            ) {
                connect(context, config)
            }
        }

        fun onAppBackgrounded(context: Context) {
            // The foreground service keeps the VPN alive while the app is backgrounded.
            // Nothing else is required here yet.
        }
    }
}
