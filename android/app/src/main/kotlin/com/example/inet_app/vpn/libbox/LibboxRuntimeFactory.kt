package com.example.inet_app.vpn.libbox

import com.example.inet_app.vpn.SingBoxLaunchOptions
import com.example.inet_app.vpn.libbox.runtime.OfficialLibboxAndroidRuntime

/**
 * Default project runtime factory.
 *
 * This keeps the bridge stable and gives you exactly one project file to finish when you wire the
 * official sing-box Android runtime:
 *   - OfficialLibboxAndroidRuntime.kt
 *
 * Once you connect the real libbox classes there, the rest of the app can stay unchanged.
 */
class LibboxRuntimeFactory : AndroidLibboxRuntimeFactory {
    override fun createRuntime(options: SingBoxLaunchOptions): AndroidLibboxRuntime {
        return OfficialLibboxAndroidRuntime(options)
    }
}
