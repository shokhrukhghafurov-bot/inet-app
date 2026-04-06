# INET sing-box runtime integration guide

This repo is now prepared for the last integration step: wiring the real native sing-box runtime.

## What is already done in this starter

### Android
- `InetVpnService.kt` creates the system VPN and TUN fd
- `SingBoxConfigFactory.kt` creates the mobile sing-box config
- `EmbeddedCoreBridge.kt` writes the config to disk and passes `tunFd` + `protectSocket(fd)`
- `LibboxSingBoxBinding.kt` resolves the runtime factory
- `LibboxRuntimeFactory.kt` now exists and points to one project adapter file

### iOS
- `PacketTunnelProvider.swift` creates the Packet Tunnel and passes `packetFlow`
- `SingBoxConfigBuilder.swift` creates the mobile sing-box config
- `EmbeddedCoreBridge.swift` writes the config to disk and passes `packetFlow`
- `LibboxSingBoxBinding.swift` resolves the runtime factory
- `LibboxRuntimeFactory.swift` now exists and points to one project adapter file

## Your remaining implementation files

### Android
Finish exactly this file:

```text
android/app/src/main/kotlin/com/example/inet_app/vpn/libbox/runtime/OfficialLibboxAndroidRuntime.kt
```

Pass into the real runtime:
- `options.configFile.absolutePath`
- `options.workingDirectory.absolutePath`
- `options.tunFd`
- `options.protectSocket(fd)`

### iOS
Finish exactly this file:

```text
ios/PacketTunnel/libbox/runtime/OfficialLibboxAppleRuntime.swift
```

Pass into the real runtime:
- `context.configURL.path`
- `context.workingDirectory.path`
- `context.packetFlow`

## Recommended order

1. Generate host projects if missing:
   `flutter create . --platforms=android,ios`
2. Merge host snippets from `docs/runtime/HOST_PROJECT_MERGE_SNIPPETS.md`
3. Make Android work first with `libbox.aar`
4. Then wire iOS with `Libbox.xcframework`

## Android checklist

1. Put runtime into `android/app/libs/libbox.aar`
2. Merge Android Gradle snippet
3. Keep manifest meta-data for binding/factory classes
4. Finish `OfficialLibboxAndroidRuntime.kt`
5. Make sure `protectSocket(fd)` is used by the runtime wrapper
6. Build and test one location from admin

## iOS checklist

1. Put runtime into `ios/Frameworks/Libbox.xcframework`
2. Add/link it to `PacketTunnel` target
3. Add `SINGBOX_RUNTIME_FACTORY_CLASS` into PacketTunnel Info.plist
4. Verify PacketTunnel entitlements
5. Finish `OfficialLibboxAppleRuntime.swift`
6. Build on a real device

## Common failure points

### Android
- AAR linked, but native `.so` files not packaged into APK
- wrong ABI for the test device
- `protectSocket(fd)` not used
- wrapper ignores `tunFd`

### iOS
- framework linked only to Runner and not to PacketTunnel
- PacketTunnel target cannot see the runtime files
- missing Network Extension entitlement
- runtime tries to create another VPN instead of using PacketTunnel `packetFlow`

## Honest limitation

This zip prepares the project structure and the last adapter files, but it does not bundle upstream GPL runtime binaries by itself.
That keeps your project clean and lets you fetch/build the runtime only from the official sources.
