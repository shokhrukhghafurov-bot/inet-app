# sing-box runtime status after uploaded official files

## Android

This patch now contains a real Android runtime wiring:

- `android/app/libs/libbox.aar` copied from the uploaded official `libbox-main.zip`
- `android/app/src/main/kotlin/com/example/inet_app/vpn/libbox/runtime/OfficialLibboxAndroidRuntime.kt`
  now imports and uses real `io.nekohasekai.libbox.*` classes
- the adapter reuses the already-created project TUN file descriptor
- outbound sockets are protected through `VpnService.protect(fd)`

### Honest status

- Android is no longer a placeholder adapter.
- I did **not** run a final APK build here because this patch archive does not include the generated host Gradle files.
- You still must ensure the host Android app module links `android/app/libs/libbox.aar`.

## iOS

What you uploaded for Apple is the official source tree orientation repo, which is useful as a reference.

But this patch still does **not** contain a ready-to-link `Libbox.xcframework`.
Therefore iOS is **not yet fully runtime-ready**.

### What is still needed for iOS

- build or obtain `Libbox.xcframework`
- place it into `ios/Frameworks/Libbox.xcframework`
- link it to the `PacketTunnel` target
- replace the current placeholder in `ios/PacketTunnel/libbox/runtime/OfficialLibboxAppleRuntime.swift`

## Bottom line

- **Android:** real libbox bridge code added
- **iOS:** still waiting for built `Libbox.xcframework`


## v8 update

- Android: official `libbox.aar` already wired
- iOS: PacketTunnel now passes the provider into the embedded core bridge so libbox can call `setTunnelNetworkSettings(...)`
- iOS: added a real `OfficialLibboxAppleRuntime.swift` adapter guarded by `#if canImport(Libbox)`
- iOS: added `tools/build_libbox_apple_from_uploaded_sources.sh`
- iOS: added `docs/SINGBOX_IOS_BUILD_FROM_SOURCE.md`

Important: iOS still requires building a real `Libbox.xcframework` on macOS and linking it to the PacketTunnel target.
