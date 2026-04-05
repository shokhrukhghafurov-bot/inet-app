package com.example.inet_app.vpn.libbox

import android.content.Context
import android.content.pm.PackageManager
import com.example.inet_app.vpn.AndroidSingBoxBinding
import com.example.inet_app.vpn.AndroidSingBoxSession
import com.example.inet_app.vpn.MissingSingBoxBindingException
import com.example.inet_app.vpn.SingBoxLaunchOptions
import java.io.Closeable
import java.lang.reflect.Method

/**
 * Project-facing adapter between EmbeddedCoreBridge and the real libbox wrapper you add later.
 *
 * How to finish the integration:
 * 1. add the sing-box/libbox Android dependency (AAR/JAR/SO)
 * 2. add a small wrapper class implementing [AndroidLibboxRuntimeFactory]
 * 3. optionally point AndroidManifest meta-data `com.example.inet_app.SINGBOX_RUNTIME_FACTORY_CLASS`
 *    to that wrapper class if you do not want to use one of the default names below
 *
 * The bridge now owns lifecycle and session shutdown. The only project-specific piece left is the
 * wrapper that translates [SingBoxLaunchOptions] into concrete libbox calls.
 */
interface AndroidLibboxRuntime {
    @Throws(Exception::class)
    fun start()

    fun stop()
}

interface AndroidLibboxRuntimeFactory {
    @Throws(Exception::class)
    fun createRuntime(options: SingBoxLaunchOptions): AndroidLibboxRuntime
}

class LibboxSingBoxBinding : AndroidSingBoxBinding {
    override fun start(options: SingBoxLaunchOptions): AndroidSingBoxSession {
        initializeOptionalLibboxRuntime(options.context)
        val runtime = resolveRuntimeFactory(options.context).createRuntime(options)
        try {
            runtime.start()
        } catch (error: Exception) {
            runCatching { runtime.stop() }
            throw error
        }
        return object : AndroidSingBoxSession {
            override fun stop() {
                runtime.stop()
            }
        }
    }

    private fun resolveRuntimeFactory(context: Context): AndroidLibboxRuntimeFactory {
        val candidates = linkedSetOf(
            manifestFactoryOverride(context),
            System.getProperty(SYSTEM_PROPERTY_FACTORY_CLASS),
            DEFAULT_FACTORY_CLASS,
            ALT_FACTORY_CLASS,
            LEGACY_FACTORY_CLASS,
        ).filterNotNull()

        for (className in candidates) {
            val instance = instantiate(className) ?: continue
            if (instance is AndroidLibboxRuntimeFactory) {
                return instance
            }
            reflectiveFactory(instance)?.let { return it }
        }

        throw MissingSingBoxBindingException(
            "No Android libbox runtime factory found. Add a class implementing AndroidLibboxRuntimeFactory " +
                "and point $MANIFEST_FACTORY_CLASS_KEY to it (or use $DEFAULT_FACTORY_CLASS).",
        )
    }

    private fun manifestFactoryOverride(context: Context): String? {
        return try {
            val applicationInfo = context.packageManager.getApplicationInfo(
                context.packageName,
                PackageManager.GET_META_DATA,
            )
            applicationInfo.metaData?.getString(MANIFEST_FACTORY_CLASS_KEY)?.trim()?.takeIf { it.isNotEmpty() }
        } catch (_: Exception) {
            null
        }
    }

    private fun instantiate(className: String): Any? {
        return try {
            val clazz = Class.forName(className)
            clazz.getDeclaredConstructor().newInstance()
        } catch (_: ClassNotFoundException) {
            null
        }
    }

    private fun reflectiveFactory(instance: Any): AndroidLibboxRuntimeFactory? {
        val method = findMethod(
            instance.javaClass,
            methodNames = listOf("createRuntime", "buildRuntime", "create"),
            parameterTypes = listOf(SingBoxLaunchOptions::class.java),
        ) ?: return null

        return object : AndroidLibboxRuntimeFactory {
            override fun createRuntime(options: SingBoxLaunchOptions): AndroidLibboxRuntime {
                val runtime = method.invoke(instance, options)
                    ?: throw IllegalStateException(
                        "${instance.javaClass.name}.${method.name} returned null instead of a libbox runtime.",
                    )
                return when (runtime) {
                    is AndroidLibboxRuntime -> runtime
                    else -> ReflectiveAndroidLibboxRuntime(runtime)
                }
            }
        }
    }

    private fun initializeOptionalLibboxRuntime(context: Context) {
        synchronized(initLock) {
            if (optionalInitDone) {
                return
            }
            optionalInitDone = true
            tryInvokeStatic(
                className = GO_SEQ_CLASS,
                methodNames = listOf("setContext", "SetContext"),
                argument = context.applicationContext,
            )
        }
    }

    private class ReflectiveAndroidLibboxRuntime(
        private val delegate: Any,
    ) : AndroidLibboxRuntime {
        override fun start() {
            val method = findMethod(
                delegate.javaClass,
                methodNames = listOf("start", "run", "launch", "resume"),
                parameterTypes = emptyList(),
            ) ?: throw IllegalStateException(
                "${delegate.javaClass.name} must expose a start()/run()/launch()/resume() method or implement AndroidLibboxRuntime."
            )
            method.invoke(delegate)
        }

        override fun stop() {
            val stopMethod = findMethod(
                delegate.javaClass,
                methodNames = listOf("stop", "close", "shutdown", "destroy", "cancel"),
                parameterTypes = emptyList(),
            )
            if (stopMethod != null) {
                runCatching { stopMethod.invoke(delegate) }
                return
            }
            if (delegate is Closeable) {
                val closeable = delegate as Closeable
                runCatching { closeable.close() }
            }
        }
    }

    private companion object {
        private const val MANIFEST_FACTORY_CLASS_KEY = "com.example.inet_app.SINGBOX_RUNTIME_FACTORY_CLASS"
        private const val SYSTEM_PROPERTY_FACTORY_CLASS = "inet.singbox.runtimeFactoryClass"
        private const val DEFAULT_FACTORY_CLASS = "com.example.inet_app.vpn.libbox.LibboxRuntimeFactory"
        private const val ALT_FACTORY_CLASS = "com.example.inet_app.vpn.libbox.MobileLibboxRuntimeFactory"
        private const val LEGACY_FACTORY_CLASS = "com.example.inet_app.vpn.libbox.DefaultLibboxRuntimeFactory"
        private const val GO_SEQ_CLASS = "go.Seq"

        private val initLock = Any()

        @Volatile
        private var optionalInitDone = false

        private fun tryInvokeStatic(className: String, methodNames: List<String>, argument: Any) {
            val clazz = try {
                Class.forName(className)
            } catch (_: ClassNotFoundException) {
                return
            }
            val method = findMethod(
                clazz,
                methodNames = methodNames,
                parameterTypes = listOf(argument.javaClass),
                acceptAssignableTypes = true,
                requireStatic = true,
            ) ?: return
            runCatching { method.invoke(null, argument) }
        }

        private fun findMethod(
            clazz: Class<*>,
            methodNames: List<String>,
            parameterTypes: List<Class<*>>,
            acceptAssignableTypes: Boolean = false,
            requireStatic: Boolean = false,
        ): Method? {
            return clazz.methods.firstOrNull { method ->
                if (requireStatic && !java.lang.reflect.Modifier.isStatic(method.modifiers)) {
                    return@firstOrNull false
                }
                if (method.name !in methodNames) {
                    return@firstOrNull false
                }
                val declaredParams = method.parameterTypes.toList()
                if (declaredParams.size != parameterTypes.size) {
                    return@firstOrNull false
                }
                declaredParams.zip(parameterTypes).all { (declared, expected) ->
                    if (acceptAssignableTypes) {
                        declared.isAssignableFrom(expected) || expected.isAssignableFrom(declared)
                    } else {
                        declared == expected
                    }
                }
            }
        }
    }
}
