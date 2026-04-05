# LTE bridge setup

This project now supports the flow:

App -> VLESS bridge -> mobile proxy provider -> Internet

## Important

- The mobile app must receive only bridge VLESS config.
- The upstream provider password must never be sent to the app.
- Backend/admin can store bridge-facing `vpn_payload` per location.
- Use `ru-lte` and `uz-lte` location codes so backend treats them as mobile locations.

## Files added for rollout

- `backend_admin/deploy/README_LTE_BRIDGE.md`
- `backend_admin/deploy/env/.env.lte.example`
- `backend_admin/deploy/sing-box/*.json`
