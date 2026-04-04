# INET App Starter

Starter-kit for the **INET** mobile client on **Flutter** with:

- Android + iOS target structure
- Riverpod state management
- go_router navigation
- Dio network layer
- flutter_secure_storage token storage
- intl / l10n setup for RU + EN
- deep link login flow (`inet://login?code=...`)
- VPN bridge placeholder for native Android/iOS modules

## What is included

- App foundation and dark theme
- Splash, Login, Home, Locations, Subscription, Devices, Settings screens
- API repositories for the backend contract
- Access/refresh token storage and refresh interceptor
- Bottom navigation shell
- Native VPN method channel placeholder (`inet/vpn`)

## Backend contract expected by this starter

### Auth
- `POST /auth/code`
- `POST /auth/refresh`
- `GET /auth/me`
- `POST /auth/logout` (optional but supported)

### App
- `GET /app/config`
- `GET /subscriptions/me`
- `GET /plans`
- `GET /devices`
- `POST /devices/register`
- `DELETE /devices/{id}`
- `GET /locations`
- `GET /locations/status`

## How to start

1. Create an empty Git repo called `inet-app`.
2. Copy this starter into the repo root.
3. If you do not already have native folders, generate them:

```bash
flutter create . --platforms=android,ios
```

4. Install packages:

```bash
flutter pub get
```

5. Run dev build:

```bash
flutter run -t lib/main_dev.dart   --dart-define=DEV_BASE_URL=https://api-dev.example.com   --dart-define=DEV_BOT_URL=https://t.me/your_bot   --dart-define=DEV_SUPPORT_URL=https://t.me/your_support
```

6. Run prod build:

```bash
flutter run -t lib/main_prod.dart   --dart-define=PROD_BASE_URL=https://api.example.com   --dart-define=PROD_BOT_URL=https://t.me/your_bot   --dart-define=PROD_SUPPORT_URL=https://t.me/your_support
```

## Native follow-up

### Android
- Configure URL scheme / app links in `android/app/src/main/AndroidManifest.xml`
- Implement VPN module with `VpnService`
- Bind it to the `inet/vpn` method channel

### iOS
- Configure custom URL scheme / universal links in Xcode and `Info.plist`
- Add Packet Tunnel extension with `NetworkExtension`
- Bind it to the `inet/vpn` method channel

See `docs/ANDROID_SETUP.md`, `docs/IOS_SETUP.md`, and `docs/NATIVE_VPN_BRIDGE.md`.
