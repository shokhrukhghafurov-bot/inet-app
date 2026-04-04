# INET app fixed notes

Что исправлено в этой версии:

- app теперь совместим с backend из `inet-vpn-fixed-v5`
- поддержан deep link login по `token` (`inet://login?token=...`)
- для bot → app сценария добавлена передача токена в `OPEN_APP_URL`
- app больше не требует `/auth/refresh` для MVP
- `/plans`, `/devices`, `/locations`, `/locations/status` теперь правильно читаются из ответов вида `{ "items": [...] }`
- `/auth/me` и `/subscriptions/me` теперь правильно читаются из вложенных JSON-ответов
- регистрация устройства теперь отправляет `device_name` и `device_fingerprint`
- кнопка Connect перед VPN-подключением проверяет подписку и регистрирует текущее устройство
- добавлен таймер VPN-сессии и 4-tab shell: Home / Locations / Subscription / Settings
- исправлен отсутствующий l10n key `openBot`

Чтобы сценарий bot → app работал:

1. В backend/bot окружении задай `OPEN_APP_URL=inet://login`
2. Собери приложение с корректным `DEV_BASE_URL` или `PROD_BASE_URL`
3. В боте кнопка `Открыть приложение` теперь будет открывать ссылку вида:
   `inet://login?token=<jwt>&lang=ru`

Ограничение:

- ручной одноразовый код как отдельная backend-фича здесь не реализован полноценно.
  Рабочий путь для MVP: вход по deep link из Telegram-бота.
