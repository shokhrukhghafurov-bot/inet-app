package com.example.inet_app.vpn.libbox.runtime

import android.content.Context
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.net.wifi.WifiManager
import android.os.Build
import android.system.OsConstants
import android.util.Base64
import android.util.Log
import com.example.inet_app.vpn.SingBoxLaunchOptions
import com.example.inet_app.vpn.libbox.AndroidLibboxRuntime
import go.Seq
import io.nekohasekai.libbox.CommandServer
import io.nekohasekai.libbox.CommandServerHandler
import io.nekohasekai.libbox.ConnectionOwner
import io.nekohasekai.libbox.InterfaceUpdateListener
import io.nekohasekai.libbox.Libbox
import io.nekohasekai.libbox.LocalDNSTransport
import io.nekohasekai.libbox.NetworkInterface
import io.nekohasekai.libbox.NetworkInterfaceIterator
import io.nekohasekai.libbox.Notification
import io.nekohasekai.libbox.OverrideOptions
import io.nekohasekai.libbox.PlatformInterface
import io.nekohasekai.libbox.SetupOptions
import io.nekohasekai.libbox.StringIterator
import io.nekohasekai.libbox.SystemProxyStatus
import io.nekohasekai.libbox.TunOptions
import io.nekohasekai.libbox.WIFIState
import java.io.File
import java.net.InterfaceAddress
import java.net.Inet6Address
import java.net.InetSocketAddress
import java.net.NetworkInterface as JNetworkInterface
import java.security.KeyStore

/**
 * Real Android libbox adapter wired against the uploaded official libbox.aar.
 *
 * Important practical note for this project:
 * - the app already establishes the system VPN/TUN in [InetVpnService]
 * - sing-box config still contains a `tun` inbound
 * - when libbox asks the platform to open TUN, we return the already-created tun fd
 * - when libbox asks to protect its own outbound sockets, we forward to VpnService.protect(fd)
 *
 * This makes the runtime work with the existing app architecture instead of creating a second
 * VpnService layer inside the embedded core.
 */
class OfficialLibboxAndroidRuntime(
    private val options: SingBoxLaunchOptions,
) : AndroidLibboxRuntime {

    private var commandServer: CommandServer? = null
    private var platform: ProjectPlatformInterface? = null
    private val stderrFile = File(options.workingDirectory, "stderr.log")
    private val debugLogFile = File(options.workingDirectory, "libbox-bridge.log")

    override fun start() {
        initializeLibbox()

        val platformInterface = ProjectPlatformInterface(options)
        val handler = ProjectCommandServerHandler(options)
        val server = CommandServer(handler, platformInterface)

        server.start()
        server.startOrReloadService(options.configJson, OverrideOptions())

        platform = platformInterface
        commandServer = server
        appendBridgeLog("started libbox runtime, tunFd=${options.tunFd}, config=${options.configFile.absolutePath}")
    }

    override fun stop() {
        val server = commandServer
        commandServer = null
        platform = null
        if (server != null) {
            runCatching { server.closeService() }
            runCatching { server.close() }
        }
        appendBridgeLog("stopped libbox runtime")
    }

    private fun initializeLibbox() {
        options.workingDirectory.mkdirs()
        stderrFile.parentFile?.mkdirs()
        stderrFile.createNewFile()
        debugLogFile.createNewFile()

        Seq.setContext(options.context.applicationContext)
        Libbox.setLocale("en_US")
        runCatching { Libbox.redirectStderr(stderrFile.absolutePath) }

        val basePath = File(options.context.noBackupFilesDir, "inet-singbox-base").apply { mkdirs() }
        val tempPath = File(options.context.cacheDir, "inet-singbox-temp").apply { mkdirs() }

        Libbox.setup(
            SetupOptions().apply {
                basePath = basePath.absolutePath
                workingPath = options.workingDirectory.absolutePath
                tempPath = tempPath.absolutePath
                fixAndroidStack = true
                logMaxLines = 3000
                debug = false
            },
        )
    }

    private fun appendBridgeLog(message: String) {
        runCatching {
            debugLogFile.appendText("${System.currentTimeMillis()} $message\n")
        }
        Log.d(TAG, message)
    }

    private inner class ProjectCommandServerHandler(
        private val launchOptions: SingBoxLaunchOptions,
    ) : CommandServerHandler {
        override fun getSystemProxyStatus(): SystemProxyStatus {
            return SystemProxyStatus().apply {
                available = false
                enabled = false
            }
        }

        override fun serviceReload() {
            val server = commandServer ?: return
            appendBridgeLog("serviceReload requested by libbox")
            server.startOrReloadService(launchOptions.configJson, OverrideOptions())
        }

        override fun serviceStop() {
            appendBridgeLog("serviceStop requested by libbox")
            stop()
        }

        override fun setSystemProxyEnabled(enabled: Boolean) {
            appendBridgeLog("setSystemProxyEnabled ignored: $enabled")
        }

        override fun writeDebugMessage(message: String) {
            appendBridgeLog(message)
        }
    }

    private inner class ProjectPlatformInterface(
        private val launchOptions: SingBoxLaunchOptions,
    ) : PlatformInterface {
        private val appContext = launchOptions.context.applicationContext
        private val connectivityManager = appContext.getSystemService(Context.CONNECTIVITY_SERVICE) as? ConnectivityManager
        private val wifiManager = appContext.getSystemService(Context.WIFI_SERVICE) as? WifiManager

        override fun autoDetectInterfaceControl(fd: Int) {
            launchOptions.protectSocket(fd)
        }

        override fun clearDNSCache() {
            // nothing to do in this project bridge
        }

        override fun closeDefaultInterfaceMonitor(listener: InterfaceUpdateListener) {
            // no live monitor yet; runtime still works without it
        }

        override fun findConnectionOwner(
            ipProtocol: Int,
            sourceAddress: String,
            sourcePort: Int,
            destinationAddress: String,
            destinationPort: Int,
        ): ConnectionOwner {
            val owner = ConnectionOwner()
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                runCatching {
                    val uid = connectivityManager?.getConnectionOwnerUid(
                        ipProtocol,
                        InetSocketAddress(sourceAddress, sourcePort),
                        InetSocketAddress(destinationAddress, destinationPort),
                    ) ?: -1
                    if (uid >= 0) {
                        owner.userId = uid
                        owner.userName = appContext.packageManager.getPackagesForUid(uid)?.firstOrNull() ?: ""
                    }
                }
            }
            return owner
        }

        override fun getInterfaces(): NetworkInterfaceIterator {
            val allInterfaces = mutableListOf<NetworkInterface>()
            val dnsServers = connectivityManager
                ?.activeNetwork
                ?.let { connectivityManager.getLinkProperties(it) }
                ?.dnsServers
                ?.mapNotNull { it.hostAddress }
                ?: emptyList()

            val iterator = JNetworkInterface.getNetworkInterfaces()?.toList()?.iterator() ?: emptyList<JNetworkInterface>().iterator()
            while (iterator.hasNext()) {
                val javaInterface = iterator.next()
                val mapped = NetworkInterface().apply {
                    index = runCatching { javaInterface.index }.getOrDefault(0)
                    name = javaInterface.name ?: ""
                    mtu = runCatching { javaInterface.mtu }.getOrDefault(0)
                    addresses = StringArray(javaInterface.interfaceAddresses.map { it.toPrefix() }.iterator())
                    dnsServer = StringArray(dnsServers.iterator())
                    flags = dumpFlags(javaInterface)
                    type = detectInterfaceType(javaInterface.name)
                    metered = connectivityManager
                        ?.activeNetwork
                        ?.let { connectivityManager.getNetworkCapabilities(it) }
                        ?.hasCapability(NetworkCapabilities.NET_CAPABILITY_NOT_METERED)
                        ?.not()
                        ?: false
                }
                allInterfaces.add(mapped)
            }
            return NetworkInterfaceArray(allInterfaces.iterator())
        }

        override fun includeAllNetworks(): Boolean = false

        override fun localDNSTransport(): LocalDNSTransport? = null

        override fun openTun(options: TunOptions): Int {
            appendBridgeLog("openTun requested by libbox, reusing project tun fd ${launchOptions.tunFd}")
            return launchOptions.tunFd
        }

        override fun readWIFIState(): WIFIState? {
            val wifiInfo = runCatching { wifiManager?.connectionInfo }.getOrNull() ?: return null
            val ssid = wifiInfo.ssid?.removePrefix("\"")?.removeSuffix("\"") ?: ""
            val bssid = wifiInfo.bssid ?: ""
            return WIFIState(ssid, bssid)
        }

        override fun sendNotification(notification: Notification) {
            appendBridgeLog("libbox notification: ${notification.title} ${notification.body}")
        }

        override fun startDefaultInterfaceMonitor(listener: InterfaceUpdateListener) {
            // optional; omitted in this thin adapter
        }

        override fun systemCertificates(): StringIterator {
            val certificates = mutableListOf<String>()
            runCatching {
                val keyStore = KeyStore.getInstance("AndroidCAStore")
                keyStore.load(null, null)
                val aliases = keyStore.aliases()
                while (aliases.hasMoreElements()) {
                    val cert = keyStore.getCertificate(aliases.nextElement()) ?: continue
                    val body = Base64.encodeToString(cert.encoded, Base64.NO_WRAP)
                    certificates += "-----BEGIN CERTIFICATE-----\n$body\n-----END CERTIFICATE-----"
                }
            }
            return StringArray(certificates.iterator())
        }

        override fun underNetworkExtension(): Boolean = false

        override fun usePlatformAutoDetectInterfaceControl(): Boolean = true

        override fun useProcFS(): Boolean = Build.VERSION.SDK_INT < Build.VERSION_CODES.Q

        private fun detectInterfaceType(name: String?): Int {
            val lower = name.orEmpty().lowercase()
            return when {
                lower.startsWith("wlan") || lower.startsWith("wifi") -> Libbox.InterfaceTypeWIFI
                lower.startsWith("rmnet") || lower.startsWith("ccmni") || lower.startsWith("pdp") -> Libbox.InterfaceTypeCellular
                lower.startsWith("eth") -> Libbox.InterfaceTypeEthernet
                else -> Libbox.InterfaceTypeOther
            }
        }

        private fun dumpFlags(networkInterface: JNetworkInterface): Int {
            var value = 0
            runCatching {
                if (networkInterface.isUp) value = value or OsConstants.IFF_UP
                if (networkInterface.isLoopback) value = value or OsConstants.IFF_LOOPBACK
                if (networkInterface.isPointToPoint) value = value or OsConstants.IFF_POINTOPOINT
                if (networkInterface.supportsMulticast()) value = value or OsConstants.IFF_MULTICAST
            }
            return value
        }

        private fun InterfaceAddress.toPrefix(): String {
            return if (address is Inet6Address) {
                "${Inet6Address.getByAddress(address.address).hostAddress}/$networkPrefixLength"
            } else {
                "${address.hostAddress}/$networkPrefixLength"
            }
        }
    }

    private class StringArray(private val iterator: Iterator<String>) : StringIterator {
        override fun hasNext(): Boolean = iterator.hasNext()
        override fun len(): Int = 0
        override fun next(): String = iterator.next()
    }

    private class NetworkInterfaceArray(
        private val iterator: Iterator<NetworkInterface>,
    ) : NetworkInterfaceIterator {
        override fun hasNext(): Boolean = iterator.hasNext()
        override fun next(): NetworkInterface = iterator.next()
    }

    private companion object {
        private const val TAG = "InetLibboxRuntime"
    }
}
