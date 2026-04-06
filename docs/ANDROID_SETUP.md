# Android setup

## Deep link scheme

Add an intent filter for the INET login link in `android/app/src/main/AndroidManifest.xml`.

```xml
<intent-filter android:autoVerify="false">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="inet" android:host="login" />
</intent-filter>
```

This handles links like:

```text
inet://login?code=abc123
```

## VPN bridge

Implement native Android VPN logic with `VpnService` and expose these methods on the `inet/vpn` channel:

- `connect` with `{ config: { ...vless } }`
- `disconnect`
- `status`
