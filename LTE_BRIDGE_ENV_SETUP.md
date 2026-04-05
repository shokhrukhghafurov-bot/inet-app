# Native VPN implementation notes

This follow-up changes the mobile contract from `locationCode`-only to **authenticated VLESS config delivery**.

## What is implemented

### Flutter
- `VpnBridge.connect()` now sends a full `config` payload instead of only `locationCode`
- `VpnAccessRepository` fetches `GET /vpn/config/{locationCode}` before connect
- `VlessConfig` model added for native channel payloads
- `VpnSnapshot` now exposes `protocol`, `server`, and `transport`
- lifecycle hooks remain: `appResumed`, `appBackgrounded`

### Backend
- `GET /vpn/config/{locationCode}` added behind authenticated user access
- `locations` now support `vpn_payload` JSON for per-location protocol config
- admin location create/patch payloads can carry `vpn_payload`

### Android
- `MainActivity` now validates a full VLESS config payload
- `VpnStateStore` persists full config JSON for reconnect after reopen
- `InetVpnService` now restores reconnect state from saved VLESS config
- TUN setup uses default IPv4/IPv6 routes and config-driven DNS/MTU

### iOS
- `IOSVpnBridge` now provisions `NETunnelProviderManager` from full VLESS config
- reconnect metadata persists with the saved config payload
- `PacketTunnelProvider` now reads VLESS summary fields from `providerConfiguration`
- tunnel settings use default IPv4/IPv6 routes and config-driven DNS/MTU

## Important limitation

This repo is now **VLESS-ready at the contract/config level**, but it still does **not** include the actual VLESS packet engine.

So the project now does these parts correctly:
- backend can return per-location authenticated VLESS config
- Flutter fetches the config and sends it through `inet/vpn`
- Android/iOS persist that config and restore reconnect state
- OS VPN sessions are created by `VpnService` / `PacketTunnelProvider`

But these parts are still required for a real production tunnel:
- Android: read packets from TUN and forward them through a VLESS outbound
- iOS: read packets from `packetFlow` and forward them through a VLESS outbound
- plug in your actual core/engine (`xray-core`, `sing-box`, or your own transport layer)
- device/session policy and config rotation on the backend

## Before building

This starter zip did not include generated Flutter host projects.
Run this first if needed:

```bash
flutter create . --platforms=android,ios
```

Then merge the native files from this repo into the generated Android and iOS host folders.

## Package / bundle identifiers to review

- Android package currently assumes `com.example.inet_app`
- iOS Packet Tunnel bundle currently assumes `com.example.inetApp.PacketTunnel`

Adjust them to match your real application ids before building.

## LTE bridge add-on in this fix pack

This patch adds an env-first LTE bridge workflow around the existing VLESS contract:

- backend/admin can now edit raw `vpn_payload` from the VPN locations panel
- env LTE locations can be merged into the built-in catalog instead of replacing it completely
- ready-to-fill bridge and env templates are included under `deploy/bridge` and `deploy/backend`
- Android/iOS now include `LibboxRuntimeFactory` placeholder hooks so the remaining work is isolated to one file per platform after you link the real libbox runtime

What is still intentionally external:

- the real mobile proxy provider credentials live on the bridge only
- the actual libbox AAR / xcframework is still not included in this repo snapshot
