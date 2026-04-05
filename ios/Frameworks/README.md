Place `Libbox.xcframework` here for the PacketTunnel target.

How to build it from your uploaded sources:

1. unzip `sing-box-testing.zip` next to the project root as `sing-box-testing/`
2. run on macOS:

```bash
./tools/build_libbox_apple_from_uploaded_sources.sh
```

Expected output:

```text
ios/Frameworks/Libbox.xcframework
```

Then add `Libbox.xcframework` to the **PacketTunnel** extension target in Xcode.
Do not link it only to Runner.

Also verify that Runner Info.plist contains the key below and that it matches the real extension bundle id:

```text
INetPacketTunnelBundleIdentifier = <your Runner bundle id>.PacketTunnel
```
