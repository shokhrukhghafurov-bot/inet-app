# iOS setup

## Custom URL scheme

Add a URL type in Xcode / `Info.plist` with the scheme:

```text
inet
```

This handles links like:

```text
inet://login?code=abc123
```

## VPN bridge

Implement Packet Tunnel / Network Extension and expose these methods on the `inet/vpn` channel:

- `connect` with `{ config: { ...vless } }`
- `disconnect`
- `status`
