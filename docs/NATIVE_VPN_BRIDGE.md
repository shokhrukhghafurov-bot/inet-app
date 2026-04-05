# Native VPN bridge contract

Method channel name:

```text
inet/vpn
```

## Methods expected by Flutter

### connect
Input:

```json
{
  "config": {
    "protocol": "vless",
    "locationCode": "de-1",
    "server": "de1.example.com",
    "port": 443,
    "uuid": "11111111-1111-1111-1111-111111111111",
    "transport": "tcp",
    "security": "reality",
    "sni": "edge.example.com",
    "publicKey": "REALITY_PUBLIC_KEY",
    "shortId": "abcd1234",
    "fingerprint": "chrome",
    "mtu": 1400,
    "dnsServers": ["1.1.1.1", "8.8.8.8"]
  }
}
```

Starts the native permission flow if needed and then starts the OS VPN session with the selected VLESS config.

### disconnect
Input:

```json
{}
```

Stops the active native VPN session.

### status
Output string:

- `disconnected`
- `connecting`
- `connected`
- `disconnecting`
- `unsupported`

### snapshot
Output map:

```json
{
  "status": "connected",
  "error": null,
  "locationCode": "de-1",
  "connectedAt": 1765000000000,
  "reconnectOnLaunch": true,
  "permissionRequired": false,
  "protocol": "vless",
  "server": "de1.example.com",
  "transport": "tcp"
}
```

### appResumed
Called by Flutter when the app returns to foreground so native reconnect logic can resume.

### appBackgrounded
Called by Flutter when the app is backgrounded.
