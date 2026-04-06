package com.example.inet_app

import android.app.Activity
import android.content.Intent
import android.net.VpnService
import com.example.inet_app.vpn.InetVpnService
import com.example.inet_app.vpn.VpnConnectConfig
import com.example.inet_app.vpn.VpnStateStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "inet/vpn"
    private var pendingResult: MethodChannel.Result? = null
    private var pendingConfigJson: String? = null
    private val vpnPermissionRequestCode = 4242

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "connect" -> handleConnect(call, result)
                    "disconnect" -> {
                        InetVpnService.disconnect(this)
                        result.success(null)
                    }
                    "status" -> result.success(VpnStateStore(this).snapshot().status)
                    "snapshot" -> result.success(VpnStateStore(this).snapshot().toMap())
                    "appResumed" -> {
                        InetVpnService.onAppResumed(this)
                        result.success(null)
                    }
                    "appBackgrounded" -> {
                        InetVpnService.onAppBackgrounded(this)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun handleConnect(call: MethodCall, result: MethodChannel.Result) {
        val config = VpnConnectConfig.fromMethodArguments(call.arguments as? Map<*, *>)
        if (config == null || !config.isComplete()) {
            result.error("missing_config", "Complete VLESS config is required.", null)
            return
        }

        val prepareIntent = VpnService.prepare(this)
        if (prepareIntent == null) {
            VpnStateStore(this).setPermissionRequired(false)
            InetVpnService.connect(this, config)
            result.success(null)
            return
        }

        pendingResult = result
        pendingConfigJson = config.toJsonString()
        VpnStateStore(this).apply {
            setPermissionRequired(true)
            setStatus(VpnStateStore.STATUS_CONNECTING)
            clearError()
            setConfig(config)
            setReconnectOnLaunch(true)
        }

        @Suppress("DEPRECATION")
        startActivityForResult(prepareIntent, vpnPermissionRequestCode)
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        if (requestCode != vpnPermissionRequestCode) {
            return
        }

        val callback = pendingResult
        val configJson = pendingConfigJson
        pendingResult = null
        pendingConfigJson = null

        val config = VpnConnectConfig.fromJsonString(configJson)
        if (resultCode == Activity.RESULT_OK && config != null && config.isComplete()) {
            VpnStateStore(this).setPermissionRequired(false)
            InetVpnService.connect(this, config)
            callback?.success(null)
        } else {
            VpnStateStore(this).apply {
                setPermissionRequired(false)
                setStatus(VpnStateStore.STATUS_DISCONNECTED)
                setError("VPN permission was not granted.")
            }
            callback?.error(
                "permission_denied",
                "VPN permission was not granted.",
                null,
            )
        }
    }
}
