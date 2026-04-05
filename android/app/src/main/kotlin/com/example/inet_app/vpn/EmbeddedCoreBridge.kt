package com.example.inet_app.vpn

import android.content.Context
import java.io.File
import java.util.UUID
import java.util.concurrent.ConcurrentHashMap

class MissingSingBoxBindingException(message: String) : IllegalStateException(message)

data class SingBoxLaunchOptions(
    val context: Context,
    val sessionId: String,
    val configJson: String,
    val configFile: File,
    val workingDirectory: File,
    val tunFd: Int,
    val protectSocket: (Int) -> Boolean,
)

interface AndroidSingBoxSession {
    fun stop()
}

interface AndroidSingBoxBinding {
    @Throws(Exception::class)
    fun start(options: SingBoxLaunchOptions): AndroidSingBoxSession
}

object EmbeddedCoreBridge {
    private const val DEFAULT_BINDING_CLASS = "com.example.inet_app.vpn.libbox.LibboxSingBoxBinding"
    private const val ALT_BINDING_CLASS = "com.example.inet_app.vpn.LibboxSingBoxBinding"

    @Volatile
    private var bindingOverride: AndroidSingBoxBinding? = null
    private val sessions = ConcurrentHashMap<String, AndroidSingBoxSession>()

    fun installSingBoxBinding(binding: AndroidSingBoxBinding) {
        bindingOverride = binding
    }

    fun clearSingBoxBindingOverride() {
        bindingOverride = null
    }

    @Throws(Exception::class)
    fun startSingBox(
        context: Context,
        configJson: String,
        tunFd: Int,
        protectSocket: (Int) -> Boolean,
    ): String {
        val binding = resolveSingBoxBinding(context)
        val sessionId = UUID.randomUUID().toString()
        val runtimeDir = prepareRuntimeDirectory(context, sessionId)
        val configFile = File(runtimeDir, "sing-box.json").apply { writeText(configJson) }
        val options = SingBoxLaunchOptions(
            context = context.applicationContext,
            sessionId = sessionId,
            configJson = configJson,
            configFile = configFile,
            workingDirectory = runtimeDir,
            tunFd = tunFd,
            protectSocket = protectSocket,
        )

        try {
            val session = binding.start(options)
            sessions[sessionId] = session
            return sessionId
        } catch (error: Exception) {
            runCatching { runtimeDir.deleteRecursively() }
            throw error
        }
    }

    fun stopSingBox(sessionId: String) {
        val session = sessions.remove(sessionId)
        runCatching { session?.stop() }
    }

    fun startXray(
        configJson: String,
        tunFd: Int,
        protectSocket: (Int) -> Boolean,
    ): String {
        throw UnsupportedOperationException(
            "Xray bridge is not implemented in this patch. Keep engine=sing-box until you add an Xray binding.",
        )
    }

    fun stopXray(sessionId: String) {
        // Intentionally left blank until an Xray binding exists.
    }

    private fun prepareRuntimeDirectory(context: Context, sessionId: String): File {
        val base = File(context.noBackupFilesDir, "inet-singbox")
        val runtimeDir = File(base, sessionId)
        runtimeDir.mkdirs()
        return runtimeDir
    }

    private fun resolveSingBoxBinding(context: Context): AndroidSingBoxBinding {
        bindingOverride?.let { return it }

        val candidateNames = linkedSetOf(
            context.applicationInfo.metaData?.getString("com.example.inet_app.SINGBOX_BINDING_CLASS"),
            DEFAULT_BINDING_CLASS,
            ALT_BINDING_CLASS,
        ).filterNotNull()

        for (name in candidateNames) {
            val binding = instantiateBinding(name)
            if (binding != null) {
                return binding
            }
        }

        throw MissingSingBoxBindingException(
            "No Android sing-box binding found. Add a class implementing AndroidSingBoxBinding, " +
                "for example $DEFAULT_BINDING_CLASS, link your libbox AAR/SO, and start the core there.",
        )
    }

    private fun instantiateBinding(className: String): AndroidSingBoxBinding? {
        return try {
            val clazz = Class.forName(className)
            val instance = clazz.getDeclaredConstructor().newInstance()
            instance as? AndroidSingBoxBinding
        } catch (_: ClassNotFoundException) {
            null
        } catch (error: Exception) {
            throw IllegalStateException("Failed to initialize sing-box binding $className", error)
        }
    }
}
