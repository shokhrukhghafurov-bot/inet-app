# Build `Libbox.xcframework` for iOS from the uploaded sources

This project now contains the **iOS runtime wiring** for PacketTunnel, but Apple still needs a real `Libbox.xcframework`.

## What you already uploaded

- `sing-box-for-apple-dev.zip` — official Apple client source reference
- `sing-box-testing.zip` — contains the `build_libbox` logic used to generate `Libbox.xcframework`

## What I verified from your uploaded sources

Inside `sing-box-testing`:

- `Makefile` has `lib_apple`:

```make
lib_apple:
	go run ./cmd/internal/build_libbox -target apple
```

- `cmd/internal/build_libbox/main.go` builds Apple bindings and outputs `Libbox.xcframework`

## Build on macOS

1. Install Xcode, Go, and gomobile.
2. Unzip `sing-box-testing.zip` next to this project as `sing-box-testing/`.
3. Run:

```bash
./tools/build_libbox_apple_from_uploaded_sources.sh
```

If the build succeeds, you will get:

```text
ios/Frameworks/Libbox.xcframework
```

## In Xcode

Add `Libbox.xcframework` to the **PacketTunnel** extension target.

Important:

- Add it to **PacketTunnel**, not only to `Runner`
- Ensure **Embed & Sign** / target membership is correct for the extension
- Rebuild the iOS app on a real Mac with Xcode

## Code path already prepared in this patch

- `ios/PacketTunnel/libbox/LibboxRuntimeFactory.swift`
- `ios/PacketTunnel/libbox/runtime/OfficialLibboxAppleRuntime.swift`
- `ios/PacketTunnel/EmbeddedCoreBridge.swift`
- `ios/PacketTunnel/PacketTunnelProvider.swift`

## Honest status

After you add a real `Libbox.xcframework`, the iOS side is wired to:

- pass the sing-box config JSON
- let libbox configure the Packet Tunnel routes/DNS
- reuse the PacketTunnel file descriptor
- start/stop the embedded sing-box runtime inside NetworkExtension

This patch does **not** include a prebuilt Apple framework because that must be built on macOS with Apple toolchains.
