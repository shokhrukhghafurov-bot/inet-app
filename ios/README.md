iOS host files for the INET Flutter starter.

This starter originally ships without a generated iOS host project.
If you are wiring this into a fresh clone, run:

flutter create . --platforms=android,ios

Then merge these files into the generated Runner target and add a Packet Tunnel extension target named `PacketTunnel` in Xcode.
Update bundle identifiers if your app does not use the default Flutter identifiers.

Important for a real working TUN build:
- add `ios/PacketTunnel/*` sources to the PacketTunnel extension target
- add `ios/Runner/Vpn/*` sources to the Runner target
- link `ios/Frameworks/Libbox.xcframework` to the PacketTunnel target
- keep the Runner Info.plist key `INetPacketTunnelBundleIdentifier` aligned with the real PacketTunnel extension bundle identifier
- make sure the PacketTunnel target Info.plist stays on `$(PRODUCT_BUNDLE_IDENTIFIER)` and the principal class is `$(PRODUCT_MODULE_NAME).PacketTunnelProvider`

If you only have the uploaded source zips and not a built Apple framework yet, run on macOS:

./tools/build_libbox_apple_from_uploaded_sources.sh

That script creates:

ios/Frameworks/Libbox.xcframework
