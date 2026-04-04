# Native VPN bridge contract

Method channel name:

```text
inet/vpn
```

Methods expected by Flutter:

## connect
Input:

```json
{ "locationCode": "de-1" }
```

## disconnect
Input:

```json
{}
```

## status
Output string:

- `disconnected`
- `connecting`
- `connected`
- `disconnecting`
- `unsupported`
